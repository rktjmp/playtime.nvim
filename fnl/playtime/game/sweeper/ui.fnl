(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Component (require :playtime.component))

(local M {})

(fn make-cell [cell tag {: row : col : z} ?corners]
  (let [corners (table.merge {:ne "┼" :n "─" :nw "┼"
                              :e "│"          :w "│"
                              :se "┼" :s "─" :sw "┼"}
                             (or ?corners {}))
        {: ne : n : nw : e : w : se : s : sw} corners]
    (fn gen-content [center]
      [[[(.. ne n n n nw) :Comment]]
       [[(.. w " " center " " e) :Comment]]
       [[(.. se s s s sw) :Comment]]])
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
        (Component.set-content [[[(.. ne n n n nw) :Comment]]
                                  [[(.. w "   " e) :Comment]]
                                  [[(.. se s s s sw) :Comment]]])
        (: :update cell))))

(fn M.mid-cell [cell tag position] (make-cell cell tag position))
(fn M.n-cell [cell tag position] (make-cell cell tag position {:ne "┬" :nw "┬"}))
(fn M.s-cell [cell tag position] (make-cell cell tag position {:se "┴" :sw "┴"}))
(fn M.e-cell [cell tag position] (make-cell cell tag position {:nw "┤" :sw "┤"}))
(fn M.w-cell [cell tag position] (make-cell cell tag position {:ne "├" :se "├"}))
(fn M.ne-cell [cell tag position] (make-cell cell tag position {:ne "┬" :nw "╮" :sw "┤"}))
(fn M.nw-cell [cell tag position] (make-cell cell tag position {:ne "╭" :nw "┬" :se "├"}))
(fn M.se-cell [cell tag position] (make-cell cell tag position {:se "┴" :sw "╯" :nw "┤"}))
(fn M.sw-cell [cell tag position] (make-cell cell tag position {:se "╰" :sw "┴" :ne "├"}))

M
