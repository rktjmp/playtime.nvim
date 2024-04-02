(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Component (require :playtime.component))
(local M {})

(local icons
  {:circle {:solid "● "
           :split "◐ "
           :outline "○ "}
  :square {:solid "■ "
           :split "◧ "
           :outline "□ "}
  :triangle {:solid "▲ "
             :split "◭ "
             :outline "△ "}})

; (local icons
;   {:circle {:solid "sq"
;            :split "hq"
;            :outline "oq"}
;   :square {:solid "so"
;            :split "ho"
;            :outline "oo"}
;   :triangle {:solid "sd"
;              :split "hd"
;              :outline "od"}})

(fn M.slot [location->position location {: width : height &as style}]
  (assert (and (= width 10) (= height 5)) "only supports w=10, h=5")
  (let [{: row : col : z} (location->position location)
        color "@playtime.game.card.back"
        content [[["╭────────╮" color]]
                 [["│        │" color]]
                 [["│        │" color]]
                 [["│        │" color]]
                 [["╰────────╯" color]]]]
    (-> (Component.build)
        (Component.set-tag location)
        (Component.set-position {: row : col : z})
        (Component.set-size {: width : height})
        (Component.set-content content))))

(fn M.card [location->position initial-location card {: width : height &as style}]
  (assert (and (= width 10) (= height 5)) "only supports w=10, h=5")
  (let [{: shape : style : color : count} card
         icon (. icons shape style)
         icon-hl (.. "@playtime.game.set." color)
         selected-hl "@playtime.game.set.selected"
         muted-hl "@playtime.game.card.empty"
         the-line (case count
                    1 (string.fmt "   %s   " icon)
                    2 (string.fmt " %s  %s " icon icon)
                    3 (string.fmt " %s%s%s " icon icon icon))
         face-down-content [[["╭────────╮" muted-hl]]
                            [["│ + +  + │" muted-hl]]
                            [["│  +  +  │" muted-hl]]
                            [["│ +  + + │" muted-hl]]
                            [["╰────────╯" muted-hl]]]
         face-up-content [[["╭────────╮" muted-hl]]
                          [["│        │" muted-hl]]
                          [["│" muted-hl] [the-line icon-hl] ["│" muted-hl]]
                          [["│        │" muted-hl]]
                          [["╰────────╯" muted-hl]]]
         selected-content [[["╭────────╮" selected-hl]]
                           [["│        │" selected-hl]]
                           [["│" selected-hl] [the-line icon-hl] ["│" selected-hl]]
                           [["│        │" selected-hl]]
                           [["╰────────╯" selected-hl]]]
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
