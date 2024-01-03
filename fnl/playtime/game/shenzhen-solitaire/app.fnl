(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Component (require :playtime.component))
(local PatienceApp (require :playtime.app.patience))
(local PatienceState (require :playtime.app.patience.state))
(local State (require :playtime.app.state))
(local Logic (require :playtime.game.shenzhen-solitaire.logic))
(local M (setmetatable {} {:__index PatienceApp}))
(local AppState (PatienceState.build Logic))

(set AppState.Default (State.build :Default {:delegate {:app AppState.Default
                                                        :input AppState.Default}}))

(fn card-graphics [suit rank _color-count]
  (let [rank-text (case [suit rank]
                    [:red] :Š
                    [:green] :Ñ
                    [:white] :Õ
                    [:flower] :ƒ
                    [_ pip] (tostring pip))
        highlight (.. "@playtime.game.shenzhen."
                      (case suit
                        :green :dragon.green
                        :red :dragon.red
                        :white :dragon.white
                        suit suit))]
    ["" rank-text highlight]))

(fn M.location->position [app location]
  (let [config {:card {:margin {:row 0 :col 2}
                       :width 7 :height 5}}
        card-col-step (+ config.card.width config.card.margin.col)
        cell {:row 2 :col 3}
        button {:row 3 :col (+ cell.col 1 (* 3 card-col-step))}
        lock {:row cell.row :col (+ cell.col (* 3 card-col-step))}
        flower {:row cell.row :col (+ lock.col (* 1 card-col-step))}
        foundation {:row cell.row :col (+ flower.col (* 1 card-col-step))}
        tableau {:row (+ cell.row config.card.height config.card.margin.row) :col cell.col}]
    (case location
      [:cell n card] {:row cell.row
                      :col (+ cell.col (* (- n 1) card-col-step))
                      :z card}
      [:flower 1 card] {:row flower.row
                        :col flower.col
                        :z card}
      [:foundation n card] {:row foundation.row
                            :col (+ foundation.col (* (- n 1) card-col-step))
                            :z card}
      [:tableau col card] {:row (+ tableau.row (* (math.max 0 (- card 1)) 2))
                           :col (+ tableau.col (* (- col 1) card-col-step))
                           :z card}
      [:button :lock color] (let [n (case color
                                      :red 1
                                      :green 2
                                      :white 3)]
                              {:row (+ button.row (- n 1))
                               :col button.col
                               :z (app:z-index-for-layer :button)})
      _ (error (Error "Unable to convert location to position, unknown location #{location}" 
                      {: location})))))

(λ make-lock-button-component [tag text position enabled-highlight disabled-highlight]
  (-> (Component.build
        (fn [self enabled?]
          (let [hi (if enabled? enabled-highlight disabled-highlight)]
            (self:set-content [[[text hi]]])
            (if enabled?
              (self:set-tag tag)
              (self:set-tag nil)))))
      (Component.set-position position)
      (Component.set-size {:width 3 :height 1})
      (: :update false)))

(fn AppState.Default.tick [app]
  (each [i color (ipairs [:red :green :white])]
    (let [button (. app.components.buttons i)]
      (button:update (not (nil? (Logic.Action.lock-dragon app.game color))))))
  (AppState.Default.Delegate.app.tick app))

(fn AppState.Default.OnEvent.app.maybe-auto-move [app]
  (case-try
    (or (Logic.Plan.next-move-to-flower app.game)
        (Logic.Plan.next-move-to-foundation app.game)) [from to]
    (Logic.Action.move app.game from to) (next-game events)
    (let [after #(do
                   (app:switch-state AppState.Default)
                   (app:queue-event :app :maybe-auto-move)
                   (app:update-game next-game [:move from to]))
          timeline (app:build-event-animation events after {:stagger-ms 200})]
      (app:switch-state AppState.Animating timeline))))

(fn AppState.Default.OnEvent.input.<LeftMouse> [app locations pos]
  (case locations
    [[:button :lock color]]
    (case-try
      (Logic.Action.lock-dragon app.game color) (next-game events)
      (let [timeline (app:build-event-animation
                       events
                       #(do
                          (app:queue-event :app :noop)
                          (app:queue-event :app :maybe-auto-move)
                          (app:switch-state AppState.Default)
                          (app:update-game next-game [:lock-dragon color]))
                       {:stagger-ms 120})]
        (app:switch-state AppState.Animating timeline))
      (catch
        (nil err) (app:notify err)))
    _ (AppState.Default.Delegate.input.OnEvent.input.<LeftMouse> app locations pos)))

(fn M.start [app-config game-config ?seed]
  (let [app (PatienceApp.start
              {:name "Shenzhen Solitaire"
               :filetype :shenzhen-solitaire
               :view {:width 80 :height 42}
               :empty-fields [[:cell 3] [:tableau 8] [:foundation 3] [:flower 1]]
               :card-style {:colors :custom
                            :graphics card-graphics}}
              {:AppImpl M
               :LogicImpl Logic
               :StateImpl AppState}
              app-config game-config ?seed)
        buttons (icollect [_ a (ipairs [[[:button :lock :red]
                                         "⊲ Š"
                                         (app:location->position [:button :lock :red])
                                         "@playtime.game.shenzhen.dragon.red"
                                         "@playtime.ui.off"]
                                       [[:button :lock :green]
                                        "⊲ Ñ"
                                         (app:location->position [:button :lock :green])
                                         "@playtime.game.shenzhen.dragon.green"
                                         "@playtime.ui.off"]
                                       [[:button :lock :white]
                                        "⊲ Õ"
                                         (app:location->position [:button :lock :white])
                                         "@playtime.game.shenzhen.dragon.white"
                                         "@playtime.ui.off"]])]
                  (make-lock-button-component (table.unpack a)))]
    (table.merge app.components {: buttons})
    app))

(fn M.render [app]
  (app.view:render [app.components.empty-fields
                    app.components.buttons
                    app.components.cards
                    (app:standard-patience-components)])
  app)

M
