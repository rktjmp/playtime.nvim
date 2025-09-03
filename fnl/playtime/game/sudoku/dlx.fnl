;; Dancing Links + Algorithm X solver
;;
;; Each cell must contain 1 number, that number exists once in each row, column
;; and house, so we have 4 constraints to consider.
;;
;; Each constraint is a column in our solver, each row is a potential number in
;; a cell.
;;
;; So we end up with this sort of giant table, where (row,col,number):
;;
;; option  | 1-1-filled | 1-2-filled | ... | row-has-1 | row-has-2 | ... | col-has-1 | ... | house-has-1 | ...
;; (1,1,1) | 1          | 0          | ... | 1         | 0         | ... | 1         | ... | 1           | ...
;; (1,1,2) | 1          | 0          | ... | 0         | 1         | ... | 0         | ... | 0           | ...
;; ...
;;
;; Pick a constraint, pick row that satisfies it, remove all confilcting rows,
;; repeat for all constaints.
;;
;; As above, (1,1,1) cannot be selected with (1,1,2) as they both cover the 1-1-filled column/constraint.
;;
;; I wrote this using FFI, assuming it would need the speed boost after how
;; abysmal the Hearts AI was in pure lua, but really there is very little heavy
;; work after you set up the datastructures. We never clone/copy anything, just
;; set and unset some pointers. Proabably doing `struct.field = index` *is*
;; faster than `table.field = table` but probably not *that* much faster that
;; it really warrants the higher complexity of the FFI impl, especially when we
;; dont use pointers (see below for reasoning).
;;
;; Honestly its fast enough that you dont even need to prune obvious candidate
;; conflicts between row/col/houses, etc. What an algo!
;;

(require-macros :playtime.prelude)
(prelude)

(local ffi (require :ffi))
(local Logger (require :playtime.logger))

(local M {})

