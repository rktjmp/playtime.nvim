(require-macros :playtime.prelude)
(prelude)

(local M {})

(λ M.setup [?config]
  "Setup playtime"
  (let [Config (require :playtime.config)]
    (Config.set-user-config (or ?config {}))))

(fn fetch-games-metadata []
  "Fetch game meta so we can work out module of given `play <game>` name."
  (let [Meta (require :playtime.game.meta)]
    (accumulate [t {} _ meta (ipairs (Meta.all))]
      (case meta
        {: rulesets} (collect [_ r (ipairs rulesets) &into t]
                       (values r.cli
                               {:mod meta.mod :game-name r.cli :config r.config}))
        _ (table.set t meta.mod {:mod meta.mod :game-name meta.mod :config {}})))))

(λ M.play [game-name ?seed ?game-config ?app-config]
  "Play game with seed"
  (let [Config (require :playtime.config)
        game-meta (case (. (fetch-games-metadata) game-name)
                    known-meta known-meta
                    ;; allow fallback to launching "unlisted" games or the playtime gui
                    nil {:mod game-name :game-name game-name :config {}})
        used-config (or ?app-config (Config.get-user-config))]
    (case (Config.config->runtime-config used-config)
      runtime-config (let [{: mod :config default-game-config} game-meta
                           modname (.. :playtime.game. mod :.app)
                           game-config (table.merge (clone default-game-config) (or ?game-config {}))]
                       (case (pcall require modname)
                         (true mod) (mod.start runtime-config game-config ?seed)
                         (false err) (error err)))
      (nil errors) (vim.notify (.. "Playtime: some values passed to setup were invalid, "
                                   "please run `:checkhealth playtime`\n"
                                   (vim.inspect errors))
                               vim.log.levels.WARN))))

M
