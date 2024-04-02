(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local PatienceApp (require :playtime.app.patience))
(local PatienceState (require :playtime.app.patience.state))
(local Component (require :playtime.component))
(local CardComponents (require :playtime.common.card.components))
(local M (setmetatable {} {:__index PatienceApp}))

(local Logic (require :playtime.game.calculation.logic))
(local AppState (PatienceState.build Logic))
(local M (setmetatable {} {:__index PatienceApp}))

(fn M.location->position [app location]
  (let [config {:card {:margin {:row 0 :col 2}
                       :width 7 :height 5}}
        card-col-step (+ config.card.width config.card.margin.col)
        foundation {:row 2 :col 13}
        tableau {:row (+ foundation.row 5) :col 13}
        stock {:row 2 :col 3}]
    (case location
      [:foundation n card] {:row foundation.row
                            :col (+ foundation.col (* card-col-step (- n 1)))
                            :z (app:z-index-for-layer :cards card)}
      [:tableau n card] {:row (+ tableau.row (* (math.max 0 (- card 1)) 2))
                         :col (+ tableau.col (* card-col-step (- n 1)))
                         :z (app:z-index-for-layer :cards card)}
      [:stock 1 card] {:row stock.row
                       :col stock.col
                       :z (app:z-index-for-layer :cards card)}
      _ (error (<s> "Unable to convert location to position, unknown location #{location}")))))

(fn update-widgets [app]
  (app.components.stock-count (length (. app.game.stock 1)))
  (fcollect [i 1 4]
    (case (table.last (. app.game :foundation i))
      onto-card (let [val (case onto-card
                            [_ :king] 13
                            [_ :queen] 12
                            [_ :jack] 11
                            [_ v] v)
                      want-value (case (% (+ i val) 13)
                                   0 1
                                   n n)
                      text (case want-value
                             13 :K
                             12 :Q
                             11 :J
                             n n)]
                  ((. app.components.guides i) (length (. app.game.foundation i)))))))

(fn M.build-components [app]
  (fn build-card-count [position z]
    (let [{: row : col} position]
      (-> (Component.build
            (fn [self count]
              (let [text (tostring count)
                    col (case (string.col-width text)
                          1 (+ col 5)
                          2 (+ col 4)
                          3 (+ col 3)
                          4 (+ col 2)
                          _ (+ col 1))]
                (self:set-position {:row (+ row 4) : col : z})
                (self:set-size {:width (length text) :height 1})
                (self:set-content [[[text "@playtime.ui.off"]]]))))
          (: :update 0))))

  (fn build-guide-strip [n guide]
    (let [content (icollect [_ b (ipairs guide)]
                    [[(tostring (case b 10 :X n n)) "@playtime.ui.off"]])
          {: row : col} (app:location->position [:stock 1 0])]
      (-> (Component.build
            (fn [comp up-to]
              (let [content (icollect [i [[s h]] (ipairs content)]
                              [[s (if (= (+ 1 up-to) i)
                                    "@playtime.ui.on"
                                    "@playtime.ui.off")]])]
                (comp:set-content content))))
          (Component.set-content content)
          (Component.set-position {:row (+ row 6)
                                   :col (+ col 0 (* 2 (- n 1)))
                                   :z (app:z-index-for-layer :base)})
          (Component.set-size {:width 2 :height (length guide)})
          (: :update 1))))

  (PatienceApp.build-components app)
  (let [guides [[:A 2  3  4  5  6  7  8  9 10 :J :Q  :K]
                 [2 4  6  8 10 :Q :A  3  5  7  8 :J  :K]
                 [3 6  9 :Q  2  5  8 :J :A  4  7 10  :K]
                 [4 8 :Q  3  7 :J  2  6 10 :A  5  9 :K]]
        guides (icollect [i g (ipairs guides)]
                 (build-guide-strip i g))
        stock-count (CardComponents.count (-> (app:location->position [:stock 1 0])
                                              (table.set :z (app:z-index-for-layer :cards 52)))
                                          app.card-style)]
    (table.merge app.components {: stock-count : guides})
    (update-widgets app)
    app))

(fn M.tick [app]
  (update-widgets app)
  (PatienceApp.tick app))

(fn M.render [app]
  (app.view:render [app.components.empty-fields
                    app.components.cards
                    app.components.guides
                    [app.components.stock-count]
                    (app:standard-patience-components)])
  app)

(fn M.start [app-config game-config ?seed]
  (PatienceApp.start
    {:name "Calculation"
     :filetype :calculation
     :view {:width 50 :height 40}
     :empty-fields [[:foundation 4] [:tableau 4] [:stock 1]]
     :card-style {:colors 2}}
    {:AppImpl M
     :LogicImpl Logic
     :StateImpl AppState}
    app-config game-config ?seed))

M
