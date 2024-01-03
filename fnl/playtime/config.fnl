(require-macros :playtime.prelude)
(prelude)

(local M {})

(local schema
  {:fps [#(and (type.number? $1) (<= 1 $1)) "must be positive integer"]
   :window-position [#(or (eq-any? $1 [:center :nw :ne])
                          (match? $1 {: row : col})
                          (type.function? $1))
                     "must be `center`, `nw`, `ne` or a table or function returning`{row=row, col=col}`"]
   :minimise-position [#(or (eq-any? $1 [:ne :nw :se :sw])
                            (match? $1 {: row : col})
                            (type.function? $1))
                       "must be `ne`, `nw`, `se`, `sw` or a table or function returning`{row=row, col=col}`"]
   :unfocused [#(eq-any? $1 [:minimise])
               "must be `minimise`"]})

(local defaults
  {:fps 30
   :window-position :center
   :minimise-position :se
   :unfocused :minimise})

(var user-config {})
(var errors nil)

(fn M.valid? [config]
  (if (type.table? config)
    (let [e (icollect [k v (pairs config)]
              (case (. schema k)
                [f msg] (if (not (f v))
                          (<s> "config key `#{k}` did not pass validation, #{msg}"))
                _ (<s> "config key `#{k}` not recognised")))]
      (values (table.empty? e) e))
    (values false ["config must be a table"])))

(fn M.set [config]
  (set errors nil)
  (case-try
    (M.valid? config) true
    (set user-config (clone config))
    (catch
      (false errs) (do
                     (set errors errs)
                     (values false errors)))))

(fn M.get []
  (table.merge (clone defaults) user-config))

(fn M.health []
  (case errors
    nil true
    _ (values false errors)))

M
