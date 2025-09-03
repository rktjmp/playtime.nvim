(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Component (require :playtime.component))

(local M {})

(fn face-col [view-size]
  (+ 1 (- (math.floor (/ view-size.width 2)) 3)))

(fn M.face [view-size]
  (let [graphics {:smile [" ⠶ ⠶ "
                          "⠠⣀⣀⣀⠄"]
                  :tense [" ⠶ ⠶ "
                          "  ⣤  "]
                  :sad [" ⠶ ⠶ "
                        "⢀⠤⠤⠤⡀"]
                  :bruh [" ⠶⠒⠶ "
                         "⠠⣤⣤⣤⠄"]}
        content-for (collect [k ls (pairs graphics)]
                      (let [lines (icollect [_ l (ipairs ls)]
                                    [[l "@playtime.color.yellow"]])]
                        (values k lines)))
        col (face-col view-size)
        ;; Note: z-index is high so we still function during lockout
        comp (Component.new {:position {:row 2 :col col :z 1001}
                             :size {:width 5 :height 2}
                             :on {:click (fn [self cofx event fx]
                                           (case event
                                             {:button :left :action :press}
                                             (do
                                               (self:emote :tense)
                                               (fx.engine.render))
                                             {:button :left :action :release}
                                             (fx.event.dispatch :app :restart-game)))
                                  :drag (fn [self cofx event fx]
                                          (case event
                                            {:button :left :action :enter}
                                            (do
                                              (self:emote :tense)
                                              (fx.engine.render))
                                            {:button :left :action :leave}
                                            (do
                                              (self:emote :smile)
                                              (fx.engine.render))
                                            {:button :left :action :release}
                                            (fx.event.dispatch :app :restart-game)))}
                             :emote (fn [c what]
                                      (doto c
                                        (tset :content (. content-for what))))})]
    (comp:emote :smile)
    comp))

(fn M.remaining-mine-count [view-size]
  (Component.new {:position {:row 3 :col (- (face-col view-size) 10) :z 100}
                  :size {:width 3 :height 1}
                  :update-count (fn [c count]
                                  (let [s (string.format "%03d" count)]
                                    (set c.content [[[s "@playtime.ui.on"]]])
                                    (set c.size.width (length s))))}))

(fn M.timer [view-size]
  (Component.new {:position {:row 3 :col (+ 5 7 (face-col view-size))  :z 100}
                  :size {:width 3 :height 1}
                  :update-time (fn [c time]
                                 (set c.content [[[time "@playtime.ui.on"]]])
                                 (set c.size.width (length time)))}))

