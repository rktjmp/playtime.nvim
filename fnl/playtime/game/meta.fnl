(require-macros :playtime.prelude)
(prelude)

(local M {})

(fn M.all []
  "Find and load all game meta description files"
  (let [files (vim.api.nvim_get_runtime_file "lua/playtime/game/*/meta.lua"
                                             true)]
    (icollect [_ f (ipairs files)]
      (let [mod (string.match f "game.(.-).meta.lua$")]
        (case (pcall require (<s> "playtime.game.#{mod}.meta"))
          (true mod) mod
          (false _err) nil)))))

M
