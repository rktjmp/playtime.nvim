(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local PatienceApp (require :playtime.app.patience))
(local PatienceState (require :playtime.app.patience.state))
(local Component (require :playtime.component))
(local CardComponents (require :playtime.common.card.components))
(local CommonComponents (require :playtime.common.components))
(local M (setmetatable {} {:__index PatienceApp}))

(local Logic (require :playtime.game.overthrone.logic))
(local AppState (PatienceState.build Logic))
(local M (setmetatable {} {:__index PatienceApp}))

(fn AppState.GameEnded.activated [app]
  (set app.ended-at (os.time))
  (let [[key other] (app:game-ended-data)]
    (if (or (= :0 key) (= :1-3 key))
      (do
        (app:save (.. (os.time) :-win))
        (app:update-statistics)))
    (app.components.game-report:update key other))
  app)

(fn M.location->position [app location]
  (let [config {:card {:margin {:row 0 :col 2}
                       :width 7 :height 5}}
        hand-size app.game-config.hand-size
        card-col-step (+ config.card.width config.card.margin.col)
        throne {:row 8 :col (case hand-size
                              5 25
                              6 28)}
        draw {:row 20 :col 2}
        hand {:row draw.row :col (+ draw.col card-col-step)}
        foundation {:row 14
                    :col 14}]
    (case location
      [:foundation 1 card] {:row (- throne.row 6) :col throne.col :z card}
      [:foundation 2 card] {:row throne.row :col (+ throne.col 2 card-col-step) :z card}
      [:foundation 3 card] {:row (+ throne.row 6) :col throne.col :z card}
      [:foundation 4 card] {:row throne.row :col (- throne.col 2 card-col-step) :z card}
      [:throne 1 card] {:row throne.row :col throne.col :z card}
      [:draw 1 card] {:row draw.row :col draw.col :z card}
      [:hand n c] {:row hand.row :col (+ hand.col (* (- n 1) 7)) :z c}
      [:discard 1 card] {:row hand.row :col (+ hand.col card-col-step (* (- hand-size 1) 7)) :z card}
      _ (error (<s> "Unable to convert location to position, unknown location #{location}")))))

(fn AppState.Default.OnEvent.app.maybe-auto-move [app])

(fn update-card-counts [app]
  (app.components.counters.draw:update (length (. app.game.draw 1)))
  (app.components.counters.discard:update (length (. app.game.discard 1))))

(fn M.build-components [app]
  (PatienceApp.build-components app)
  (let [throne-pos (M.location->position app [:throne 1 0])
        throne (-> (Component.build)
                   (Component.set-size {:width 11 :height 7})
                   (Component.set-position {:row (- throne-pos.row 1)
                                            :col (- throne-pos.col 2)
                                            :z 0})
                   (Component.set-content [[["🞠 ═══════🞠 " "@playtime.color.magenta"]]
                                           [[" ▏       ▕" "@playtime.color.magenta"]]
                                           [[" ▏       ▕" "@playtime.color.magenta"]]
                                           [[" ▏       ▕" "@playtime.color.magenta"]]
                                           [[" ▏       ▕" "@playtime.color.magenta"]]
                                           [[" ▏       ▕" "@playtime.color.magenta"]]
                                           [["🞠 ═══════🞠 " "@playtime.color.magenta"]]]))
        counters {:draw (CardComponents.count (-> (app:location->position [:draw 1 0])
                                                  (table.set :z (app:z-index-for-layer :cards 52)))
                                              app.card-style)
                  :discard (CardComponents.count (-> (app:location->position [:discard 1 0])
                                                     (table.set :z (app:z-index-for-layer :cards 52)))
                                                 app.card-style)}
        game-report (CommonComponents.game-report app.view.width
                                                  app.view.height
                                                  (app:z-index-for-layer :report)
                                                  [[:0   "Perfect (0)"]
                                                   [:1-3 "Good (1-3)"]
                                                   [:4-7 "Not so good (4-7)"]
                                                   [:8+  "Uh-oh... (8+)"]])]
    (table.merge app.components {: game-report : throne : counters})
    (update-card-counts app)
    app))

(fn M.render [app]
  (app.view:render [[app.components.throne]
                    app.components.empty-fields
                    app.components.cards
                    [app.components.counters.draw
                     app.components.counters.discard]
                    (app:standard-patience-components)])
  app)

(fn M.game-ended-data [app]
  (let [score (Logic.Query.game-result app.game)
        score (if (= 0 score) :0
                (< 0 score 4) :1-3
                (< 3 score 8) :4-7
                (< 8 score) :8+)
        other [(string.fmt "Moves: %d" app.game.moves)
               (string.fmt "Time:  %ds" (- app.ended-at app.started-at))]]
    [score other]))

(fn M.tick [app]
  (update-card-counts app)
  (PatienceApp.tick app))

(λ M.start [app-config game-config ?seed]
  (let [game-config (table.merge {:hand-size 5} game-config)
        width (case game-config.hand-size
                5 57
                6 64)]
    (PatienceApp.start
      {:name "Overthrone"
       :filetype :overthrone
       :view {:width width :height 27}
       :empty-fields [[:foundation 4]
                      [:throne 1]
                      [:draw 1]
                      [:discard 1]
                      [:hand game-config.hand-size]]
       :card-style {:colors 4}}
      {:AppImpl M
       :LogicImpl Logic
       :StateImpl AppState}
      app-config game-config ?seed)))

M
