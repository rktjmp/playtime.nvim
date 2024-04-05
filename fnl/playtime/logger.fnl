(require-macros :playtime.prelude)
(prelude)

(var enabled? false)
(local M {})

(fn view [x]
  (case (pcall require :fennel)
    (true {: view}) (view x)
    (false _) (vim.inspect x)))

(local fd (io.open (vim.fs.normalize (.. (vim.fn.stdpath :log) "/playtime.log")) :a))

(fn M.info [msg ?details]
  (fn get-detail [name]
    (case (. (or ?details {}) name)
      (where t (type.table? t)) (case (getmetatable t)
                                  (where mt mt.__tostring) (mt.__tostring t)
                                  _ (view t))
      v (tostring v)
      nil (.. "! missing detail value: " name " !")))
  (when enabled?
    (let [msg (if (type.string? msg)
                (string.gsub msg "#{(.-)}" get-detail)
                (view msg))]
      (fd:write (.. (os.date) " -- " msg "\n"))
      (fd:flush)))
  (values nil))

(fn M.enable [] (set enabled? true))
(fn M.disable [] (set enabled? false))

M
