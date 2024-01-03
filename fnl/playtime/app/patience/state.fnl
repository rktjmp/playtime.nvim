(require-macros :playtime.prelude)
(prelude)

(local Error (require :playtime.error))
(local Logger (require :playtime.logger))
(local State (require :playtime.app.state))
(local uv (or vim.loop vim.uv))
(local Serializer (require :playtime.serializer))

(local M {})

; (set AppState.TelekenesisPickingCard
;      (State.build :TelekenesisPickingCard {:delegate {:app AppState.Default}}))
; (set AppState.TelekenesisPickingDestination
;      (State.build :TelekenesisPickingDestination {:delegate {:app AppState.Default}}))

; (fn AppState.TelekenesisPickingCard.activated [app]
;   (app.components.cheating:set-visible true))

; (fn AppState.TelekenesisPickingDestination.deactivated [app]
;   (app.components.cheating:set-visible false))

; (fn AppState.TelekenesisPickingCard.OnEvent.input.<LeftMouse> [app [location] pos]
;   (case location
;     ;; picked a card
;     (where (or [:tableau] [:cell] [:foundation]))
;     (app:switch-state AppState.TelekenesisPickingDestination {:from location})

;     ;; deactivate
;     _ (app:switch-state AppState.Default)))

; (fn AppState.TelekenesisPickingDestination.OnEvent.input.<LeftMouse> [app [location] pos]
;   (case location
;     ;; picked a card
;     (where (or [:tableau] [:cell] [:foundation]))
;     (let [[f-field f-col f-card-n] app.state.context.from
;           [t-field t-col t-card-n] location
;           next-game (clone app.game)
;           (from-top bottom) (table.split (. next-game f-field f-col) f-card-n)
;           ([card] bottom) (table.split bottom 2)
;           _ (icollect [_ c (ipairs bottom) &into from-top] c)
;           _ (tset next-game f-field f-col from-top)
;           (to-top bottom) (table.split (. next-game t-field t-col) (+ t-card-n 1))
;           _ (table.insert to-top card)
;           _ (icollect [_ c (ipairs bottom) &into to-top] c)
;           _ (tset next-game t-field t-col to-top)]
;       (app:update-game next-game)
;       (app:switch-state AppState.Default))

;     ;; deactivate
;     _ (app:switch-state AppState.Default)))

