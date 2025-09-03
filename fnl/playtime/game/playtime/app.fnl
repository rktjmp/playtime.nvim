(require-macros :playtime.prelude)
(prelude)

(local App (require :playtime.app))
(local Meta (require :playtime.game.meta))
(local Component (require :playtime.component))

(local M (App.scaffold-module {}))

(λ M.start [runtime-config _game-config ?seed_]
  (let [app (App.new {:module M
                      :name "Playtime"
                      :app-id :playtime-menu
                      :view {:width 80 :height 40}
                      :menu [["Playtime" []]]}
                     runtime-config)]
    (table.merge app.components (app:build-components))
    (app.view:open)
    (app:request-tick)
    (app:request-render)
    app))

(fn M.on.app.start-game [app _cofx {: modname : config} _fx]
  (vim.defer_fn #(let [Playtime (require :playtime)]
                   (Playtime.play modname nil config))
                50)
  (app:quit))

(fn build-game-button [width {: row : col} game-meta]
  (fn justify [a b c ?colors]
    (let [max-mid (- width 1 (length a) (length c) 2)
          colors (or ?colors ["@playtime.color.yellow" "@playtime.ui.off" "@playtime.ui.off"])
          mid (string.sub b 1 max-mid)
          fill (string.rep " " (math.max 0 (- max-mid (length mid))))]
      [[a (. colors 1)] [(.. " " mid fill " ") (. colors 2)] [c (. colors 3)]]))
  (let [{: name : desc : authors : categories} game-meta
        rulesets (case game-meta.rulesets
                   ;; build implicit ruleset
                   nil [{:menu name :config {}}]
                   ;; use default meta if none given in ruleset
                   [one-ruleset nil] [{:menu (or one-ruleset.menu name)
                                       :config (or one-ruleset.config {})}]
                   rulesets rulesets)
        lines [(justify name
                        (.. "by " (table.concat authors ", "))
                        (-> categories (table.sort) (table.concat ", "))
                        ["@playtime.color.yellow" "@playtime.ui.off" "@playtime.ui.off"])
               (justify desc "" ""
                        ["@playtime.color.blue" "@playtime.ui.off" "@playtime.ui.off"])]
        _ (fcollect [_i 1 (length rulesets) &into lines] [])
        height (length lines)
        buttons (icollect [i ruleset (ipairs rulesets)]
                  (let [text (.. "Play " ruleset.menu)]
                    (Component.new {:position {:row (+ row 1 i) : col :z 101}
                                    :size {:width (string.col-width text) :height 1}
                                    :content [[[text "@playtime.ui.menu"]]]
                                    :on {:click (fn [_self _cofx event fx]
                                                  (case event
                                                    {:action :release}
                                                    (fx.event.dispatch :app
                                                                       :start-game
                                                                       {:modname game-meta.mod
                                                                        :config ruleset.config})))}})))]
    (Component.new {:size {: width : height}
                    :position {: row : col :z 100}
                    :content lines
                    :children buttons})))

(fn M.build-components [app]
  (let [buttons (accumulate [(bs row) (values [] 2)
                             _i game-meta (ipairs (Meta.all))]
                  (let [button (build-game-button (- app.view.size.width 2)
                                                  {:row row :col 2}
                                                  game-meta)]
                    (values (table.insert bs button)
                            (+ row button.size.height 1))))
        scroll-prompt (let [text "More↓ "
                            pos {:row (- app.view.size.height 1)
                                 :col (/ app.view.size.width 2)
                                 :z 100}]
                        (Component.new {:position pos
                                        :size {:width 100 :height 1}
                                        :content [[[text "@playtime.ui.off"]]]}))]
    {:buttons (Component.new {:children buttons})
     :scroll scroll-prompt }))


M
