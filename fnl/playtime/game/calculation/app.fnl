(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local PatienceApp (require :playtime.patience))
(local Component (require :playtime.component))
(local PatienceComponent (require :playtime.patience.component))
(local Logic (require :playtime.game.calculation.logic))

(local M (PatienceApp.scaffold-module {}))

(local super-synchronise-components-to-game-state M.synchronise-components-to-game-state)
(fn M.synchronise-components-to-game-state [app]
  (set app.components.stock-count.content [[[(string.format "%2s" (length (. app.game.draw 1)))
                                             "@playtime.ui.off"]]])
  (each [i comp (ipairs app.components.guides.children)]
    (case (table.last (. app.game.foundation i))
      [_suit raw-value]
      (let [text-value (case raw-value
                         1 :A
                         10 :X
                         :jack :J
                         :queen :Q
                         :king :K
                         n (.. "" n))
            hl-index (accumulate [t nil i [[text _hl]] (ipairs comp.content) &until t]
                       (when (= text text-value) (+ i 1)))
            content (icollect [index [[text _hl]] (ipairs comp.content)]
                      (case hl-index
                        14 [[text "@playtime.color.green"]]
                        (where (= index)) [[text "@playtime.ui.on"]]
                        _ [[text "@playtime.ui.off"]]))]
        (set comp.content content))))
  (super-synchronise-components-to-game-state app))

(λ M.build-other-components [app]
  (let [guides [[:A :2 :3 :4 :5 :6 :7 :8 :9 :X :J :Q :K]
                [:2 :4 :6 :8 :X :Q :A :3 :5 :7 :9 :J :K]
                [:3 :6 :9 :Q :2 :5 :8 :J :A :4 :7 :X :K]
                [:4 :8 :Q :3 :7 :J :2 :6 :X :A :5 :9 :K]]
        guides (icollect [i guide (ipairs guides)]
                 (let [text (icollect [i t (pairs guide)]
                              [[(string.format "%s" t)
                                (case i 1 "@playtime.ui.on" _ "@playtime.ui.off")]])]
                   (Component.new {:size {:width 2 :height 13}
                                   :position {:row 8 :col (+ 2 (* 3 (- i 1))) :z 80}
                                   :content text})))
        guides (Component.new {:children guides})
        stock-count (Component.new {:size {:width 8 :height 1}
                                    :position {:row 6 :col 7 :z 80}
                                    :content [[["52" "@playtime.ui.on"]]]})]
      (table.merge app.components {:stock-count stock-count
                                   :guides guides}))
  app)

(fn M.location->position [app location]
  (let [config {:card {:margin {:row 0 :col 2}
                       :width 7 :height 5}}
        card-col-step (+ config.card.width config.card.margin.col)
        foundation {:row 2 :col 14}
        tableau {:row (+ foundation.row 5) :col 14}
        stock {:row 2 :col 3}]
    (case location
      [:foundation n card] {:row foundation.row
                            :col (+ foundation.col (* card-col-step (- n 1)))
                            :z card}
      [:tableau n card] {:row (+ tableau.row (* (math.max 0 (- card 1)) 2))
                         :col (+ tableau.col (* card-col-step (- n 1)))
                         :z card}
      [:draw 1 card] {:row stock.row
                      :col stock.col
                      :z card}
      _ (error (<s> "Unable to convert location to position, unknown location #{location}")))))

(λ M.start [runtime-config game-config ?seed]
  (let [patience-config {:LogicImpl Logic
                         :StateImpl M.State
                         :ComponentImpl {:spec {:slots [{:location :tableau
                                                         :count 4
                                                         :label :*}
                                                        {:location :foundation
                                                         :count 4
                                                         :label :A}
                                                        {:location :draw
                                                         :count 1
                                                         :label :*}]}
                                         :card PatienceComponent.card-2-colors}}
        app-config {:module M
                    :name "Calculation"
                    :app-id :calculation
                    :view {:width 50 :height 40}
                    :menu [["Calculation" [["New Game" [:app :new-game]]]]]}]
    (PatienceApp.start patience-config
                       app-config
                       runtime-config
                       game-config
                       ?seed)))

M
