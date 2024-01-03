(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local Animate (require :playtime.animate))
(local Component (require :playtime.component))
(local CommonComponents (require :playtime.common.components))
(local CardComponents (require :playtime.common.card.components))
(local CardUtils (require :playtime.common.card.utils))
(local App (require :playtime.app))
(local Window (require :playtime.app.window))

(local {: api} vim)
(local uv (or vim.loop vim.uv))
(local M (setmetatable {} {:__index App}))
(local Logic (require :playtime.game.optrita-lines.logic))

(local AppState {})

(set AppState.Default (App.State.build :Default {:delegate {:app App.State.DefaultAppState}}))
(set AppState.NewRound (App.State.build :NewRound {:delegate {:app AppState.Default}}))
(set AppState.PickTrump (App.State.build :PickTrump {:delegate {:app AppState.Default}}))
(set AppState.PickCard (App.State.build :PickCard {:delegate {:app AppState.Default}}))
(set AppState.PlayTrick (App.State.build :PlayTrick {:delegate {:app AppState.Default}}))
(set AppState.ResolveTrick (App.State.build :ResolveTrick {:delegate {:app AppState.Default}}))
(set AppState.GameEnded (App.State.build :GameEnded {:delegate {:app AppState.Default}}))

;;
;; Default
;;

(fn AppState.Default.OnEvent.input.<LeftMouse> [app [click-location & rest] pos]
  (case click-location
    [:menu idx nil &as menu-item]
    (app:push-state App.State.DefaultInMenuState {: menu-item})))

(fn AppState.Default.OnEvent.app.new-game [app]
  (app:setup-new-game app.game-config nil)
  (vim.defer_fn #(app:switch-state AppState.NewRound) 300))

(fn AppState.Default.OnEvent.app.restart-game [app]
  (app:setup-new-game app.game-config app.seed)
  (vim.defer_fn #(app:switch-state AppState.NewRound) 300))

(fn AppState.Default.OnEvent.app.replay [app {: replay :verify ?verify :state ?state}]
  (case replay
    [nil] app ;; TODO: verify game against verify
    [action & rest] (case action
                      [nil] (app:queue-event :app :replay {:replay rest :verify ?verify})
                      action (case-try
                               action [f-name & args]
                               (. Logic.Action f-name) f
                               (f app.game (table.unpack args)) (next-game events)
                               (let [after #(do
                                              ;; TODO: this loads into an invalid state
                                              (app:switch-state AppState.Default)
                                              (app:queue-event :app :replay {:replay rest :verify ?verify})
                                              (app:update-game next-game action))
                                     ;; TODO: generic `build-animation-for action data after opts`?
                                     ;; TODO: put replay in App.State.DefaultAppState
                                     timeline (app:build-event-animation events after {:duration-ms 80})]
                                 (app:switch-state App.State.DefaultAnimatingState timeline))
                               (catch
                                 (nil err) (error err))))))

(fn AppState.GameEnded.activated [app]
  (set app.ended-at (os.time))
  (let [other [(string.fmt "Time: %ds" (- app.ended-at app.started-at))]
        result (Logic.Query.game-result app.game)]
    (app.components.game-report:update result other)))

(fn AppState.GameEnded.OnEvent.input.<LeftMouse> [app [location] pos]
  (case location
    [:menu] (AppState.Default.OnEvent.input.<LeftMouse> app [location] pos)))

;;
;; New Round
;;

(fn AppState.NewRound.activated [app]
  ;; two steps to get around card animation memo-ise insert-then-draw issue, and
  ;; shuffle-draw issue.
  (let [(next-game events) (Logic.Action.clear-round app.game)
        after #(do
                 (app:update-game next-game [:clear-round])
                 (let [(next-game events) (Logic.Action.new-round app.game)
                       after #(do
                                (app:update-game next-game [:new-round])
                                (app:switch-state AppState.PickTrump))
                       timeline (app:build-event-animation events after {:duration-ms 300} (length next-game.hand))]
                   (app:switch-state App.State.DefaultAnimatingState timeline)))
        timeline (app:build-event-animation events after {:duration-ms 180} (length next-game.hand))]
    (app:switch-state App.State.DefaultAnimatingState timeline)))

;;
;; Pick Trump
;;

(fn AppState.PickTrump.activated [app]
  (app.components.pick-trump-label:set-visible true))

(fn AppState.PickTrump.deactivated [app]
  (app.components.pick-trump-label:set-visible false))

(fn AppState.PickTrump.OnEvent.input.<LeftMouse> [app [location] pos]
  (set app.state.context.hover nil)
  (case location
    [:hand n] (set app.state.context.hover [:hand n])
    [:menu] (AppState.Default.OnEvent.input.<LeftMouse> app [location] pos)))

(fn AppState.PickTrump.OnEvent.input.<LeftDrag> [app [location] pos]
  (set app.state.context.hover nil)
  (case location
    [:hand n] (set app.state.context.hover [:hand n])))

(fn AppState.PickTrump.OnEvent.input.<LeftRelease> [app [location] pos]
  (set app.state.context.hover nil)
  (case location
    [:hand n] (case-try
                (Logic.Action.pick-trump app.game n) (next-game moves)
                (let [after #(do
                               (app:update-game next-game [:pick-trump n])
                               (app:switch-state AppState.PickCard))
                      timeline (app:build-event-animation moves after {} (length next-game.hand))]
                  (app:switch-state App.State.DefaultAnimatingState timeline))
                (catch
                  (nil e) (app:notify e)))))

