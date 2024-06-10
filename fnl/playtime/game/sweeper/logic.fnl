(require-macros :playtime.prelude)
(prelude)

(local Error (require :playtime.error))
(local Logger (require :playtime.logger))
(local Id (require :playtime.common.id))

(local M {:Action {}
          :Plan {}
          :Query {}})

(fn M.location->index [{:size {: width : height}} {: x : y}]
    (+ (* (- y 1) width) x))

(fn location-content [state location]
  (let [index (M.location->index state location)]
    (. state :grid index)))

(λ M.iter-cells [state]
  (let [{:size {: width : height}} state]
    (fn iter []
      (for [y 1 height]
        (for [x 1 width]
          (let [loc {: x : y}
                i (M.location->index state loc)]
            (coroutine.yield {: x : y : i} (location-content state loc))))))
    (coroutine.wrap iter)))

(fn north-of [state {: x : y}]
  (let [y (- y 1)]
    (if (<= 1 y) {: x : y})))

(fn south-of [{:size {: height}} {: x : y}]
  (let [y (+ y 1)]
    (if (<= y height) {: x : y})))

(fn east-of [state {: x : y}]
  (let [x (- x 1)]
    (if (<= 1 x) {: x : y})))

(fn west-of [{:size {: width}} {: x : y}]
  (let [x (+ x 1)]
    (if (<= x width) {: x : y})))

(fn north-east-of [state location]
  (-?>> (north-of state location)
        (east-of state)))

(fn north-west-of [state location]
  (-?>> (north-of state location)
        (west-of state)))

(fn south-east-of [state location]
  (-?>> (south-of state location)
        (east-of state)))

(fn south-west-of [state location]
  (-?>> (south-of state location)
        (west-of state)))

(fn new-game-state [size n-mines]
  (let [{: width : height} size
        grid (icollect [_ _ (M.iter-cells {: size :grid []})]
               {:id (Id.new)
                :mine? false
                :mark nil
                :count 0
                :revealed? false})]
    {: grid
     :size {: width : height}
     : n-mines
     :remaining n-mines
     :saving-throw? true
     :lost? false
     :won? false}))

(λ M.build [config ?seed]
  (assert (match? config {: width : height : n-mines})
          "Sweeper config must match {: width : height : n-mines}")
  (math.randomseed (or ?seed (os.time)))
  (let [{: width : height : n-mines} config
        state (new-game-state {: width : height} n-mines)]
    state))

(fn set-mines! [state not-at-locations]
  (let [{:size {: width : height}} state
        allowed-at-location? (fn [{: x : y}]
                               (not (accumulate [t false _ loc (ipairs not-at-locations) &until t]
                                      (case loc
                                        (where {:x (= x) :y (= y)}) true
                                        _ false))))
        positions (icollect [location _ (M.iter-cells state)]
                    (if (allowed-at-location? location)
                      location))
        random-indexes (table.shuffle (icollect [i _ (ipairs positions)] i))
        inc-count (fn [loc]
                    (if (not (nil? loc))
                      (let [i (M.location->index state loc)
                            cell (. state.grid i)]
                        (set cell.count (+ cell.count 1)))))
        mines-at (fcollect [i 1 state.n-mines]
                   (let [i (. random-indexes i)
                         center (. positions i)
                         cell (location-content state center)]
                     (tset cell :mine? true)
                     (inc-count (north-of state center))
                     (inc-count (north-east-of state center))
                     (inc-count (east-of state center))
                     (inc-count (south-east-of state center))
                     (inc-count (south-of state center))
                     (inc-count (south-west-of state center))
                     (inc-count (west-of state center))
                     (inc-count (north-west-of state center))))]
    state))

(fn maybe-update-won [state]
  (let [won? (accumulate [won? true _ cell (M.iter-cells state) &until (not won?)]
               (case cell
                 {:mine? true :mark :flag} true
                 {:revealed? true} true
                 _ false))]
    (set state.won? (and (not state.lost?) won?))
    state))

(λ M.Action.reveal-location [state location]
  (let [next-state (clone state)
        ;; Wait until the first reveal to place mines, as the first click never loses.
        next-state (if next-state.saving-throw?
                     (let [fns [north-west-of north-of north-east-of
                                west-of east-of
                                south-west-of south-of south-east-of]
                           safe-locations (icollect [_ f (ipairs fns) &into [location]]
                                            (f state location))]
                       ;; tset instead of set to avoid fennel bug
                       (tset next-state :saving-throw? false)
                       (set-mines! next-state safe-locations))
                     next-state)
        cell (location-content next-state location)]
    (case cell
      {:revealed? true}
      (values nil "location already revealed")
      {:mark :flag}
      (values nil "Cant revealed a flagged location")
      {:mine? true}
      (do
        ;; ya lost son.
        (set next-state.lost? true)
        ;; reveal all miles
        (each [_ cell (M.iter-cells next-state)]
          (set cell.revealed? (or cell.revealed? cell.mine?))))
      {:mine? false}
      (do
        ;; You may revealed "maybe" marked cells, unset the flag so
        ;; the following code works.
        (set cell.mark nil)
        (accumulate [queue [location] _ l (ipairs queue)]
          (let [visit-cell (location-content next-state l)]
            (case visit-cell
              ;; Flood-reveal cells, where we have not already revealed it,
              ;; and have not flagged it in either state, 
              ;; the initial cell has been unflagged if needed
              {:revealed? false :mark nil &as visit-cell}
              (do
                (set visit-cell.revealed? true)
                (case visit-cell
                  {:count 0} (doto queue
                               (table.insert (north-of next-state l))
                               (table.insert (north-east-of next-state l))
                               (table.insert (east-of next-state l))
                               (table.insert (south-east-of next-state l))
                               (table.insert (south-of next-state l))
                               (table.insert (south-west-of next-state l))
                               (table.insert (west-of next-state l))
                               (table.insert (north-west-of next-state l)))
                  {:count n} queue))
              _ queue)))))
    (maybe-update-won next-state)
    next-state))

(λ M.Action.mark-location [state location]
  (let [next-state (clone state)
        cell (location-content next-state location)]
    (case cell
      {:revealed? false :mark nil} (do
                                     (set next-state.remaining (- next-state.remaining 1))
                                     (set cell.mark :flag))
      {:revealed? false :mark :flag} (do
                                       (set next-state.remaining (+ next-state.remaining 1))
                                       (set cell.mark :maybe))
      _ (set cell.mark nil))
    (maybe-update-won next-state)
    next-state))

(λ M.Query.game-ended? [state]
  (or state.lost? state.won?))

(λ M.Query.game-result [state]
  (if state.lost? :lost
    state.won? :won
    :unknown))

M
