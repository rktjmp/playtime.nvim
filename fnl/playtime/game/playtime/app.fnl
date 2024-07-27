(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Animate (require :playtime.animate))
(local CommonComponents (require :playtime.common.components))
(local Component (require :playtime.component))
(local App (require :playtime.app))
(local Window (require :playtime.app.window))
(local Meta (require :playtime.meta))

(local {: api} vim)
(local uv (or vim.loop vim.uv))
(local M (setmetatable {} {:__index App}))

(local AppState {})
(set AppState.Default (App.State.build :Default {:delegate {:app App.State.DefaultAppState}}))

(fn AppState.Default.OnEvent.input.<LeftMouse> [app [location] _pos]
  (case location
    [:game mod ?config] (do
                         (vim.schedule #(let [Playtime (require :playtime)]
                                          (Playtime.play mod nil ?config)))
                         (app:queue-event :app :quit))
    [:menu idx nil &as menu-item]
    (app:push-state App.State.DefaultInMenuState {: menu-item})))

(fn M.location->position [app location]
  (let []
    (case location
      [:list n] {:row (+ 2 (* (- n 1) 1)) :col 2 :z 1}
      _ (error (Error "Unable to convert location to position, unknown location #{location}"
                      {: location})))))

(λ build-game-title [view-width position meta]
  (fn justify [a b c ?colors]
    (let [max-mid (- view-width 4 (length a) (length c) 2)
          colors (or ?colors ["@playtime.color.yellow" "@playtime.ui.off" "@playtime.ui.off"])
          mid (string.sub b 1 max-mid)
          fill (string.rep " " (math.max 0 (- max-mid (length mid))))]
      [[a (. colors 1)] [(.. " " mid fill " ") (. colors 2)] [c (. colors 3)]]))
  (let [lines [;(justify meta.name meta.desc (table.concat meta.authors ", "))
               (justify meta.name
                        (.. "by " (table.concat meta.authors ", "))
                        (-> meta.categories (table.sort) (table.concat ", "))
                        ["@playtime.color.yellow" "@playtime.ui.off" "@playtime.ui.off"])
               (justify meta.desc "" ""
                        ["@playtime.color.blue" "@playtime.ui.off" "@playtime.ui.off"])]]
    (-> (Component.build)
        (Component.set-size {:width view-width :height 2})
        (Component.set-position position)
        (Component.set-content lines))))

(λ build-game-button [view-width position meta ?menu-name config]
  (let [menu-name (case ?menu-name
                    nil "Play"
                    x (.. "Play " x))
        lines [[[(.. "" menu-name) "@playtime.ui.menu"]]]]
    (-> (Component.build)
        (Component.set-size {:width view-width :height 1})
        (Component.set-tag [:game meta.mod config])
        (Component.set-position position)
        (Component.set-content lines))))

(λ M.start [app-config game-config ?seed]
  (let [app (-> (App.build "Playtime" :playtime-menu app-config game-config)
                (setmetatable {:__index M}))
        view (Window.open :menu
                          (App.build-default-window-dispatch-options app)
                          {:width  80
                           :height 40
                           :window-position app-config.window-position
                           :minimise-position app-config.minimise-position})
        _ (set app.view view)
        metas (Meta.find)
        list (accumulate [(t n) (values [] 1)
                          _ meta (ipairs metas)]
               (let [title (build-game-title app.view.width (M.location->position nil [:list n]) meta)
                     n (+ n 1)
                     rulesets (or meta.rulesets [{:menu nil :config {}}])
                     variants (icollect [i {:menu _menu : config} (ipairs rulesets)]
                                (build-game-button app.view.width
                                                   (M.location->position nil [:list (+ n i)])
                                                   meta _menu config))]
                 (values (table.join t [title] variants)
                         (+ n 2 (length variants)))))
;         list (icollect [i m (ipairs meta)]
;                         (build-game-item app i m))
        menubar (CommonComponents.menubar [["Playtime" [:file]
                                            [["" nil]
                                             ["Quit" [:quit]]
                                             ["" nil]]]]
                                          {:width view.width
                                           :z (app:z-index-for-layer :menubar)})]
    (table.merge app.components {: menubar : list})
    (app:switch-state AppState.Default)
    (app:render)))

(fn M.render [app]
  (app.view:render [app.components.list [app.components.menubar]])
  app)


(fn M.tick [app]
  (let [now (uv.now)]
    (app:process-next-event)
    (app:request-render)))

M
