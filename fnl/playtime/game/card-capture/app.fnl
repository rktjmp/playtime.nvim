(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local Animate (require :playtime.animate))
(local CommonComponents (require :playtime.common.components))
(local CardComponents (require :playtime.common.card.components))
(local CardUtils (require :playtime.common.card.utils))
(local Component (require :playtime.component))
(local App (require :playtime.app))
(local Window (require :playtime.app.window))

(local {: api} vim)
(local uv (or vim.loop vim.uv))
(local M (setmetatable {} {:__index App}))

(fn enabled-indexes [list]
  (icollect [i v (ipairs list)]
    (if v i)))

(local Logic (require :playtime.game.card-capture.logic))
(local AppState {})

(set AppState.Default (App.State.build :Default {:delegate {:app App.State.DefaultAppState}}))
(set AppState.DealPhase (App.State.build :DealPhase {:delegate {:app AppState.Default}}))
(set AppState.EnemyPhase (App.State.build :EnemyPhase {:delegate {:app AppState.Default}}))
(set AppState.DiscardPhase (App.State.build :DiscardPhase {:delegate {:app AppState.Default}}))
(set AppState.DrawPhase (App.State.build :DrawPhase {:delegate {:app AppState.Default}}))
(set AppState.CapturePhase (App.State.build :CapturePhase {:delegate {:app AppState.Default}}))
(set AppState.GameEnded (App.State.build :GameEnded {:delegate {:app AppState.Default}}))

(local {: build-event-animation} CardUtils)

(fn AppState.GameEnded.activated [app]
  (let [winner (Logic.Query.game-result app.game)
        other (case winner
                :player ["You captured all cards"]
                :enemy ["The opposition captured a K,Q,J or A"])]
    (set app.ended-at (os.time))
    (app.components.game-report:update winner other)
    (case winner
      :player (do
                (app:save (.. (os.time) :-win))
                (app:update-statistics)))))

(fn AppState.GameEnded.OnEvent.input.<LeftMouse> [app [location] pos]
  (Logger.info location)
  (case location
    [:menu idx nil &as menu-item] (app:push-state App.State.DefaultInMenuState {: menu-item})))

(fn AppState.Default.OnEvent.app.new-game [app]
  (app:setup-new-game app.game-config nil))

(fn AppState.Default.OnEvent.app.restart-game [app]
  (app:setup-new-game app.game-config app.seed))

(fn AppState.Default.OnEvent.app.replay [app {: replay :verify ?verify : state}]
  (case replay
    ;; TODO: verify game against verify
    [nil] (app:switch-state state)
    [action & rest] (case action
                      [nil] (app:queue-event :app :replay {:replay rest :verify ?verify : state})
                      action (case-try
                               action [f-name & args]
                               (. Logic.Action f-name) f
                               (f app.game (table.unpack args)) (next-game moves)
                               (if true
                                 (do
                                   (app:update-game next-game action)
                                   (AppState.Default.OnEvent.app.replay app
                                                                        {:replay rest
                                                                         :verify ?verify
                                                                         : state}))
                                 (let [after #(do
                                                (app:switch-state AppState.Default)
                                                (app:queue-event :app :noop)
                                                (app:queue-event :app :replay {:replay rest :verify ?verify : state})
                                                (app:update-game next-game action))
                                       timeline (build-event-animation moves after {:duration-ms 120})]
                                   (app:switch-state App.State.DefaultAnimatingState timeline)))))))

(fn AppState.DealPhase.activated [app]
  (let [(next-game moves) (Logic.Action.both-draw app.game)
        after #(do
                 (app:update-game next-game [:both-draw])
                 (app:switch-state AppState.DiscardPhase))
        timeline (build-event-animation app moves after)]
    (app:switch-state App.State.DefaultAnimatingState timeline)))

(fn AppState.EnemyPhase.activated [app]
  (app.components.discard-label:set-visible false)
  (app.components.capture-label:set-visible false)
  (app.components.sacrifice-label:set-visible false)
  (app.components.yield-label:set-visible false)
  (let [(next-game moves) (Logic.Action.enemy-draw app.game)
        after #(do
                 (app:update-game next-game [:enemy-draw])
                 (app:switch-state AppState.DiscardPhase))
        timeline (build-event-animation app moves after)]
    (app:switch-state App.State.DefaultAnimatingState timeline)))

(fn AppState.DiscardPhase.activated [app]
  (set app.state.context.player [false false false false])
  (app.components.discard-label:set-visible true)
  (app.components.discard-label:update true 0)
  (let [c (faccumulate [s 0 i 1 4] (+ s (if (. app.game.player.hand i) 1 0)))]
    (when (= 0 c)
      (app:switch-state AppState.DrawPhase))))

