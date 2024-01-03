(fn match? [x pat]
  "Does `x` match pattern `pat`"
  `(case ,x (where ,pat) true _# false))

(fn nil? [x] `(= nil ,x))

(fn assert-match [pattern value ?msg]
  `(case ,value
     ,pattern ,value
     _# (error ,(or ?msg (.. (view value) " must match " (view pattern))))))

(fn <s> [str ?bindings]
  "string interpolation, `xyz #{abc}` where abc is in-scope, or given via bindings"
  ;; The fennel.parser() is not availiable in the macro environment, so we rely
  ;; on single symbol names.
  (let [other (or ?bindings {})
        lookup (collect [name (string.gmatch str "#{(.-)}")]
                 (if (. other name)
                   (values name (. other name))
                   (in-scope? name)
                   (values name (sym name))
                   (assert-compile false (.. "symbol `" name "` not in scope"))))]
    `(let [data# ,lookup
           resolve# (fn [name#]
                      (case (. data# name#)
                        (where t# (= :table (type t#))) (case (getmetatable t#)
                                                          {:__tostring f#} (f# t#)
                                                          _# (vim.inspect t#))
                        v# (tostring v#)))]
       (string.gsub ,str "#{(.-)}" resolve#))))

(local modname ...)
(fn prelude []
  `(local {:math ,(sym :math)
           :string ,(sym :string)
           :type ,(sym :type)
           :table ,(sym :table)
           :eq-all? ,(sym :eq-all?)
           :eq-any? ,(sym :eq-any?)
           :clone ,(sym :clone)} (require (.. ,modname))))

(fn benchmark [out ...]
  `(let [uv# (or vim.uv vim.loop)
         a# (uv#.hrtime)
         pack# (fn [...] {:v [...] :n (select :# ...)})
         v# (pack# (do ,...))
         b# (uv#.hrtime)]
     (,out (.. (math.floor (/ (- b# a#) 1_000_000)) "ms"))
     (unpack v#.v 1 v#.n)))

(fn benchmark [...]
  `(do ,...))

{: match?
 : assert-match
 : nil?
 : <s>
 : benchmark
 : prelude}
