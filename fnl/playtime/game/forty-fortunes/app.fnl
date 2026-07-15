(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local PatienceApp (require :playtime.patience))
(local PatienceComponent (require :playtime.patience.component))
(local Logic (require :playtime.game.forty-fortunes.logic))

(local M (PatienceApp.scaffold-module {}))

(fn M.location->position [app location]
  (let [config {:card {:margin {:row 0 :col 2}
                       :width 7 :height 5}}
        card-col-step (+ config.card.width config.card.margin.col)
        cell {:row 2 :col 4}
        foundation {:row cell.row :col (+ 2 cell.col (* 7 card-col-step))}
        tableau {:row (+ cell.row config.card.height config.card.margin.row) :col cell.col}]
    (case location
      [:cell n card] {:row cell.row
                      :col (+ tableau.col (* (- 7 1) card-col-step))
                      :z card}
      [:foundation n card] {:row (+ 0 foundation.row)
                            :col (+ tableau.col
                                    card-col-step
                                    (* (- n 1) card-col-step)
                                    (case n
                                      (where n (< n 5)) 0
                                      (where n (<= 5 n)) (* 3 card-col-step)))
                            :z card}
      [:tableau col card] {:row (+ tableau.row (* (math.max 0 (- card 1)) 2))
                           :col (+ tableau.col (* (- col 1) card-col-step))
                           :z card}
      [:draw 1 card] {:row tableau.row
                      :col (+ tableau.col (* (- 7 1) card-col-step))
                      :z card}
      _ (error (Error "Unable to convert location to position, unknown location #{location}"
                      {: location})))))

(fn M.State.PlanningMove.on.app.move [state cofx event fx] 
  (set event.fast-forward-animation? false)
  (PatienceApp.State.PlanningMove.on.app.move state cofx event fx))

(λ M.start [runtime-config game-config ?seed]
  (let [patience-config {:LogicImpl Logic
                         :StateImpl M.State
                         :ComponentImpl {:spec {:slots [{:location :cell
                                                         :count 1
                                                         :label "*"}
                                                        {:location :foundation
                                                         :count 8
                                                         :label "A"}
                                                        {:location :tableau
                                                         :count 13
                                                         :label "*"}]}
                                         :card PatienceComponent.card-4-colors}}
        app-config {:module M
                    :name "Forty Fortunes"
                    :app-id :forty-fortunes
                    :view {:width 123 :height 42}
                    :menu [["Forty Fortunes" [["New Game" [:app :new-game]]]]]}
        app (PatienceApp.start patience-config
                               app-config
                               runtime-config
                               game-config
                               ?seed)]
    app))

M
