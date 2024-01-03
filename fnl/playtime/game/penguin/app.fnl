(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local PatienceApp (require :playtime.app.patience))
(local PatienceState (require :playtime.app.patience.state))
(local M (setmetatable {} {:__index PatienceApp}))

(local Logic (require :playtime.game.penguin.logic))
(local AppState (PatienceState.build Logic))
(local M (setmetatable {} {:__index PatienceApp}))

(fn M.location->position [app location]
  (let [config {:card {:margin {:row 0 :col 2}
                       :width 7 :height 5}}
        card-col-step (+ config.card.width config.card.margin.col)
        cell {:row 2 :col 4}
        foundation {:row cell.row :col (+ 2 cell.col (* 7 card-col-step))}
        tableau {:row (+ cell.row config.card.height config.card.margin.row) :col cell.col}]
    (case location
      [:cell n card] {:row cell.row
                      :col (+ cell.col (* (- n 1) card-col-step))
                      :z card}
      [:foundation n card] {:row (+ foundation.row (* (- n 1) config.card.height))
                            :col foundation.col
                            :z card}
      [:tableau col card] {:row (+ tableau.row (* (math.max 0 (- card 1)) 2))
                           :col (+ tableau.col (* (- col 1) card-col-step))
                           :z card}
      [:draw 1 card] {:row (+ tableau.row (* (math.max 0 (- 9 1)) 2))
                      :col (+ tableau.col (* 4 card-col-step) -4)
                      :z card}
      _ (error (<s> "Unable to convert location to position, unknown location #{location}")))))

(fn AppState.Default.OnEvent.app.maybe-auto-move [app]
  (case-try
    (Logic.Plan.next-move-to-foundation app.game) [from to]
    (Logic.Action.move app.game from to) (next-game events)
    (let [after #(do
                   (app:switch-state AppState.Default)
                   (app:queue-event :app :maybe-auto-move)
                   (app:update-game next-game [:move from to]))
          timeline (app:build-event-animation events after {:stagger-ms 200})]
      (app:switch-state AppState.Animating timeline))))

(fn M.start [app-config game-config ?seed]
  (PatienceApp.start
    {:name "Penguin"
     :filetype :penguin
     :view {:width 80 :height 42}
     :empty-fields [[:cell 7] [:tableau 7] [:foundation 4]]
     :card-style {:colors 4}}
    {:AppImpl M
     :LogicImpl Logic
     :StateImpl AppState}
    app-config game-config ?seed))

M
