(require-macros :playtime.prelude)
(prelude)

(local M {})
(local Error (require :playtime.error))

(fn M.blank [{: width : height &as style}]
  (assert (and (= width 7) (= height 5)) "only supports w=7, h=5")
  (let [hl "@playtime.game.card.back"]
    [[["╭─────╮" hl]]
     [["│     │" hl]]
     [["│     │" hl]]
     [["│     │" hl]]
     [["╰─────╯" hl]]]))

(fn M.regular [card {: width : height &as style}]
      (assert (and (= width 7) (= height 5)) "only supports w=7, h=5")
      (let [[suit rank] card
            text (case card
                   [:red] :Š
                   [:green] :Ñ
                   [:white] :Õ
                   [:flower] :ƒ
                   [_ pip] (tostring pip))

            suit-text (case suit
                        ; :coins :∷
                        ; :strings :⧧
                        ; :myriads :∬
                        ; :red :Š
                        ; :green :Ñ
                        ; :white :Õ
                        ; :flower :ƒ
                        _ " ")
            ; rank-text (case rank :king :K :queen :Q :jack :J 1 :A pip (tostring pip))
            color (.. "@playtime.game.shenzhen."
                      (case suit
                        :green :dragon.green
                        :red :dragon.red
                        :white :dragon.white
                        suit suit))
            ;padding (string.rep " " (- 5 (string.len text)))
            padding (string.rep " " 3)
            details (.. text padding suit-text)
            ]
        [[["╭─────╮" color]]
         [["│" color] [details color] ["│" color]]
         [["│     │" color]]
         [["│     │" color]]
         [["╰─────╯" color]]]))

M