;;
;; Pick Card
;;

(fn AppState.PickCard.activated [app]
  (when (Logic.Query.round-ended? app.game)
    (let [next-game (Logic.Action.score-round app.game)]
      (app:update-game next-game [:score-round]))
    (if (Logic.Query.game-ended? app.game)
      (app:switch-state AppState.GameEnded)
      (app:switch-state AppState.NewRound))))

(fn AppState.PickCard.OnEvent.input.<LeftMouse> [app [location] pos]
  (case location
    [:hand n] (app:switch-state AppState.PlayTrick {:hand [:hand n]})
    ([:menu] _) (AppState.Default.OnEvent.input.<LeftMouse> app [location] pos)))
;;
;; Play Trick
;;

(fn AppState.PlayTrick.OnEvent.input.<LeftMouse> [app [location] pos]
  (case (values location app.state.context.hand)
    ;; put down, play is handled by left-release
    ([:hand n] [:hand n]) (set app.state.context.lifting-from nil)
    ([:menu] _) (AppState.Default.OnEvent.input.<LeftMouse> app [location] pos)))

(fn AppState.PlayTrick.OnEvent.input.<LeftDrag> [app [location] position]
  (if (not app.state.context.drag-start)
    (case (values location app.state.context.hand)
      ([:hand n] [:hand n]) (set app.state.context.drag-start location)))
  (case (values app.state.context.hand app.state.context.drag-start)
    ([:hand n] [:hand n]) (set app.state.context.drag-position position)))

(fn AppState.PlayTrick.OnEvent.input.<LeftRelease> [app [_holding location] pos]
  (let [[_hand hand-n] app.state.context.hand]
    (case location
      [:play] (case-try
                (Logic.Action.play-trick app.game hand-n location) (next-game events)
                (let [events (accumulate [(t memo) (values [] [:hand hand-n]) _ e (ipairs events)]
                               (case e
                                 [:face-up [:grid row col]]
                                 (values (table.join t [[:move memo [:grid-comp row col]]
                                                        e
                                                        [:wait 300]])
                                         [:grid-comp row col])
                                 [:move _ [:trick]] (values (table.join t [[:wait 300] e]) memo)
                                 _ (values (table.insert t e) memo)))
                      after #(do
                               (app:update-game next-game [:play-trick hand-n location])
                               (if (accumulate [winner? false _ e (ipairs events) &until winner?]
                                     (case e [:move _ [:trick]] true))
                                 (app:switch-state AppState.PickCard)
                                 (let [choices (case location
                                                 [:play :top col] (fcollect [i 1 6] [:grid i col])
                                                 [:play :bottom col] (fcollect [i 6 1 -1] [:grid i col])
                                                 [:play :left row] (fcollect [i 1 6] [:grid row i])
                                                 [:play :right row] (fcollect [i 6 1 -1] [:grid row i]))]
                                   (app:switch-state AppState.ResolveTrick {:hand hand-n
                                                                            :card-pos pos
                                                                            : choices}))))
                      timeline (app:build-event-animation events after {} (length next-game.hand))]
                  (app:switch-state App.State.DefaultAnimatingState timeline))
                (catch
                  (nil e) (do
                            (app:notify e)
                            (app:switch-state AppState.PickCard))))
      _ (app:switch-state AppState.PickCard))))

(fn AppState.PlayTrick.OnEvent.input.<RightMouse> [app [location] pos]
  (app:switch-state AppState.PickCard))

