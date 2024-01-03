(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local State (require :playtime.app.state))
(local CommonComponents (require :playtime.common.components))
(local Serializer (require :playtime.serializer))

(local M {: State})
(local uv (or vim.loop vim.uv))

(λ M.build [name app-id app-config game-config]
  "Scaffold a basic app table from a config."
  {: name
   : app-id ;; kinda smells, since we have 'id' as an int and 'app-id' as a "computer readable name"
   :filetype (.. "playtime-" app-id)
   :data-dir (-> (string.format "%s/playtime/%s" (vim.fn.stdpath :data) app-id)
                 (vim.fs.normalize))
   : app-config
   :started-at (os.time)
   :ended-at nil

   :seed (Error "Seed not initialised")
   :game (Error "Game not initialised")
   : game-config
   :game-history []

   :view (Error "View not initialised")
   :z-layers {:base 0 :report 500 :menubar 600}
   :tick-rate-ms (math.floor (/ 1000 (or app-config.fps 30)))
   :components {:menubar (CommonComponents.menubar
                           [["Playtime" [:todo]]]
                           {:width 80 :z 100})
                :cheating (-> (CommonComponents.cheating)
                              (: :set-visible false))}
   :state (setmetatable [[State.DefaultAppState {}]]
                        ;; Some convenience to access "current" state/context
                        ;; because fennel does not support numbers in
                        ;; key-paths.
                        {:__index (fn [t k]
                                    (case k
                                      :context (?. t 1 2)
                                      :module (?. t 1 1)))
                         :__newindex (fn [t k v]
                                       (case k
                                         :context (tset t 1 2 v)))})
   :event-queue []
   :throttle {:render {:requested? false}
              :tick {:last-at 0 :scheduled? false}}
   :quit? false})