(fn make-cell [game-cell grid-coord {: row : col} ?corners]
  ;; Cells are two components, a border component and an inner component with
  ;; iconography and an interaction grid-coords. Since borders are overlayed on each
  ;; other on at least one edge, the nested component prevents "bad clicks"
  ;; on borders.
  (let [contents {:default              [[["▓▓▓" "@playtime.ui.off"]]]
                  :pressed              [[["░░░" "@playtime.ui.off"]]]
                  :empty                [[["   " "@playtime.ui.off"]]]
                  :flag                 [[[" ⚑ " "@playtime.color.red"]]]
                  :maybe                [[[" ⚐ " "@playtime.color.yellow"]]]
                  :default->flag        [[[" ⚑ " "@playtime.color.blue"]]]
                  :flag->maybe          [[[" ⚐ " "@playtime.color.blue"]]]
                  :maybe->default       [[["░░░" "@playtime.color.blue"]]]
                  :mine                 [[[" ⹋ " "@playtime.color.red"]]]}
        update-content-for-cell (fn [self cell ?other]
                                  (set self.cell cell)
                                  (let [{: pressed?} (table.merge {:pressed? false} (or ?other {}))
                                        content (case cell
                                                  {:revealed? true :mark nil}
                                                  (case cell
                                                    {:mine? true} contents.mine
                                                    {:count 0} contents.empty
                                                    {: count} [[[(.. " " count " ")
                                                               "@playtime.ui.off"]]])
                                                  {:revealed? false :mark nil}
                                                  (if pressed? contents.pressed contents.default)
                                                  {:revealed? _ :mark :flag}
                                                  [[[(if pressed? " ⚐ " " ⚑ ")
                                                   "@playtime.color.red"]]]
                                                  {:revealed? _ :mark :maybe}
                                                  [[[(if pressed? "   " " ⚐ ")
                                                   "@playtime.color.yellow"]]])]
                                    (set self.content content)))
        icon-component (Component.new
                         {:size {:height 1 :width 3}
                          :position {:row (+ row 1) :col (+ col 1) :z 501}
                          :on {:drag (fn [self cofx event fx]
                                       (case event
                                         ;; Left Button
                                         (where (or {:button :left :action :inside}
                                                    {:button :left :action :enter}))
                                         (when (and (not self.cell.revealed?)
                                                    (not (= self.cell.mark :flag)))
                                           (set self.content contents.pressed)
                                           (fx.event.dispatch :app :emote {:emote :tense})
                                           (fx.engine.render))
                                         {:button :left :action :leave}
                                         (when (and (not self.cell.revealed?)
                                                    (not (= self.cell.mark :flag)))
                                           (case self.cell
                                             {:mark :maybe} (set self.content contents.maybe)
                                             _ (set self.content contents.default))
                                           (fx.event.dispatch :app :emote {:emote :smile})
                                           (fx.engine.render))
                                         {:button :left :action :release}
                                         (when (and (not self.cell.revealed?)
                                                    (not (= self.cell.mark :flag)))
                                           (fx.event.dispatch :app :emote {:emote :smile})
                                           (fx.event.dispatch :app :reveal grid-coord))
                                         ;; Right button
                                         (where (or {:button :right :action :inside}
                                                    {:button :right :action :enter}))
                                         (when (not self.cell.revealed?)
                                           (case self.cell
                                             {:mark nil} (set self.content contents.default->flag)
                                             {:mark :flag} (set self.content contents.flag->maybe)
                                             {:mark :maybe} (set self.content contents.maybe->default))
                                           (fx.event.dispatch :app :emote {:emote :tense})
                                           (fx.engine.render))
                                         {:button :right :action :leave}
                                         (when (not self.cell.revealed?)
                                           (case self.cell
                                             {:mark nil} (set self.content contents.default)
                                             {:mark :flag} (set self.content contents.flag)
                                             {:mark :maybe} (set self.content contents.maybe))
                                           (fx.event.dispatch :app :emote {:emote :smile})
                                           (fx.engine.render))
                                         {:button :right :action :release}
                                         (when (not self.cell.revealed?)
                                           (fx.event.dispatch :app :emote {:emote :smile})
                                           (fx.event.dispatch :app :mark grid-coord))))
                               :click (fn [self cofx event fx]
                                        (case event
                                          ;; Left Button
                                          {:button :left :action :press}
                                          (when (and (not self.cell.revealed?)
                                                     (not (= self.cell.mark :flag)))
                                            (set self.content contents.pressed)
                                            (fx.event.dispatch :app :emote {:emote :tense})
                                            (fx.engine.render))
                                          {:button :left :action :release}
                                          (when (and (not self.cell.revealed?)
                                                     (not (= self.cell.mark :flag)))
                                            (fx.event.dispatch :app :emote {:emote :smile})
                                            (fx.event.dispatch :app :reveal grid-coord))
                                          ;; Right Button
                                          {:button :right :action :press}
                                          (when (not self.cell.revealed?)
                                            (case self.cell
                                              {:mark nil} (set self.content contents.default->flag)
                                              {:mark :flag} (set self.content contents.flag->maybe)
                                              {:mark :maybe} (set self.content contents.maybe->default))
                                            (fx.event.dispatch :app :emote {:emote :tense}))
                                          {:button :right :action :release}
                                          (when (not self.cell.revealed?)
                                            (fx.event.dispatch :app :emote {:emote :smile})
                                            (fx.event.dispatch :app :mark grid-coord))))}
                          :content [[["!!!" "@playtime.color.magenta"]]]
                          : update-content-for-cell})
        corners (table.merge {:nw "┼" :n "─" :ne "┼" 
                              :e "│"          :w "│"
                              :sw "┼" :s "─" :se "┼"}
                             (or ?corners {}))
        {: ne : n : nw : e : w : se : s : sw} corners
        content [[[(.. nw n   n   n  ne) :PlaytimeMuted]]
                 [[(.. w " " " " " " e) :PlaytimeMuted]]
                 [[(.. sw s   s   s  se) :PlaytimeMuted]]]
        comp (Component.new {:size {:height 3 :width 5}
                             :position {: row : col :z 500}
                             :content content
                             :children [icon-component]
                             :update-content-for-cell #(icon-component:update-content-for-cell $2 $3)})]
    (comp:update-content-for-cell game-cell)
    comp))

(fn make-mid-cell [cell grid-coord position]
  (make-cell cell grid-coord position {}))
(fn make-n-cell [cell grid-coord position]
  (make-cell cell grid-coord position {:nw "┬" :ne "┬"}))
(fn make-s-cell [cell grid-coord position]
  (make-cell cell grid-coord position {:sw "┴" :se "┴"}))
(fn make-e-cell [cell grid-coord position]
  (make-cell cell grid-coord position {:ne "┤" :se "┤"}))
(fn make-w-cell [cell grid-coord position]
  (make-cell cell grid-coord position {:nw "├" :sw "├"}))
(fn make-ne-cell [cell grid-coord position]
  (make-cell cell grid-coord position {:nw "┬" :ne "╮" :se "┤"}))
(fn make-nw-cell [cell grid-coord position]
  (make-cell cell grid-coord position {:nw "╭" :ne "┬" :sw "├"}))
(fn make-se-cell [cell grid-coord position]
  (make-cell cell grid-coord position {:sw "┴" :se "╯" :ne "┤"}))
(fn make-sw-cell [cell grid-coord position]
  (make-cell cell grid-coord position {:sw "╰" :se "┴" :nw "├"}))

(fn M.grid [{:grid {:width grid-width :height grid-height} : position} cell-iterator]
  (local cell-height 3)
  (local cell-width 5)
  (let [{: row : col} position
        (lookup ordered) (accumulate [(lookup ordered) (values {} [])
                                      {: x : y} cell (cell-iterator)]
                           (let [grid-coord {: x : y}
                                 f (case (values x y)
                                     (where (1 1)) make-nw-cell
                                     (where ((= grid-width) 1)) make-ne-cell
                                     (where (1 (= grid-height))) make-sw-cell
                                     (where ((= grid-width) (= grid-height))) make-se-cell
                                     (where (1 _)) make-w-cell
                                     (where ((= grid-width) _)) make-e-cell
                                     (where (_ 1)) make-n-cell
                                     (where (_ (= grid-height))) make-s-cell
                                     _ make-mid-cell)
                                 row (+ row (* (- cell-height 1) (- y 1)))
                                 col (+ col (* (- cell-width 1) (- x 1)))
                                 c (f cell grid-coord {: row : col })]
                             (table.insert lookup cell.id c)
                             (table.insert ordered c)
                             (values lookup ordered)))]
    (Component.new {:children ordered
                    :lookup lookup})))

M
