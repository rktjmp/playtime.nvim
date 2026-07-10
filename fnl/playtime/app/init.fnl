(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local Serializer (require :playtime.serializer))

(local Engine (require :playtime.app.engine))
(local Clock (require :playtime.app.clock))
(local Window (require :playtime.app.window))
(local EventQueue (require :playtime.app.event-queue))
(local FSM (require :playtime.app.state-machine))

(local Menubar (require :playtime.component.menubar))

(local M {})
(local uv (or vim.loop vim.uv))

(fn make-app-cofx-interceptor [app]
  {:id :app-cofx
   :before (fn [self pipe]
             (set pipe.context.app app)
             pipe)})

(local GameManager
  {:new (fn [game-config]
          {:config game-config
           :state nil
           :history []
           ; should also have interceptor to inject game state into cofx
           ; and then also have update fx?
           :new (fn [manager new-state ?config]
                  (set manager.config (or ?config manager.config))
                  (set manager.history [])
                  (set manager.state new-state))
           :update (fn [manager next-state replay-action]
                     (table.insert manager.history 1 [manager.state replay-action])
                     (set manager.state next-state)
                     manager)
           :undo (fn [manager]
                   (case (table.remove manager.history 1)
                     [state _replay-action] (set manager.state state))
                   manager)})})

(local default-on-handlers
  {:input {}
   :app {:noop (fn [])
         :notify (fn [app cofx event fx] (app:notify (tostring event.message)))
         :quit (fn [app cofx event fx] (app:quit))}
   :window {:unfocused (fn [app cofx {: window} fx]
                         (when (vim.api.nvim_win_is_valid window.win)
                           (app.view:minimise)
                           (app.clock:pause)
                           (app:request-render)))
            :focused (fn [app cofx {: window} fx]
                       (when (vim.api.nvim_win_is_valid window.win)
                         (app.view:maximise)
                         (app.clock:resume)
                         (app:request-render)
                         (app:request-tick)))
            :closed (fn [app cofx {: window} fx]
                      (fx.event.dispatch :app :quit))}})

(λ M.scaffold-module [module]
  ;; Configure given module with default app functions and on.x handlers.
  ;; Does not overwrite any existing values but should be called early anyway.
  ;; Copy over non-special functions
  (let [ignore-functions [:new :derive :scaffold-module]]
    (each [_ func-name (ipairs (table.keys M))]
      (when (not (eq-any? func-name ignore-functions))
        (set (. module func-name) (or (. module func-name) (. M func-name))))))
  ; ;; Set `new` but wrap the call so the returned app __index's to the correct module.
  ; (set module.new (or module.new
  ;                     (fn [...]
  ;                       (let [app (M.new ...)
  ;                             __index (fn [_t k] (. module k))]
  ;                         (setmetatable app {: __index })))))
  ;; Copy over event handlers
  (set (. module :on) (or module.on {}))
  (each [ns handlers (pairs default-on-handlers)]
    (set (. module :on ns) (or (. module :on ns) {}))
    (each [name handler (pairs handlers)]
      (set (. module :on ns name) (or (. module :on ns name)
                                      handler))))
  module)

