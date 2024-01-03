(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local PatienceApp (require :playtime.app.patience))
(local PatienceState (require :playtime.app.patience.state))

(local M (setmetatable {} {:__index PatienceApp}))
(local Logic (require :playtime.game.spider.logic))
(local AppState (PatienceState.build Logic))

(fn M.location->position [app location]
  (let [config {:card {:margin {:row 0 :col 2}
                       :width 7 :height 5}}
        draw {:row 2 :col 4}
        card-col-step (+ config.card.width config.card.margin.col)
        tableau {:row (+ draw.row config.card.height config.card.margin.row) :col draw.col}
        max-draws 7]
    (case location
      [:tableau col card] {:row (+ tableau.row (* (math.max 0 (- card 1)) 2))
                           :col (+ tableau.col (* (- col 1) card-col-step))
                           :z card}
      [:draw n card] {:row draw.row
                      :col (+ draw.col (* (- max-draws n 1) 2))
                      :z (+ (* (- max-draws n) 10) card)}
      [:complete n card] {:row draw.row
                          :col (+ tableau.col (* card-col-step 9) (* -2 (- n 1)))
                          :z (+ (* n 10) card)}
      _ (error (Error "Unable to convert location to position, unknown location #{location}"
                      {: location})))))

(fn AppState.Default.OnEvent.app.maybe-auto-move [app]
  (case-try
    (Logic.Plan.next-complete-sequence app.game) from
    (Logic.Action.remove-complete-sequence app.game from) (next-game events)
    (let [after #(do
                   (app:switch-state AppState.Default)
                   (app:queue-event :app :maybe-auto-move)
                   (app:update-game next-game [:remove-complete-sequence from]))
          timeline (app:build-event-animation events after {:stagger-ms 120})]
      (app:switch-state AppState.Animating timeline)))
  app)

(λ M.start [app-config game-config ?seed]
  (let [game-config (table.merge {:suits 4} game-config)]
    (PatienceApp.start
      {:name (string.format "Spider (%s Suits)" game-config.suits)
       :filetype (string.format "spider-%s" game-config.suits)
       :view {:width 96 :height 42}
       :empty-fields [[:tableau 10]]
       :card-style {:colors 4}}
      {:AppImpl M
       :LogicImpl Logic
       :StateImpl AppState}
      app-config game-config ?seed)))

M
