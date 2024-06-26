(require-macros :playtime.prelude)
(prelude)

(local M {})

(var setup-config {})
(fn M.setup [?config]
  ;; Since playtime is a toy and options might change rapidly, dont break
  ;; peoples configs if they give invalid options until they actually try to
  ;; play something.
  (set setup-config (or ?config {}))
  true)

(fn M.play [game-name ?seed ?game-config ?app-config]
  (let [Config (require :playtime.config)
        Meta (require :playtime.meta)
        flat-meta (accumulate [t [] _ meta (ipairs (Meta.find))]
                    (case meta
                      {: rulesets} (icollect [_ r (ipairs rulesets) &into t]
                                     {:mod meta.mod :game-name r.cli :config r.config})
                      _ (table.insert t {:mod meta.mod :game-name meta.mod :config {}})))
        game-meta (accumulate [found nil _ meta (ipairs flat-meta) &until found]
                    (if (= game-name meta.game-name) meta))
        ;; allow fallback to launching "unlisted" games or the playtime gui
        game-meta (or game-meta {:mod game-name : game-name :config {}})]
    (case (Config.set setup-config)
      true (case-try
             game-meta {: mod :config default-config}
             (.. :playtime.game. mod :.app) modname
             (or ?app-config (table.merge {} (Config.get))) app-config
             (table.merge (clone default-config) (or ?game-config {})) game-config
             (case (pcall require modname)
               (true mod) (mod.start app-config game-config ?seed)
               ;; TODO? During dev its nice to have this throw the actual error, but 
               ;; to users its a bit ugly.
               (false err) (error err))
             (catch
               _ (error (<s> "Could not start game: #{game-name}"))))
      (false e) (vim.notify (.. "Playtime: some values passed to setup were invalid, "
                                "please run `:checkhealth playtime`\n")
                            vim.log.levels.WARN))))

M
