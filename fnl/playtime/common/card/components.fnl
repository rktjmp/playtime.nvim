(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Component (require :playtime.component))
(local M {})

(λ fill-width [width left-edge left fill right right-edge]
  (.. left-edge
      left
      (string.rep fill (math.floor
                         (/ (- width
                               (string.col-width left-edge)
                               (string.col-width left)
                               (string.col-width right)
                               (string.col-width right-edge))
                            (string.col-width fill))))
      right
      right-edge))

(λ M.slot [location->position location {: width : height &as card-style}]
  (let [{: row : col : z} (location->position location)
        wide #(fill-width width $...)]
    (-> (Component.build)
        (Component.set-tag location)
        (Component.set-position {: row : col : z})
        (Component.set-size {: width : height})
        (Component.set-content
          (let [middle (fcollect [i 1 (- height 2)]
                         [[(wide "│" "" " " "" "│") "@playtime.game.card.empty"]])]
            (table.join
              [[[(wide "╭" "" "─" "" "╮") "@playtime.game.card.empty"]]]
              middle
              [[[(wide "╰" "" "─" "" "╯") "@playtime.game.card.empty"]]]))))))

;; TODO: expose and demand its provided to card-style
(fn default-french-graphics [suit rank color-count]
  "Describe how to represent a suit and rank on a card, and the highlight to use"
  (let [suit-text (case suit
                    :hearts :♥
                    :diamonds :♦
                    :clubs :♣
                    :spades :♠
                    :joker "🮲🮳")
        rank-text (case rank
                    :king :K
                    :queen :Q
                    :jack :J
                    1 :A
                    n (tostring n))
        (suit-text rank-text) (case suit
                                :joker (values "" suit-text)
                                _ (values suit-text rank-text))
        highlight (case color-count
                    2 (<s> "@playtime.game.card.#{suit}.two_colors")
                    4 (<s> "@playtime.game.card.#{suit}.four_colors"))]
    [suit-text rank-text highlight]))

(λ M.card [location->position initial-location card card-style]
  (let [{: width : height} card-style
        graphics (or card-style.graphics default-french-graphics)
        [suit rank] card
        [suit-text rank-text color] (graphics suit rank card-style.colors)
        wide #(fill-width width $...)
        top [[(wide "╭" "" "─" "" "╮") color]]
        bottom [[(wide "╰" "" "─" "" "╯") color]]
        body (case (or card-style.stacking :vertical-down)
               :horizontal-left [[[(wide "│" rank-text " " "" "│") color]]
                                 [[(wide "│" suit-text " " "" "│") color]]]
               :horizontal-right [[[(wide "│" "" " " rank-text "│") color]]
                                  [[(wide "│" "" " " suit-text "│") color]]]
               _ [[[(wide "│" rank-text " " suit-text "│") color]]
                  [[(wide "│" "" " " "" "│") color]]])
        _ (for [i 1 (- height 4)] ;; height - top bottom desc-lines
            (table.insert body [["│     │" color]]))
        face-up-content (table.join [top] body [bottom])
        face-down-color "@playtime.game.card.back"
        top [[(wide "╭" "" "─" "" "╮") face-down-color]]
        bottom [[(wide "╰" "" "─" "" "╯") face-down-color]]
        face-down-content (case height
                            5 [top
                               [[(wide "│" "+" " + " "+" "│") face-down-color]]
                               [[(wide "│" "" " +" " " "│") face-down-color]]
                               [[(wide "│" "+" " + " "+" "│") face-down-color]]
                               bottom]
                            n (-> (fcollect [i 1 (- n 2)]
                                    [[(wide "│" "+" " " "+" "│") face-down-color]])
                                  (table.insert 1 top)
                                  (table.insert bottom)))
        comp (-> (Component.build
                   (fn [self location card]
                     (self:set-tag location)
                     (self:set-position (location->position location))
                     ;; TODO: optim, only set content when card actually changes (flips)
                     (self:set-content (case card.face
                                         :up face-up-content
                                         :down face-down-content))))
                 (Component.set-size {: width : height})
                 (: :update initial-location card))]
    (λ comp.force-flip [self dir]
      ;; TODO: sorta ugly hack for animating card flipping when the game state
      ;; does not match the app state
      (case dir
        :face-down (self:set-content face-down-content)
        :face-up (self:set-content face-up-content)))
    comp))

(λ M.count [position card-style]
  (let [{: row : col : z} position]
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

M
