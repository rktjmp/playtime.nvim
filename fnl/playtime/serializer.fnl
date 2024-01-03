(require-macros :playtime.prelude)
(prelude)

(local Error (require :playtime.error))
(local Id (require :playtime.common.id))
(local Logger (require :playtime.logger))

(local M {})

;;; Mostly wraps vim.json, but with an affordance for generating new 'id'
;;; values when needed.

(fn M.encode [data]
  (vim.json.encode data))

(fn M.decode [data]
  (fn re-id [data]
    (case (type data)
      :table (collect [key val (pairs data)]
               (let [key (case (tonumber key)
                           num num
                           nil key)]
                 (if (= :id key)
                   (values key (Id.new))
                   (values key (re-id val)))))
      _ data))
  (-> (vim.json.decode data {:luanil {:array false :object false}})
      (re-id)))

(λ M.write [path data]
  (case-try
    (vim.fs.dirname path) dir
    (vim.fn.mkdir dir :p) 1
    (io.open path :w) fd
    (fd:write (M.encode data)) ok
    (fd:close) ok
    true))

(λ M.read [path]
  (case-try
    (io.open path) fd
    (fd:read :*a) json
    (fd:close) ok
    (M.decode json)))

M
