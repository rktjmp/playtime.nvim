(require-macros :playtime.prelude)
(prelude)

(local M {})
(local m {})
(local uv (or vim.loop vim.uv))

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))


(λ M.new [{: game-module : strategy-module & rest}]
  (let [defaults {:time-limit 2500 :world-limit 20 :rollout-limit 1000}
        {: time-limit : world-limit : rollout-limit} (table.merge defaults rest)]
    {: game-module : strategy-module
     : time-limit : world-limit : rollout-limit}))

(λ M.select-action [config root-state observer-player]
  (let [{: game-module} config]
    (case (game-module.available-actions root-state)
      [false one-action nil] one-action
      _ (let [top-level-actions (m.map-space root-state observer-player config)
              [[best-action _stats]] top-level-actions]
          best-action))))

(fn m.map-space [root-state observer-player {: game-module &as config}]
  (let [legal-actions (game-module.available-actions root-state)]
    nil))

M
