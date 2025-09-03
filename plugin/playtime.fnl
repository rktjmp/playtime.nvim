(var game-names nil)
(fn list-games []
  (when (not game-names)
    (let [{: all} (require :playtime.game.meta)
          games (accumulate [t [] _ game (ipairs (all))]
                 (case game
                   {:rulesets nil} (doto t (table.insert game.mod))
                   {: rulesets} (accumulate [t t _ {: cli} (ipairs rulesets)]
                                  (doto t (table.insert cli)))))]
      (set game-names games)
      (table.sort game-names)))
  game-names)

(λ load-diskette [game-name args]
  (let [Playtime (require :playtime)
        [?seed] args]
    (Playtime.play game-name ?seed)))

(fn run [{: fargs}]
  (case fargs
    ; Run playtime menu
    [nil] (load-diskette :playtime {})
    [game & args] (load-diskette game args)
    _ (error "Usage: `:Playtime <game-name> <game-seed> <game-options>` or `:Playtime` for menu")))

(fn complete [arg-lead _cmd-line _cursor-pos]
  (icollect [_ name (ipairs (list-games))]
    (if (= 1 (string.find name arg-lead 1 true))
      name)))

(vim.api.nvim_create_user_command
  :Playtime
  run
  {:nargs :*
   : complete
   :desc "Launch Playtime or Playtime <game> ..."})
