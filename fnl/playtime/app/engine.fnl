(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local Id (require :playtime.id))
(local InterceptorChain (require :playtime.app.interceptor-chain))
(local DragInterceptor (require :playtime.app.interceptor.drag))
(local FocusInterceptor (require :playtime.app.interceptor.focus))
(local ComponentDispatcherInterceptor (require :playtime.app.interceptor.component-dispatcher))
(local AppDispatcherInterceptor (require :playtime.app.interceptor.app-dispatcher))
(local InteractionLockoutInterceptor (require :playtime.app.interceptor.interaction-lockout))
(local InputGroupIdInterceptor (require :playtime.app.interceptor.input-group-id))
(local AnimationInterceptor (require :playtime.app.interceptor.animation))

(local EventQueue (require :playtime.app.event-queue))
(local AnimationManager (require :playtime.app.animation-manager))

(local uv (or vim.uv vim.loop))
(local M {})
(local m {})

(fn make-immediate-queue-interceptor [event-queue]
  (let [force-immediate (fn [events]
                          (for [i (length events) 1 -1]
                            (event-queue:_force-next-immediate-dequeue (. events i))))]
    {:id :queue-events-immediately
     :before (fn [_self chain]
               (set chain.__internal__ (or chain.__internal__ {}))
               (table.merge chain.__internal__ {:queue-events-immediately force-immediate})
               chain)}))

