(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local PatienceApp (require :playtime.app.patience))
(local PatienceState (require :playtime.app.patience.state))

(local M (setmetatable {} {:__index PatienceApp}))
(local Logic (require :playtime.game.curds-and-whey.logic))
(local AppState (PatienceState.build Logic))

(fn M.location->position [app location]
  (let [config {:card {:margin {:row 0 :col 2}
                       :width 7 :height 5}}
        draw {:row 2 :col 2}
        card-col-step (+ config.card.width config.card.margin.col)
        tableau {:row (+ draw.row config.card.height config.card.margin.row) :col draw.col}]
    (case location
      [:tableau col card] {:row (+ tableau.row (* (math.max 0 (- card 1)) 2))
                           :col (+ tableau.col (* (- col 1) card-col-step))
                           :z card}
      [:draw n card] {:row draw.row
                      :col draw.col
                      :z (+ 10 card)}
      [:complete n card] {:row draw.row
                          :col (+ -5 tableau.col (* card-col-step 4) (* n card-col-step))
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
  (PatienceApp.start
    {:name "Curds & Whey"
     :filetype :curds-and-whey
     :view {:width 119 :height 42}
     :empty-fields [[:tableau 13] [:complete 4]]
     :card-style {:colors 4}}
    {:AppImpl M
     :LogicImpl Logic
     :StateImpl AppState}
    app-config game-config ?seed))

M
