(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Animate (require :playtime.animate))
(local CommonComponents (require :playtime.common.components))
(local Component (require :playtime.component))
(local App (require :playtime.app))
(local Window (require :playtime.app.window))

(local {: api} vim)
(local uv (or vim.loop vim.uv))

(local Logic (require :playtime.game.sweeper.logic))
(local UI (require :playtime.game.sweeper.ui))
(local M (setmetatable {} {:__index App}))

(local AppState {})
(set AppState.Default (App.State.build :Default {:delegate {:app App.State.DefaultAppState}}))
(set AppState.PickingCell (App.State.build :PickingCell {:delegate {:app AppState.Default}}))
(set AppState.MarkingCell (App.State.build :MarkingCell {:delegate {:app AppState.Default}}))
(set AppState.GameEnded (App.State.build :GameEnded {:delegate {:app AppState.Default}}))

;; TODO: Chording
;; TODO: If you flag most mines, any single cell surrounded by revealed cells is automatically flagged and you win
;; TODO: stats: win counting

(fn AppState.Default.activated [app]
  (app.components.smile:update :smile))

(fn AppState.GameEnded.activated [app]
  (set app.ended-at (os.time))
  (let [other [(string.fmt "Time: %ds" (- app.ended-at app.started-at))]
        result (Logic.Query.game-result app.game)
        face (case result
               :won :bruh
               :lost :sad)]
    (app.components.game-report:update result other)
    (app.components.smile:update face)))

(fn AppState.PickingCell.activated [app]
  (app.components.smile:update :scare))

(fn AppState.Default.OnEvent.input.<LeftMouse> [app [location] pos]
  (case location
    [:face]
    (app:queue-event :app :restart-game)

    [:grid]
    (app:push-state AppState.PickingCell {:picking location})

    [:menu idx nil &as menu-item]
    (app:push-state App.State.DefaultInMenuState {: menu-item})))

(fn AppState.Default.OnEvent.input.<RightMouse> [app [location] pos]
  (case location
    [:grid]
    (app:push-state AppState.MarkingCell {:picking location})))

(fn AppState.GameEnded.OnEvent.input.<LeftMouse> [app [location]]
  (case location
    [:face] (app:queue-event :app :restart-game)
    [:menu idx nil &as menu-item]
    (app:push-state App.State.DefaultInMenuState {: menu-item})))

(fn AppState.PickingCell.OnEvent.input.<LeftDrag> [app [location] pos]
  (case location
    [:grid] (set app.state.context.picking location)
    _ (set app.state.context.picking nil)))

(fn AppState.PickingCell.OnEvent.input.<LeftRelease> [app [location] pos]
  (case location
    [:face] (app:queue-event :app :restart-game)
    [:grid {: x : y}]
    (case-try
      (Logic.Action.reveal-location app.game {: x : y}) next-game
      (do
        (app:update-game next-game [:reveal-location {: x : y}])
        (if (Logic.Query.game-ended? app.game)
          (app:switch-state AppState.GameEnded)
          (app:switch-state AppState.Default))))
    _ (app:switch-state AppState.Default)))

(fn AppState.MarkingCell.OnEvent.input.<RightDrag> [app [location] pos]
  (case location
    [:grid] (set app.state.context.picking location)
    _ (set app.state.context.picking nil)))

(fn AppState.MarkingCell.OnEvent.input.<RightRelease> [app [location] pos]
  (case location
    [:grid {: x : y}]
    (case-try
      (Logic.Action.mark-location app.game {: x : y}) next-game
      (do
        (app:update-game next-game [:mark-location {: x : y}])
        (if (Logic.Query.game-ended? app.game)
          (app:switch-state AppState.GameEnded)
          (app:switch-state AppState.Default))))
    _ (app:switch-state AppState.Default)))

(fn AppState.Default.OnEvent.app.restart-game [app]
  (AppState.Default.OnEvent.app.new-game app [app.game-config.width
                                              app.game-config.height
                                              app.game-config.n-mines]))

