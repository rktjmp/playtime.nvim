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

(λ M.build-event-animation [app moves after ?opts]
  (CardUtils.build-event-animation app moves after ?opts))

(λ M.start [template-config impl-config app-config game-config ?seed]
  (assert-match {: name
                 : filetype
                 :card-style {: colors}
                 :view {: width : height}
                 : empty-fields}
                template-config)
  (assert-match {: AppImpl : LogicImpl : StateImpl}
                impl-config)
  (assert-match {: Default : Animating : GameEnded : LiftingCards : DraggingCards}
                impl-config.StateImpl)
  (assert-match {:Action {: move}
                 :Query {: liftable? : droppable? : game-ended? : game-result}}
                impl-config.LogicImpl)
  (fn __index [_ key] (or (. impl-config.AppImpl key) (. M key)))
  (let [app (-> (App.build template-config.name
                           template-config.filetype
                           app-config
                           game-config)
                (setmetatable {: __index}))
        view (Window.open template-config.filetype
                          (App.build-default-window-dispatch-options app)
                          {:width template-config.view.width
                           :height template-config.view.height
                           :window-position app-config.window-position
                           :minimise-position app-config.minimise-position})
        card-style (table.merge {:width 7 :height 5} template-config.card-style)]
    (set app.Impl impl-config)
    (set app.Template template-config)
    (set app.view view)
    (set app.card-style card-style)
    (table.merge app.z-layers {:button 5 :cards 25 :animation 200 :lift 200})
    (app:setup-new-game app.game-config ?seed)
    (vim.defer_fn #(app:queue-event :app :deal) 300)
    (app:render)))

(λ M.setup-new-game [app game-config ?seed]
  (app:new-game app.Impl.LogicImpl.build game-config ?seed)
  (app:build-components)
  (app:switch-state app.Impl.StateImpl.Default)
  app)

(λ M.build-components [app]
  (let [card-card-components (collect [location card (app.Impl.LogicImpl.iter-cards app.game)]
                               (let [comp (CardComponents.card #(app:location->position $...)
                                                               location
                                                               card
                                                               app.card-style)]
                                 (values card.id comp)))
        menubar (CommonComponents.menubar [[app.name [:file]
                                            [["" nil]
                                             ["New Deal" [:new-deal]]
                                             ["Repeat Deal" [:repeat-deal]]
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
        win-count (let [{: wins} (app:fetch-statistics)]
                    (CommonComponents.win-count wins
                                                {:width app.view.width
                                                 :z (app:z-index-for-layer :menubar 1)}))
        empty-fields app.Template.empty-fields
        empty-fields (accumulate [base [] _ [field count] (ipairs empty-fields)]
                       (fcollect [i 1 count &into base]
                         (CardComponents.slot (fn [location]
                                                (table.set (app:location->position location)
                                                           :z (app:z-index-for-layer :base)))
                                              [field i 0]
                                              app.card-style)))
        game-report (CommonComponents.game-report app.view.width
                                                  app.view.height
                                                  (app:z-index-for-layer :report)
                                                  [[:won "Solved"]
                                                   [:lost "Not Solved"]])]
    (table.merge app.components {: empty-fields : menubar : win-count : game-report})
    (set app.card-id->components card-card-components)
    (set app.components.cards (table.values card-card-components))
    app))

(λ M.standard-patience-components [app]
  (icollect [_ key (ipairs [:game-report :win-count :menubar :cheating])]
    (. app.components key)))

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

(λ M.update-statistics [app]
  (fn update [d]
    (let [data (table.merge {:version 1 :wins 0 :games []} d)]
      (set data.wins (+ data.wins 1))
      (set data.games (table.insert data.games
                                    {:seed app.seed
                                     :moves app.game.moves
                                     :time (- (or app.ended-at app.started-at) app.started-at)}))
      data))
  (App.update-statistics app update))

(fn M.render [app]
  (app.view:render [app.components.empty-fields
                    app.components.cards
                    (app:standard-patience-components)])
  app)

(fn M.game-ended-data [app]
  (let [key (case (app.Impl.LogicImpl.Query.game-result app.game)
              true :won
              _ :lost)
        other [(string.fmt "Moves: %d" app.game.moves)
               (string.fmt "Time:  %ds" (- app.ended-at app.started-at))]]
    [key other]))

(fn M.tick [app]
  (let [now (uv.now)]
    (app:process-next-event)
    (case (. app.state.module.tick)
      f (f app)
      _ (each [location card (app.Impl.LogicImpl.iter-cards app.game)]
          (let [comp (. app.card-id->components card.id)]
            (comp:update location card))))
    ;; TODO: iffy (or = in-menu-state) but works for now ... easy to break.
    ;; solution: GameEnded.tick function ?
    (if (and (not (or (= app.Impl.StateImpl.GameEnded app.state.module)
                      (= App.State.DefaultInMenuState app.state.module)))
             (app.Impl.LogicImpl.Query.game-ended? app.game))
      (app:switch-state app.Impl.StateImpl.GameEnded))
    (app:request-render)))

M
