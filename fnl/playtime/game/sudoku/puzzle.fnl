(require-macros :playtime.prelude)
(prelude)

(local ffi (require :ffi))
(local Logger (require :playtime.logger))
(local DLX (require :playtime.game.sudoku.dlx))

(local M {})

(fn M.index-for-cell [{: row : col}]
  (+ (* 9 (- row 1))
     (- col 1) 1))

(fn M.cells-in-row [cells row-num]
  (let [start-at (* (- row-num 1) 9)]
    (fcollect [i 1 9]
      (. cells (+ start-at i)))))

(fn M.cells-in-col [cells col-num]
  (let [stride 9]
    (fcollect [i 1 9]
      (. cells (+ col-num (* 9 (- i 1)))))))

(fn M.cell-at [cells {: row : col}]
  (. cells (+ (* 9 (- row 1))
              (- col 1) 1)))

;; House layout:
;;
;; 1 1 1 2 2 2 3 3 3
;; 1 1 1 2 2 2 3 3 3
;; 1 1 1 2 2 2 3 3 3
;; 4 4 4 5 5 5 6 6 6
;; 4 4 4 5 5 5 6 6 6
;; 4 4 4 5 5 5 6 6 6
;; 7 7 7 8 8 8 9 9 9
;; 7 7 7 8 8 8 9 9 9
;; 7 7 7 8 8 8 9 9 9
;;
(fn M.cells-in-house [cells house-num]
  ;; find the rows
  ;; find col-offset
  ;; then for row, for col-offset..+3
  (let [first-row (+ (* (math.floor (/ (- house-num 1) 3)) 3) 1)
        first-col (+ (* (% (- house-num 1) 3) 3) 1)
        in-house []]
    (for [row first-row (+ first-row 2)]
      (for [col first-col (+ first-col 2)]
        (table.insert in-house (. cells (+ (* 9 (- row 1))
                                           (- col 1) 1)))))
    in-house))

(fn update-candidates-in-set! [cells-set get-cell-value-fn]
  ;; We run this against cells multiple times, for row, col and house, so we
  ;; cannot blindly merge a set-specific candidate list.
  ;; First create candidate list specific to this set of cells
  ;; then merge that list onto the cells existing candidates,
  ;; careful to not clobber previously unset candidates.
  (let [not-viable (accumulate [candidates [true true true
                                            true true true
                                            true true true]
                                _ cell (ipairs cells-set)]
                     (case (get-cell-value-fn cell)
                       0 candidates
                       n (table.set candidates n false)))]
    (each [_ cell (ipairs cells-set)]
      (set cell.candidates (table.merge cell.candidates not-viable
                                        (fn [_num prev-val new-val]
                                          (case (values prev-val new-val)
                                            ;; previously eliminated, retain elimination.
                                            (false false) false
                                            (false true) false
                                            ;; previously not eliminated  but we have eliminated it
                                            ;; by this set.
                                            (true false) false
                                            ;; otherwise dont eliminate.
                                            (true true) true)))))))

