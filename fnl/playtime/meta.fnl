(require-macros :playtime.prelude)
(prelude)

(local M {})

(fn M.find []
  (let [files (vim.api.nvim_get_runtime_file "lua/playtime/game/*/meta.lua"
                                             true)]
    (icollect [_ f (ipairs files)]
      (let [mod (string.match f "game.(.-).meta.lua$")]
        (case (pcall require (<s> "playtime.game.#{mod}.meta"))
          (true mod) mod
          (false err) nil)))))

M
