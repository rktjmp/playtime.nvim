(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local App (require :playtime.app))
(local Component (require :playtime.component))
(local PatienceComponent (require :playtime.patience.component))
(local GameReport (require :playtime.component.game-report))
(local {: State} (require :playtime.app.state-machine))

(local M {:on {:app {}}
          :State {:Idle {:on {:app {} :input {}}}
                  :PlanningMove {:on {:app {} :input {}}}
                  :GameEnded {:on {:app {} :input {}}}}})

;;;
;;; Generalised implementation of a "patience" game, where the player moves
;;; cards between the tableau, eventually into foundations to win the game.
;;;
;;; Used for Freecell/Bakers, Shenzhen, Forty-fortunes, Curds and Whey, Spider,
;;; Penguin.
;;;

(λ M.scaffold-module [module]
  (let [module (App.scaffold-module module)]
    ;; Functions
    (let [ignore-functions [:new :scaffold-module :on]]
      (each [_ func-name (ipairs (table.keys M))]
        (when (not (eq-any? func-name ignore-functions))
          (set (. module func-name) (or (. module func-name) (. M func-name))))))

    ;; App event handlers
    (each [ns handlers (pairs M.on)]
      (set (. module :on ns) (or (. module :on ns) {}))
      (each [name handler (pairs handlers)]
        (set (. module :on ns name) (or (. module :on ns name)
                                        handler))))
    ;; Create state instances, copy handlers
    (let [Idle (State.new {:id :idle})
          PlanningMove (State.new {:id :planning-move})
          GameEnded (State.new {:id :game-ended})
          state-spec [[:Idle :idle]
                      [:PlanningMove :planning-move]
                      [:GameEnded :game-ended]]
          states (collect [_ [state-name id] (ipairs state-spec)]
                   (let [new-state (State.new {: id})]
                     (each [ns handlers (pairs (. M.State state-name :on))]
                       (case (type handlers)
                         ;; on.app.<name>
                         :table (do
                                  (set (. new-state :on ns) (or (. new-state :on ns) {}))
                                  (each [name handler (pairs handlers)]
                                    (set (. new-state  :on ns name) handler)))
                         ;; on.enter
                         :function (set (. new-state :on ns)
                                        (or (. new-state :on ns) handlers))))
                     (values state-name new-state)))]
      (set module.State states))
    module))

(λ M.start [patience-config app-config runtime-config game-config ?seed]
  (let [{: LogicImpl : StateImpl : ComponentImpl} patience-config
        _ (assert-match {:Action {: move}
                         :Query {: liftable? : droppable? : moveable?
                                 : game-ended? : game-result
                                 : automatic-action}}
                        LogicImpl)
        _ (assert-match {: Idle : PlanningMove : GameEnded} StateImpl)
        _ (assert-match {:spec {:slots [data]}} ComponentImpl)
        _ (set app-config.features (table.merge {:save-load true}
                                                (or app-config.features {})))
        app (App.new app-config runtime-config)]
    (table.merge app {: LogicImpl : StateImpl : ComponentImpl : game-config})
    (app.view:open)
    ;; There is some neovim particularity here, if we deal too soon after the
    ;; window is created we can land in some kind of bookkeeping
    ;; and our deal animation will stutter after the first few frames.
    ;;
    ;; Delay our initial deal to mask this.
    (app:request-tick)
    (app:request-render)
    (app:queue-event :app :new-game {:delay 200 :seed ?seed})))

;;
;; Default State Handlers
;;

;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Idle state
;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(fn M.State.Idle.on.app.deal [state {: app} event fx]
  (let [{: LogicImpl} app
        (next-game events) (LogicImpl.Action.deal app.game)
        on-complete (fn []
                      (app:synchronise-components-to-game-state)
                      (fx.event.dispatch :app :maybe-auto-move)
                      (fx.interaction-lock.unlock)
                      (fx.engine.render))
        animation (app:build-card-animation-from-events events on-complete)]
    (set app.game next-game)
    (fx.engine.tick)
    (fx.engine.render)
    (fx.animation.play animation)
    (fx.interaction-lock.general-lockout)))

(fn M.State.Idle.on.app.draw [state {: app} event fx]
  (let [{: LogicImpl} app]
    (case (LogicImpl.Action.draw app.game)
      (next-game events)
      (let [animation (app:build-card-animation-from-events
                        events
                        (fn []
                          (app:synchronise-components-to-game-state)
                          (fx.event.dispatch :app :maybe-auto-move)
                          (fx.interaction-lock.unlock)
                          (fx.engine.render)))]
        (fx.animation.play animation)
        (fx.interaction-lock.general-lockout)
        (set app.game next-game))
      (nil ?err)
      (do
        (fx.notify (or ?err "invalid action"))))))