(λ M.build-default-window-dispatch-options [app]
  ;; TODO: passing app here could just be the via, need to bind the app target
  {:mouse {:via #(app:queue-event :input $...)
           :events [:<LeftMouse>
                    :<2-LeftMouse>
                    :<3-LeftMouse>
                    :<LeftDrag>
                    :<LeftRelease>
                    :<MiddleMouse>
                    :<RightMouse>
                    :<RightDrag>
                    :<RightRelease>]}
   :window {:via #(app:queue-event :app $...)}})

(fn M.z-index-for-layer [app layer ?plus]
  (case (?. app.z-layers layer)
    n (+ n (or ?plus 0))
    _ (error (<s> "Unknown layer name for z-index: #{layer}"))))

(λ M.new-game [app game-builder game-config ?seed]
  (let [seed (or ?seed (os.time))
        game (game-builder game-config seed)]
    (set app.seed seed)
    (set app.game-config game-config)
    (set app.game-history [])
    (Logger.info "Built #{name} seed: #{seed}" {:name app.name : seed})
    (app:update-game game [])))

(λ M.update-game [app next-game replay]
  "Update the current game state, record the previous state and action appied to it for replay"
  (table.insert app.game-history [app.game replay])
  (set app.game next-game)
  app)

(fn throttled-tick [app]
  (when (not app.quit?)
    (set app.throttle.tick.last-at (uv.now))
    (app:tick)
    (when app.throttle.render.requested?
      (set app.throttle.render.requested? false)
      (app:render)))
  app)

(λ M.request-tick [app]
  "Request app tick ASAP, but without exceeding tickrate. Will render if previously requested."
  (when (not app.throttle.tick.scheduled?)
    (set app.throttle.tick.scheduled? true)
    (let [now (uv.now)
          next-tick-at (+ app.throttle.tick.last-at app.tick-rate-ms)
          time-to-next-tick-ms (math.max 0 (- next-tick-at now))
          run (fn []
                (set app.throttle.tick.scheduled? false)
                (throttled-tick app))]
      (vim.defer_fn run time-to-next-tick-ms)))
  app)

(λ M.request-render [app]
  "Request the app be rendered during a future tick, does not request tick."
  (set app.throttle.render.requested? true)
  app)

(λ M.queue-event [app namespace event ...]
  ;; LeftDrag generates a lot of events, which will basically *always*
  ;; outpace our tick-rate, so when receiving many in a row, replace the last
  ;; event with the new event to "fast forward".
  ;; Other input events are unlikely to, but could also outpace us, so do the
  ;; same thing.
  ;; App events may be generated quickly, but if they are we probably intend to
  ;; queue the same event multiple times, so they are not debounced.
  ;; TODO: This can maybe make starting a card drag awkward over ssh.
  (let [index (case (values namespace (table.last app.event-queue))
                (where (:input [:input (= event)])) (length app.event-queue)
                _ (+ 1 (length app.event-queue)))]
    (tset app.event-queue index [namespace event (table.pack ...)])
    (app:request-tick))
  app)

(λ M.process-next-event [app]
  "Pull next event off event queue and run it, otherwise does nothing.
  If any event is dequeued, the application automatically requests another
  tick after processing the event."
  (case app.event-queue
    [[ns event args] & other-events]
    (do
      ;; Request tick after dequeing to process next event, or events queued
      ;; during this tick.
      (app:request-tick)
      (set app.event-queue other-events)
      (case (?. app :state :module :OnEvent ns event)
        f (f app (table.unpack args))
        _ (Logger.info "#{state} had no handler for event #{ns}.#{event}"
                       {:state (. app :state 1) : ns : event})))))

(fn M.switch-state [app new-state ?context]
  "Switch the current state with a new state, executes deactivated and activated callbacks"
  (M.pop-state app)
  (M.push-state app new-state ?context)
  app)

(fn M.push-state [app new-state ?context]
  "Push given state onto the state stack, executes activated callbacks, but not deactivated."
  ;; TODO: should push/pop trigger activated/deactivated state callbacks?
  ;; The state is likely "still active" in a sense.
  (let [context (or ?context [])]
    (table.insert app.state 1 [new-state context])
    (if new-state.activated
      (new-state.activated app context))
    app))

(fn M.pop-state [app]
  "Pop current state from the state stack, executes deactivated callbacks, but not activated.
  Does not protect against over-popping."
  ;; TODO: should push/pop trigger activated/deactivated state callbacks?
  (case (table.remove app.state 1)
    [state ?context] (if state.deactivated (state.deactivated app ?context)))
  app)

(fn M.notify [app msg]
  ;; TODO: configable, with better visibility
  (vim.notify (tostring msg)))

(λ M.save [app filename data]
  "Save give per-application data to a filename, which can be retrieved by `load`."
  (let [dir app.data-dir
        path (-> (string.format "%s/%s.json" dir filename)
                 (vim.fs.normalize))]
    (case-try
      (vim.fn.mkdir dir :p) 1
      (Serializer.write path data) true
      (app:notify (string.format "Saved to %s" path))
      (catch
        (nil err) (app:notify err)))))

(λ M.load [app filename]
  "Load previously saved per-application data from filename.
  returns the data for further processing. Application of the data is left to
  the implementation."
  (let [path (-> (string.format "%s/%s.json" app.data-dir filename)
                 (vim.fs.normalize))]
    (case-try
      (Serializer.read path) data
      (do
        (app:notify (string.format "Loaded %s" path))
        data)
      (catch
        (nil err) (app:notify err)))))

(λ M.update-statistics [app updater-fn]
  (let [path (-> (string.format "%s/%s.json" app.data-dir :stats)
                 (vim.fs.normalize))]
    (case-try
      (or (Serializer.read path) {}) data
      (updater-fn data) new-data
      (Serializer.write path new-data) true
      app
      (catch
        (nil err) (app:notify err)))))

(λ M.fetch-statistics [app]
  (let [path (-> (string.format "%s/%s.json" app.data-dir :stats)
                 (vim.fs.normalize))]
    (or (Serializer.read path) {})))

M
