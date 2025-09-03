(require-macros :playtime.prelude)
(prelude)

(local M {})
(local m {})
(local uv (or vim.loop vim.uv))

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(λ build-node [information-set unexpanded-actions]
  {:information-set information-set
   :unexpanded-actions (table.shuffle unexpanded-actions)
   :actions {}
   :visits 0})

(λ M.new [{: game-module : strategy-module & rest}]
  (let [defaults {:iterations 1000
                  :time-limit-ms 2500
                  :explore-constant (math.sqrt 2)}
        {: iterations : explore-constant : time-limit-ms} (table.merge defaults rest)]
    {: game-module : strategy-module
     : explore-constant
     : iterations : time-limit-ms}))

(λ M.select-action [config root-state observer-player]
  (let [{: game-module} config]
    (case (game-module.available-actions root-state)
      [one-action nil] one-action
      _ (let [top-level-actions (m.map-space root-state observer-player config)
              ; _ (Logger.info top-level-actions)
              [[best-action _stats]] top-level-actions]
          best-action))))

(λ m.map-space [root-state observer-player {: iterations : game-module &as config}]
  (let [time-start (uv.hrtime)
        (tree time-expired?) (faccumulate [(tree time-expired?) (values {} false)
                                           i 1 iterations
                                           &until time-expired?]
                               (summark :iteration
                                        (let [path []
                                              determinised-state (game-module.determinise root-state observer-player)
                                              (selected-path selected-state) (summark :select
                                                                                      (m.select tree determinised-state path observer-player config))
                                              (simulation-path simulation-state) (case selected-path
                                                                                   ;; short circuit expansion if the state is terminal
                                                                                   [:terminal _rest]
                                                                                   (values selected-path selected-state)
                                                                                   [[information-set :expand] _rest]
                                                                                   (summark :expand (m.expand tree selected-state selected-path observer-player config))
                                                                                   _ (error (%s "unexpected selected path for expand #{selected-path}")))
                                              utility (benchmark #(if (< 9 $2) (Logger.info [:simulate-was-slow $1]))
                                                                 (summark :simulate (m.simulate simulation-state observer-player config)))
                                              tree (summark :backpropagate (m.backpropagate tree utility simulation-path))]
                                          (values tree (< config.time-limit-ms (/ (- (uv.hrtime) time-start) 1_000_000))))))]
    (if time-expired?
      (Logger.info "map-space-halted-by-time-budget"))
    (let [root-information-set (game-module.information-set root-state observer-player)]
      (case (. tree root-information-set)
        {: actions} (let [list (icollect [key val (pairs actions)] [key val])]
                      (table.sort list (fn [[_key {:visits a}] [_key {:visits b}]] (> a b))))
        nil (error (Error "SOISMCTS did not generate information-set node for root-state!"))))))

(λ m.select [tree input-state path observer-player {: game-module &as config}]
  (let []
    (case (values (= observer-player (game-module.current-player input-state))
                  (game-module.terminal? input-state))
      ;; Observers turn on a non-terminal state, try to select further or stop
      ;; for expansion.
      (true false)
      (let [information-set (game-module.information-set input-state observer-player)]
        (case (. tree information-set)
          ;; No node for information-set, we need to create it (via expand)
          nil
          (values [[information-set :expand] path] input-state)

          ;; Node exists but has unexpanded actions, so target it for expansion
          ;; TODO: progressive-widening may be applied here
          {:unexpanded-actions [any-action] &as node}
          (values [[information-set :expand] path] input-state)

          ;; Node has all actions expanded, so we can instead select the best
          ;; UCT action and recurse down the tree.
          {:unexpanded-actions [nil] &as node}
          (let [log-parent (math.log (math.max 1 node.visits))
                {:explore-constant c} config
                best-actions (accumulate [(best-actions best-score) (values [] (* -1 math.huge))
                                          action-name action-stats (pairs node.actions)]
                               (let [uct-score (case action-stats
                                                 {:visits 0} math.huge
                                                 {:visits v :utility u} (let [exploit (/ u v)
                                                                              explore (* c (math.sqrt (/ log-parent v)))]
                                                                          (+ exploit explore)))]
                                 (if
                                   (> uct-score best-score) (values [action-name] uct-score)
                                   (= uct-score best-score) (values (table.insert best-actions action-name) best-score)
                                   (< uct-score best-score) (values best-actions best-score))))
                [action] (table.shuffle best-actions)
                path [[information-set action] path]
                new-state (game-module.next-state input-state action)]
            (m.select tree new-state path observer-player config))
          node (error (%s "found node for #{information-set} but it was weird: #{node}"))))

      ;; Observers turn but terminal input-state, nothing to do.
      (true true)
      (values [:terminal path] input-state)

      ;; Not observers turn, is terminal, nothing to do.
      (false true)
      (values [:terminal path] input-state)

      ;; Not observers turn in non terminal state, pick random action
      (false false)
      (let [[action] (table.shuffle (game-module.available-actions input-state))
            next-state (game-module.next-state input-state action)]
        (m.select tree next-state path observer-player config)))))

(fn m.expand [tree state path observer-player {: game-module : strategy-module &as config}]
  (let [[[information-set why-expand] rest-of-path] path
        _ (assert (or (= why-expand :create) (= why-expand :expand))
                  "called expand without [information-set why] as path head")
        ;; find or create target node
        node (case (. tree information-set)
               existing existing
               nil (let [new (build-node information-set (game-module.available-actions state))]
                     (tset tree information-set new)
                     new))
        ;; pluck an action to expand, update book keeping.
        ;; dont drop into __fennel-rest by using: [action & remaining-actions] node.unexpanded-actions
        action (table.remove node.unexpanded-actions)
        node (doto node (tset :actions action {:visits 0 :utility 0}))
        ;; replace [information-set nil] with [information-set action] in path.
        path [[information-set action] rest-of-path]
        ;; apply action and re-determinise.
        next-state (game-module.next-state state action)
        ;; RIS-MCTS would redeterminise here I think, but uh, we wont for now.
        ; next-state (game-module.determinise next-state observer-player)
        ]
    (values path next-state)))

(fn m.simulate [state observer-player {: game-module : strategy-module &as config}]
  (summark :rollout (let [end-state (game-module.rollout state)]
    (game-module.utility end-state observer-player))))

(λ m.backpropagate [tree utility path]
  (fn backpropagate-into-node [tree [node-key action-key] utility]
    (let [node (. tree node-key)
          action (. node.actions action-key)]
      (set node.visits (+ 1 node.visits))
      (set action.visits (+ 1 action.visits))
      (set action.utility (+ utility action.utility))))
  (fn recurse [tree utility path]
    (case path
      [nil] tree
      [:terminal rest] (recurse tree utility rest)
      ;; Note: path is [[is-key action] [[is-key-2 action] [...]]] so its
      ;; correct to not use [key & rest] here.
      [key rest] (do
                   (backpropagate-into-node tree key utility)
                   (recurse tree utility rest))))
  (recurse tree utility path))


M