(fn AppState.PlayTrick.tick [app]
  (each [location card (Logic.iter-cards app.game)]
    (let [comp (. app.card-id->components card.id)]
      (comp:update location card)
      (case (values location app.state.context)
        ([:hand n] {:hand [:hand n] :drag-position {: row : col}})
        (comp:set-position {:row (- row 2)
                            :col (- col 2)
                            :z (app:z-index-for-layer :lift)})))))

;;
;; ResolveTrick
;;

(fn AppState.ResolveTrick.activated [app]
  (app.components.pick-resolve-label:set-visible true))

(fn AppState.ResolveTrick.deactivated [app]
  (app.components.pick-resolve-label:set-visible false))

(fn AppState.ResolveTrick.valid-choice? [app location]
  (accumulate [b false _ [_grid row col] (ipairs app.state.context.choices) &until b]
    (case location
      (where [:grid (= row) (= col)]) true)))

(fn AppState.ResolveTrick.tick [app]
  (each [location card (Logic.iter-cards app.game)]
    (let [comp (. app.card-id->components card.id)]
      (comp:update location card)
      (case (values location app.state.context)
        ([:hand n] {:hand n :card-pos {: row : col}})
        (comp:set-position {:row (- row 2)
                            :col (- col 2)
                            :z (app:z-index-for-layer :lift)})
        ([:grid row col] {:hover [:grid row col]})
        (let [{: row : col} (app:location->position [:grid row col])]
          (comp:set-position {:row (- row 1)
                              :col col 
                              :z (app:z-index-for-layer :lift)}))))))

(fn AppState.ResolveTrick.OnEvent.input.<LeftMouse> [app [location] pos]
  (case location
    (where [:grid] (AppState.ResolveTrick.valid-choice? app location))
    (set app.state.context.hover location)
    _ (set app.state.context.hover nil)))

(fn AppState.ResolveTrick.OnEvent.input.<LeftDrag> [app [location] pos]
  (case location
    (where [:grid] (AppState.ResolveTrick.valid-choice? app location))
    (set app.state.context.hover location)
    _ (set app.state.context.hover nil)))

(fn AppState.ResolveTrick.OnEvent.input.<LeftRelease> [app [location] pos]
  (case location
    (where [:grid] (AppState.ResolveTrick.valid-choice? app location))
    (case-try
      app.state.context.hand hand-n
      (Logic.Action.force-trick app.game hand-n location) (next-game events)
      (let [after #(do
                     (app:update-game next-game [:force-trick hand-n location])
                     (app:switch-state AppState.PickCard))
            timeline (app:build-event-animation events after {} (length next-game.hand))]
        (app:switch-state App.State.DefaultAnimatingState timeline))
      (catch
        (nil e) (app:notify e)))
    [:menu] (AppState.Default.OnEvent.input.<LeftMouse> app [location] pos)))


;;
;; App
;;

(fn M.build-event-animation [app events after ?opts ?hand-length]
  (fn location->position [_proxy location]
    (if (= AppState.PlayTrick app.state.module)
      (let [{:hand [_ hand-n] :drag-position {: row : col}} app.state.context]
        (case location
          (where [:hand (= hand-n)]) {:row (- row 2) :col (- col 2) :z (app:z-index-for-layer :lift)}
          _ (app:location->position location ?hand-length)))
      (app:location->position location ?hand-length)))

  (if ?hand-length
    (let [proxy (setmetatable {: location->position}
                              {:__index app})]
      (CardUtils.build-event-animation proxy events after ?opts))
    (CardUtils.build-event-animation app events after ?opts)))

