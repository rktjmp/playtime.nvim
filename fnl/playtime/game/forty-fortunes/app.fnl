(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local PatienceApp (require :playtime.app.patience))
(local PatienceState (require :playtime.app.patience.state))

(local Logic (require :playtime.game.forty-fortunes.logic))
(local AppState (PatienceState.build Logic))
(local M (setmetatable {} {:__index PatienceApp}))

(fn M.location->position [app location]
  (let [config {:card {:margin {:row 0 :col 2}
                       :width app.card-style.width :height app.card-style.height}}
        card-col-step (+ config.card.width config.card.margin.col)
        cell {:row 2 :col 4}
        foundation {:row cell.row :col (+ 2 cell.col (* 7 card-col-step))}
        tableau {:row (+ cell.row config.card.height config.card.margin.row) :col cell.col}]
    (case location
      [:cell n card] {:row cell.row
                      :col (+ tableau.col (* (- 7 1) card-col-step))
                      :z card}
      [:foundation n card] {:row (+ 0 foundation.row)
                            :col (+ tableau.col
                                    card-col-step
                                    (* (- n 1) card-col-step)
                                    (case n
                                      (where n (< n 5)) 0
                                      (where n (<= 5 n)) (* 3 card-col-step)))
                            :z card}
      [:tableau col card] {:row (+ tableau.row (* (math.max 0 (- card 1)) 2))
                           :col (+ tableau.col (* (- col 1) card-col-step))
                           :z card}
      [:draw 1 card] {:row tableau.row
                      :col (+ tableau.col (* (- 7 1) card-col-step))
                      :z card}
      _ (error (Error "Unable to convert location to position, unknown location #{location}"
                      {: location})))))

(fn AppState.Default.OnEvent.app.maybe-auto-move [app]
  (case-try
    (Logic.Plan.next-move-to-foundation app.game) [from to]
    (Logic.Action.move app.game from to) (next-game events)
    (let [after #(do
                   (app:switch-state AppState.Default)
                   (app:queue-event :app :maybe-auto-move)
                   (app:update-game next-game [:move from to]))
          timeline (app:build-event-animation events after {:stagger-ms 200})]
      (app:switch-state AppState.Animating timeline))))

(fn AppState.DraggingCards.OnEvent.input.<LeftRelease> [app [_ location] pos]
  (if (Logic.Query.droppable? app.game location)
    (case-try
      (values app.state.context.lifted-from location) (from to)
      (Logic.Action.move app.game from to) (next-game events)
      (let [after #(do
                     (app:switch-state AppState.Default)
                     (app:queue-event :app :maybe-auto-move)
                     (app:update-game next-game [:move from to]))
            timeline (app:build-event-animation events after {:stagger-ms 120})]
        ;; force the first move in the timeline to finish immediately as it is
        ;; the card we are dragging so its already at its destination.
        (: (. timeline 1) :tick (. timeline 1 :finish-at))
        (table.remove timeline 1)
        (app:switch-state AppState.Animating timeline))
      (catch
        (nil err) (do
                    (app:notify err)
                    (app:switch-state AppState.Default))
        _ (app:switch-state AppState.Default)))
    (app:switch-state AppState.Default)))

(fn M.start [app-config game-config ?seed]
  (PatienceApp.start
    {:name "Forty Fortunes"
     :filetype :forty-fortunes
     :view {:width 123 :height 42}
     :empty-fields [[:cell 1] [:tableau 13] [:foundation 8]]
     :card-style {:colors 4}}
    {:AppImpl M
     :LogicImpl Logic
     :StateImpl AppState}
    app-config game-config ?seed))

M
