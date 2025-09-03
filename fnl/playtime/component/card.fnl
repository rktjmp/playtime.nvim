(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Component (require :playtime.component))

(local M {})

(λ M.slot [options]
  (let [hl "@playtime.game.card.empty"
        label (or options.label " ")
        content [[["╭─────╮" hl]]
                 [[(string.format "│%s    │" label) hl]]
                 [["│     │" hl]]
                 [["│     │" hl]]
                 [["╰─────╯" hl]]]]
    (Component.new (table.merge {:size {:width 7 :height 5} : content}
                                options))))

(λ M.base-card [{: front-face & options}]
  (let [hl "@playtime.game.card.back"
        back-face (or options.back-face
                      [[["╭─────╮" hl]]
                       [["│+ + +│" hl]]
                       [["│ + + │" hl]]
                       [["│+ + +│" hl]]
                       [["╰─────╯" hl]]])
        ;; important: component.content = component.field so faces can be
        ;; changed by the card itself, eg: shenzhen-solitaire when locking
        ;; dragons.
        flip-face-up (fn [component] (set component.content component.front-face) component)
        flip-face-down (fn [component] (set component.content component.back-face) component)
        component (Component.new (table.merge {:size {:width 7 :height 5}
                                               : back-face
                                               : front-face
                                               : flip-face-up
                                               : flip-face-down}
                                              options))]
    (component:flip-face-up)))

(λ M.card [{: card &as options}]
  (let [color-count (or options.color-count 2)
        stacking-orientation (or options.stacking-orientation :vertical)
        [suit rank] card
        rank-text (case rank
                    :king :K
                    :queen :Q
                    :jack :J
                    1 :A
                    14 :A
                    n (tostring n))
        suit-text (case suit
                    :hearts :♥
                    :diamonds :♦
                    :clubs :♣
                    :spades :♠
                    :joker "🮲🮳")
        (suit-text rank-text) (case suit
                                :joker (values "" suit-text)
                                _ (values suit-text rank-text))
        color (case color-count
                    2 (<s> "@playtime.game.card.#{suit}.two_colors")
                    4 (<s> "@playtime.game.card.#{suit}.four_colors"))
        details (string.format "%-4s%s" rank-text suit-text)
        front-vertical (let [details (string.format "%-4s%s" rank-text suit-text)]
                         [[["╭─────╮" color]]
                          [["│" color] [details color] ["│" color]]
                          [["│     │" color]]
                          [["│     │" color]]
                          [["╰─────╯" color]]])
        front-horizontal (let [rank (string.format "%-5s" rank-text)
                               suit (.. suit-text (string.rep " " (- 5 (string.col-width suit-text))))]
                           [[["╭─────╮" color]]
                            [["│" color] [rank color] ["│" color]]
                            [["│" color] [suit color] ["│" color]]
                            [["│     │" color]]
                            [["╰─────╯" color]]])
        front-face (case stacking-orientation
                     :horizontal front-horizontal
                     :vertical front-vertical
                     _ (error (<s> "Unknown stacking-orientation #{stacking-orientation}")))
        component (M.base-card (table.merge {: front-face} options))]
    (set component.card card)
    component))

M