(fn M.location->position [app location ?hand-length]
  (let [{:height card-height :width card-width} app.card-style
        grid {:row card-height
              :col (+ 1 (* 3 card-width))}
        draw {:row (+ grid.row 1 (* 7 (- card-height 1)))
              :col (- grid.col 3 (* card-width))}
        ;; We layout the grid as a 8x8, where 1,8 is the "play"/"drop" edges
        hand {:row draw.row
              :col (+ draw.col 3 (* 4 card-width) -3)}]
    (case (or ?hand-length (length app.game.hand))
      0 nil
      1 nil
      n (set hand.col (- hand.col (* 2 (- n 1)))))
    (case location
      [:label :score :grid] {:row 2
                             :col (+ grid.col (* card-width 7))
                             :z (app:z-index-for-layer :base)}
      [:label :score :player] {:row 2
                               :col 3
                               :z (app:z-index-for-layer :base)}
      [:draw card-n] {:row draw.row
                      :col draw.col
                      :z (app:z-index-for-layer :cards card-n)}
      [:trick who n card-n] (let [col (case who
                                        :grid (+ grid.col (* 7 card-width) (* 3 (- card-n 1)))
                                        :player (+ grid.col 3 (* -3 card-width) (* 3 (- card-n 1))))]
                              {:row (+ 3 (* (- card-height 1) (- n 1)))
                               :col col
                               :z (+ (* 2 n) card-n)})
      [:trump _] {:row draw.row
                  :col (+ draw.col 0)
                  :z (app:z-index-for-layer :cards 54)}
      [:hand n]  {:row hand.row
                  :col (+ hand.col (* 4 (- n 1)))
                  :z (app:z-index-for-layer :hand n)}
      [:grid row col] {:row (+ grid.row (* (- card-height 1) (- row 1)))
                       :col (+ grid.col (* (- col 1) (- card-width 0)))
                       :z (app:z-index-for-layer :cards (+ (* (- row 1) 6) col))}
      [:grid-comp row col] {:row (+ grid.row 1 (* (- card-height 1) (- row 1)))
                            :col (+ grid.col 3 (* (- col 1) (- card-width 0)))
                            :z (app:z-index-for-layer :cards (+ 100 (* row 6) col))}
      [:play :left row] {:row (+ grid.row (* (- card-height 1) (- row 1)))
                         :col (- grid.col card-width)
                         :z 1}
      [:play :right row] {:row (+ grid.row (* (- card-height 1) (- row 1)))
                          :col (+ grid.col 1 (* 6 (- card-width 0)))
                          :z 1}
      [:play :top col] {:row (- grid.row (- card-height 1))
                        :col (+ grid.col (* (- col 1) card-width))
                        :z 1}
      [:play :bottom col] {:row (+ grid.row 1 (* (- card-height 1) 6))
                           :col (+ grid.col (* (- col 1) card-width))
                           :z 1})))