(fn AppState.DiscardPhase.deactivated [app]
  (app.components.discard-label:set-visible false))

(fn AppState.DiscardPhase.OnEvent.input.<LeftMouse> [app [location] pos]
  (case location
    [:menu idx nil &as menu-item] (app:push-state App.State.DefaultInMenuState {: menu-item})
    ;; :player :hand n 0 is the empty slot, so checking for nil means we're
    ;; clicking an actual card.
    [:player :hand n nil] (tset app.state.context.player n (not (. app.state.context.player n)))
    [:player :discard] (let [indexes (enabled-indexes app.state.context.player)
                             (next-game moves) (Logic.Action.discard app.game indexes)
                             after #(do
                                      (app:update-game next-game [:discard indexes])
                                      (app:switch-state AppState.DrawPhase))
                             timeline (build-event-animation app moves after)]
                         (app:switch-state App.State.DefaultAnimatingState timeline))))

(fn AppState.DrawPhase.activated [app]
  (let [(next-game moves) (Logic.Action.player-draw app.game)
        after #(do
                 (app:update-game next-game [:player-draw])
                 (app:switch-state AppState.CapturePhase))
        timeline (build-event-animation app moves after)]
    (app:switch-state App.State.DefaultAnimatingState timeline)))

(fn AppState.CapturePhase.activated [app]
  (set app.state.context {:player [false false false false]
                          :enemy [false false false false]})
  (app.components.discard-label:update false)
  (app.components.capture-label:update false)
  (app.components.sacrifice-label:update false)
  (app.components.yield-label:update false)
  (app.components.capture-label:set-visible true)
  (app.components.sacrifice-label:set-visible true)
  (app.components.yield-label:set-visible true))

(fn AppState.CapturePhase.deactivated [app]
  (app.components.capture-label:set-visible false)
  (app.components.sacrifice-label:set-visible false)
  (app.components.yield-label:set-visible false))

(fn AppState.CapturePhase.OnEvent.input.<LeftMouse> [app [location] pos]
  (case location
    [:menu idx nil &as menu-item] (app:push-state App.State.DefaultInMenuState {: menu-item})
    [:player :hand n] (tset app.state.context.player n (not (. app.state.context.player n)))
    [:enemy :hand n] (each [i _ (ipairs app.state.context.enemy)]
                       (tset app.state.context.enemy i (and (= n i) (not (. app.state.context.enemy i))))))
  (if (= AppState.CapturePhase app.state.module) ;; guard against menu click...
    (let [player-indexes  (enabled-indexes app.state.context.player)
          [enemy-index]  (enabled-indexes app.state.context.enemy)]
      (app.components.yield-label:update false)
      (app.components.sacrifice-label:update false)
      (app.components.capture-label:update false)
      (when (and enemy-index (< 0 (length player-indexes)))
        (app.components.yield-label:update
          (and (= 1 enemy-index)
               (not (nil? (Logic.Action.yield app.game player-indexes)))))
        (app.components.sacrifice-label:update
          (not (nil? (Logic.Action.sacrifice app.game player-indexes enemy-index))))
        (app.components.capture-label:update
          (not (nil? (Logic.Action.capture app.game player-indexes enemy-index))))
        (let [op (case location
                   [:player :discard] [:capture player-indexes enemy-index]
                   [:enemy :discard] [:yield player-indexes]
                   [:enemy :draw] [:sacrifice player-indexes enemy-index])]
          (case op
            [f & rest] (case-try
                         ((. Logic.Action f) app.game (table.unpack rest)) (next-game moves)
                         (let [after #(do
                                        (app:update-game next-game op)
                                        (app:queue-event :app :noop)
                                        ; (app:queue-event :app :draw)
                                        (app:switch-state AppState.EnemyPhase))
                               timeline (build-event-animation app moves after)]
                           (app:switch-state App.State.DefaultAnimatingState timeline))
                         (catch
                           (nil err) (app:notify err)))))))))

(fn tick-with-picked-cards [app]
  (each [location card (Logic.iter-cards app.game)]
    (let [comp (. app.card-id->components card.id)]
      (comp:update location card)
      (case location
        [actor :hand n] (let [{: row : col : z} (app:location->position [actor :hand n])
                              mod (case actor :player -1 :enemy 1)]
                          (if (?. app.state.context actor n)
                            (comp:set-position {:row (+ row mod) : col : z})))))))

(fn AppState.DiscardPhase.tick [app]
  (tick-with-picked-cards app))

