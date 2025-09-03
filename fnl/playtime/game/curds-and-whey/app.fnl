(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local PatienceApp (require :playtime.patience))
(local PatienceComponent (require :playtime.patience.component))
(local Logic (require :playtime.game.curds-and-whey.logic))

(local M (PatienceApp.scaffold-module {}))

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

(λ M.start [runtime-config game-config ?seed]
  (let [patience-config {:LogicImpl Logic
                         :StateImpl M.State
                         :ComponentImpl {:spec {:slots [{:location :tableau
                                                         :count 13
                                                         :label :K}
                                                        {:location :complete
                                                         :count 4}]}
                                         :card PatienceComponent.card-4-colors}}
        app-config {:module M
                    :name "Curds & Whey"
                    :app-id :curds-and-whey
                    :view {:width 119 :height 42}
                    :menu [["Curds & Whey" [["New Game" [:app :new-game]]]]]}]
    (PatienceApp.start patience-config
                       app-config
                       runtime-config
                       game-config
                       ?seed)))

M