;; We cant have typed pointers in our struct if we dont use cdef, and cdef
;; declarations are global, with an apparent struct limit?
;; So we use typeof with integer indexing which works ... fine. Not quite as
;; elegant to read. Maybe that's just being dumb but cdef feels kind of rude to
;; use in a shared environment.
(local dlx_node_t
  (ffi.typeof
    "struct {
       // Note: this structure is used for literal nodes and
       // constraint column headers. Since we're avoiding pointers
       // so we dont have to worry about casting we piggyback both
       // types in this strucure.
       // Headers will have (r,c,n) = (0,0,0), index == constraint_index
       // and do not use the *_candidate_for_constraint_index field.

       uint32_t index; // simplify linking by marking our own index
       uint32_t constraint_index; // index of constraint this node belongs to

       // header specific
       uint32_t constraint_size;

       // other constraints this (r,c,n) set satisfies
       uint32_t left_index;
       uint32_t right_index;
       // other candidates for this constraint
       uint32_t up_index;
       uint32_t down_index;
       // the actual (r,c,n), all values 1..9
       uint8_t row;
       uint8_t col;
       uint8_t number;
     }"))

(local dlx_matrix_t
  (ffi.typeof
    "struct {
       // We have a total of 3241 nodes.
       //
       // The very first node is a 'root' dummy node, used for
       // searching. It is never taken out of the 'header columns list'
       // and we know when search is finished when root.left/right = root.
       // Since we're not using cdef + struct pointers, we can't have 
       // a matrix.root member as it has no index (technically luajit would
       // allow nodes[-1] or nodes[len+1] to step outside of the correct memory
       // location but its naughty.).
       //
       // The next 324 are 'constraint column headers', as described:
       //
       // 1..81 'is-cell-1-81-filled?' (81)
       // 82..162 'row 1..9 has 1..9' (81)
       // 163..243 'col 1..9 has 1..9' (81)
       // 243..324 'house 1..9 has 1..9' (81)
       //
       // The remaining 2916 nodes are the actual constraint nodes:
       //
       // 9*9 cells = 81, each cell has 4 constraints
       // 81 * 4 = 324
       // 9 possible candidates per (constraint, cell)
       // 81 * 4 * 9 = 2916
       $ nodes[1 + 324 + 2916];
       uint32_t next_node_index;
     }" dlx_node_t))

(local CONSTRAINT_ROW_R_COL_C_FILLED 1)
(local CONSTRAINT_ROW_R_VALUE_V 2)
(local CONSTRAINT_COL_C_VALUE_V 3)
(local CONSTRAINT_HOUSE_H_VALUE_V 4)

(fn lookup-constraint-index [constraint-t row col candidate]
  ;; ZERO indexed
  (case constraint-t
    (where (= CONSTRAINT_ROW_R_COL_C_FILLED))
    (let [major-offset (* 81 0)
          minor-offset (+ (* 9 (- row 1)) (- col 1))]
      (+ 1 major-offset minor-offset))
    (where (= CONSTRAINT_ROW_R_VALUE_V))
    (let [major-offset (* 81 1)
          row-offset (* 9 (- row 1))
          value-offset (- candidate 1)
          minor-offset (+ row-offset value-offset)]
      (+ 1 major-offset minor-offset))
    (where (= CONSTRAINT_COL_C_VALUE_V))
    (let [major-offset (* 81 2)
          col-offset (* 9 (- col 1))
          value-offset (- candidate 1)
          minor-offset (+ col-offset value-offset)]
      (+ 1 major-offset minor-offset))
    (where (= CONSTRAINT_HOUSE_H_VALUE_V))
    (let [major-offset (* 81 3)
          house (if
                  (and (<= 1 row 3) (<= 1 col 3)) 1
                  (and (<= 1 row 3) (<= 4 col 6)) 2
                  (and (<= 1 row 3) (<= 7 col 9)) 3
                  (and (<= 4 row 6) (<= 1 col 3)) 4
                  (and (<= 4 row 6) (<= 4 col 6)) 5
                  (and (<= 4 row 6) (<= 7 col 9)) 6
                  (and (<= 7 row 9) (<= 1 col 3)) 7
                  (and (<= 7 row 9) (<= 4 col 6)) 8
                  (and (<= 7 row 9) (<= 7 col 9)) 9
                  true (error "bad house offset"))
          house-offset (* 9 (- house 1))
          value-offset (- candidate 1)
          minor-offset (+ house-offset value-offset)]
      (+ 1 major-offset minor-offset))))

(fn identify-constraint-index [constraint-index]
  (let [block (math.floor (/ constraint-index 81))
        off (% constraint-index 81)]
    (case block
      0 (let [row (+ (math.floor (/ off 9)) 1)
              col (+ (% off 9) 1)]
          ; [:CONSTRAINT_ROW_R_COL_C_FILLED row col 0]
          (string.format "ROW_%d_COL_%d_FILLED" row col))
      1 (let [row (+ (math.floor (/ off 9)) 1)
              candidate (+ (% off 9) 1)]
          [:CONSTRAINT_ROW_R_VALUE_V row 0 candidate]
          (string.format "ROW_%d_VALUE_%d" row candidate))
      2 (let [col (+ (math.floor (/ off 9)) 1)
              candidate (+ (% off 9) 1)]
          [:CONSTRAINT_COL_C_VALUE_V 0 col candidate]
          (string.format "COL_%d_VALUE_%d" col candidate))
      3 (let [house (+ (math.floor (/ off 9)) 1)
              candidate (+ (% off 9) 1)
              (row col) (case house
                          1 (values 1 1)
                          2 (values 1 4)
                          3 (values 1 7)
                          4 (values 4 1)
                          5 (values 4 4)
                          6 (values 4 7)
                          7 (values 7 1)
                          8 (values 7 4)
                          9 (values 7 7)
                          _ (error :bad-house))]
          [:CONSTRAINT_HOUSE_H_VALUE_V row col candidate]
          (string.format "HOUSE_%d_VALUE_%d" house candidate)))))

(fn header-node [matrix node] (. matrix.nodes node.constraint_index))
(fn up-node [matrix node] (. matrix.nodes node.up_index))
(fn left-node [matrix node] (. matrix.nodes node.left_index))
(fn right-node [matrix node] (. matrix.nodes node.right_index))
(fn down-node [matrix node] (. matrix.nodes node.down_index))

(fn set-up [node up] (set node.up_index up.index))
(fn set-down [node down] (set node.down_index down.index))
(fn set-left [node left] (set node.left_index left.index))
(fn set-right [node right] (set node.right_index right.index))

(fn build-matrix [cells]
  (let [matrix (ffi.new dlx_matrix_t)]
    ;; Set initial book keeping for the constraint headers.
    ;; This means setting their indexes and linking their left/right circulars
    ;; an up/down to themselves..
    ;; 1..324 because 0 is our dummy root
    (for [i 1 324]
      (let [constraint-header (. matrix.nodes i)]
        (set constraint-header.index i)
        (set constraint-header.constraint_index i)
        (set constraint-header.left_index (- i 1))
        (set constraint-header.right_index (+ i 1))
        (set constraint-header.up_index i)
        (set constraint-header.down_index i)))
    (set matrix.next_node_index 325)
    ;; link in dummy root
    (let [root (. matrix.nodes 0)
          first-header (. matrix.nodes 1)
          last-header (. matrix.nodes 324)]
      (set-left root last-header)
      (set-right root first-header)
      (set-left first-header root)
      (set-right last-header root))
    ;; For every cell - with row and col -, get its candidates, treating fixed
    ;; values as a single candidate, and create 4 nodes, one for each
    ;; constraint for that (r, c, n) set.
    ;;
    ;; Nodes are all allocated upfront, so we simply get the "next available
    ;; node" out of memory and update its attributes, then update  the
    ;; constraint column book keeping.
    (each [_ cell (ipairs cells)]
      (let [{: row : col} cell
            candidates (case cell
                         {:number 0 : candidates} candidates
                         {:number n} {n true})
            ;; convert {3 true} into [3] so we can shuffle
            candidates (icollect [number valid? (pairs candidates)]
                         (when valid?
                           number))
            ;; shuffle here to support generating puzzles too, has no effect on solve.
            _ (table.shuffle candidates)]
        (each [_ number (ipairs candidates)]
          (let [node-index-offset matrix.next_node_index
                ;; Build the 4 constraint nodes, generally not complicated,
                ;; just set some values.
                nodes (icollect [i constraint-t (ipairs [CONSTRAINT_ROW_R_COL_C_FILLED
                                                         CONSTRAINT_ROW_R_VALUE_V
                                                         CONSTRAINT_COL_C_VALUE_V
                                                         CONSTRAINT_HOUSE_H_VALUE_V])]
                        (let [constraint-index (lookup-constraint-index constraint-t row col number)
                              node-index (+ node-index-offset (- i 1))
                              node (. matrix.nodes node-index)]
                          (set node.index node-index)
                          (set node.constraint_index constraint-index)
                          (set node.row row)
                          (set node.col col)
                          (set node.number number)
                          node))]
            (set matrix.next_node_index (+ matrix.next_node_index 4))
            ;; link each given node into structures.
            (each [i node (ipairs nodes)]
              (do
                ;; Linking left / right between the new nodes is simple, they
                ;; all belong to the same circular chain.
                (let [next-node-i (case i 4 1 n (+ n 1))
                      prev-node-i (case i 1 4 n (- n 1))]
                  (set node.left_index (. nodes prev-node-i :index))
                  (set node.right_index (. nodes next-node-i :index)))
                ;; Linking up / down requires finding the header node for the constraint
                ;; inserting the new nodes into the up/down chain and
                ;; updating the constraint size.
                (let [constraint-header (. matrix.nodes node.constraint_index)]
                  (case constraint-header.constraint_size
                    ;; first time we're adding to this constraint, so we are the head and tail
                    0 (do
                        ;; The header is retained in the circular list, so
                        ;; from it, we are next, from us, it is next.
                        ;; <H> <-> <H> => <H> <-> <N> <-> <H>
                        (set constraint-header.down_index node.index)
                        (set constraint-header.up_index node.index)
                        (set node.up_index constraint-header.index)
                        (set node.down_index constraint-header.index)
                        ;; increment size
                        (set constraint-header.constraint_size 1))
                    ;; Otherwise, insert oursevles as the current tail.
                    ;; <H> <-> ... <-> <tail> <-> <H> => <H> <-> ... <-> <tail> <-> <N> <-> <H>
                    _ (let [tail-node (. matrix.nodes constraint-header.up_index)]
                        ;; point old tail to us
                        (set tail-node.down_index node.index)
                        ;; point us to old tail
                        (set node.up_index tail-node.index)
                        ;; point constraint tail at us
                        (set constraint-header.up_index node.index)
                        ;; point us at constraint-header
                        (set node.down_index constraint-header.index)
                        ;; increment size
                        (set constraint-header.constraint_size (+ constraint-header.constraint_size 1)))))))))))
    matrix))

(fn cover [matrix constraint-index]
  ;; select the constraint header
  ;; for every row in this header, remove the siblings in other columns and
  ;; adjust size book keeping.
  (let [constraint-header (. matrix.nodes constraint-index)]
    ;; unstitch constraint header from its siblings
    (let [left (left-node matrix constraint-header)
          right (right-node matrix constraint-header)]
      (set-right left right)
      (set-left right left))
    ;; for every candidate in this constraint, remove its siblings from their
    ;; constraints.
    (accumulate [node (down-node matrix constraint-header)
                 _ #true &until (= node constraint-header)]
      (do
        (accumulate [right (right-node matrix node)
                     _ #true &until (= right node)]
          (let [up (up-node matrix right)
                down (down-node matrix right)
                header (header-node matrix right)]
            (set-down up down)
            (set-up down up)
            (set header.constraint_size (- header.constraint_size 1))
            (right-node matrix right)))
        ;; next down in column
        (down-node matrix node)))))

(fn uncover [matrix constraint-index]
  (let [constraint-header (. matrix.nodes constraint-index)]
    (accumulate [node (up-node matrix constraint-header)
                 _ #true &until (= node constraint-header)]
      (do
        (accumulate [left (left-node matrix node)
                     _ #true &until (= left node)]
          (let [up (up-node matrix left)
                down (down-node matrix left)
                header (header-node matrix left)]
            (set-down up left)
            (set-up down left)
            (set header.constraint_size (+ header.constraint_size 1))
            (left-node matrix left)))
        (up-node matrix node)))
    (let [left (left-node matrix constraint-header)
          right (right-node matrix constraint-header)]
      (set-right left constraint-header)
      (set-left right constraint-header))))

(fn shortest-column [matrix]
  (let [root (. matrix.nodes 0)
        index (accumulate [(smallest count node) (values nil math.huge (right-node matrix root))
                           _ #true
                           &until (= node root)]
                (if (< node.constraint_size count)
                  (values node.index node.constraint_size (right-node matrix node))
                  (values smallest count (right-node matrix node))))]
    (case index
      nil nil
      index (. matrix.nodes index))))

(fn inc [num] (+ num 1))
(fn dec [num] (- num 1))

(fn do-search [matrix partial-solution on-solved difficulty]
  (let [root (. matrix.nodes 0)]
    (if (= root (right-node matrix root))
      (case (on-solved partial-solution difficulty)
        :stop (set partial-solution.stop? true))
      (let [column (shortest-column matrix)]
        (when (< 1 column.constraint_size)
          (table.insert difficulty.branching-factor column.constraint_size))
        ; (table.insert difficulty.branching-factor column.constraint_size)
        (cover matrix column.index)
        (accumulate [solution-node (down-node matrix column)
                     _ #true &until (= solution-node column)]
          (do
            (set difficulty.rows-seen (inc difficulty.rows-seen))
            (table.insert partial-solution solution-node)
            (accumulate [right (right-node matrix solution-node)
                         _ #true &until (= right solution-node)]
              (do
                (cover matrix right.constraint_index)
                (right-node matrix right)))
            (set difficulty.depth (inc difficulty.depth))
            (set difficulty.max-depth (math.max difficulty.max-depth difficulty.depth))
            (if (not partial-solution.stop?)
              (do-search matrix partial-solution on-solved difficulty))
            (set difficulty.depth (dec difficulty.depth))
            (accumulate [left (left-node matrix solution-node)
                         _ #true &until (= left solution-node)]
              (do
                (uncover matrix left.constraint_index)
                (left-node matrix left)))
            (table.remove partial-solution)
            (down-node matrix solution-node)))
        (uncover matrix column.index)))))

(fn search [matrix on-solved]
  (let [root-node (. matrix.nodes 0)
        sum-size (accumulate [(size node) (values 0 (right-node matrix root-node))
                              _ #true &until (= node root-node)]
                   (values (+ size node.constraint_size)
                           (right-node matrix node)))]
    (do-search matrix [] on-solved {:branching-factor []
                                    :depth 0 :max-depth 0
                                    :rows-seen 0
                                    :sum-size sum-size})))

(fn matrix-solution->solution [solution]
  (icollect [_ {: row : col : number} (ipairs solution)]
    {: row : col : number}))

(λ M.find-solutions [cells limit]
  (let [matrix (build-matrix cells)
        solutions []
        _ (search matrix (fn [solution]
                           (table.insert solutions (matrix-solution->solution solution))
                           (if (<= limit (length solutions)) :stop)))]
    (icollect [_ solution (ipairs solutions)]
      (icollect [_ {: row : col : number} (ipairs solution)] {: row : col : number}))))

(λ M.solve [cells]
  (let [matrix (build-matrix cells)
        solutions []
        _ (search matrix (fn [solution]
                           (table.insert solutions (matrix-solution->solution solution))
                           (case (length solutions)
                             1 nil
                             2 :stop)))]
    (case solutions
      [solution nil] solution
      _ (values nil "More than one solution to puzzle"))))

M