(λ M.build [LogicImpl]
  (assert-match {:Action {: move}
                 :Query {: liftable? : droppable?
                         : game-ended? : game-result}} LogicImpl)

  (local AppState {})

  (set AppState.Default (State.build :Default {:delegate {:app State.DefaultAppState}}))
  (set AppState.DraggingCards (State.build :DraggingCards {:delegate {:app AppState.Default}}))
  (set AppState.LiftingCards (State.build :LiftingCards {:delegate {:app AppState.Default}}))
  (set AppState.Animating (clone State.DefaultAnimatingState))
  (set AppState.GameEnded (State.build :GameEnded {:delegate {:app AppState.Default}}))

  (fn AppState.Default.OnEvent.app.replay [app {: replay :verify ?verify}]
    (case replay
      [nil] app ;; TODO: verify game against verify
      [action & rest] (case action
                        [nil] (app:queue-event :app :replay {:replay rest :verify ?verify})
                        action (case-try
                                 action [f-name & args]
                                 (. LogicImpl.Action f-name) f
                                 (f app.game (table.unpack args)) (next-game moves)
                                 (let [after #(do
                                                (app:switch-state AppState.Default)
                                                (app:queue-event :app :replay {:replay rest :verify ?verify})
                                                (app:update-game next-game action))
                                       ;; TODO: generic `build-animation-for action data after opts`?
                                       ;; TODO: put replay in App.State.DefaultAppState
                                       timeline (app:build-event-animation moves after {:duration-ms 80})]
                                   (app:switch-state AppState.Animating timeline))
                                 (catch
                                   (nil err) (error err))))))

  (fn AppState.Default.OnEvent.app.menu [app menu-item]
    (case menu-item
      _ (error (Error "unhandled menu item #{menu-item}" {: menu-item}))))

  (fn AppState.Default.OnEvent.app.new-deal [app]
    (app:setup-new-game app.game-config nil)
    (vim.defer_fn #(app:queue-event :app :deal) 300))

  (fn AppState.Default.OnEvent.app.repeat-deal [app]
    (app:setup-new-game app.game-config app.seed)
    (vim.defer_fn #(app:queue-event :app :deal) 300))

  (fn AppState.Default.OnEvent.app.deal [app]
    (let [(next-game moves) (LogicImpl.Action.deal app.game)
          after #(do
                   (app:switch-state AppState.Default)
                   (app:update-game next-game [:deal])
                   ;; We need the "not animating, update components" tick to run
                   ;; to lower the z-index for the just animated cards, otherwise
                   ;; the automoves move *under* the tableau.
                   ;; So force it to run once for noop, then run the automove TODO: icky hack..
                   (app:queue-event :app :noop)
                   (app:queue-event :app :maybe-auto-move))
          timeline (app:build-event-animation moves after {:stagger-ms 50 :duration-ms 120})]
      (app:switch-state AppState.Animating timeline)))

  (fn AppState.Default.OnEvent.app.draw [app ?context]
    (case-try
      (LogicImpl.Action.draw app.game ?context) (next-game moves)
      (let [after #(do
                     (app:switch-state AppState.Default)
                     (app:update-game next-game [:draw ?context])
                     ;; We need the "not animating, update components" tick to run
                     ;; to lower the z-index for the just animated cards, otherwise
                     ;; the automoves move *under* the tableau.
                     ;; So force it to run once for noop, then run the automove TODO: icky hack..
                     (app:queue-event :app :noop)
                     (app:queue-event :app :maybe-auto-move))
            timeline (app:build-event-animation moves after {:stagger-ms 50 :duration-ms 120})]
        (app:switch-state AppState.Animating timeline))
      (catch
        (nil err) (app:notify err))))

  (fn AppState.Default.OnEvent.app.maybe-auto-move [app]
    "Called after moving a card, where the move may have exposed
    foundation-able cards for example"
    ;; It's not always safe to move cards to foundations, so we do nothing by
    ;; default.
    app)

  (fn AppState.Default.OnEvent.input.<LeftMouse> [app [click-location & rest] pos]
    (case click-location
      (where [field] (eq-any? field [:tableau :cell :hand :discard :stock]))
      (if (LogicImpl.Query.liftable? app.game click-location)
        (app:switch-state AppState.LiftingCards {:lifted-from click-location}))

      [:draw]
      (app:queue-event :app :draw click-location)

      [:menu idx nil &as menu-item]
      (app:push-state State.DefaultInMenuState {: menu-item})))

  (fn AppState.LiftingCards.OnEvent.input.<LeftMouse> [app [location] pos]
    (set app.state.context.drag-start nil)
    (case (values location app.state.context.lifted-from)
      ;; Clicking the original card should put the card down, but we only want
      ;; to do this if the user does not drag, so wait for
      ;; LiftingCards.LeftRelease.
      ([f c n] [f c n])
      (set app.state.context.return-on-left-release true)

      ([f c] [f c])
      (if (LogicImpl.Query.liftable? app.game location)
        (app:switch-state AppState.LiftingCards {:lifted-from location}))

      ;; Otherwise clicking should try to place the card.
      (to from)
      (if (LogicImpl.Query.droppable? app.game location)
        (case-try
          (LogicImpl.Action.move app.game from to) (next-game moves)
          (let [after #(do
                         (app:update-game next-game [:move from to])
                         (app:switch-state AppState.Default)
                         (app:queue-event :app :noop)
                         (app:queue-event :app :maybe-auto-move))
                timeline (app:build-event-animation moves after)]
            (app:switch-state AppState.Animating timeline))))))

  (fn AppState.LiftingCards.OnEvent.input.<LeftRelease> [app [location] pos]
    (case (values location app.state.context.lifted-from)
      ([f c n] [f c n])
      (if app.state.context.return-on-left-release
        (app:switch-state AppState.Default))))

  (fn AppState.LiftingCards.OnEvent.input.<RightMouse> [app _ _]
    (app:switch-state AppState.Default))

  (fn AppState.LiftingCards.OnEvent.input.<LeftDrag> [app [location] pos]
    (if (not app.state.context.drag-start)
      (table.merge app.state.context {:drag-start {:location location :position pos}}))
    (let [context app.state.context]
      (case (values pos app.state.context.drag-start.position)
        ({: row : col} {: row : col}) nil
        _ (case (values location context.lifted-from context.drag-start.location)
            ;; only pick up if the drag started in the down location
            (_ [f c n] [f c n])
            (app:switch-state AppState.DraggingCards
                              (table.merge context {:drag {:location location
                                                           :position pos}}))))))

  (fn AppState.DraggingCards.OnEvent.input.<LeftDrag> [app [location] pos]
    (set app.state.context.drag.position pos)
    (set app.state.context.drag.location location))

  ;; TODO: this is pretty implementation specific  regarding how we draw dragged cards.
  ;; It assumes that we have *one* card drawn under the cursor, so we try to
  ;; drop on the second location under ther cursor. If the drag-draw offset is
  ;; changed this will be effected.
  (fn AppState.DraggingCards.OnEvent.input.<LeftRelease> [app [_ location] pos]
    (if (LogicImpl.Query.droppable? app.game location)
      (case-try
        (values app.state.context.lifted-from location) (from to)
        (LogicImpl.Action.move app.game from to) (next-game _moves)
        (do
          (app:update-game next-game [:move from to])
          (app:queue-event :app :noop)
          (app:queue-event :app :maybe-auto-move))
        (catch
          (nil err) (app:notify err))))
    (app:switch-state AppState.Default))

  (fn AppState.Default.tick [app]
    (each [location card (LogicImpl.iter-cards app.game)]
      (let [comp (. app.card-id->components card.id)]
        (comp:update location card))))

  (fn AppState.LiftingCards.tick [app]
    (each [location card (LogicImpl.iter-cards app.game)]
      (let [comp (. app.card-id->components card.id)]
        (case (values location app.state.context.lifted-from)
          (where ([f c card-n] [f c lift-n]) (<= lift-n card-n))
          (let [{: row : col : z} (app:location->position [f c card-n])] ;; TODO
            (comp:update location card)
            (comp:set-position {: row
                                :col (+ col 1)
                                :z (app:z-index-for-layer :lift z)}))
          _ (comp:update location card)))))

  (fn AppState.DraggingCards.tick [app]
    (each [location card (LogicImpl.iter-cards app.game)]
      (let [comp (. app.card-id->components card.id)]
        (case (values location app.state.context.lifted-from)
          (where ([f c card-n] [f c lift-n]) (<= lift-n card-n))
          (let [{: z} (app:location->position [f c card-n])
                {: row : col} app.state.context.drag.position]
            (comp:update location card)
            (comp:set-position {:row (+ row 0 (* (- card-n lift-n) 2))
                                :col (- col 3)
                                :z (app:z-index-for-layer :lift comp.z)}))
          _ (comp:update location card)))))

  (fn AppState.GameEnded.OnEvent.input.<LeftMouse> [app [location] pos]
    (case location
      [:menu idx nil &as menu-item]
      (app:push-state State.DefaultInMenuState {: menu-item})))

  (fn AppState.GameEnded.activated [app]
    (set app.ended-at (os.time))
    (app:save (.. (os.time) :-win))
    (app:update-statistics)
    (let [[key other] (app:game-ended-data)]
      (app.components.game-report:update key other))
    app)

  AppState)

M