(λ M.start [app-config game-config ?seed]
  (let [app (-> (App.build "Optrita Lines"
                           :optrita-lines
                           app-config
                           game-config)
                (setmetatable {:__index M}))
        view (Window.open :optrita-lines
                          (App.build-default-window-dispatch-options app)
                          {:width 73
                           :height 31
                           :window-position app-config.window-position
                           :minimise-position app-config.minimise-position})
        _ (table.merge app.z-layers {:cards 25 :hand 100 :label 100 :lift 200 :animation 200})]
    (set app.view view)
    (set app.card-style {:width 6 :height 4 :colors 4 :stacking :horizontal-left})
    (app:setup-new-game app.game-config ?seed)
    (vim.defer_fn #(app:switch-state AppState.NewRound) 300)
    (app:render)))

(λ M.setup-new-game [app game-config ?seed]
  (app:new-game Logic.build game-config ?seed)
  (app:build-components)
  (app:switch-state AppState.Default)
  app)

(λ M.build-components [app]
  (fn build-label [text position]
    (let [{: row : col : z} position]
      (-> (Component.build
            (fn [self enabled]
              (let [hl (if enabled "@playtime.ui.on" "@playtime.ui.on")]
                (self:set-content [[[text hl]]]))))
          (Component.set-position position)
          (Component.set-size {:width (length text) :height 1})
          (Component.set-content [[[text "@playtime.ui.on"]]]))))

  (fn build-score [text limit position]
    (let [{: row : col : z} position]
      (-> (Component.build
            (fn [self score]
              (let [text (string.format "%s: %d/%d" text score limit)]
                (self:set-content [[[text "@playtime.ui.on"]]])
                (self:set-size {:width (length text) :height 1}))))
          (Component.set-position position)
          (: :update 0))))

  (fn play-drop [side position tag]
    (let [{: row : col : z} position
          color "@playtime.ui.off"
          content (case side
                    :left [[["     " color]]
                           [["   → " color]]
                           [["     " color]]
                           [["     " color]]]
                    :right [[["     " color]]
                            [["     " color]]
                            [["←    " color]]
                            [["     " color]]]
                    :top [[["      " color]]
                          [["      " color]]
                          [["      " color]]
                          [["  ↓   " color]]]
                    :bottom [[["  ↑   " color]]
                             [["      " color]]
                             [["      " color]]
                             [["      " color]]])
          content [[["     " color]]
                   [["     " color]]
                   [["     " color]]
                   [["     " color]]]]
      (-> (Component.build
            (fn [self enabled]
              (let [hl (if enabled "@playtime.ui.on" "@playtime.ui.off")]
                (self:set-content content))))
          (Component.set-tag tag)
          (Component.set-position position)
          (Component.set-size {:width 5 :height 4})
          (Component.set-content content))))

  (let [card-card-components (collect [location card (Logic.iter-cards app.game)]
                               (let [comp (CardComponents.card #(app:location->position $...)
                                                               location
                                                               card
                                                               app.card-style)]
                                 (values card.id comp)))
        menubar (CommonComponents.menubar [["Optrita: Lines" [:file]
                                            [["" nil]
                                             ["New Game" [:new-game]]
                                             ["Restart Game" [:restart-game]]
                                             ["" nil]
                                             ["Undo" [:undo]]
                                             ; ["" nil]
                                             ; ["Save current game" [:save]]
                                             ; ["Load last save" [:load]]
                                             ["" nil]
                                             ["Quit" [:quit]]
                                             ["" nil]
                                             [(string.format "Seed: %s" app.seed) nil]]]]
                                          {:width app.view.width
                                           :z (app:z-index-for-layer :menubar)})
        pick-trump-label (-> (build-label "Pick trump suit" {:row 24 :col 29 :z 100})
                             (: :set-visible false))
        pick-resolve-label (-> (build-label "Pick card to remove" {:row 24 :col 27 :z 100})
                               (: :set-visible false))
        game-report (CommonComponents.game-report app.view.width
                                                app.view.height
                                                (app:z-index-for-layer :report)
                                                [[:player "The GRID has been vanquished"]
                                                 [:grid "The GRID's reign of terror continues"]])
        droppers (faccumulate [t [] i 1 6]
                   (icollect [_ side (ipairs [:top :bottom :left :right]) &into t]
                     (-> 
                       ; (CardComponents.slot #(table.set (app:location->position $...)
                       ;                                  :z (app:z-index-for-layer :base))
                       ;                      [:play side i]
                       ;                      app.card-style)
                       (play-drop side
                                    (app:location->position [:play side i])
                                    [:play side i])
                         ;; TODO: we need two components, the arrow (invisble then visible)
                         ;; and the dropper which is always "visible" but empty
                         ;; content, visible so we can interact with is.
                         (: :set-visible true))))
        droppers-by-tag (collect [_ d (ipairs droppers)]
                          (values d.tag d))
        grid-score (build-score "Grid"
                                app.game.rules.score-limit.grid
                                (app:location->position [:label :score :grid]))
        player-score (build-score "Player"
                                  app.game.rules.score-limit.player
                                  (app:location->position [:label :score :player]))]
    (set app.card-id->components card-card-components)
    (set app.droppers-by-tag droppers-by-tag)
    (table.merge app.components {: droppers
                                 : menubar
                                 : game-report
                                 : pick-trump-label
                                 : pick-resolve-label
                                 : grid-score : player-score
                                 :cards (table.values card-card-components)})))


(fn M.render [app]
  (app.view:render [app.components.droppers
                    app.components.cards
                    [app.components.pick-trump-label
                     app.components.pick-resolve-label
                     app.components.grid-score
                     app.components.player-score]
                    [app.components.game-report
                     app.components.menubar]])
  app)

(fn M.tick [app]
  (let [now (uv.now)]
    (app:process-next-event)
    (case (. app.state.module.tick)
      f (f app)
      _ (each [location card (Logic.iter-cards app.game)]
          (let [comp (. app.card-id->components card.id)]
            (comp:update location card)
            (case app.state.context
              {:hover [:hand n]} (case location
                                   (where [:hand (= n)])
                                   (comp:set-position {:row (- comp.row 1)}))))))
    (app.components.player-score:update app.game.score.player)
    (app.components.grid-score:update app.game.score.grid)
    (app:request-render)))

;; TODO: replay
;; TODO: stats
;; TODO: win count

(λ M.save [app filename]
  (App.save app filename {:version 1
                          :app-id app.app-id
                          :seed app.seed
                          :config app.game-config
                          :latest app.game
                          :replay (icollect [_ [_state action] (ipairs app.game-history)]
                                    action)}))

(λ M.load [app filename]
  (case-try
    (App.load app filename) data
    (let [{: config : seed : latest : replay} data]
      (app:setup-new-game config seed)
      (app:queue-event :app :replay {: replay :verify latest}))))

M