(fn AppState.CapturePhase.tick [app]
  (tick-with-picked-cards app))

(fn M.location->position [app location]
  (let [config {:card {:margin {:row 0 :col 1}
                       :width 7 :height 5}}
        card-col-step (+ config.card.width config.card.margin.col)
        enemy {:row 4}
        player {:row 12}
        draw {:col 4}
        hand {:col (* 2 card-col-step)}
        discard {:col (+ draw.col (* 6 card-col-step))}]
    (case location
      [:label :discard] {:row (+ player.row config.card.height -3)
                          :col discard.col
                          :z (app:z-index-for-layer :label)}
      [:label :yield] {:row (+ enemy.row config.card.height -3)
                        :col (+ 1 discard.col)
                        :z (app:z-index-for-layer :label)}
      [:label :sacrifice] {:row (+ enemy.row config.card.height -3)
                        :col (+ draw.col -1)
                        :z (app:z-index-for-layer :label)}
      [:label :capture] {:row (+ player.row config.card.height -3)
                          :col (+ 1 -1 discard.col)
                          :z (app:z-index-for-layer :label)}
      [:enemy :draw n] {:row enemy.row
                        :col draw.col
                        :z n}
      [:enemy :hand n] {:row enemy.row
                        :col (+ hand.col (* (- 4 n) card-col-step))
                        :z n}
      [:enemy :discard n] {:row enemy.row
                           :col discard.col
                           :z n}
      [:player :draw n] {:row player.row
                         :col draw.col
                         :z n}
      [:player :hand n] {:row player.row
                         :col (+ hand.col (* (- 4 n) card-col-step))
                         :z n}
      [:player :discard n] {:row player.row
                            :col discard.col
                            :z n}
      _ (error (Error "Unable to convert location to position, unknown location #{location}"
                      {: location})))))

(λ M.start [app-config game-config ?seed]
  (let [app (-> (App.build "Card Capture"
                           :card-capture
                           app-config
                           game-config)
                (setmetatable {:__index M}))
        view (Window.open :card-capture
                          (App.build-default-window-dispatch-options app)
                          {:width 63
                           :height 22
                           :window-position app-config.window-position
                           :minimise-position app-config.minimise-position})
       _ (table.merge app.z-layers {:cards 25 :label 100 :animation 200})]
    (set app.view view)
    (set app.card-style {:width 7 :height 5 :colors 2})
    (app:setup-new-game app.game-config ?seed)
    (vim.defer_fn #(app:switch-state AppState.DealPhase) 300)
    (app:render)))

(λ M.setup-new-game [app game-config ?seed]
  (app:new-game Logic.build game-config ?seed)
  (app:build-components)
  (app:switch-state AppState.Default)
  app)

(fn update-card-counts [app]
  (app.components.card-counts.player.draw (length app.game.player.draw))
  (app.components.card-counts.player.discard (length app.game.player.discard))
  (app.components.card-counts.enemy.draw (length app.game.enemy.draw))
  (app.components.card-counts.enemy.discard (length app.game.enemy.discard)))

(λ M.build-components [app]
  (fn build-label [text position]
    (let [{: row : col : z} position]
      (-> (Component.build
            (fn [self enabled]
              (let [hl (if enabled "@playtime.ui.on" "@playtime.ui.off")]
                (self:set-content [[[text hl]]]))))
          (Component.set-position position)
          (Component.set-size {:width (length text) :height 1})
          (Component.set-content [[[text "@playtime.ui.off"]]]))))

  (fn build-card-count [position z]
    (let [{: row : col} position]
      (-> (Component.build
            (fn [self count]
              (let [text (tostring count)
                    col (case (length text)
                          1 (+ col 5)
                          2 (+ col 4))]
                (self:set-position {:row (+ row 4) : col : z})
                (self:set-size {:width (length text) :height 1})
                (self:set-content [[[text "@playtime.ui.off"]]]))))
          (: :update 0))))

  (let [card-card-components (collect [location card (Logic.iter-cards app.game)]
                               (let [comp (CardComponents.card #(app:location->position $...)
                                                               location
                                                               card
                                                               app.card-style)]
                                 (values card.id comp)))
        card-counts {:player {:draw (build-card-count (app:location->position [:player :draw 0])
                                                      (app:z-index-for-layer :label))
                              :discard (build-card-count (app:location->position [:player :discard 0])
                                                         (app:z-index-for-layer :label))}
                     :enemy {:draw (build-card-count (app:location->position [:enemy :draw 0])
                                                      (app:z-index-for-layer :label))
                             :discard (build-card-count (app:location->position [:enemy :discard 0])
                                                        (app:z-index-for-layer :label))}}
        discard-label (build-label "discard" (app:location->position [:label :discard]))
        yield-label (build-label "yield" (app:location->position [:label :yield]))
        sacrifice-label (build-label "sacrifice" (app:location->position [:label :sacrifice]))
        capture-label (build-label "capture" (app:location->position [:label :capture]))
        menubar (CommonComponents.menubar [["Card Capture" [:file]
                                            [["" nil]
                                             ["New Game" [:new-game]]
                                             ["Restart Game" [:restart-game]]
                                             ["" nil]
                                             ["Undo" [:undo]]
                                             ["" nil]
                                             ["Save current game" [:save]]
                                             ["Load last save" [:load]]
                                             ["" nil]
                                             ["Quit" [:quit]]
                                             ["" nil]
                                             [(string.format "Seed: %s" app.seed) nil]]]]
                                          {:width app.view.width
                                           :z (app:z-index-for-layer :menubar)})
        empty-fields (accumulate [base [] _ [field count] (ipairs [[:hand 4] [:draw 1] [:discard 1]])]
                       (do
                         (each [_ actor (ipairs [:player :enemy])]
                           (fcollect [i 1 count &into base]
                             (CardComponents.slot #(table.set (app:location->position $...)
                                                              :z (app:z-index-for-layer :base))
                                                  [actor field i 0]
                                                  app.card-style)))
                         base))
        game-report (CommonComponents.game-report app.view.width
                                                  app.view.height
                                                  (app:z-index-for-layer :report)
                                                  [[:player "Won"]
                                                   [:enemy "Lost"]])]

    (table.merge app.components {: empty-fields
                                 : menubar
                                 : game-report
                                 : card-counts
                                 : yield-label : discard-label : sacrifice-label : capture-label})
    (set app.card-id->components card-card-components)
    (set app.components.cards (table.values card-card-components))
    (update-card-counts app)
    app))

