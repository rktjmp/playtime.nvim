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

(fn M.slot [{: card-width &as options}]
  (let [width card-width
        height 5
        fill #(make-line width $1 $2 $3)
        color "@playtime.game.card.back"
        content [[[(fill "╭" "─" "╮") color]]
                 [[(fill "│" " " "│") color]]
                 [[(fill "│" " " "│") color]]
                 [[(fill "│" " " "│") color]]
                 [[(fill "╰" "─" "╯") color]]]]
      (Component.new (table.merge {:size {: width : height}
                                   :content content}
                                  options))))

(λ M.card [{: card : location : card-width &as options}]
  (let [{: shape : style : color : count} card
        width card-width
        height 5
        fill #(make-line width $1 $2 $3)
        icon (. icons shape style)
        icon-hl (.. "@playtime.game.set." color)
        selected-hl "@playtime.game.set.selected"
        muted-hl "@playtime.game.card.empty"
        the-line (let [right-pad (case card-width 10 " " 9 "")]
                   (case count
                     1 (string.fmt "   %s   %s" icon right-pad)
                     2 (string.fmt "  %s %s  %s" icon icon right-pad)
                     3 (string.fmt " %s %s %s %s" icon icon icon right-pad)))
         face-down-content [[[(fill "╭" "─" "╮") muted-hl]]
                            [[(fill "│" "╲" "│") muted-hl]]
                            [[(fill "│" "╱" "│") muted-hl]]
                            [[(fill "│" "╲" "│") muted-hl]]
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
         click (fn [self cofx event fx]
                           (case event
                             {:button :left :action :press}
                             (fx.event.dispatch :app :click-card {:card self.card
                                                                  :component self
                                                                  :location self.location})))]
      (Component.new (table.merge {:size {: width : height}
                                   :on {: click}
                                   :flip-face-up #(set $1.content face-up-content)
                                   :flip-face-down #(set $1.content face-down-content)
                                   :select (fn [self]
                                             (set self.content selected-content))
                                   :deselect (fn [self]
                                               (when (= self.content selected-content)
                                                 (set self.content face-up-content)))
                                   :content face-down-content}
                                  options))))

M
