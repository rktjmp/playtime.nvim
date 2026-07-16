(require-macros :playtime.prelude)
(prelude)

(local M {})

(local config-schema
  {:fps [#(and (type.number? $1) (<= 1 $1)) "must be positive integer"]
   :window-border [#(type.string? $1) "must be valid window border name"]
   :notify [#(type.function? $1) "must be a function"]
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
   :__game-the-emissary-icon [#(type.string? $1) "must be string"]
   :__beta-game-set-font-glyph-width [#(eq-any? $1 [:wide nil])
                                      "must be `wide` or `nil`"]})

(local defaults
  {:fps 30
   :notify #(vim.notify $...) ;; wrap so clone doesn't clone weird notify-callable-table setups
   :window-border nil ;; do not bind value so users can alter at runtime via opt.winborder
   :window-position :center
   :minimise-position :se
   :unfocused :minimise
   :__beta-game-set-font-glyph-width nil
   :__game-the-emissary-icon nil})

(var user-config {})
(var validation-errors nil)

(fn lua-name-to-fennel-name [name]
  ;; convert my_option to my-option, note __beta_option becomes __beta-option.
  (string.gsub name "([^_])_" "%1-"))

(λ validate-against-schema [a-config a-schema]
  (if (type.table? a-config)
    (let [e (icollect [k v (pairs a-config)]
              (case (. a-schema (lua-name-to-fennel-name k))
                [f msg] (if (not (f v))
                          (<s> "config key `#{k}` did not pass validation, #{msg}"))
                _ (<s> "config key `#{k}` not recognised")))]
      (values (table.empty? e) e))
    (values false ["config must be a table"])))

(λ M.set-user-config [new-config]
  (case (validate-against-schema new-config config-schema)
    true (do
           (set user-config new-config)
           (set validation-errors nil)
           true)
    (false errors) (do
                     (set user-config new-config)
                     (set validation-errors errors)
                     (values false errors))))

(λ M.get-user-config []
  user-config)

(λ M.config->runtime-config [a-config]
  (let [merged-config (table.merge (clone defaults) a-config)]
    (case (validate-against-schema merged-config config-schema)
      true {:app {:engine {:fps merged-config.fps}
                  :notify merged-config.notify
                  :window {:border merged-config.window-border
                           :maximise-position merged-config.window-position
                           :minimise-position merged-config.minimise-position}}
            :game {:set {:font-glyph-width merged-config.__beta-game-set-font-glyph-width}
                   :the-emissary {:glyph merged-config.__game-the-emissary-icon}}}
      (false errors) (values nil errors))))

(fn M.health []
  (case validation-errors
    nil true
    _ (values false validation-errors)))

M