(fn M.render [app]
  (app.view:render [app.components.empty-fields
                    app.components.cards
                    [app.components.card-counts.player.discard
                     app.components.card-counts.player.draw
                     app.components.card-counts.enemy.discard
                     app.components.card-counts.enemy.draw]
                    [app.components.yield-label
                     app.components.discard-label
                     app.components.sacrifice-label
                     app.components.capture-label]
                    [app.components.game-report]
                    [
                     app.components.menubar
                     app.components.cheating]])
  app)

(fn M.tick [app]
  (let [now (uv.now)]
    (app:process-next-event)
    (case (. app.state.module.tick)
      f (f app)
      _ (each [location card (Logic.iter-cards app.game)]
          (let [comp (. app.card-id->components card.id)]
            (comp:update location card))))
    (update-card-counts app)
    ;; TODO: iffy (or = in-menu-state) but works for now ... easy to break.
    ;; solution: GameEnded.tick function ?
    (if (and (not (or (= AppState.GameEnded app.state.module)
                      (= App.State.DefaultInMenuState app.state.module)))
             (Logic.Query.game-ended? app.game))
      (app:switch-state AppState.GameEnded))
    (app:request-render)))

(λ M.save [app filename]
  (App.save app filename {:version 1
                          :app-id app.app-id
                          :seed app.seed
                          :config app.game-config
                          :latest app.game
                          :turn (case app.state.module
                                  (where (= AppState.DiscardPhase)) :discard
                                  (where (= AppState.CapturePhase)) :capture
                                  (where (= AppState.GameEnded)) :ended
                                  ?mod (error (Error "unable to save turn for #{s}" {:s ?mod})))
                          :replay (icollect [_ [_state action] (ipairs app.game-history)]
                                    action)}))

(λ M.load [app filename]
  (case-try
    (App.load app filename) data
    (let [{: config : seed : latest : replay : turn} data
          state (case turn
                  :discard AppState.DiscardPhase
                  :capture AppState.CapturePhase
                  :ended AppState.GameEnded
                  _ (error (Error "unknown turn: #{turn}" {: turn})))]
      (app:setup-new-game config seed)
      (app:queue-event :app :replay {: replay :verify latest : state}))))

(λ M.update-statistics [app]
  (fn update [d]
    (let [data (table.merge {:version 1 :wins 0 :games []} d)]
      (set data.wins (+ data.wins 1))
      (set data.games (table.insert data.games
                                    {:seed app.seed
                                     :time (- (or app.ended-at app.started-at) app.started-at)}))
      data))
  (App.update-statistics app update))

M
