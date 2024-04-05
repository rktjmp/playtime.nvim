(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local CommonComponents (require :playtime.common.components))
(local CardComponents (require :playtime.common.card.components))
(local SetComponents (require :playtime.game.set.components))
(local CardUtils (require :playtime.common.card.utils))
(local App (require :playtime.app))
(local Window (require :playtime.app.window))

(local M (setmetatable {} {:__index App}))
(local Logic (require :playtime.game.set.logic))

;; "Find 6 in preset deal"
(local PuzzleAppState {})

;;
;; Regular SET game, find sets in a deal and progress through the deck.
;;

(local RegularAppState {})

(set RegularAppState.Default (App.State.build :Default {:delegate {:app App.State.DefaultAppState}}))
(set RegularAppState.SubmitSet (App.State.build :SubmitSet {:delegate {:app RegularAppState.Default}}))
(set RegularAppState.GameEnded (App.State.build :GameEnded {:delegate {:app RegularAppState.Default}}))
(set RegularAppState.Animating (clone App.State.DefaultAnimatingState))

(fn RegularAppState.Default.activated [app ?context]
  (case ?context
    {:selected nil} (set app.state.context.selected [])))

(fn RegularAppState.Default.OnEvent.app.new-game [app]
  (app:setup-new-game app.game-config nil)
  (vim.defer_fn #(app:queue-event :app :deal) 300))

(fn RegularAppState.Default.OnEvent.app.restart-game [app]
  (app:setup-new-game app.game-config app.seed)
  (vim.defer_fn #(app:queue-event :app :deal) 300))

(fn RegularAppState.Default.OnEvent.app.hint-random-set [app]
  (case (Logic.Query.find-sets app.game)
    [nil] (app:notify "No sets to hint!")
    sets (let [[a-set] (table.shuffle sets)
               logic-hint (Logic.Query.hint-for-set app.game a-set)
               {: same : diff} (accumulate [h {:same [] :diff []}
                                            k v (pairs logic-hint)]
                                 (table.set h v (table.insert (. h v) k)))
               single-hint (case (values same diff)
                             ([nil] _) "everything different"
                             (_ [nil]) "everything identical"
                             (sames diffs) (string.fmt "identical %s and different %s"
                                                       (table.concat sames ", ")
                                                       (table.concat diffs ", ")))
               [verb-1 verb-2 count noun] (case (length sets)
                                            1 [:is :it 1 :set]
                                            n [:are :One n :sets])
               msg (<s> "There #{verb-1} #{count} possible #{noun}. #{verb-2} has #{single-hint}.")]
           (app:notify msg))))

(fn RegularAppState.Default.OnEvent.app.deal-more [app]
  (case-try
    (Logic.Action.deal-more app.game) (next-game moves)
    (let [after #(do
                   (app:update-game next-game [:deal-more])
                   (if (Logic.Query.game-ended? app.game)
                     (app:switch-state RegularAppState.GameEnded)
                     (do
                       (app:switch-state RegularAppState.Default)
                       (app:queue-event :app :noop)
                       (if (table.empty? (Logic.Query.find-sets app.game))
                         (app:queue-event :app :deal-more)))))
          timeline (app:build-event-animation moves after {:stagger-ms 50 :duration-ms 120})]
      (app:switch-state RegularAppState.Animating timeline))
    (catch
      (nil e) (app:notify e))))

(fn RegularAppState.Default.OnEvent.input.<LeftMouse> [app [location] _pos]
  (case location
    [:menu _idx nil &as menu-item]
    (app:push-state App.State.DefaultInMenuState {: menu-item})
    [:draw _] (app:queue-event :app :deal-more)
    [:deal n] (let [{: selected} app.state.context
                    ?index (accumulate [found nil i deal-n (ipairs selected) &until found]
                             (if (= n deal-n) i))]
                (case ?index
                  nil (table.insert selected n)
                  i (table.remove selected i))
                (when (= 3 (length selected))
                  (app:switch-state RegularAppState.SubmitSet {: selected})))))

(fn RegularAppState.Default.OnEvent.app.deal [app]
  (let [(next-game moves) (Logic.Action.deal app.game)
        after #(do
                 (app:switch-state RegularAppState.Default {:selected []})
                 (app:update-game next-game [:deal])
                 ;; We need the "not animating, update components" tick to run
                 ;; to lower the z-index for the just animated cards, otherwise
                 ;; the automoves move *under* the tableau.
                 ;; So force it to run once for noop, then run the automove TODO: icky hack..
                 (app:queue-event :app :noop)
                 ;; Ensure there is a set
                 (when (table.empty? (Logic.Query.find-sets app.game))
                   (app:queue-event :app :deal-more)))
        timeline (app:build-event-animation moves after {:stagger-ms 50 :duration-ms 120})]
    (app:switch-state RegularAppState.Animating timeline)))

(fn RegularAppState.Default.tick [app]
  (let [{: selected} app.state.context]
    (app.components.set-count:update (/ (length app.game.discard) 3))
    (app.components.draw-count:update (length app.game.draw))
    (each [location card (Logic.iter-cards app.game)]
      (let [comp (. app.card-id->components card.id)
            selected? (case location
                        [:deal n] (accumulate [found false i deal-n (ipairs selected) &until found]
                                    (= n deal-n))
                        _ false)]
        (comp:update location card selected?)))))

(fn RegularAppState.SubmitSet.activated [app _context]
  ;; for better feel, delay submitting the set for a few frames
  (vim.defer_fn #(app:queue-event :app :submit) 180))

(fn RegularAppState.SubmitSet.tick [...]
  ;; TODO Hack reroute tick to default for select highlighting
  (RegularAppState.Default.tick ...))

(fn RegularAppState.SubmitSet.OnEvent.app.submit [app]
  (let [{: selected} app.state.context]
    (case-try
      (Logic.Action.submit-set app.game selected) (next-game moves)
      (let [after #(do
                     (app:update-game next-game [:submit-set selected])
                     (if (Logic.Query.game-ended? app.game)
                       (app:switch-state RegularAppState.GameEnded)
                       (do
                         (app:switch-state RegularAppState.Default)
                         (if (table.empty? (Logic.Query.find-sets app.game))
                           (app:queue-event :app :deal-more)))))
            timeline (app:build-event-animation moves after {:stagger-ms 50 :duration-ms 120})]
        (app:switch-state RegularAppState.Animating timeline))
      (catch
        (nil e) (do
                  (app:notify e)
                  (app:switch-state RegularAppState.Default {:selected []}))))))

(fn RegularAppState.GameEnded.activated [app]
  (set app.ended-at (os.time))
  (let [{: sets : remaining} (Logic.Query.game-result app.game)
        other [(string.fmt "Sets found: %d" sets)
               (string.fmt "Remaining cards: %d" remaining)
               (string.fmt "Time: %ds" (- app.ended-at app.started-at))]]
    (app.components.game-report:update :won other)))

(fn RegularAppState.GameEnded.OnEvent.input.<LeftMouse> [app [location] pos]
  (case location
    [:menu idx nil &as menu-item]
    (app:push-state App.State.DefaultInMenuState {: menu-item})))

(λ M.build-event-animation [app moves after ?opts]
  (CardUtils.build-event-animation app moves after ?opts))

(fn M.location->position [app location]
  (let [{:width card-width} app.card-style
        deal-start-col (+ 4 card-width)
        deal-start-row 2]
    (case location
      [:draw n] {:row deal-start-row
                 :col (- deal-start-col (+ card-width 2))
                 :z n}
      [:discard n] {:row deal-start-row
                    :col (+ (* (+ card-width 1) 5) 4)
                    :z n}
      [:deal n] (let [row (+ 1 (math.modf (/ (- n 1) 4)))
                      col (+ 1 (% (- n 1) 4))]
                  {:row (+ 2 (* (- row 1) 5))
                   :col (+ deal-start-col (* (- col 1) (+ card-width 1)))
                   :z 1})
      _ (error (Error (<s> "Unable to convert location to position, unknown location #{location}"))))))

(λ M.start [app-config game-config ?seed]
  (let [app (-> (App.build "SET" :set app-config game-config)
                (setmetatable {:__index M}))
        game-set-glyph-width nil ;:wide
        card-style {:height 5
                    :glyph-width game-set-glyph-width
                    :width (if (= :wide game-set-glyph-width) 10 9)}
        view (Window.open :set
                          (App.build-default-window-dispatch-options app)
                          {:width (if (= game-set-glyph-width :wide) 71 65)
                           :height 25
                           :window-position app-config.window-position
                           :minimise-position app-config.minimise-position})
        _ (table.merge app.z-layers {:cards 25 :report 120 :animation 200})]
    (set app.view view)
    (set app.card-style card-style)
    (app:setup-new-game app.game-config ?seed)
    (vim.defer_fn #(app:queue-event :app :deal) 300)
    (app:render)))

(λ M.setup-new-game [app game-config ?seed]
  (app:new-game Logic.build game-config ?seed)
  (app:build-components)
  (app:switch-state RegularAppState.Default {:selected []})
  app)

(λ M.build-components [app]
  (let [card-style app.card-style
        card-card-components (collect [location card (Logic.iter-cards app.game)]
                               (let [comp (SetComponents.card
                                            #(app:location->position $1)
                                            location
                                            card
                                            card-style)]
                                 (values card.id comp)))
        game-report (CommonComponents.game-report app.view.width
                                                  app.view.height
                                                  (app:z-index-for-layer :report)
                                                  [[:won "You did it!"]])
        slots [(SetComponents.slot #(app:location->position $1)
                                   [:draw 0]
                                   card-style)
               (SetComponents.slot #(app:location->position $1)
                                   [:discard 0]
                                   card-style)]
        draw-count (-> (CardComponents.count (app:location->position [:draw 100]) card-style)
                       (: :update 81))
        set-count (CardComponents.count (app:location->position [:discard 100]) card-style)
        menubar (CommonComponents.menubar [["SET" [:file]
                                            [["" nil]
                                             ["New Game" [:new-game]]
                                             ["Restart Game" [:restart-game]]
                                             ["" nil]
                                             ["Undo" [:undo]]
                                             ["" nil]
                                             ["Hint" [:hint-random-set]]
                                             ; ["" nil]
                                             ; ["Save current game" [:save]]
                                             ; ["Load last save" [:load]]
                                             ["" nil]
                                             ["Quit" [:quit]]
                                             ["" nil]
                                             [(string.format "Seed: %s" app.seed) nil]]]]
                                          {:width app.view.width
                                           :z (app:z-index-for-layer :menubar)})]
    (set app.card-id->components card-card-components)
    (table.merge app.components {: menubar
                                 : slots
                                 : draw-count
                                 : set-count
                                 : game-report
                                 :cards (table.values card-card-components)})))

(fn M.render [app]
  (app.view:render [[app.components.menubar]
                    app.components.slots
                    [app.components.draw-count app.components.set-count]
                    app.components.cards
                    [app.components.game-report]])
  app)

(fn M.tick [app]
  (app:process-next-event)
  (case (. app.state.module.tick)
    f (f app)
    _ (each [location card (Logic.iter-cards app.game)]
        (let [comp (. app.card-id->components card.id)]
          (comp:update location card))))
  (app:request-render))

M
