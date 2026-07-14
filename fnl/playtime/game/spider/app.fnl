(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local PatienceApp (require :playtime.patience))
(local PatienceComponent (require :playtime.patience.component))
(local Component (require :playtime.component))
(local Logic (require :playtime.game.spider.logic))

(local M (PatienceApp.scaffold-module {}))

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

(fn M.build-other-components [app]
  ;; Build invisible draw-buttons over draw piles, and an interaction blocker
  ;; over the completed cards.
  (let [{: row : col : z} (app:location->position [:draw 6 1])
        {:z z-offset} (app:location->position [:draw 1 100])
        draw-buttons (fcollect [i 1 5]
                       ;; Note we initially have 6 draw piles, deal the
                       ;; tableau from the top most. draws stack right to left,
                       ;; so draw-6 is the last, most left one.
                       (let [position {: row : col :z (+ z-offset i)}
                             size {:height 5 :width (+ 7 (* (- i 1) 2))}]
                         (Component.new {: size : position
                                         :tag [:draw-button i]
                                         :content [[] [] [] [] []]
                                         :on {:click (fn [self cofx event fx]
                                                       (case event
                                                         {:action :release :button :left}
                                                           (case (Logic.Query.draw? cofx.app.game)
                                                             true (do
                                                                    (set self.visible? false)
                                                                    (fx.event.dispatch :app :draw)
                                                                    (fx.engine.render))
                                                             (nil err) (fx.notify err))))}})))
        container (Component.new {:children draw-buttons})]
    (table.merge app.components {: container})
    app))

(λ M.start [runtime-config game-config ?seed]
  (let [patience-config {:LogicImpl Logic
                         :StateImpl M.State
                         :ComponentImpl {:spec {:slots [{:location :tableau
                                                         :count 10
                                                         :label "*"}]}
                                         :card PatienceComponent.card-4-colors}}
        game-config (table.merge {:suits 4} game-config)
        app-config {:module M
                    :name (string.format "Spider (%s Suits)" game-config.suits)
                    :app-id (string.format "spider-%s" game-config.suits)
                    :view {:width 96 :height 42}
                    :menu [["Spider" [["New Game" [:app :new-game]]]]]}]
    (PatienceApp.start patience-config
                       app-config
                       runtime-config
                       game-config
                       ?seed)))

M
