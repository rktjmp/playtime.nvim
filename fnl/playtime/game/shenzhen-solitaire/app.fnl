(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local PatienceApp (require :playtime.patience))
(local Logic (require :playtime.game.shenzhen-solitaire.logic))
(local Components (require :playtime.game.shenzhen-solitaire.components))

(local M (PatienceApp.scaffold-module {}))

(fn M.State.Idle.on.app.click-lock [state {: app} {: suit} fx]
  (case (Logic.Action.lock-dragon app.game suit)
    (next-game events) (let [animation (M.build-card-animation-from-events
                                         app
                                         events
                                         (fn []
                                           (app:synchronise-components-to-game-state)
                                           (fx.event.dispatch :app :maybe-auto-move)
                                           (fx.interaction-lock.unlock)
                                           (each [_ comp (ipairs app.components.cards.children)]
                                             (case comp.card
                                               (where [(= suit)]) (comp:lock)))
                                           (fx.engine.render)))]
                         (fx.animation.play animation)
                         (fx.interaction-lock.general-lockout)
                         (set app.game next-game))))

;;
;; ShenzhenSolitaire App
;;

(λ M.start [runtime-config game-config ?seed]
  (let [patience-config {:LogicImpl Logic
                         :StateImpl M.State
                         :ComponentImpl {:spec {:slots [{:location :cell
                                                         :count 3
                                                         :label "*"}
                                                        {:location :flower
                                                         :count 1
                                                         :label "ƒ"}
                                                        {:location :foundation
                                                         :count 3
                                                         :label "1"}
                                                        {:location :tableau
                                                         :count 8
                                                         :label "*"}]}
                                         :card Components.card}}
        app-config {:module M
                    :name "Shenzhen Solitaire"
                    :app-id :shenzhen-solitaire
                    :view {:width 76 :height 42}
                    :menu [["Shenzhen Solitaire" [["New Game" [:app :new-game]]]]]}]
    (PatienceApp.start patience-config
                       app-config
                       runtime-config
                       game-config
                       ?seed)))

(λ M.synchronise-components-to-game-state [app]
  (PatienceApp.synchronise-components-to-game-state app)
  (let [colors [:red :green :white]]
    (each [_ color (ipairs [:red :green :white])]
      (let [button (. app.components (.. color :-lock-button))]
        (if (not (nil? (Logic.Action.lock-dragon app.game color)))
          (button:enable)
          (button:disable))))))

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
                               :z 150})
      _ (error (Error "Unable to convert location to position, unknown location #{location}"
                      {: location})))))

(fn M.build-other-components [app]
  (let [[red green white] (icollect [_ {: text : suit} (ipairs [{:text "⊲ Š" :suit :red}
                                                                {:text "⊲ Ñ" :suit :green}
                                                                {:text "⊲ Õ" :suit :white}])]
                            (let [position (app:location->position [:button :lock suit])]
                              (Components.lock-button {: text : suit : position})))]
    (table.merge app.components {:red-lock-button red
                                 :green-lock-button green
                                 :white-lock-button white})))

M
