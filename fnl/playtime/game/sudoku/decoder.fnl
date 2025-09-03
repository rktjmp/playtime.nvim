(require-macros :playtime.prelude)
(prelude)

(local M {})

(fn input->cell [num row col]
  (let [cell {: row : col
              :value 0
              :candidates [true true true
                           true true true
                           true true true]}]
    (case num
      0 (table.set cell :value 0)
      n (doto cell
          (tset :value n)
          (tset :candidates [])))))

(fn M.decode [input]
  "Convert a standard `[0-9]{81}` sharable sudoku format into a table of
  rows, each rows element a cell (representing a column).

  Each cell is `{: row : col : value : candidates {1 true 2 false ...}}`,
  where value is the value given in the string, where 0 is an 'empty' cell."
  (assert (= 81 (length input)) "sudoku input must be 81 chars long")
  (let [input (string.gsub input "%D" "0")
        cells (fcollect [row 1 81 9]
                (let [line (string.sub input row (+ row 8))]
                  (fcollect [col 1 9]
                    (let [num (-> (string.sub line col col)
                                  (tonumber))]
                      (input->cell num (math.ceil (/ row 9)) col)))))]
    cells))

M