(λ M.new [{: module : name : app-id :view ?view :menu ?menu :features ?features} runtime-config]
  (let [app {: name : app-id}
        features {:save-load (?. ?features :save-load)
                  :statistics (?. ?features :statistics)}
        data-dir (-> (string.format "%s/playtime/%s" (vim.fn.stdpath :data) app-id)
                     (vim.fs.normalize))
        event-queue (EventQueue.new {:on-enqueued #(app.engine:request-tick)})
        game-manager (GameManager.new)
        fsm (FSM.new)
        clock (Clock.new)
        engine (Engine.new {: event-queue
                            : app
                            :interceptors [{:after :coeffects
                                            :insert [(make-app-cofx-interceptor app)
                                                     (fsm:state-coeffects-interceptor)
                                                     (fsm:transition-interceptor)]}
                                           {:after :dispatch-to-component
                                            :insert [(fsm:event-dispatch-interceptor)]}]
                            :render #(app:render)
                            :fps runtime-config.app.engine.fps})
        app (-> (table.merge app {: engine
                                  :components {}
                                  :focused? true
                                  : data-dir
                                  : fsm
                                  : clock
                                  : runtime-config
                                  : game-manager
                                  : event-queue})
                (setmetatable {:__index (fn [_t k] (. module k))}))]
    ;; Create default view if view configuration is given
    (case ?view
      {: width : height :filetype ?filetype}
      (let [filetype (or ?filetype app-id)
            logo-component (let [Component (require :playtime.component)]
                             (Component.new {:size {:width (string.col-width "🄿 🄻 🄰 🅈 🅃 🄸 🄼 🄴 ")
                                                    :height 1}
                                             :position {:row 0 :col 0 :z 1}
                                             :content [[["🄿 🄻 🄰 🅈 🅃 🄸 🄼 🄴 " "@playtime.ui.menu"]]]}))
            view (Window.new {: filetype
                              :dispatch-event #(app:queue-event $...)
                              :size {: width : height}
                              :position {:when-maximised runtime-config.app.window.maximise-position
                                         :when-minimised runtime-config.app.window.minimise-position}
                              :style runtime-config.app.window.border})]
        (set view.logo-component logo-component)
        (set app.view view)))
    ;; Create default menu component if menu configuration is given
    (when ?menu
      (let [separator ["──" nil]
            spec (accumulate [spec []
                              menu-i [title & item-groups] (ipairs ?menu)]
                   (let [a-drop-down [[" " nil]]
                         _ (each [_ item-group (ipairs item-groups)]
                             (each [_ [name action] (ipairs item-group)]
                               (table.insert a-drop-down [name action]))
                             (table.insert a-drop-down separator))]
                     (when (and features.save-load (= 1 menu-i))
                       (table.insert a-drop-down ["Load" [:app :load]])
                       (table.insert a-drop-down ["Save" [:app :save]])
                       (table.insert a-drop-down separator))
                     (when (= 1 menu-i)
                       (table.insert a-drop-down ["Quit" [:app :quit]])
                       (table.insert a-drop-down separator))
                     ;; remove last separator
                     (table.remove a-drop-down)
                     (table.insert a-drop-down [" " nil])
                     (table.insert spec [title a-drop-down])))
            width (or (?. ?view :width) (length (. spec 1 1)))
            menubar (Menubar.new {: width : spec})]
          (set app.components.menubar menubar)))
    app))

(λ M.update-game [app next-game ?action]
  (app.game-manager:update next-game ?action)
  app)

(λ M.notify [app message]
  (app.runtime-config.app.notify (tostring message))
  app)

(λ M.quit [app]
  (set app.quit? true)
  (app.engine:halt)
  (if (and app.view (vim.api.nvim_win_is_valid app.view.win))
    (vim.api.nvim_win_close app.view.win true))
  app)

(λ M.queue-event [app ns name ?data]
  (-> (EventQueue.Event.new ns name ?data)
      (app.event-queue:enqueue))
  (app:request-tick))

(λ M.request-tick [app]
  "Request app tick ASAP, but without exceeding tickrate."
  (app.engine:request-tick)
  app)

(λ M.request-render [app]
  "Request app render ASAP, but without exceeding render rate."
  (app.engine:request-render)
  app)

(λ M.render [app]
  ;; Reasonably sane default render implementation, render all
  ;; components under the components property. Derivations can just
  ;; toggle visibility or add/remove from the table.
  (let [components (icollect [_ c (pairs app.components)] c)]
    (app.view:render components)))
;
; (λ M.new-game [app game-builder game-config ?seed]
;   (let [seed (or ?seed (os.time))
;         game (game-builder game-config seed)]
;     (set app.started-at (os.time))
;     (set app.ended-at nil)
;     (set app.seed seed)
;     (set app.game-config game-config)
;     (set app.game-history [])
;     (Logger.info "Built #{name} seed: #{seed}" {:name app.name : seed})
;     (app:update-game game [])))
;
; (λ M.update-game [app next-game replay]
;   "Update the current game state, record the previous state and action appied to it for replay"
;   (table.insert app.game-history [app.game replay])
;   (set app.game next-game)
;   app)
;
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
;
; (λ M.update-statistics [app]
;   (fn update [d]
;     (let [data (table.merge {:version 1 :wins 0 :games []} d)]
;       (set data.wins (+ data.wins 1))
;       (set data.games (table.insert data.games
;                                     {:seed app.seed
;                                      :time (- (or app.ended-at app.started-at) app.started-at)}))
;       data))
;   (App.update-statistics app update))

; (λ M.update-statistics [app updater-fn]
;   (let [path (-> (string.format "%s/%s.json" app.data-dir :stats)
;                  (vim.fs.normalize))]
;     (case-try
;       (or (Serializer.read path) {}) data
;       (updater-fn data) new-data
;       (Serializer.write path new-data) true
;       app
;       (catch
;         (nil err) (app:notify err)))))
;
; (λ M.fetch-statistics [app]
;   (let [path (-> (string.format "%s/%s.json" app.data-dir :stats)
;                  (vim.fs.normalize))]
;     (or (Serializer.read path) {})))

M
