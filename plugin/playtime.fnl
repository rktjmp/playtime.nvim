(var game-names nil)
(fn list-games []
  (when (not game-names)
    (let [{: find} (require :playtime.meta)
          games (accumulate [t [] _ game (ipairs (find))]
                 (case game
                   {:rulesets nil} (doto t (table.insert game.mod))
                   {: rulesets} (accumulate [t t _ {: cli : config} (ipairs rulesets)]
                                  (doto t (table.insert cli)))))]
      (set game-names games)
      (table.sort game-names)))
  game-names)

(λ load-diskette [game-name args]
  (let [Playtime (require :playtime)
        [?seed] args]
    (Playtime.play game-name ?seed)))

(fn eq-any? [x ys]
  (accumulate [ok? false _ y (ipairs ys) &until ok?]
    (= x y)))

(fn run [{: fargs}]
  (case fargs
    ; Run playtime menu
    [nil] (load-diskette :playtime {})
    [game & args] (load-diskette game args)
    ; (where [game & args] (eq-any? game (list-games))) (load-diskette game args)
    ; [game] (error (string.format "Unknown game `%s`" game))
    _ (error "Usage: `:Playtime <game-name> <game-seed> <game-options>` or `:Playtime` for menu")))

(fn complete [arg-lead cmd-line cursor-pos]
  (icollect [_ name (ipairs (list-games))]
    (if (= 1 (string.find name arg-lead 1 true))
      name)))

(vim.api.nvim_create_user_command :Playtime run {:nargs :* : complete})
