(require-macros :playtime.prelude)
(prelude)

(local Error (require :playtime.error))
(local Logger (require :playtime.logger))
(local Id (require :playtime.id))
(local Puzzle (require :playtime.game.sudoku.puzzle))

(local M {:Action {}
          :Plan {}
          :Query {}})

;; optimisation methods: each cell has pre-computed indexes for all column,row and house cells
;; use bitmask for candidate values
;; lcv heuristic cheaply: for each value, count how many eliminations it would cause in neighbors (using bit ops) and sort values by this small integer.
;;
;; We represent the grid as 9x9 cells, (row,col), where (1,1) is top left, (9,9) is
;; bottom right.
;;

(fn puzzle->game [puzzle]
  ;; attach extra data to Puzzle, to handle user notes, etc.
  (icollect [_ cell (ipairs puzzle)]
    (let [{: row : col : index : number : solution : candidates} cell]
      {: index : row : col
       ;; note we use 0 as a holder for 'empty'
       :number {: solution ;; as in puzzle solution
                :default number ;; as in default puzzle state
                :input 0} ;; as set by user
       : candidates
       :notes {}})))

(λ M.build [config seed]
  (let [easy "010000674089700000002063800028000760000100430006920018060235000200408106570000000"
        seed "A*X1_.2800500240000000007nab0005003017086000500500002zy4000300000000061090000100?"
        ;; sudoku-coach
        hard "007000009002530000008906000070109000100050003000000008000025087200060000000300460"
        xxl-hard "050100000780006002000020080000075013400000000075003400004800029090000300300000005"
        ;; sudoku.com
        extreme "073090006000020040000005070000680010500000020000004600209000700700100008600000000"
        escargo "100007090030020008009600500005300900010080002600004000300000010040000007007000300"
        generated (let [dlx (require :playtime.game.sudoku.dlx)
                        puzzle (benchmark #(Logger.info [:dlx.generate $1]) (Puzzle.new-puzzle {:difficulty 30}))]
                    puzzle)
        cells (puzzle->game generated)]
    {: cells
     : seed}))

(fn M.Action.new-game [game-string]
  ;; sudoku strings are 81 chars, representing 9-char rows.
  ;; 1-9 as given, any other character is a blank
  ; (assert (= 81 (length game-string)) "sudoku game-string must be 81 characters long")
  )

;; Auto-candidate interaction
;; We treat auto-candidate and user-notes as two separate structures.
;;
;; auto-candidates are always correct to the current state, but may
;; over-represent candidates that would be removed by higher-order inference.
;;
;; User notes sit as an extra layer on top of auto-candidates. By default they
;; are empty, and are toggled by candidate-index to false/true.
;;
(λ M.Action.apply-auto-notes [game]

  game)

(λ M.Action.update-cell [game {: row : col} number]
  (let [cell (Puzzle.cell-at game.cells {: row : col})]
    (Logger.info cell)
    ;; Mark input
    (set cell.number.input number)
    ;; Refresh candidates to new information
    (Logger.info cell)
    (Puzzle.update-candidates! game.cells
                               #(case $1.number
                                  {:default n :solution n} n
                                  {:input n} n))
    ;; Optionally, merge updated candidates onto player notes.
    ;; This is done with some care while the candidates are the full reflection
    ;; of the given cells, the user may have inferred by higher logic that a
    ;; cell value is eliminated even if its technically a candidate.
    ;; We also only want to update if auto-note has been run.

    ; (Puzzle.update-candidates
    ;   game.cells
    ;   (fn [cell new-candidates]
    ;     (let [old-candidates cell.candidates]
    ;       (for [i 1 9]
    ;         (case (values (. cell.notes i) (. new-candidates i))
    ;           ;; previously marked false, retain no matter what
    ;           (false _) (set (. cell.notes i) false)
    ;           ;; previously auto-noted, unmodified so mirror new candidates
    ;           (true false) (set (. cell.notes i) false))))
    ;     (set cell.candidates new-candidates)))
    game
    ))

(λ M.iter-cells [state]
  (fn iter []
    (for [row 1 9]
      (for [col 1 9]
        (let [loc {: row : col}
              cell (Puzzle.cell-at state.cells loc)
              index cell.index]
          (coroutine.yield {: row : col : index} cell)))))
  (coroutine.wrap iter))

(λ M.Query.cell-at [state {: row : col}]
  (Puzzle.cell-at state.cells {: row : col}))

(λ M.Query.cells-in-row [state row]
  (Puzzle.cells-in-row state.cells row))

(λ M.Query.cells-in-col [state col]
  (Puzzle.cells-in-col state.cells col))

(λ M.Query.cells-in-house [state {: row : col}]
  (Puzzle.cells-in-house state.cells {: row : col}))

M
