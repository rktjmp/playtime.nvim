(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local App (require :playtime.app))
(local Component (require :playtime.component))
(local GameReport (require :playtime.component.game-report))
(local {: State} (require :playtime.app.state-machine))

(local Logic (require :playtime.game.sweeper.logic))
(local Components (require :playtime.game.sweeper.components))

(local PlayingGame (State.new {:id :playing-game}))
(local GameEnded (State.new {:id :game-ended}))

(local M (App.scaffold-module {}))
(local m {})

(fn PlayingGame.on.enter [state {: app} event fx]
  (app.engine:set-idle-behaviour [:interval 1000])
  (app.components.face:emote :smile)
  (fx.interaction-lock.unlock)
  (fx.engine.render))

(fn PlayingGame.on.app.emote [state {: app} event fx]
  (app.components.face:emote event.emote)
  (fx.engine.render))

(fn PlayingGame.on.app.reveal [state {: app} {: x : y} fx]
  (case-try
    (Logic.Action.reveal-location app.game {: x : y}) next-game
    (do
      (set app.game next-game)
      (app:synchronise-components-to-game-state)
      (fx.engine.render)
      (if (Logic.Query.game-ended? next-game)
        (fx.state.transition GameEnded)))))

(fn PlayingGame.on.app.mark [state {: app} {: x : y} fx]
  (case-try
    (Logic.Action.mark-location app.game {: x : y}) next-game
    (do
      (set app.game next-game)
      (app:synchronise-components-to-game-state)
      (fx.engine.render)
      (if (Logic.Query.game-ended? next-game)
        (fx.state.transition GameEnded)))))

(fn GameEnded.on.enter [state {: app} event fx]
  (let [{: result : correct : incorrect : total} (Logic.Query.game-result app.game)
        other [(string.format "Swept: %d/%d" correct total)
               (string.format "Time: %s" (app.clock:elapsed-time))]
        _ (if (< 0 incorrect)
            (table.insert other 2 (string.format "Incorrect: %d" incorrect)))
        [face won?] (case result
                      :won [:bruh :won]
                      :lost [:sad :lost])
        report (GameReport.new {:view-size app.view.size
                                :play-again ["Play Again?" [:app :new-game app.game-config]]
                                :result result
                                :result-lines [[:won "Clean Sweep!"]
                                               [:lost "Oh no!"]]
                                :other-lines other})]
    (table.merge app.components {: report})
    (app.components.face:emote face)
    (fx.interaction-lock.general-lockout)
    (app.engine:set-idle-behaviour :sleep)
    (fx.engine.render)))

(fn M.build-components [app]
  (let [grid (Components.grid {:grid {:width app.game.size.width
                                      :height app.game.size.height}
                               :position {:row 5 :col 3}}
                              #(Logic.iter-cells app.game))
        remaining-mine-count (Components.remaining-mine-count app.view.size)
        timer (Components.timer app.view.size)
        face (Components.face app.view.size)]
    {: remaining-mine-count : timer : grid : face}))

(λ M.start [runtime-config game-config ?seed]
  (let [game-config (table.merge {:width 9 :height 9 :n-mines 10} game-config)
        app (App.new {:module M
                      :name :Sweeper
                      :app-id :sweeper
                      :view {:width (+ 7 (* 4 game-config.width))
                             :height (+ 7 (* 2 game-config.height))}
                      :menu [["Sweeper"
                              [["New Classic 8x8, 10" [:app :restart-app {:width 8 :height 8 :n-mines 10}]]
                               ["New Easy 9x9, 10" [:app :restart-app {:width 9 :height 9 :n-mines 10}]]
                               ["New Medium 16x16, 40" [:app :restart-app {:width 16 :height 16 :n-mines 40}]]
                               ["New Expert 30x16, 99" [:app :restart-app {:width 30 :height 16 :n-mines 99}]]]]]}
                     runtime-config)]
    (set app.game-config game-config)
    (app.view:open)
    (app:queue-event :app :new-game (table.merge game-config {:seed ?seed}))
    app))

(local default-unfocused M.on.window.unfocused)
(local default-focused M.on.window.focused)
(fn M.on.window.unfocused [app cofx event fx]
  ; (app.clock:pause)
  (app.engine:set-idle-behaviour :sleep)
  (default-unfocused app cofx event fx))

(fn M.on.window.focused [app cofx event fx]
  ; (app.clock:resume)
  (app.engine:set-idle-behaviour [:interval 1000])
  (default-focused app cofx event fx))

(fn M.on.app.restart-app [app cofx {: seed : width : height : n-mines} fx]
  (vim.schedule #(M.start app.runtime-config {: width : height : n-mines} seed))
  (app:quit))

(fn M.on.app.new-game [app cofx {: seed : width : height : n-mines} fx]
  (let [new-config {: width : height : n-mines}
        game (Logic.build new-config seed)]
    (set app.game-config new-config)
    (set app.game game)
    (app.clock:reset)
    (table.merge app.components (app:build-components))
    (set app.components.report nil)
    (set app.cell-id->component app.components.grid.lookup)
    (app:synchronise-components-to-game-state)
    (fx.state.reset PlayingGame)
    (fx.interaction-lock.general-lockout)
    (app:request-tick)
    (app:request-render)))

(fn M.on.app.restart-game [app cofx event fx]
  (M.on.app.new-game app cofx app.game-config fx))

(λ M.synchronise-components-to-game-state [app]
  (each [{: x : y} cell (Logic.iter-cells app.game)]
    (let [comp (. app.cell-id->component cell.id)]
      (comp:update-content-for-cell cell)))
  (app.components.remaining-mine-count:update-count app.game.remaining))

(λ M.tick [app dt]
  (app.components.timer:update-time (app.clock:elapsed-time))
  (when (not app.view.minimised?)
    (app:request-render)))

M
