(require-macros :playtime.prelude)
(prelude)

;; TODO: turn msg into <s> usage instead, probably just (error (<s> ...))
(fn Error [msg ?details]
  (fn get-detail [name]
    (case (. (or ?details {}) name)
      (where t (type.table? t)) (case (getmetatable t)
                                  {:__tostring f} (f t)
                                  _ (vim.inspect t))
      v (tostring v)
      nil (.. "! missing detail value: " name " !")))

  (let [msg (string.gsub msg "#{(.-)}" get-detail)
        e {: msg :details ?details}
        mt {:__tostring #msg}]
    (setmetatable e mt)))
