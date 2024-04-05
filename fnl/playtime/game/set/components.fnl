(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Component (require :playtime.component))
(local M {})

(local icons
  {:circle {:solid "●"
           :split "◐"
           :outline "○"}
  :square {:solid "■"
           :split "◧"
           :outline "□"}
  :triangle {:solid "▲"
             :split "◭"
             :outline "△"}})

(fn make-line [width left mid right]
  (.. left (string.rep mid (- width 2)) right))

(fn M.slot [location->position location {: width : height &as card-style}]
  ; (assert (and (= width 10) (= height 5)) "only supports w=10, h=5")
  (let [{: row : col : z} (location->position location)
        fill #(make-line width $1 $2 $3)
        color "@playtime.game.card.back"
        content [[[(fill "╭" "─" "╮") color]]
                 [[(fill "│" " " "│") color]]
                 [[(fill "│" " " "│") color]]
                 [[(fill "│" " " "│") color]]
                 [[(fill "╰" "─" "╯") color]]]]
    (-> (Component.build)
        (Component.set-tag location)
        (Component.set-position {: row : col : z})
        (Component.set-size {: width : height})
        (Component.set-content content))))

(fn M.card [location->position initial-location card {: glyph-width : width : height &as card-style}]
  ; (assert (and (= width 10) (= height 5)) "only supports w=10, h=5")
  (let [{: shape : style : color : count} card
        fill #(make-line width $1 $2 $3)
        icon (. icons shape style)
        icon-hl (.. "@playtime.game.set." color)
        selected-hl "@playtime.game.set.selected"
        muted-hl "@playtime.game.card.empty"
        the-line (let [right-pad (if (= :wide glyph-width) " " "")]
                   (case count
                     1 (string.fmt "   %s   %s" icon right-pad)
                     2 (string.fmt "  %s %s  %s" icon icon right-pad)
                     3 (string.fmt " %s %s %s %s" icon icon icon right-pad)))
         face-down-content [[[(fill "╭" "─" "╮") muted-hl]]
                            [[(fill "│" "\\" "│") muted-hl]]
                            [[(fill "│" "/" "│") muted-hl]]
                            [[(fill "│" "\\" "│") muted-hl]]
                            [[(fill "╰" "─" "╯") muted-hl]]]
         face-up-content [[[(fill "╭" "─" "╮") muted-hl]]
                          [[(fill "│" " " "│") muted-hl]]
                          [["│" muted-hl] [the-line icon-hl] ["│" muted-hl]]
                          [[(fill "│" " " "│") muted-hl]]
                          [[(fill "╰" "─" "╯") muted-hl]]]
         selected-content [[[(fill "╭" "─" "╮") selected-hl]]
                           [[(fill "│" " " "│") selected-hl]]
                           [["│" selected-hl] [the-line icon-hl] ["│" selected-hl]]
                           [[(fill "│" " " "│") selected-hl]]
                           [[(fill "╰" "─" "╯") selected-hl]]]
         comp (-> (Component.build
                    (fn [self location card selected?]
                      (self:set-tag location)
                      (self:set-position (location->position location))
                      ;; TODO: optim, only set content when card actually changes (flips)
                      (self:set-content (case card.face
                                          :up (if selected? selected-content face-up-content)
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

M
