(require-macros :playtime.prelude)
(prelude)

(local M {})
(local uv (or vim.uv vim.loop))
(local {: report_start : report_info : report_ok : report_error}
  (case vim.health
    ;; 0.10.0+
    {: ok : info : error : start} {:report_start start
                                   :report_info info
                                   :report_error error
                                   :report_ok ok}
    ;; 0.9.0...
    other other))

(fn check-config []
  (report_start "Playtime Configuration")
  (let [Config (require :playtime.config)]
    (case (Config.health)
      (true) (report_ok "Config is ok")
      (false e) (each [_ msg (ipairs e)]
                  (report_error msg)))))

(fn check-disk []
  (report_start "Playtime Data")
  ;; TODO: make this configurable, as well as the log path
  (let [dir (-> (string.format "%s/playtime" (vim.fn.stdpath :data))
                (vim.fs.normalize))
        paths (vim.fn.globpath dir "**" true true true)
        count (length paths)
        size (accumulate [size 0 _ p (ipairs paths)]
               (+ size (or (?. (uv.fs_stat p) :size)) 0))
        size (math.floor (/ size 1024))]
    (report_info (<s> "Data-dir: #{dir}"))
    (report_info (<s> "#{count} files, #{size}kb"))))

(fn M.check []
  (check-config)
  (check-disk))

M
