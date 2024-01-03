;; Fix lua to be not lua. Sometimes.

(local *raw-string* string)
(local *raw-math* math)
(local *raw-type* type)
(local *raw-table* table)
(local *raw-unpack* unpack)

;;
;; Maths
;;

(local math (setmetatable {:clamp (fn [v min max]
                                    (-> (*raw-math*.max v min)
                                        (*raw-math*.min max)))
                           :odd? (fn [n] (= 1 (% n 2)))
                           :even? (fn [n] (= 0 (% n 2)))}
                          {:__index *raw-math*}))

;;
;; Type
;;

(local type (setmetatable {:table? (fn [v] (= :table (*raw-type* v)))
                           :string? (fn [v] (= :string (*raw-type* v)))
                           :number? (fn [v] (= :number (*raw-type* v)))
                           :coroutine? (fn [v] (= :thread (*raw-type* v)))
                           :userdata? (fn [v] (= :userdata (*raw-type* v)))
                           :function? (fn [v] (= :function (*raw-type* v)))}
                          {:__call (fn [_t v] (*raw-type* v))}))

;;
;; Table
;;

;; regular insert, but returns t instead of nil
(fn *insert [t ...] (doto t (*raw-table*.insert ...)))
;; table.set but returns t for chaining
(fn *set [t k v] (doto t (tset k v)))

(fn split-at [t index]
  "Split seq at index, -index also supported"
  (let [p (if (<= 0 index) index (+ (length t) (+ 1 index)))]
    (accumulate [(a b) (values [] []) i v (ipairs t)]
      (if (< i p)
        (values (*insert a v) b)
        (values a (*insert b v))))))

(fn split-by [t f]
  "Split t by f, where f returns true|false, given (f v i)"
  (accumulate [(a b) (values [] []) i v (ipairs t)]
    (if (f v i)
      (values (*insert a v) b)
      (values a (*insert b v)))))

(λ merge [table-into table-from ?resolver]
  (let [resolve (or ?resolver (fn [key val-a val-b] val-b))]
    (collect [key value (pairs table-from) &into table-into]
      (case (values (. table-into key) value)
        (same same) (values key value)
        (nil b) (values key b)
        (a b) (values key (resolve key a b))))))

(fn shuffle [t]
  "shuffle table in place"
  (for [i (length t) 2 -1]
    (let [j (math.random i)
          a (. t j)
          b (. t i)]
      (tset t i a)
      (tset t j b)))
  t)

(fn join [t ...]
  (assert (type.table? t) "table.join first argument must be a table")
  (case (select :# ...)
    0 t
    1 (icollect [_ v (ipairs (select 1 ...)) &into t] v)
    n (join (join t (pick-values 1 (select 1 ...))) (select 2 ...))))

(fn stable-insertion-sort [t ?cmp]
  (local cmp (or ?cmp (fn [a b] (< a b))))
  (for [i 2 (length t)]
    (let [val (. t i)]
      (faccumulate [stop? false
                    j i 1 -1
                    &until stop?]
        (if (and (< 1 j) (cmp val (. t (- j 1))))
          (do
            (tset t j (. t (- j 1)))
            false)
          (do
            (tset t j val)
            true)))))
  t)

(fn get-in [t path]
  (assert (type.table? t) (string.format "target argument must be table, got %s" (type t)))
  (assert (type.table? path) "path argument must be table")
  (case path
    [key nil] (. t key)
    [key & rest] (get-in (. t key) rest)))

(fn update-in [t path f]
  (assert (type.table? t) (string.format "target argument must be table, got %s" (type t)))
  (assert (type.table? path) "path argument must be table")
  (assert (type.function? f) "f argument must be function")
  (case path
    [key nil] (doto t (tset key (f (. t key))))
    [key & rest] (do
                   (update-in (. t key) rest f)
                   t)))

(fn set-in [t path val]
  (update-in t path #val))

(fn insert-in [t path val]
  (assert (type.table? t) (string.format "target argument must be table, got %s" (type t)))
  (assert (type.table? path) "path argument must be table")
  (case path
    [key nil] (doto t
                (table.insert key val))
    [key & rest] (do
                   (insert-in (. t key) rest val)
                   t)))

(local table (setmetatable {:empty? (fn [t] (= nil (next t)))
                            :first (fn [t] (. t 1))
                            :last (fn [t] (. t (length t)))
                            :keys (fn [t] (icollect [k _ (pairs t)] k))
                            :values (fn [t] (icollect [_ v (pairs t)] v))
                            :invert (fn [t] (collect [k v (pairs t)] (values v k)))
                            : update-in
                            : set-in
                            : insert-in
                            : get-in
                            :split split-at
                            : split-at
                            : merge
                            ;; concat is already taken ...
                            : join
                            ;; back port pack unpack
                            :pack (fn [...] (doto [...] (tset :n (select :# ...))))
                            :unpack (fn [t] (unpack t 1 t.n))
                            :insert *insert
                            :set *set
                            :sort stable-insertion-sort ;(fn [t ?comp] (doto t (*raw-table*.sort ?comp)))
                            :group-by (fn [t f]
                                        (accumulate [g {} k v (pairs t)]
                                          (let [key (f v k)]
                                            (case (. g key)
                                              nil (*set g key [v])
                                              sub-t (*set g key (*insert sub-t v))))))
                            : shuffle}
                           {:__index *raw-table*}))

; (local seq (setmetatable {: split-at
;                           : split-by
;                           : pack
;                           : unpack
;                           : insert
;                           : first
;                           : last
;                           : shuffle}
;                          {:__index (fn [_m k]
;                                      (or (. table-extensions k)
;                                          (. *raw-table* k)))}))

(local *string* (setmetatable {:fmt *raw-string*.format}
                              {:__index *raw-string*}))


;;
;; Misc functions
;;

(fn clone [data]
  "Clone `data`, recursively clones all elements of a table except for not
  metatable elements. Attach custom behaviour via `mt.__clone`"
  (case (type data)
    :table (let [mt (getmetatable data)]
             (case mt
               {:__clone custom} (-> (custom data)
                                     (setmetatable mt))
               _ (-> (collect [key val (pairs data)] (values key (clone val)))
                     (setmetatable mt))))
    _ data))

(fn eq-any? [x ys]
  (accumulate [ok? false _ y (ipairs ys) &until ok?]
    (= x y)))

(fn eq-all? [x ys]
  (accumulate [ok? true _ y (ipairs ys) &until (not ok?)]
    (and ok? (= x y))))

{: math
 :string *string*
 : type
 : table
 : clone
 : eq-any?
 : eq-all?}
