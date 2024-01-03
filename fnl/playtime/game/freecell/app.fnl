(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local PatienceApp (require :playtime.app.patience))
(local PatienceState (require :playtime.app.patience.state))
(local Logic (require :playtime.game.freecell.logic))
(local {: same-location-field-column?} (require :playtime.common.card.utils))

(local M (setmetatable {} {:__index PatienceApp}))
(local AppState (PatienceState.build Logic))

(fn M.build-event-animation [app events after ?opts]
  ;; Moves are always from 1 field+column to another, but may contain multiple
  ;; cards if we are moving a stack, because freecell only allows moving 1 card
  ;; at a time.
  ;; Moves between tableau columns are broken down into individual events, which
  ;; may touch non-tableau fields, but we know that the number of cards moved
  ;; *from* a column will be equal to the number of cards moved *to* a column.
  ;; Using this knowlege, we can skip any intermediate steps.
  (fn simple-resort? [events]
    (accumulate [yes? true i move (ipairs events) &until (not yes?)]
      (case move
        [:move [:tableau a n] [:tableau b n]] true
        _ false)))
  (let [events (case events
                 ;; Deal animations come from [:draw ...] and are played as given
                 [[_ [:draw 1 52]]] events
                 ;; "free re-order" are sent as a a->b column swap.
                 (where events (simple-resort? events)) events
                 ;; All other card moves are a sequence of single card moves.
                 ;; The first from is always the source column, and last to is always the
                 ;; destination. We can use this information to pluck out all cards initial
                 ;; positions and final positions.
                 _ (let [[_move first-from _first-to] (table.first events)
                         [_move _last-from last-to] (table.last events)
                         ;; If we're moving some cards from the middle of a
                         ;; column we can just count all cards that move
                         ;; "from" the "from" column.
                         ;; If we're moving all cards from a column, we need to
                         ;; count until we hit the first [:tableau col 1] because
                         ;; moves with substacks may end up reusing the original
                         ;; "from" column when rebuilding onto the final target,
                         ;; so we need to take care not to include those in the
                         ;; total-cards count.
                         froms (accumulate [(t stop?) (values [] false)
                                            _ [_move from _] (ipairs events)
                                            &until stop?]
                                 (case from
                                   (where [:tableau n 1] (same-location-field-column? first-from from))
                                   (values (table.insert t from) true)
                                   (where _ (same-location-field-column? first-from from))
                                   (values (table.insert t from) false)
                                   _
                                   (values t false)))
                         tos (faccumulate [t [] i (length events) 1 -1 &until (= (length t) (length froms))]
                               (let [[_move _from to] (. events i)]
                                 (if (same-location-field-column? last-to to)
                                   (table.insert t to)
                                   t)))
                         ff-moves (fcollect [i 1 (length froms)]
                                    (let [from (. froms i)
                                          [f c n] from
                                          card (. app.game f c n)]
                                      [:move (. froms i) (. tos i)]))]
                     (fcollect [i (length ff-moves) 1 -1]
                       (. ff-moves i))))]
    (PatienceApp.build-event-animation app events after ?opts)))

(fn M.location->position [app location]
  (let [config {:card {:margin {:row 0 :col 2}
                       :width app.card-style.width :height app.card-style.height}}
        card-col-step (+ config.card.width config.card.margin.col)
        cell {:row 2 :col 4}
        foundation {:row cell.row :col (+ cell.col (* 4 card-col-step))}
        tableau {:row (+ cell.row config.card.height config.card.margin.row) :col cell.col}]
    (case location
      [:cell n card] {:row cell.row
                      :col (+ cell.col (* (- n 1) card-col-step))
                      :z card}
      [:foundation n card] {:row foundation.row
                            :col (+ foundation.col (* (- n 1) card-col-step))
                            :z card}
      [:tableau col card] {:row (+ tableau.row (* (math.max 0 (- card 1)) 2))
                           :col (+ tableau.col (* (- col 1) card-col-step))
                           :z card}
      [:draw 1 card] {:row (+ tableau.row (* (math.max 0 (- 9 1)) 2))
                      :col (+ tableau.col (* 4 card-col-step) -4)
                      :z card}
      _ (error (<s> "Unable to convert location to position, unknown location #{location}")))))

(fn AppState.Default.OnEvent.app.maybe-auto-move [app]
  (case-try
    (Logic.Plan.next-move-to-foundation app.game) [from to]
    (Logic.Action.move app.game from to) (next-game events)
    (let [after #(do
                   (app:switch-state AppState.Default)
                   (app:queue-event :app :maybe-auto-move)
                   (app:update-game next-game [:move from to]))
          timeline (app:build-event-animation events after)]
      (app:switch-state AppState.Animating timeline))))

(λ M.start [app-config game-config ?seed]
  (let [game-config (table.merge {:rules :freecell} game-config)
        (name filetype colors) (case game-config.rules
                                 :bakers (values "Baker's Game" :bakers 4)
                                 :freecell (values "FreeCell" :freecell 2)
                                 r (error (<s> "Unknown ruleset #{r}")))]
    (PatienceApp.start
      {: name
       : filetype
       :view {:width 78 :height 42}
       :card-style {: colors}
       :empty-fields [[:cell 4] [:foundation 4] [:tableau 8]]}
      {:AppImpl M
       :LogicImpl Logic
       :StateImpl AppState}
      app-config game-config ?seed)))

M
