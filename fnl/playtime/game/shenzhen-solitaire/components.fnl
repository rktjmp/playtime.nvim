(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Component (require :playtime.component))
(local PatienceComponent (require :playtime.patience.component))

(local M {})

(λ M.card [{: card &as options}]
  (let [[suit rank] card
        dragon? (case card
                  (where (or [:red] [:green] [:white])) true
                  _ false)
        text (case card
               [:red] :Š
               [:green] :Ñ
               [:white] :Õ
               [:flower] :ƒ
               [_ pip] (tostring pip))
        color (.. "@playtime.game.shenzhen."
                  (case suit
                    :green :dragon.green
                    :red :dragon.red
                    :white :dragon.white
                    suit suit))
        suit-text (case suit
                    ; :coins :∷
                    ; :strings :⧧
                    ; :myriads :∬
                    ; :red :Š
                    ; :green :Ñ
                    ; :white :Õ
                    ; :flower :ƒ
                    _ " ")
        padding (string.rep " " 3)
        details (.. text padding suit-text)
        locked-details (.. text padding text)
        default-front-face [[["╭─────╮" color]]
                            [["│" color] [details color] ["│" color]]
                            [["│     │" color]]
                            [["│     │" color]]
                            [["╰─────╯" color]]]
        locked-front-face [[["╭─────╮" color]]
                           [["│" color] [locked-details color] ["│" color]]
                           [["│     │" color]]
                           [["│" color] [locked-details color] ["│" color]]
                           [["╰─────╯" color]]]
        component (PatienceComponent.base-card
                    (table.merge {:front-face default-front-face
                                  :lock (fn [self]
                                          ;; overide default front face so
                                          ;; synchronise-components-to-game-state
                                          ;; doesn't undo our change.
                                          (set self.front-face locked-front-face)
                                          (set self.content locked-front-face))}
                                 options))]
    component))

(λ M.lock-button [{: suit : text : position &as options}]
  (let [on {:click (fn [self ctx event fx]
                     (case event
                       {:button :left :action :release}
                       (if self.enabled?
                         (fx.event.dispatch :app :click-lock {: suit}))))}
        size {:height 1 :width (length text)}
        enabled-hl (.. "@playtime.game.shenzhen."
                       (case suit
                         :green :dragon.green
                         :red :dragon.red
                         :white :dragon.white))
        disabled-hl "@playtime.ui.off"
        enabled-content [[[text enabled-hl]]]
        disabled-content [[[text disabled-hl]]]
        comp (Component.new (table.merge {: size : on} options))]
    (set comp.enable (fn [self]
                       (table.merge self {:content enabled-content
                                          :enabled? true})))
    (set comp.disable (fn [self]
                        (table.merge self {:content disabled-content
                                           :enabled? false})))
    (comp:disable)
    comp))

M
