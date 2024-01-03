(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local M {})
(local uv (or vim.loop vim.uv))

(λ M.build [name ?opts]
  (fn with-delegates [delegates namespace]
    (fn __index [t k]
      (case (?. delegates namespace :OnEvent namespace k)
        f f
        nil (fn [app] app)))
    (setmetatable {} {: __index}))
  (let [opts (or ?opts {})
        delegates {:app (?. opts :delegate :app)
                   :input (?. opts :delegate :input)}
        base {:OnEvent {:app (with-delegates delegates :app)
                        :input (with-delegates delegates :input)}
              :Delegate delegates}]
    (setmetatable base {:__tostring (fn [] (.. name "State"))})))

;;;
;;; Some default always useful or generic states
;;;

;;
;; Handles the most basic app events such as quitting, undoing and no-oping
;;

(set M.DefaultAppState (M.build :DefaultAppState))
;; Warn if the some app event gets all the way to us without being handled.
(setmetatable M.DefaultAppState.OnEvent.app
              {:__index (fn [_t k] (error (Error "Failed to respond to app.#{k}" {: k})))})

(fn M.DefaultAppState.OnEvent.app.load [app ?filename]
  (app:load (or ?filename :latest)))

(fn M.DefaultAppState.OnEvent.app.save [app ?filename]
  (app:save (or ?filename :latest)))

(fn M.DefaultAppState.OnEvent.app.noop [app]
  app)

(fn M.DefaultAppState.OnEvent.app.quit [app]
  (doto app (tset :quit? true))
  (if (vim.api.nvim_win_is_valid app.view.win)
    (vim.api.nvim_win_close app.view.win true)))

(fn M.DefaultAppState.OnEvent.app.undo [app]
  ;; TODO: dont allow undoing into deal state
  (case (table.split app.game-history -1)
    ([nil] [nil]) (app:notify "Nothing to undo")
    (history [[new-state _]]) (doto app
                                (tset :game new-state)
                                (tset :game-history history))))

; (fn M.DefaultAppState.OnEvent.app.replay [app {: replay :verify ?verify : state : fast?}]
;   (case replay
;     ;; TODO: verify game against verify
;     [nil] (app:switch-state state)
;     [action & rest] (case action
;                       [nil] (if fast?
;                               (M.DefaultAppState.OnEvent ... uhh? pass state in to a build/attach function?
;                               (app:queue-event :app :replay {:replay rest :verify ?verify})
;                       action (case-try
;                                action [f-name & args]
;                                (. Logic.Action f-name) f
;                                (f app.game (table.unpack args)) (next-game moves)
;                                (if true
;                                  (do
;                                    (app:update-game next-game action)
;                                    (AppState.Default.OnEvent.app.replay app
;                                                                         {:replay rest
;                                                                          :verify ?verify
;                                                                          : state}))
;                                    (let [after #(do
;                                                   (app:switch-state AppState.Default)
;                                                   (app:queue-event :app :noop)
;                                                   (app:queue-event :app :replay {:replay rest :verify ?verify})
;                                                   (app:update-game next-game action))
;                                          timeline (build-event-animation moves after {:duration-ms 120})]
;                                      (app:switch-state App.State.DefaultAnimatingState timeline)))))))


;;
;; Handles ticking through one timeline animation, which
;; covers most apps needs.
;;

;; TODO: smell? We delegate to *this* default app state, not the current apps
;; default app state. This lets us handle generic quit, etc during animations
;; but might bite us later. One way to solve would be cloning the state and
;; allowing seting the delegates then somehow.
(set M.DefaultAnimatingState (M.build :DefaultAnimatingState
                                      {:delegate {:app M.DefaultAppState}}))

(fn M.DefaultAnimatingState.activated [app animation]
  (let [animations (case animation
                     {: start-at} [animation]
                     timeline timeline)]
    (set app.state.context.running [])
    (icollect [_ animation (ipairs animations)
               &into app.state.context.running]
      animation)
    (app:request-tick)
    app))

(fn M.DefaultAnimatingState.tick [app]
  (let [now (uv.now)]
    (case app.state.context.running
      [any &as animations]
      ;; bind the specific context instance, in case an after callback alters
      ;; the current state and the current state context, so we dont attach
      ;; the running animations to that new context.
      (let [context app.state.context
            animations (icollect [i animation (ipairs animations)]
                         (let [{: finish-at : start-at : tick} animation]
                           (if (<= start-at now)
                             (do
                               (animation:tick now)
                               (if (< now finish-at)
                                 animation))
                             animation)))]
        (set context.running animations)
        (app:request-tick)))))

;;
;; Handles the menubar system, delegates events back to the previous state so
;; be sure to push-state into it.
;;

;; TODO: smell, see also DefaultAnimatingState
(set M.DefaultInMenuState (M.build :DefaultInMenuState
                                   {:delegate {:app M.DefaultAppState}}))
(fn M.DefaultInMenuState.activated [app {: menu-item}]
  (let [[_ idx] menu-item]
    (each [i menu (ipairs app.components.menubar.children)]
      (menu:update (= i idx)))))

(fn M.DefaultInMenuState.deactivated [app]
  (each [i menu (ipairs app.components.menubar.children)]
    (menu:update false)))

(fn M.DefaultInMenuState.OnEvent.input.<LeftDrag> [app [location] pos]
  (case location
    ;; swap current top menu item
    [:menu first nil]
    (each [i menu (ipairs app.components.menubar.children)]
      (menu:update (= i first)))))

(fn M.DefaultInMenuState.OnEvent.input.<LeftRelease> [app [location] pos]
  (case location
    ;; swap current top menu item
    [:menu first nil]
    (each [i menu (ipairs app.components.menubar.children)]
      (menu:update (= i first)))

    ;; select some menu item
    [:menu dropdown-index item-index]
    (let [tag (?. app.components.menubar.menu dropdown-index 3 item-index 2)]
      (each [i menu (ipairs app.components.menubar.children)]
        (menu:update false))
      (case tag
        [event-name ?args] (app:queue-event :app event-name ?args))
      (app:pop-state))

    ;; click non-menu, deactivate
    _
    (app:pop-state)))

M
