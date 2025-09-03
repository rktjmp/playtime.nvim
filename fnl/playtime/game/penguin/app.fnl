(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local PatienceApp (require :playtime.patience))
(local PatienceComponent (require :playtime.patience.component))
(local Logic (require :playtime.game.penguin.logic))

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

(λ M.start [runtime-config game-config ?seed]
  (let [patience-config {:LogicImpl Logic
                         :StateImpl M.State
                         :ComponentImpl {:spec {:slots [{:location :cell
                                                         :count 7
                                                         :label "*"}
                                                        {:location :foundation
                                                         :count 4
                                                         :label "A"}
                                                        {:location :tableau
                                                         :count 7
                                                         :label "K"}]}
                                         :card PatienceComponent.card-4-colors}}
        app-config {:module M
                    :name "Penguin"
                    :app-id :penguin
                    :view {:width 80 :height 42}
                    :menu [["Penguin" [["New Game" [:app :new-game]]]]]}]
    (PatienceApp.start patience-config
                       app-config
                       runtime-config
                       game-config
                       ?seed)))

M
