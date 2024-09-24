(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Component (require :playtime.component))

(local M {})

(fn make-cell [cell tag {: row : col : z} ?corners]
  (let [corners (table.merge {:nw "┼" :n "─" :ne "┼"
                              :e "│"          :w "│"
                              :sw "┼" :s "─" :se "┼"}
                             (or ?corners {}))
        {: ne : n : nw : e : w : se : s : sw} corners]
    (fn gen-content [center]
      [[[(.. nw n n n ne) :PlaytimeMuted]]
       [[(.. w " " center " " e) :PlaytimeMuted]]
       [[(.. sw s s s se) :PlaytimeMuted]]])
    (-> (Component.build
          (fn [{:children [c]} cell ...]
            (c:update cell ...)))
        (Component.set-children
          [(-> (Component.build
                 (fn [comp cell ?other]
                   (let [{: pressed?} (table.merge {:pressed? false} (or ?other {}))]
                     (case cell
                       {:revealed? true :mark nil}
                       (let [[content hl] (case cell
                                            {:mine? true} [(.. " ⹋ ") "@playtime.color.red"]
                                            {:count 0} [(.. "   ") "@playtime.ui.off"]
                                            {: count} [(.. " " count " ") "@playtime.ui.off"])]
                         (comp:set-content [[[content hl]]]))
                       {:revealed? false :mark nil}
                       (comp:set-content [[[(if pressed? "░░░" "▓▓▓") "@playtime.ui.off"]]])
                       {:revealed? _ :mark :flag}
                       (comp:set-content [[[(if pressed? " ⚐ " " ⚑ ") "@playtime.color.red"]]])
                       {:revealed? _ :mark :maybe}
                       (comp:set-content [[[(if pressed? "   " " ⚐ ") "@playtime.color.yellow"]]])))))
               (Component.set-tag [:grid tag])
               (Component.set-size {:width 3 :height 1})
               (Component.set-position {:row (+ row 1) :col (+ col 1) : z})
               (: :update cell))])
        (Component.set-position {: row : col : z})
        (Component.set-size {:height 3 :width 5})
        (Component.set-content (gen-content " "))
        (: :update cell))))

(fn M.mid-cell [cell tag position] (make-cell cell tag position))
(fn M.n-cell [cell tag position] (make-cell cell tag position {:nw "┬" :ne "┬"}))
(fn M.s-cell [cell tag position] (make-cell cell tag position {:sw "┴" :se "┴"}))
(fn M.e-cell [cell tag position] (make-cell cell tag position {:ne "┤" :se "┤"}))
(fn M.w-cell [cell tag position] (make-cell cell tag position {:nw "├" :sw "├"}))
(fn M.nw-cell [cell tag position] (make-cell cell tag position {:nw "╭" :ne "┬" :sw "├"}))
(fn M.ne-cell [cell tag position] (make-cell cell tag position {:nw "┬" :ne "╮" :se "┤"}))
(fn M.sw-cell [cell tag position] (make-cell cell tag position {:sw "╰" :se "┴" :nw "├"}))
(fn M.se-cell [cell tag position] (make-cell cell tag position {:sw "┴" :se "╯" :ne "┤"}))

M
