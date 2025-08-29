(require-macros :playtime.prelude)
(prelude)

(local M {})

(local schema
  {:fps [#(and (type.number? $1) (<= 1 $1)) "must be positive integer"]
   :window-border [#(type.string? $1) "must be valid window border name"]
   :window-position [#(or (eq-any? $1 [:center :nw :ne])
                          (match? $1 {: row : col})
                          (type.function? $1))
                     "must be `center`, `nw`, `ne` or a table or function returning`{row=row, col=col}`"]
   :minimise-position [#(or (eq-any? $1 [:ne :nw :se :sw])
                            (match? $1 {: row : col})
                            (type.function? $1))
                       "must be `ne`, `nw`, `se`, `sw` or a table or function returning`{row=row, col=col}`"]
   :unfocused [#(eq-any? $1 [:minimise])
               "must be `minimise`"]
   :__beta-game-set-font-glyph-width [#(eq-any? $1 [:wide nil])
                                      "must be `wide` or `nil`"]})

; (local defaults
;   {:fps 30
;    :window {:position :center
;             :on-unfocus {:minimise :se}}
;    :game {:set {:font-glyph-width 2}}})

(local defaults
  {:fps 30
   :window-border nil ;; do not bind value so users can alter at runtime via opt.winborder
   :window-position :center
   :minimise-position :se
   :unfocused :minimise
   :__beta-game-set-font-glyph-width nil})

(var user-config {})
(var errors nil)

(fn lua-name-to-fennel-name [name]
  ;; convert my_option to my-option, note __beta_option becomes __beta-option.
  (string.gsub name "([^_])_" "%1-"))

(fn M.valid? [config]
  (if (type.table? config)
    (let [e (icollect [k v (pairs config)]
              (case (. schema (lua-name-to-fennel-name k))
                [f msg] (if (not (f v))
                          (<s> "config key `#{k}` did not pass validation, #{msg}"))
                _ (<s> "config key `#{k}` not recognised")))]
      (values (table.empty? e) e))
    (values false ["config must be a table"])))

(fn M.set [config]
  (set errors nil)
  (case-try
    (M.valid? config) true
    (let [c (collect [k v (pairs config)]
              (values (lua-name-to-fennel-name k) v))]
      (set user-config (clone c))
      true)
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
