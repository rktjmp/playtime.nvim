(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Component (require :playtime.component))

(local M {})

(fn M.grid []
  (let [lines-1 ["┏━━━━━━━┯━━━━━━━┯━━━━━━━┳━━━━━━━┯━━━━━━━┯━━━━━━━┳━━━━━━━┯━━━━━━━┯━━━━━━━┓"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┠───────┼───────┼───────╂───────┼───────┼───────╂───────┼───────┼───────┨"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┠───────┼───────┼───────╂───────┼───────┼───────╂───────┼───────┼───────┨"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┣━━━━━━━┿━━━━━━━┿━━━━━━━╋━━━━━━━┿━━━━━━━┿━━━━━━━╋━━━━━━━┿━━━━━━━┿━━━━━━━┫"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┠───────┼───────┼───────╂───────┼───────┼───────╂───────┼───────┼───────┨"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┠───────┼───────┼───────╂───────┼───────┼───────╂───────┼───────┼───────┨"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┣━━━━━━━┿━━━━━━━┿━━━━━━━╋━━━━━━━┿━━━━━━━┿━━━━━━━╋━━━━━━━┿━━━━━━━┿━━━━━━━┫"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┠───────┼───────┼───────╂───────┼───────┼───────╂───────┼───────┼───────┨"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┠───────┼───────┼───────╂───────┼───────┼───────╂───────┼───────┼───────┨"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┗━━━━━━━┷━━━━━━━┷━━━━━━━┻━━━━━━━┷━━━━━━━┷━━━━━━━┻━━━━━━━┷━━━━━━━┷━━━━━━━┛"]
        lines-2 ["┏━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━┓"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┣━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━┫"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┣━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━┫"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┃       │       │       ┃       │       │       ┃       │       │       ┃"
                 "┗━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━━━┛"]
        lines-3 ["                                                                         "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 " ╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴ "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 " ╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴ "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 " ━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━ "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 " ╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴ "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 " ╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴ "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 " ━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━╋━━━━━━━━━━━━━━━━━━━━━━━ "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 " ╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴ "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 " ╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴┃╶──────┼───────┼──────╴ "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "        │       │       ┃       │       │       ┃       │       │        "
                 "                                                                         "]
        lines lines-3
        content (icollect [_ line (ipairs lines)]
                  [[line "@playtime.ui.off"]])]
        (Component.new {:size {:width (length (. lines 1))
                               :height (length lines)}
                        :position {:row 1 :col 0 :z 100}
                        :content content})))
;       1 2 3
;  ANSR     4
;  NOTE  x  5
;  ERSR     6
;       9 8 7
;
; [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ]
; [ 6 ] [ 7 ]   ?   [ 8 ] [ 9 ]
; [ ANSR ] [ NOTE ]       [ X ]
;
;
; ANSR   
; NOTE x [ 5 ] [ 6 ]
; ERSR   [ 7 ] [ 8 ] [ 9 ] [ X ]
   ""
 ""
 "│ 7 │"
 "╰───╯"

(fn M.cell [{: row : col}]
  (let [lines [" ¹ ² ³ "
               " ⁴ ⁵ ⁶ "
               " ⁷ ⁸ ⁹ "]
        ; lines [" 1 2 3 "
        ;        " 4 5 6 "
        ;        " 7 8 9 "]
        blank-content [[["       "]]
                       [["   ?   "]]
                       [["       "]]]
        sync (fn [self data ?highlight]
               (let [render-how (case data
                                  {:number {:default number :solution number}} :fixed-given
                                  {:number {:default 0 :input 0}} :other)
                     content (case data
                               ; _
                               ; [[[(string.format "(%d,%d) " data.row data.col)]]
                               ;  [[(string.format "   %d   " data.index)
                               ;    "@playtime.game.sudoku.fixed"]]
                               ;  [["       "]]]
                               ;; default-value == solution, this cell is a 'given'
                               {:number {:default number
                                         :solution number}}
                               ; (let [hl "@playtime.color.black"]
                               ;   [[[" ╭───╮ " hl]]
                               ;    [[" │ " hl] [(string.format "%d" number) hl] [" │ " hl]]
                               ;    [[" ╰───╯ " hl]]])
                               ; (let [hl "@playtime.color.black"]
                               ;   [[["       " hl]]
                               ;    [["  ╴" hl] [(string.format "%d" number) hl] ["╶  " hl]]
                               ;    [["       " hl]]])
                               (let [hl "@playtime.color.black"]
                                 [[["       " hl]]
                                  [["   " hl] [(string.format "%d" number) hl] ["   " hl]]
                                  [["   ⎺   " hl]]])

                               ;; User has given no value, so show notes
                               {:number {:default 0 :input 0}
                                : candidates}
                               (let [numbers (fcollect [i 1 9]
                                               (case (values (. candidates i) (and ?highlight (= ?highlight i)))
                                                 (true nil) [(tostring i) ["@playtime.color.white"]]
                                                 (true true) [(tostring i) ["@playtime.game.sudoku.note.highlight"]]
                                                 ; (true false) [(tostring i) ["@playtime.color.black"]]
                                                 (true false) [(tostring i) ["@playtime.color.white"]]

                                                 _ [" " "@playtime.ui.off"]))]
                                 [[[" "] (. numbers 1) [" "] (. numbers 2) [" "] (. numbers 3) [" "]]
                                  [[" "] (. numbers 4) [" "] (. numbers 5) [" "] (. numbers 6) [" "]]
                                  [[" "] (. numbers 7) [" "] (. numbers 8) [" "] (. numbers 9) [" "]]])
                               {:number {:default 0 :input number}}
                               [[["       "]]
                                [[(string.format "   %d   " number)
                                  "@playtime.color.cyan"]]
                                [["       "]]]
                               ; ;; notes may have nil, :maybe, :not
                               ; {: notes} (let [numbers (fcollect [i 1 9]
                               ;                           (case (values (. notes i) (= ?highlight i))
                               ;                             nil [" " "@playtime.ui.off"]
                               ;                             false [" " "@playtime.ui.off"]
                               ;                             (true false) [(tostring i) ["@playtime.game.sudoku.note.maybe"]]
                               ;                             (true true) [(tostring i) ["@playtime.game.sudoku.note.highlight"]]
                               ;                             true [(tostring i) "@playtime.game.sudoku.note.maybe"]
                               ;                             :maybe [(tostring i) "@playtime.game.sudoku.note.maybe"]
                               ;                             :not [(tostring i) "@playtime.game.sudoku.note.not"]))]
                               ;             [[[" "] (. numbers 1) [" "] (. numbers 2) [" "] (. numbers 3) [" "]]
                               ;              [[" "] (. numbers 4) [" "] (. numbers 5) [" "] (. numbers 6) [" "]]
                               ;              [[" "] (. numbers 7) [" "] (. numbers 8) [" "] (. numbers 9) [" "]]])
                               _ blank-content)]
                 (set self.data data)
                 (set self.content content)))
        highlight-number (fn [self number]
                           (self:update self.data number))
        content (icollect [_ line (pairs lines)]
                  [[line ["@playtime.game.sudoku.strike"]]])
        width 7
        height 3
        position (let [grid-start-row 2
                       grid-start-col 1]
                   {:row (+ grid-start-row (* (- row 1) (+ height 1)))
                    :col (+ grid-start-col (* (- col 1) (+ width 1)))
                    :z 101})]
    (Component.new {:size {:width 7 :height 3}
                    ;; Note this equation must match Puzzle.cell-at for correct
                    ;; row, col lookup.
                    :index (+ (* 9 (- row 1)) (- col 1) 1)
                    :position position
                    :update sync
                    :on {:click (fn [self cofx event fx]
                                  (case event
                                    {:button :left :action :release}
                                    (fx.event.dispatch :app :interact-cell {: row : col})))}
                    : highlight-number
                    :content blank-content})))


(fn M.pick-number [number position]
  (let [content (string.format " %d " number)
        disable (fn [self])
        enable (fn [self])
        toggle (fn [self])
        on {:click (fn [self cofx event fx]
                     (case event
                       {:button :left :action :release}
                       (fx.event.dispatch :app :pick-number {: number})))}
        ]
    (Component.new {: position
                    :content [[[content :Normal]]]
                    :size {:width 3 :height 1}
                    : on
                    : toggle
                    : disable
                    : enable
                    
                    })))

M