(fn M.State.Idle.on.app.maybe-auto-move [state {: app} event fx]
  (let [{: LogicImpl : StateImpl} app]
    (if (LogicImpl.Query.game-ended? app.game)
      (fx.state.transition StateImpl.GameEnded)
      (case (LogicImpl.Query.automatic-action app.game)
        [action & args] (let [(next-game events) ((. LogicImpl.Action action) app.game (table.unpack args))
                              on-complete (fn []
                                            (app:synchronise-components-to-game-state)
                                            (fx.event.dispatch :app :maybe-auto-move)
                                            (fx.interaction-lock.unlock)
                                            (fx.engine.render))
                              animation (app:build-card-animation-from-events events on-complete)]
                          (fx.animation.play animation)
                          (fx.interaction-lock.general-lockout)
                          (set app.game next-game))))))

(fn M.State.Idle.on.app.click-card [state {: app} {: card : component : location} fx]
  (let [{: LogicImpl : StateImpl} app]
    (case-try
      (LogicImpl.Query.liftable? app.game location) true
      (fx.state.transition StateImpl.PlanningMove {: card : component : location
                                                   :allow {:click? true :drag? true}})
      (catch
        (false ?err) (fx.notify (or ?err "invalid action"))))))

;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Planning Move
;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(fn M.State.PlanningMove.on.enter [state {: app} event fx]
  (let [{: LogicImpl} app
        moveable? (or LogicImpl.Query.moveable? #false)]
    (set state.snap-to-location? #(moveable? app.game state.location $1))
    (state.component:pick-up app)
    (fx.engine.render)))

;; Note this needs a click handler on cards and slots to dispatch the same
;; cancel event (or fx.event.propagate)
;; Alternative solution is an interceptor that captures all right
;; clicks (but what about menu clicks?) and eats them.
;; That would not be an incorrect use of the interceptors.
(fn M.State.PlanningMove.on.input.click [state {: app} event fx]
  (case event
    {:button :right :action :press}
    (fx.event.dispatch :app :cancel)))

(fn M.State.PlanningMove.on.app.click-card [state {: app} event fx]
  (let [{: StateImpl} app]
    (case (values state.location event.location)
      ([f c n] [f c n])
      (do
(state.component:put-down)
        (fx.state.transition StateImpl.Idle)
        (fx.engine.render))
      _
      (fx.event.dispatch :app :move {:from state.location
                                     :to event.location}))))

(fn M.State.PlanningMove.on.app.click-slot [state cofx event fx]
  (fx.event.dispatch :app :move {:from state.location
                                 :to event.location}))

(fn M.State.PlanningMove.on.app.drop-card [state cofx event fx]
  (case (values state.location event.location)
    ;; dropping card where it came from is not a move
    (where ([f c n] [f c ^n]) (= ^n (- n 1))) (fx.event.dispatch :app :cancel)
    ;; dropping on nothing is also not a move
    (_ nil) (fx.event.dispatch :app :cancel)
    ;; otherwise try move, which will surface error notification if bad move.
    _ (fx.event.dispatch :app :move {:from state.location
                                     :to event.location
                                     :fast-forward-animation? true
                                     :return-card? true})))

(fn M.State.PlanningMove.on.app.cancel [state {: app} event fx]
  (let [{: StateImpl} app]
    (state.component:put-down)
    (fx.state.transition StateImpl.Idle)
    (fx.engine.render)))

(fn M.State.PlanningMove.on.app.move [state {: app} {: from : to : fast-forward-animation? : return-card?} fx]
  (let [{: LogicImpl : StateImpl} app]
    (case (LogicImpl.Action.move app.game from to)
      (next-game events)
      (let [animation (app:build-card-animation-from-events
                        events
                        (fn []
                          (app:synchronise-components-to-game-state)
                          (fx.state.transition StateImpl.Idle)
                          (fx.event.dispatch :app :maybe-auto-move)
                          (fx.interaction-lock.unlock)
                          (fx.engine.render)))]
        (fx.animation.play animation)
        (fx.interaction-lock.general-lockout)
        (set app.game next-game)
        (if fast-forward-animation?
          (fx.animation.fast-forward)))
      (nil ?err)
      (do
        (fx.notify (or ?err "invalid action"))
        (when return-card?
          (state.component:put-down)
          (fx.state.transition StateImpl.Idle)
          (fx.engine.render))))))

;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Game Ended
;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(fn M.State.GameEnded.on.enter [state {: app} event fx]
  (let [{: LogicImpl} app
        result (if (LogicImpl.Query.game-result app.game) :won :lost)
        other-lines [(string.fmt "Moves: %d" app.game.moves)
                     (string.format "Time: %s" (app.clock:elapsed-time))]
        report (GameReport.new {:view-size app.view.size
                                :play-again ["Play Again?" [:app :new-game]]
                                : result
                                :result-lines [[:won "Solved"]
                                               [:lost "Not Solved"]]
                                : other-lines})]
    (set app.components.report report)
    (fx.interaction-lock.general-lockout)
    (fx.engine.render)))

;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; App Handlers
;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(fn M.on.app.new-game [app cofx {: seed :delay ?delay} fx]
  (let [{: LogicImpl : StateImpl} app
        game (LogicImpl.build app.game-config seed)]
    (app.clock:reset)
    (set app.game game)
    (app:build-card-components)
    (app:build-slot-components)
    (app:build-other-components)
    (app:synchronise-components-to-game-state)
    (set app.components.report nil)
    (fx.state.reset StateImpl.Idle)
    (fx.event.dispatch-after (or ?delay 1) :app :deal)
    (fx.interaction-lock.general-lockout)
    (fx.engine.render)
    (fx.engine.tick)))

(λ M.on.app.save [app cofx event fx]
  (app:save :user-save app.game))

(λ M.on.app.load [app cofx event fx]
  (set app.game (app:load :user-save))
  (app:build-card-components)
  (app:build-slot-components)
  (app:build-other-components)
  (app:synchronise-components-to-game-state)
  (fx.engine.tick)
  (fx.engine.render))


;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Functions
;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(λ M.synchronise-components-to-game-state [app]
  (let [{: LogicImpl} app]
    (each [location card (LogicImpl.iter-cards app.game)]
      (let [comp (app:find-card-component-by-card-id card.id)
            position (app:location->position location)]
        (case card
          {:face :up} (comp:flip-face-up)
          {:face :down} (comp:flip-face-down))
        (set comp.location location)
        (set comp.position position))))
  app)

;; probably more complicated for generic. needs some spec for n-cells
;; n-foundations n-tablaue cards, etc.
(λ M.build-slot-components [app]
  (let [{: ComponentImpl} app
        {: spec} ComponentImpl
        make-slot (or ComponentImpl.slot PatienceComponent.slot)
        on {:click (fn [self cofx event fx]
                     (case event
                       {:action :press :button :left}
                       (fx.event.dispatch :app :click-slot {:location self.location})))}
        slots (accumulate [t []
                           _ {: location : count : label} (ipairs spec.slots)]
                (fcollect [i 1 count &into t]
                  (let [location [location i 0]
                        position (app:location->position location)]
                    (make-slot {: on : location : position : label}))))]
    (table.merge app.components {:slots (Component.new {:children slots})})
    app))

(λ M.build-card-components [app]
  (let [{: ComponentImpl : LogicImpl} app
        make-card (or ComponentImpl.card PatienceComponent.card)
        funcs {:pick-up (fn [self app]
                          (let [[f c n] self.location
                                also-lifted (icollect [loc card (LogicImpl.iter-cards app.game [f])]
                                              (let [[_ cc nn] loc]
                                                (when (and (= c cc) (< n nn))
                                                  (app:find-card-component-by-card-id card.id))))
                                offsets (icollect [_ comp (ipairs also-lifted)]
                                          [comp {:row (- comp.position.row self.position.row)
                                                 :col (- comp.position.col self.position.col)
                                                 :z (- comp.position.z self.position.z)}])
                                align-children (fn [self]
                                                 (each [_ [comp offset] (ipairs offsets)]
                                                   (set comp.position {:row (+ self.position.row offset.row)
                                                                       :col (+ self.position.col offset.col)
                                                                       :z (+ self.position.z offset.z)})))]
                            (set self.original-position (clone self.position))
                            (set self.align-children align-children)
                            (set self.selected? true)
                            (set self.position {:row self.position.row
                                                :col (+ 1 self.position.col)
                                                :z 500})
                            (self:align-children)))
               :put-down (fn [self]
                           (set self.position self.original-position)
                           (self:align-children)
                           (set self.selected? false)
                           (set self.original-position nil)
                           (set self.align-children nil))}
        on {:click (fn [self cofx event fx]
                     ;; Note we dont want mouse-down-mouse-up to immediately select-deselect the card
                     ;; so the release must be from a different event group.
                     (case event
                       {:action :press :button :right}
                       (fx.event.dispatch :app :cancel)
                       {:action :press :button :left}
                       (do
                         (set self.mouse-down-group-id event.group-id)
                         (fx.event.dispatch :app :click-card {:card self.card
                                                              :component self
                                                              :location self.location}))
                       {:action :release :button :left}
                       (when (and self.selected? (not= self.mouse-down-group-id event.group-id))
                         (fx.event.dispatch :app :click-card {:card self.card
                                                              :component self
                                                              :location self.location}))))
            :drag (fn [self cofx event fx]
                    (when (?. cofx :state :allow :drag?)
                      (case event
                        {:button :left :action :start}
                        (when self.selected?
                          (let [{: row : col} event
                                position {:row (+ row 0)
                                          :col (- col 3)
                                          :z 500}]
                            (set self.position position)
                            (self:align-children)
                            (fx.drag.accept self)
                            (fx.engine.render)))
                        {:button :left :action :move}
                        (let [{: row : col} event
                              event-position {:row (+ row 0)
                                              :col (- col 3)
                                              :z 500}]
                          (case event.over-target
                            (where {: location :position {: row : col : z}}
                                   (cofx.state.snap-to-location? location))
                            (case location
                              [:tableau] (set self.position {:row (+ row 2) : col :z (+ z 1)})
                              _ (set self.position {:row row : col :z (+ z 1)}))
                            _ (set self.position event-position))
                          (self:align-children)
                          (fx.engine.render))
                        {:button :left :action :stop}
                        (fx.event.dispatch :app :drop-card {:location (?. event.drop-target :location)}))))}]
    (let [cards (icollect [location card (LogicImpl.iter-cards app.game)]
                  (let [position (app:location->position location)
                        comp (make-card {: card
                                         : location
                                         : position
                                         :pick-up funcs.pick-up
                                         :put-down funcs.put-down
                                         : on})]
                    (comp:flip-face-down)
                    comp))
          container (Component.new {:children cards})]
      (table.merge app.components {:cards container}))
    app))

(λ M.build-other-components [app] app)

(λ M.find-card-component-by-card-id [app card-id]
  (let [lookup (or app.__find-card-component-by-card-id-lookup
                   (table.set app :__find-card-component-by-card-id-lookup {:memo nil :table nil}))
        root-component app.components.cards]
    (when (~= root-component lookup.memo)
      (set lookup.memo root-component)
      (set lookup.table
           (collect [_ comp (ipairs root-component.children)]
             (values comp.card.id comp))))
    (. lookup.table card-id)))

(λ M.location->position [app location]
  (error "Implementation must provide location->position function"))

(fn M.build-card-animation-from-events [app events on-complete]
  (let [{: Animation : Group} (require :playtime.app.animation-manager)
        flip-duration 1
        move-duration 120
        stagger 50
        move-delay (fn [i] (* (- i 1) 50))
        flip-delay (fn [i] (+ (move-delay i) (/ move-duration 1)))
        ;; Event locations may include "transient" card locations, eg
        ;; a card is moved from discard -> deck -> hand, but our current state
        ;; only has the card in discard, and the future state has it in hand.
        ;; So we maintain a cache of the location -> cards during the event
        ;; stream so we can resolve transient locations to cards.
        move-location-cache {}
        find-card-by-location (fn [[f c n]]
                                (case (?. move-location-cache f c n)
                                  card card
                                  nil (. app.game f c n)))
        save-card-move-to-cache (fn [card [f c n]]
                                  (case (. move-location-cache f)
                                    nil (set (. move-location-cache f) {}))
                                  (case (. move-location-cache f c)
                                    nil (set (. move-location-cache f c) {}))
                                  (set (. move-location-cache f c n) card))
        animations (icollect [i event (ipairs events)]
                     (case event
                       (where (or [:face-up location] [:face-down location]))
                       (let [[f c n] location
                             card (find-card-by-location location)
                             component (app:find-card-component-by-card-id card.id)]
                             (Animation.new
                                    {: component
                                     :apply (fn [component value percent]
                                              (when (<= 1 percent)
                                                (case event
                                                  [:face-up _] (component:flip-face-up)
                                                  [:face-down _] (component:flip-face-down))))
                                     :property :visible-face
                                     :from 0
                                     :to 1
                                     :ease :linear
                                     :duration flip-duration
                                     :delay (flip-delay i)}))
                       [:move from to]
                       (let [[f c n] from
                             card (find-card-by-location from)
                             _ (save-card-move-to-cache card to)
                             component (app:find-card-component-by-card-id card.id)
                             {:position {:z default-z}} component]
                             (Animation.new
                                    {: component
                                     :apply (fn [component value percent]
                                              (set component.position {:row (math.ceil value.row)
                                                                       :col (math.ceil value.col)
                                                                       ;; TODO: deal specific z setting, have two animation fs
                                                                       ;; move & deal.
                                                                       :z (+ 200 (. (app:location->position to) :z))}))
                                     :property :position
                                     :from (app:location->position from)
                                     :to (app:location->position to)
                                     :ease :ease-out-quad
                                     :duration move-duration
                                     :delay (move-delay i)}))))]
    (Group.new {: animations : on-complete})))
M
