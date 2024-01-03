(require-macros :playtime.prelude)
(prelude)

(local M {})
(local uv (or vim.uv vim.loop))

(fn check-config []
  (vim.health.report_start "Playtime Configuration")
  (let [Config (require :playtime.config)]
    (case (Config.health)
      (true) (vim.health.report_ok "Config is ok")
      (false e) (each [_ msg (ipairs e)]
                  (vim.health.report_error msg)))))

(fn check-disk []
  (vim.health.report_start "Playtime Data")
  ;; TODO: make this configurable, as well as the log path
  (let [dir (-> (string.format "%s/playtime" (vim.fn.stdpath :data))
                (vim.fs.normalize))
        paths (vim.fn.globpath dir "**" true true true)
        count (length paths)
        size (accumulate [size 0 _ p (ipairs paths)]
               (+ size (or (?. (uv.fs_stat p) :size)) 0))
        size (math.floor (/ size 1024))]
    (vim.health.report_info (<s> "Data-dir: #{dir}"))
    (vim.health.report_info (<s> "#{count} files, #{size}kb"))))

(fn M.check []
  (check-config)
  (check-disk))

M