(fn AppState.Default.OnEvent.app.new-game [app [width height n-mines]]
  (app:queue-event :app :quit)
  (vim.schedule #(M.start app.app-config {: width : height : n-mines} nil)))

(fn dim-hover [app]
  (each [loc cell (Logic.iter-cells app.game)]
    (let [comp (. app.cell-id->cell-component cell.id)]
      (case (values loc app.state.context.picking)
        ({: x : y} [:grid {: x : y}])
        (let [pressed? (case (values cell app.state.module)
                         (where ({:mark nil} (= AppState.PickingCell))) true
                         (where ({: mark} (= AppState.MarkingCell))) true
                         _ false)]
          (comp:update cell {: pressed?}))
        _ (comp:update cell)))))

(fn AppState.PickingCell.tick [app]
  (dim-hover app))

(fn AppState.MarkingCell.tick [app]
  (dim-hover app))

(fn AppState.Default.tick [app]
  (each [loc cell (Logic.iter-cells app.game)]
    (let [comp (. app.cell-id->cell-component cell.id)]
      (comp:update cell))))

(fn M.setup-new-game [app game-config ?seed]
  (app:new-game Logic.build game-config ?seed)
  (app:build-components)
  (app:switch-state AppState.Default)
  app)

(fn M.build-components [app]
  (fn build-grid-component [game offset]
    (let [{:size {: width : height}} game
          {: row : col} offset
          cell-height 3
          cell-width 5
          t (collect [{: x : y} cell (Logic.iter-cells game)]
              (let [tag {: x : y}
                    f (case (values x y)
                        (where (1 1)) UI.nw-cell
                        (where ((= width) 1)) UI.ne-cell
                        (where (1 (= height))) UI.sw-cell
                        (where ((= width) (= height))) UI.se-cell
                        (where (1 _)) UI.w-cell
                        (where ((= width) _)) UI.e-cell
                        (where (_ 1)) UI.n-cell
                        (where (_ (= height))) UI.s-cell
                        _ UI.mid-cell)]
                (values cell.id
                        (f cell tag
                           {:row (+ row (* (- cell-height 1) (- y 1)))
                            :col (+ col (* (- cell-width 1) (- x 1)))
                            :z (app:z-index-for-layer :grid)}))))
          ;; Keep the cell-component order the same as the logical cells for sanity.
          components (icollect [_ {: id} (Logic.iter-cells game)] (. t id))]
      (values components t)))

  (let [(grid cell-id->cell-component) (build-grid-component app.game {:row 5 :col 3})
        menubar (CommonComponents.menubar [["Sweeper" [:file]
                                            [["" nil]
                                             ["New Classic 8x8, 10" [:new-game [8 8 10]]]
                                             ["New Easy 9x9, 10" [:new-game [9 9 10]]]
                                             ["New Medium 16x16, 40" [:new-game [16 16 40]]]
                                             ["New Expert 30x16, 99" [:new-game [30 16 99]]]
                                             ["" nil]
                                             ["Undo" [:undo]]
                                             ["" nil]
                                             ["Quit" [:quit]]
                                             ["" nil]]]]
                                          {:width app.view.width
                                           :z (app:z-index-for-layer :menubar)})
        remaining (-> (Component.build
                        (fn [self count]
                          (let [s (string.format "%03d" count)]
                            (self:set-content [[[s "@playtime.color.red"]]])
                            (self:set-size {:width (length s) :height 1}))))
                      (Component.set-position {:row 3 :col 4 :z 10})
                      (: :update app.game.n-mines))
        timer (-> (Component.build
                    (fn [self count]
                      (let [s (string.format "%03d" count)]
                        (self:set-content [[[s "@playtime.color.red"]]])
                        (self:set-size {:width (length s) :height 1}))))
                  (Component.set-position {:row 3 :col (- app.view.width 8) :z 10})
                  (: :update 0))
        smile (-> (Component.build
                    (fn [self what]
                      (let [lines (case what
                                    :smile [" ⠶ ⠶ "
                                            "⠠⣀⣀⣀⠄"]
                                    :scare [" ⠶ ⠶ "
                                            "  ⣤  "]
                                    :sad [" ⠶ ⠶ "
                                          "⢀⠤⠤⠤⡀"]
                                    :bruh [" ⠶⠒⠶ "
                                           "⠠⣤⣤⣤⠄"])
                            content (icollect [_ l (ipairs lines)]
                                      [[l "@playtime.color.yellow"]])]
                        (self:set-content content))))
                  (Component.set-size {:width 5 :height 2})
                  (Component.set-tag [:face])
                  (Component.set-position {:row 2 :col (- (math.floor (/ app.view.width 2)) 3) :z 100})
                  (: :update :smile))
        game-report (CommonComponents.game-report app.view.width
                                                app.view.height
                                                (app:z-index-for-layer :report)
                                                [[:won :Won] [:lost :Lost]])]
    (each [{: i} cell (Logic.iter-cells app.game)]
      (let [comp (. grid i)]
        (comp:update cell)))
    (set app.cell-id->cell-component cell-id->cell-component)
    (table.merge app.components {: smile : remaining : timer
                                 : grid : menubar : game-report})
    app))

(fn M.start [app-config game-config ?seed]
  (let [app (-> (App.build "Sweeper" :sweeper app-config game-config ?seed)
                (setmetatable {:__index M}))
        view-width (+ 8 (* 4 game-config.width))
        view-height (+ 8 (* 2 game-config.height))
        view (Window.open :sweeper
                          (App.build-default-window-dispatch-options app)
                          {:width view-width
                           :height view-height
                           :window-position app-config.window-position
                           :minimise-position app-config.minimise-position})
        _ (table.merge app.z-layers {:grid 25})]
    (set app.view view)
    (app:setup-new-game app.game-config ?seed)
    (app:render)))

(fn M.render [app]
  (app.view:render [app.components.grid
                    [app.components.smile app.components.remaining app.components.timer]
                    [app.components.game-report
                     app.components.menubar
                     app.components.cheating]])
  app)

(fn M.tick [app]
  (let [now (uv.now)]
    (app:process-next-event)
    (app.components.remaining:update app.game.remaining)
    (app.components.timer:update (- (or app.ended-at (os.time)) app.started-at))
    (case (. app.state.module.tick)
      f (f app)
      _ (each [loc cell (Logic.iter-cells app.game)]
          (let [comp (. app.cell-id->cell-component cell.id)]
            (comp:update cell))))
    (app:request-render)))

M
