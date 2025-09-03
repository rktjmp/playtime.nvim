(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local App (require :playtime.app))
(local {: State} (require :playtime.app.state-machine))

(local Logic (require :playtime.game.sudoku.logic))
(local Components (require :playtime.game.sudoku.components))
(local Component (require :playtime.component))

(local PlayingGame (State.new {:id :playing-game}))

(local SelectMode (State.new {:id :select-mode}))
(local PencilMode (State.new {:id :pencil-mode}))
(local PenMode (State.new {:id :pen-mode}))

(local GameEnded (State.new {:id :game-ended}))

(local M (App.scaffold-module {}))
(local m {})

;; UI aspects
;;
;; When a number is completely filled, turn it grey
;; Dragging in pen mode converts to pencil
;; If you start dragging pencil, if 1 is in the cell, then you toggle 1 OFF in
;; any dragged cells, vis versa.
;; When you select a number, highlight all instances of it
;; When you select a cell, highlight house row col.
;; Allow selection mode vs number mode?
;; tnick picker input? (radial menu)

(λ SelectMode.on.enter [])
(λ SelectMode.on.app.interact-cell [state {: app} event fx]
  (case app.__picked-number
    number (let [{: row : col} event
                 _ (Logger.info [event ])
                 cell (Logic.Query.cell-at app.game {: row : col})
                 next-game  (Logic.Action.update-cell app.game {: row : col} number)]
             (set app.game next-game)
             (app:synchronise-components-to-game-state)
             (fx.engine.render))))

(λ PencilMode.on.enter [state cofx event fx])
(λ PencilMode.on.app.update-cell [state cofx event fx])

(λ PenMode.on.enter [state cofx event fx])
(λ PencilMode.on.app.update-cell [state cofx event fx]
  ;; set cell pen value
  ;; recalculate candidates for cells
  ;; auto-fill any single candidate cells in house if ...? if candidates == manual notes if manual notes set?
  
  )

(λ M.on.app.pick-number [app cofx {: number} fx]
  ;; mark number as being highlighted
  ;; set current state number
  (set app.__picked-number number)
  (app:synchronise-components-to-game-state)
  (fx.engine.render)

  )

(λ M.start [runtime-config game-config ?seed]
  (let [app (App.new {:module M
                      :name :Sudoku
                      :app-id :sudoku
                      :view {:width 80 :height 40}
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

(fn M.on.app.new-game [app cofx {: seed : width : height : n-mines} fx]
  (let [game (Logic.build {} "seed")]
    ; (set app.game-config new-config)
    (set app.game game)
    (Logger.info [app.game.seed :next-game])
    (app.clock:reset)
    (table.merge app.components (app:build-components))
    (Logger.info app.components.cells)
    (set app.cell-lookup (collect [_ cell (ipairs app.components.cells.children)]
                           (values cell.index cell)))
    (app:synchronise-components-to-game-state)
    (set app.components.report nil)
    (fx.state.reset SelectMode)
    ; (set app.cell-id->component app.components.grid.lookup)
    ; (app:synchronise-components-to-game-state)
    ; (fx.state.reset PlayingGame)
    ; (fx.interaction-lock.general-lockout)
    (app:request-tick)
    (app:request-render)))


(fn M.build-components [app]
  (let [grid (Components.grid)
        cells (Component.new {:children (faccumulate [cells [] row 1 9]
                                          (fcollect [col 1 9 &into cells]
                                            (Components.cell {: row : col})))})
        number-buttons (Component.new {:children (fcollect [n 1 9]
                                                   (let [pos (app:location->position [:button :number n])]
                                                     (Components.pick-number n pos)))})
        ]

    {: grid : cells : number-buttons}))

(fn M.synchronise-components-to-game-state [app]
  (each [location cell (Logic.iter-cells app.game)]
    (let [comp (. app.cell-lookup cell.index)]
      (comp:update cell)
      (when app.__picked-number
        (comp:highlight-number app.__picked-number)))))

(fn M.location->position [app location]
  (case location
    [:button :number n] (let [col 74
                              row (+ 2 (- n 1))]
                          {: col : row :z 100})
    
    _ (error (%s "bad location->position location #{location}"))))

M