(fn M.update-candidates! [cells ?get-cell-value-fn]
  ;; unset all previous candidate states so we can more easily merge our new
  ;; eliminations.
  (let [get-value-fn (or ?get-cell-value-fn #(. $1 :number))]
    (each [_ cell (ipairs cells)]
      (set cell.candidates [true true true
                            true true true
                            true true true]))
    (for [house-num 1 9]
      (let [house (M.cells-in-house cells house-num)]
        (update-candidates-in-set! house get-value-fn)))
    (for [row-num 1 9]
      (let [row (M.cells-in-row cells row-num)]
        (update-candidates-in-set! row get-value-fn)))
    (for [col-num 1 9]
      (let [col (M.cells-in-col cells col-num)]
        (update-candidates-in-set! col get-value-fn)))
    cells))

;;
;; Puzzle generation & helpers
;;

(fn decode-share-string [input]
  "Convert a standard `[0-9]{81}` sharable sudoku string a list of cells"
  (assert (and input (= 81 (length input))) "sudoku input must be 81 chars long")
  (let [input (string.gsub input "%D" "0")
        cells (fcollect [index 1 81]
                (let [i-z (- index 1)
                      row (+ (math.floor (/ i-z 9)) 1)
                      col (+ (% i-z 9) 1)
                      number (-> (string.sub input index index) (tonumber))
                      candidates [true true true
                                  true true true
                                  true true true]]
                  {: index : row : col
                   : number : candidates}))]
    (M.update-candidates! cells)))

(fn solution->string [solution]
  (-> (accumulate [t [] _ {: row : col : number} (ipairs solution)]
        (doto t
          (tset (M.index-for-cell {: row : col}) number)))
      (table.concat)))

(fn generate-random-complete-puzzle []
  (let [cells (decode-share-string (string.rep "0" 81))] ;; nothing is true, everything is permitted
    (case (DLX.find-solutions cells 1)
      ;; We pay some cost going back to string rep, the back again to
      ;; matrix/table rep but currently its fine as we dont call this function
      ;; more than a few times.
      [solution] (solution->string solution))))

(λ M.new-puzzle-from-input [sudoku-string]
  ;; decode input then ensure its actually solveable
  (let [cells (decode-share-string sudoku-string)]
    (case (DLX.solve cells)
      solution (do
                 ;; attach solution values to cells
                 (each [_ {: row : col : number} (ipairs solution)]
                   (let [index (M.index-for-cell {: row : col})]
                     (set (. cells index :solution) number)))
                 cells)
      (nil err) (values nil "Given sudoku string invalid, more than one solution!"))))

(λ M.new-puzzle [{: difficulty}]
  ;; Generate a complete solved puzzle, then progressively remove cells from it
  ;; until we reckon its hard enough and still has a unique solution.
  ;; For now, we just keep feeding the puzzle string back, building an entirely
  ;; new matrix each time, if this becomes a bottle kneck we can probably
  ;; retain the same matrix structure and edit it though that sounds like a lot
  ;; of searching.
  (assert (<= 1 difficulty 80) "difficulty must be between [1, 80]")
  (let [solution-string (generate-random-complete-puzzle)
        solution-cells (decode-share-string solution-string)
        puzzle-cells (decode-share-string solution-string)
        breaker {:n 0}
        built (accumulate [builder {:puzzle puzzle-cells
                                    :zero-count 0
                                    :non-zero-indexes (table.shuffle (fcollect [i 1 81] i))}
                           _ #true
                           &until (or (= 0 (length builder.non-zero-indexes))
                                      (<= (- 81 builder.zero-count) difficulty))]
                ;; Flip random non-zero to zero, run solver, if we get over 1 solution,
                ;; undo and try another index.
                ;; If flipping a cell to zero gives more than one solution, we
                ;; can never flip that cell in this puzzle, so we don't add it
                ;; back to the list. We may exhaust all posibilities in a
                ;; puzzle, so they do have some minimum 'fixed-count'.
                (let [index-in-puzzle (table.remove builder.non-zero-indexes)
                      undo-value (. builder.puzzle index-in-puzzle)
                      ;; set target to zero, all candidates possible.
                      _ (set (. builder.puzzle index-in-puzzle) {:row undo-value.row :col undo-value.col
                                                                 :number 0 :candidates [true true true
                                                                                        true true true
                                                                                        true true true]})]
                  (set breaker.n (+ 1 breaker.n))
                  (assert (<= breaker.n 1000))
                  (case (DLX.solve builder.puzzle)
                    ;; we legitimately reduce non-zero
                    solution (set builder.zero-count (+ builder.zero-count 1))
                    ;; we failed to reduce, repair and try another
                    nil (set (. builder.puzzle index-in-puzzle) undo-value))
                  builder))
        _ (Logger.info [:count built.zero-count
                        :non-zero (- 81 built.zero-count)
                        :len (length built.non-zero-indexes)])
        ;; Convert puzzle back to string, and pass it to new-puzzle-from-input.
        ;; We suffer some performance impact from all this string -> x -> y ->
        ;; ... -> string but generally the it all seems "fast enough".
        puzzle-string (solution->string puzzle-cells)]
    (M.new-puzzle-from-input puzzle-string)))

M