(fn make-engine-manager-interceptor [{: event-queue &as engine}]
  (fn event-or-create-event [event-or-ns ?name ?data]
    (case event-or-ns
      {: ns : name &as event} event
      ns (EventQueue.Event.new ns ?name ?data)))

  {:id :standard-engine-and-event-effects
   :before (fn [_self chain]
             (table.merge chain.effects
                          {:notify (fn [message]
                                     (let [event (event-or-create-event :app :notify {: message})]
                                       (event-queue:enqueue event)))
                           :event {:dispatch (fn [ns name data]
                                               (let [event (event-or-create-event ns name data)]
                                                 (event-queue:enqueue event)
                                                 event))
                                   :dispatch-after (fn [ms ns name data]
                                                     (let [event (event-or-create-event ns name data)]
                                                       (vim.defer_fn #(event-queue:enqueue event) ms)
                                                       event))
                                   :dispatch-next (fn [ns name data]
                                                    (let [event (event-or-create-event ns name data)]
                                                      (event-queue:_force-next-immediate-dequeue event)
                                                      event))}
                           :engine {:render #(engine:request-render)
                                    :tick #(engine:request-tick)}})
             chain)})



(λ M.new [{: event-queue : app : interceptors : render : fps}]
  (let [minmax-fps (math.min (math.max fps 30) 240)
        render-ms (math.floor (/ 1000 minmax-fps))
        tick-ms (math.floor (/ 1000 (math.max fps 64)))
        engine {: event-queue
                : app
                :animation-manager (AnimationManager.new)
                :idle {:behaviour :sleep
                       :timer nil}
                :halted? false
                :interceptors []
                :render {:function render
                         :last-at 0
                         :timer nil
                         :rate-ms render-ms
                         :requested? false}
                :tick {:last-at 0
                       :count 0
                       :timer nil
                       :scheduled? false
                       :rate-ms tick-ms}}
        default-interceptors [(make-immediate-queue-interceptor event-queue)
                              (make-engine-manager-interceptor engine)
                              (AnimationInterceptor.new engine.animation-manager)
                              ;; careful moving this, dont put it after fsm transition handler
                              (InteractionLockoutInterceptor.new)
                              {:id :coeffects}
                              (DragInterceptor.new)
                              (InputGroupIdInterceptor.new)
                              (FocusInterceptor.new)
                              {:id :dispatchers}
                              (ComponentDispatcherInterceptor.new)
                              (AppDispatcherInterceptor.new app)]]
    (set engine.interceptors
         (accumulate [into default-interceptors
                      _ {: after : insert} (ipairs interceptors)]
           (let [offset (accumulate [offset nil
                                     i {: id} (ipairs into)
                                     &until offset]
                          (if (= id after) i))]
             (assert offset (.. "no offset for interceptor id: " after))
             (each [index interceptor (ipairs insert)]
               (table.insert into (+ offset index) interceptor))
             into)))
    ; (Logger.info (icollect [_ {: id} (ipairs engine.interceptors)] id))
    (set engine.render.last-at (- (uv.now) engine.render.rate-ms 1))
    (set engine.tick.last-at (- (uv.now) engine.tick.rate-ms 1))
    (setmetatable engine {:__index M})
    engine))

(λ M.halt [engine]
  (set engine.halted? true)
  (each [_ key (ipairs [:idle :tick :render])]
    (case (. engine key :timer)
      t (uv.timer_stop t))
    (set (. engine key :timer) nil))
  engine)

(λ M.set-idle-behaviour [engine behaviour]
  "Configure engine to `:sleep` when nothing to do, or always self-wake every
  `[:interval ms]` to tick. Most things should sleep and wake on user action,
  some applications (realtime or with timers) need to wake on an interval."
  (case behaviour
    :sleep (set engine.idle.behaviour :sleep)
    [:interval ms] (set engine.idle.behaviour [:interval ms])
    _ (error (<s> "Unknown idle behaviour #{behaviour}" {:behaviour (vim.inspect behaviour)})))
  (engine:request-tick)
  engine)

(λ M.request-tick [engine]
  "Request engine tick ASAP, but without exceeding tickrate."
  (when (not engine.tick.scheduled?)
    (set engine.tick.scheduled? true)
    (let [now (uv.now)
          next-tick-at (+ engine.tick.last-at engine.tick.rate-ms)
          time-to-next-tick-ms (math.max 1 (- next-tick-at now))
          ; _ (Logger.info [:engine.request-tick {: next-tick-at : time-to-next-tick-ms}])
          run (fn []
                (set engine.tick.scheduled? false)
                (set engine.tick.timer nil)
                (when (not engine.halted?)
                  (engine:_tick)))
          timer (vim.defer_fn run time-to-next-tick-ms)]
      (set engine.tick.timer timer)))
  engine)

(λ M.request-render [engine]
  ;; TODO: semantics here is a bit squishy? It relies on knowing that
  ;; the tick function runs through events -> render() so calling
  ;; request-render in an event will render after all events.
  "Request engine render ASAP, but without exceeding render rate."
  (set engine.render.requested? true)
  engine)

(λ m.schedule-render [engine]
  ;; Coalesce calls to requests to render to avoid needless work.
  ;; Our framerate in this case is mostly a *limiter* rather than an upper
  ;; bound.
  (when (not engine.render.scheduled?)
    (set engine.render.scheduled? true)
    (let [now (uv.now)
          next-render-at (+ engine.render.last-at engine.render.rate-ms)
          time-to-next-render-ms (math.max 0 (- next-render-at now))
          run (fn []
                (set engine.render.last-at (uv.now))
                (set engine.render.scheduled? false)
                (set engine.render.timer nil)
                (when (not engine.halted?)
                  (engine.render.function)))
          timer (vim.defer_fn run time-to-next-render-ms)]
      (set engine.render.timer timer)))
  engine)

(λ M._tick [engine]
  (when engine.idle.timer
    (uv.timer_stop engine.idle.timer)
    (set engine.idle.timer nil))
  (let [{: event-queue : interceptors : app : animation-manager} engine
        now (uv.now)
        ;; We dont have a constant tick-rate, as we "sleep" when no events are
        ;; waiting or the engine is not busy. This is good, we dont burn cylces
        ;; doing nothing, but deferred events can trigger a tick with a huge dt
        ;; which can negatively effect other systems like animations.
        ;;
        ;; For example, we idle for 1000ms then a deferred fn triggers an event
        ;; which creates an 300ms animation. That anmiation is added to the
        ;; manager and ticked wih the dt of 1000 and instantly completes.
        ;;
        ;; We solve this by considering large dt's as "idle" and resetting it
        ;; to 1ms. Alternative solutions such as ignoring the first
        ;; animation.tick() call were disregarded as too specific to that
        ;; system.
        true-dt (- now engine.tick.last-at)
        dt (case engine.idle.behaviour
             :sleep (if (<= 150 true-dt) 1 true-dt)
             [:interval _] true-dt)]
    ; (Logger.info [:engine.tick {: dt : true-dt :state (?. app.fsm.state :module :id)}])
    (set engine.tick.last-at now)
    (set engine.tick.count (+ 1 engine.tick.count))

    ;; Prevent event runaway by buffering any new events generated in this
    ;; block, then queue them all at once afterwards. This is just a lazy way
    ;; to have two queues.
    (event-queue:hold-new-events)
    (while (not (event-queue:empty?))
      (let [event (event-queue:dequeue)
            interceptor-chain (InterceptorChain.new {:chain interceptors
                                                     :context {: event}})]
        (interceptor-chain:run)))
    (event-queue:release-new-events)

    (when (not (event-queue:empty?))
      (engine:request-tick))

    (when (animation-manager:active?)
      (animation-manager:tick dt)
      (engine:request-tick)
      (engine:request-render))

    (if app.tick (app:tick dt))
    (when engine.render.requested?
      (set engine.render.requested? false)
      (m.schedule-render engine))

    (case engine.idle.behaviour
      :sleep nil
      [:interval ms] (let [timer (vim.defer_fn #(engine:request-tick) ms)]
                       (set engine.idle.timer timer)))

    engine))
M
