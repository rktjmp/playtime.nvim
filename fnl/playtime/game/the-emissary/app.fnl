(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local Animate (require :playtime.animate))
(local Component (require :playtime.component))
(local CommonComponents (require :playtime.common.components))
(local CardComponents (require :playtime.common.card.components))
(local CardUtils (require :playtime.common.card.utils))
(local App (require :playtime.app))
(local Window (require :playtime.app.window))

(local {: api} vim)
(local uv (or vim.loop vim.uv))
(local M (setmetatable {} {:__index App}))
(local Logic (require :playtime.game.the-emissary.logic))

(local AppState {})

(set AppState.Default (App.State.build :Default {:delegate {:app App.State.DefaultAppState}}))

(set AppState.DealPhase (App.State.build :DealPhase {:delegate {:app AppState.Default}}))
(set AppState.PickKingdomPhase (App.State.build :PickKingdomPhase {:delegate {:app AppState.Default}}))

(set AppState.PreparePhase (App.State.build :PreparePhase {:delegate {:app AppState.Default}}))
(set AppState.RulerPhase (App.State.build :RulerPhase {:delegate {:app AppState.Default}}))
(set AppState.RespondPhase (App.State.build :RespondPhase {:delegate {:app AppState.Default}}))
(set AppState.FinishKingdom (App.State.build :FinishKingdom {:delegate {:app AppState.Default}}))
(set AppState.AbilityDiplomacy (App.State.build :AbilityDiplomacy {:delegate {:app AppState.Default}}))
(set AppState.AbilityMilitary (App.State.build :AbilityMilitary {:delegate {:app AppState.Default}}))
(set AppState.AbilityPolitics (App.State.build :AbilityPolitics {:delegate {:app AppState.Default}}))
(set AppState.AbilityCommerce (App.State.build :AbilityCommerce {:delegate {:app AppState.Default}}))
(set AppState.GameEnded (App.State.build :GameEnded {:delegate {:app AppState.Default}}))

(fn AppState.Default.OnEvent.app.new-game [app]
  (app:setup-new-game app.game-config nil)
  (vim.defer_fn #(app:switch-state AppState.DealPhase) 300))

(fn AppState.Default.OnEvent.app.restart-game [app]
  (app:setup-new-game app.game-config app.seed)
  (vim.defer_fn #(app:switch-state AppState.DealPhase) 300))

(fn AppState.Default.OnEvent.input.<LeftMouse> [app [click-location & rest] pos]
  (case click-location
    [:menu idx nil &as menu-item]
    (app:push-state App.State.DefaultInMenuState {: menu-item})))

(fn AppState.GameEnded.activated [app]
  (set app.ended-at (os.time))
  (let [[won? score] (Logic.Query.game-result app.game)
        other [(string.fmt "Time: %ds" (- app.ended-at app.started-at))
               (string.fmt "Score: %d/16" score)]]
    (if won? (app:update-statistics))
    (app.components.game-report:update won? other)))

(fn AppState.GameEnded.OnEvent.input.<LeftMouse> [app [location] pos]
  (case location
    [:menu] (AppState.Default.OnEvent.input.<LeftMouse> app [location] pos)))
;;
;; Diplomacy
;;

(fn AppState.AbilityDiplomacy.activated [app which-advisor]
  (app.components.guide-text:update "Discarding cards in rulers suit...")
  (let [(next-game events) (Logic.Action.diplomacy app.game which-advisor)
        after #(do
                 (app:update-game next-game [:diplomacy which-advisor])
                 (app:switch-state AppState.RulerPhase))
        timeline (app:build-event-animation events after {} (length next-game.hand))]
    (app:switch-state App.State.DefaultAnimatingState timeline)))

;;
;; Military
;;

(fn AppState.AbilityMilitary.activated [app which-advisor]
  (app.components.guide-text:update "Drawing cards for each club in hand...")
  (let [(next-game events) (Logic.Action.military app.game which-advisor)
        after #(do
                 (app:update-game next-game [:military which-advisor])
                 (app:switch-state AppState.RulerPhase))
        timeline (app:build-event-animation events after {} (length next-game.hand))]
    (app:switch-state App.State.DefaultAnimatingState timeline)))

;;
;; Politics
;;

(fn AppState.AbilityPolitics.activated [app which-advisor]
  (app.components.guide-text:update "Select kingdom ruler to swap with current ruler...")
  (set app.state.context {: which-advisor}))

(fn AppState.AbilityPolitics.OnEvent.input.<LeftMouse> [app [location]]
  (set app.state.context.selecting nil)
  (case location
    [:kingdom n 1] (set app.state.context.selecting [:kingdom n])
    [:menu idx nil &as menu-item]
    (app:push-state App.State.DefaultInMenuState {: menu-item})))

(fn AppState.AbilityPolitics.OnEvent.input.<LeftDrag> [app [location]]
  (set app.state.context.selecting nil)
  (case location
    [:kingdom n 1] (set app.state.context.selecting [:kingdom n])))

(fn AppState.AbilityPolitics.OnEvent.input.<LeftRelease> [app [location]]
  (case location
    [:kingdom n 1] (let [{: which-advisor} app.state.context
                         (next-game events) (Logic.Action.politics app.game which-advisor n)
                         after #(do
                                  (app:update-game next-game [:politics which-advisor])
                                  (app:switch-state AppState.RulerPhase))
                         timeline (app:build-event-animation events after {} (length next-game.hand))]
                     (app:switch-state App.State.DefaultAnimatingState timeline))
    _ (set app.state.context.selecting nil)))

;;
;; Commerce
;;

(fn AppState.AbilityCommerce.activated [app which-advisor]
  (app.components.guide-text:update "Drawing two cards, select two cards to discard...")
  (set app.state.context {: which-advisor
                          :selected {:hand []}
                          :selecting nil})
  (let [(next-game events) (Logic.Action.commerce app.game which-advisor)
        after #(do
                 (app:update-game next-game [:commerce which-advisor])
                 (app:pop-state))
        timeline (app:build-event-animation events after {} (length next-game.hand))]
    (app:push-state App.State.DefaultAnimatingState timeline)))

(fn AppState.AbilityCommerce.OnEvent.input.<LeftMouse> [app [location]]
  (set app.state.context.selecting nil)
  (case location
    [:hand n] (set app.state.context.selecting [:hand n])
    [:menu idx nil &as menu-item]
    (app:push-state App.State.DefaultInMenuState {: menu-item})))

(fn AppState.AbilityCommerce.OnEvent.input.<LeftDrag> [app [location]]
  (set app.state.context.selecting nil)
  (case location
    [:hand n] (set app.state.context.selecting [:hand n])))

(fn AppState.AbilityCommerce.OnEvent.input.<LeftRelease> [app [location]]
  (set app.state.context.selecting nil)
  (case location
    [:hand n] (let [{: which-advisor : selected} app.state.context
                    _ (tset selected.hand n (if (nil? (. selected.hand n)) true))
                    ns (table.keys selected.hand)]
                (if (= 2 (length ns))
                  (let [(next-game events) (Logic.Action.commerce app.game which-advisor ns)
                        after #(do
                                 (app:update-game next-game [:commerce which-advisor ns])
                                 (app:switch-state AppState.RulerPhase))
                        timeline (app:build-event-animation events after {} (length next-game.hand))]
                    (app:switch-state App.State.DefaultAnimatingState timeline))))))

;;
;; Deal
;;

(fn AppState.DealPhase.activated [app]
  (app.components.guide-text:update "Select a kingdom to visit...")
  (let [(next-game events) (Logic.Action.deal app.game)
        after #(do
                 (app:update-game next-game [:deal])
                 (app:switch-state AppState.PickKingdomPhase))
        timeline (app:build-event-animation events after {} (length next-game.hand))]
    (app:switch-state App.State.DefaultAnimatingState timeline)))

;;
;; Pick Kingdom
;;

(fn try-ability [app suit n]
  ;; Abilities can be activated when picking a kingdom or in the prepare phase.
  (let [map {:hearts [:diplomacy AppState.AbilityDiplomacy]
             :clubs [:military AppState.AbilityMilitary]
             :spades [:politics AppState.AbilityPolitics]
             :diamonds [:commerce AppState.AbilityCommerce]}
        [action state] (. map suit)]
    (case ((. Logic.Query action) app.game n)
      true (app:switch-state state n)
      (nil err) (app:notify err))))

(fn AppState.PickKingdomPhase.OnEvent.input.<LeftMouse> [app [location] pos]
  (set app.state.context.selecting nil)
  (case location
    [:kingdom n 1] (set app.state.context.selecting [:kingdom n])))

(fn AppState.PickKingdomPhase.OnEvent.input.<LeftDrag> [app [location] pos]
  (set app.state.context.selecting nil)
  (case location
    [:kingdom n 1] (set app.state.context.selecting [:kingdom n])))

(fn AppState.PickKingdomPhase.OnEvent.input.<LeftRelease> [app [location] pos]
  (set app.state.context.selecting nil)
  (case location
    ;; You may swap kingdom until you perform an advisor or draw action
    [:kingdom n _] (case-try
                     (Logic.Action.pick-kingdom app.game n) next-game
                     (let [{: row : col : z} (app:location->position [:kingdom n])]
                       (app.components.emissary:set-position {:row (+ row 1) :col (- col 1) :z (+ z 1)})
                       (app:update-game next-game [:pick-kingdom n]))
                     (catch
                       (nil e) (app:notify e)))
    ;; Otherwise you're committing to a kingdom
    [:draw] (if app.game.at-kingdom (app:switch-state AppState.RulerPhase))
    [:hand] (if app.game.at-kingdom (app:switch-state AppState.RulerPhase))
    [:advisor suit n] (if app.game.at-kingdom (try-ability app suit n))
    [:menu] (AppState.Default.OnEvent.input.<LeftMouse> app [location] pos)))

;;
;; PreparePhase
;;

(fn AppState.PreparePhase.activated [app]
  (app.components.guide-text:update "Activate an ability or click deck/hand for ruler turn"))

(fn AppState.PreparePhase.OnEvent.input.<LeftMouse> [app [location] pos]
  (case location
    [:draw] (app:switch-state AppState.RulerPhase)
    [:hand] (app:switch-state AppState.RulerPhase)
    [:advisor suit n] (try-ability app suit n)
    [:menu] (AppState.Default.OnEvent.input.<LeftMouse> app [location] pos)))

;;
;; RulerPhase
;;

(fn AppState.RulerPhase.activated [app]
  (if (Logic.Query.hand-exhausted? app.game)
    (app:switch-state AppState.FinishKingdom)
    (case-try
      (Logic.Action.draw app.game) (next-game moves)
      (let [after #(do
                     (app:update-game next-game [:draw])
                     (app:switch-state AppState.RespondPhase))
            timeline (app:build-event-animation moves after)]
        (app:switch-state App.State.DefaultAnimatingState timeline))
      (catch
        (nil e) (app:notify e)))))

;;
;; RespondPhase
;;

(fn AppState.RespondPhase.activated [app]
  (app.components.guide-text:update "Select card to respond"))

(fn AppState.RespondPhase.OnEvent.input.<LeftMouse> [app [location] pos]
  ;; since we can click the hand to progress the ruler, we want only
  ;; handle releases when the initial click occured in this state
  (set app.state.context.safe true)
  (set app.state.context.selecting nil)
  (case location
    [:hand n] (set app.state.context.selecting [:hand n])
    [:menu] (AppState.Default.OnEvent.input.<LeftMouse> app [location] pos)))

(fn AppState.RespondPhase.OnEvent.input.<LeftDrag> [app [location] pos]
  (when app.state.context.safe
    (set app.state.context.selecting nil)
    (case location
      [:hand n] (set app.state.context.selecting [:hand n]))))

(fn AppState.RespondPhase.OnEvent.input.<LeftRelease> [app [location] pos]
  (when app.state.context.safe
    (set app.state.context.selecting nil)
    (case location
      [:hand n] (case-try
                  (Logic.Action.play-hand app.game n) (next-game moves)
                  (let [_ (table.insert moves 2 [:wait 300])
                        after #(do
                                 (app:update-game next-game [:play-hand n])
                                 (if (Logic.Query.hand-exhausted? app.game)
                                   (app:switch-state AppState.FinishKingdom)
                                   (app:switch-state AppState.PreparePhase)))
                        timeline (app:build-event-animation moves after {} (length next-game.hand))]
                    (app:switch-state App.State.DefaultAnimatingState timeline))
                  (catch
                    (nil e) (app:notify e)))
      [:advisor] (app:notify "You may only activate a advisor before a ruler statement"))))

(fn AppState.FinishKingdom.activated [app]
  (let [(next-game events) (Logic.Action.finish-kingdom app.game)
        after #(do
                 (app:update-game next-game [:finish-kingdom])
                 (if (Logic.Query.game-ended? app.game)
                   (app:switch-state AppState.GameEnded)
                   (app:switch-state AppState.DealPhase)))
        timeline (app:build-event-animation events after {} (length next-game.hand))]
    (app:switch-state App.State.DefaultAnimatingState timeline)))

;;
;; App
;;

(fn update-card-counts [app]
  (app.components.card-counts.draw:update (length app.game.draw))
  (app.components.card-counts.discard:update (length app.game.discard))
  (app.components.card-counts.score:update (length app.game.score)))

(fn M.build-event-animation [app events after ?opts ?hand-length]
  (if ?hand-length
    (let [proxy (setmetatable {:location->position #(app:location->position $2 ?hand-length)}
                              {:__index app})]
      (CardUtils.build-event-animation proxy events after ?opts))
    (CardUtils.build-event-animation app events after ?opts)))

(fn M.location->position [app location ?hand-length]
  (let [config {:card {:margin {:row 1 :col 1}
                       :width 7 :height 5}}
        card-col-step (+ config.card.width config.card.margin.col 2)
        kingdom {:row 2 :col 3}
        draw {:row 8 :col 38}
        discard {:row 8 :col (- draw.col card-col-step)}
        debate {:row 8 :col draw.col}
        score {:row 8 :col (+ draw.col card-col-step)}
        hand {:row 14 :col 28}
        advisor {:row 20 :col 23}
        hand-offset (case (or ?hand-length (length app.game.hand))
                      0 (set hand.col draw.col)
                      1 (set hand.col draw.col)
                      n (set hand.col (- draw.col (* 2 (- n 1)))))
        ]
    (case location
      [:kingdom n _] {:row kingdom.row
                      :col (+ kingdom.col (* card-col-step (- n 1)))
                      :z (app:z-index-for-layer :cards)}
      [:hand n]  {:row hand.row
                  :col (+ hand.col (* 4 (- n 1)))
                  :z (app:z-index-for-layer :hand n)}
      [:debate c] {:row debate.row
                   :col (case c
                          1 (- debate.col 2)
                          2 (+ debate.col 2)
                          _ 0)
                   :z (app:z-index-for-layer :debate (+ (* 1 10) c))}
      [:discard c] {:row discard.row
                    :col discard.col
                    :z (app:z-index-for-layer :cards c)}
      [:draw c] {:row draw.row
                 :col draw.col
                 :z (app:z-index-for-layer :cards c)}

      [:score c] {:row score.row
                  :col score.col
                  :z (app:z-index-for-layer :cards c)}

      [:advisor :hearts :label] {:row (- advisor.row 0)
                                 :col (+ advisor.col 1)
                                 :z (app:z-index-for-layer :label)}
      [:advisor :hearts n] {:row (+ advisor.row (* (- n 1) 2))
                            :col advisor.col
                            :z n}

      [:advisor :clubs :label] {:row (- advisor.row 0)
                                :col (+ advisor.col (* 1 card-col-step) 1)
                                :z (app:z-index-for-layer :label)}
      [:advisor :clubs n] {:row (+ advisor.row (* (- n 1) 2))
                           :col (+ advisor.col (* 1 card-col-step))
                           :z n}

      [:advisor :spades :label] {:row (- advisor.row 0)
                                 :col (+ advisor.col 1 (* 2 card-col-step))
                                 :z (app:z-index-for-layer :label)}
      [:advisor :spades n] {:row (+ advisor.row (* (- n 1) 2))
                            :col (+ advisor.col (* 2 card-col-step))
                            :z n}

      [:advisor :diamonds :label] {:row (- advisor.row 0)
                                   :col (+ advisor.col 1 (* 3 card-col-step))
                                   :z (app:z-index-for-layer :label)}
      [:advisor :diamonds n] {:row (+ advisor.row (* (- n 1) 2))
                              :col (+ advisor.col (* 3 card-col-step))
                              :z n}

      _ (error (Error "Unable to convert location to position, unknown location #{location}" {: location})))))


(λ M.start [app-config game-config ?seed]
  (let [app (-> (App.build "The Emissary"
                           :the-emissary
                           app-config
                           game-config)
                (setmetatable {:__index M}))
        view (Window.open :the-emissary
                          (App.build-default-window-dispatch-options app)
                          {:width 83
                           :height 32
                           :window-position app-config.window-position
                           :minimise-position app-config.minimise-position})
        _ (table.merge app.z-layers {:cards 25 :kingdom 25 :debate 90 :label 100 :hand 100 :animation 200})]
    (set app.view view)
    (set app.card-style {:width 7 :height 5 :colors 4 :stacking :horizontal-left})
    (app:setup-new-game app.game-config ?seed)
    (app:render)))

(λ M.setup-new-game [app game-config ?seed]
  (app:new-game Logic.build game-config ?seed)
  (app:build-components)
  (app:switch-state AppState.Default)
  (vim.defer_fn #(app:switch-state AppState.DealPhase) 300)
  app)

(λ M.build-components [app]
  (fn build-emissary [position]
    (-> (Component.build)
        (Component.set-content [[["🮲🮳" "@playtime.ui.on"]]])
        (Component.set-size {:width 2 :height 1})
        (Component.set-position {:row 13 :col 41})))
  (fn build-label [text position]
    (let [{: row : col : z} position]
      (-> (Component.build
            (fn [self enabled]
              (let [hl (if enabled "@playtime.ui.on" "@playtime.ui.off")]
                (self:set-content [[[text hl]]]))))
          (Component.set-position position)
          (Component.set-size {:width (length text) :height 1})
          (Component.set-content [[[text "@playtime.ui.off"]]]))))
  (let [card-card-components (collect [location card (Logic.iter-cards app.game)]
                               (let [card-style (if (< 8 (Logic.card-value card))
                                                  (-> (clone app.card-style)
                                                      (table.set :stacking :vertical-down))
                                                  app.card-style)
                                     comp (CardComponents.card #(app:location->position $...)
                                                               location
                                                               card
                                                               card-style)]
                                 (values card.id comp)))
        menubar (CommonComponents.menubar [["The Emissary" [:file]
                                            [["" nil]
                                             ["New Game" [:new-game]]
                                             ["Restart Game" [:restart-game]]
                                             ; ["" nil]
                                             ; ["Undo" [:undo]]
                                             ; ["" nil]
                                             ; ["Save current game" [:save]]
                                             ; ["Load last save" [:load]]
                                             ["" nil]
                                             ["Quit" [:quit]]
                                             ["" nil]
                                             [(string.format "Seed: %s" app.seed) nil]]]]
                                          {:width app.view.width
                                           :z (app:z-index-for-layer :menubar)})
        card-counts (collect [_ key (ipairs [:draw :discard :score])]
                      (values key
                              (CardComponents.count (-> (app:location->position [key 0])
                                                        (table.update-in [:z] #(app:z-index-for-layer :label)))
                                                    app.card-style)))
        win-needed-labels (let [pos (fn [n]
                                      (doto (app:location->position [:kingdom n])
                                        (table.update-in [:row] #(+ $1 4))
                                        (table.update-in [:col] #(+ $1 2))
                                        (table.update-in [:z] #(+ $1 5))))]
                            (fcollect [n 1 8]
                              (build-label (.. " " (tostring n) " ") (pos n))))
        advisors {:hearts :dip. :clubs :mil. :spades :pol. :diamonds :com.}
        advisor-titles (icollect [suit short-name (pairs advisors)]
                        (build-label short-name (app:location->position [:advisor suit :label])))
        empty-fields (accumulate [base [] _ [field count] (ipairs [[:kingdom 8]
                                                                   [:draw 1]
                                                                   [:discard 1]
                                                                   [:score 1]])]
                       (fcollect [i 1 count &into base]
                         (CardComponents.slot #(table.set (app:location->position $...)
                                                          :z (app:z-index-for-layer :base))
                                              [field i 0]
                                              app.card-style)))
        empty-fields (icollect [_ t (ipairs advisors) &into empty-fields]
                       (CardComponents.slot #(table.set (app:location->position $...)
                                                        :z (app:z-index-for-layer :base))
                                            [:advisor t 0]
                                            app.card-style))
        game-report (CommonComponents.game-report app.view.width
                                                app.view.height
                                                (app:z-index-for-layer :report)
                                                [[true "The land is in concord."]
                                                 [false "The land remains fractured."]])
        guide-text (-> (Component.build
                         (fn [self text]
                           (self:set-content [[[text "@playtime.ui.off"]]])
                           (self:set-position {:row 30
                                               :col (math.floor (- (/ app.view.width 2)
                                                                   (/ (length text) 2)))
                                               :z (app:z-index-for-layer :label)})
                           (self:set-size {:width (length text) :height 1})))
                       (: :update "Select a kingdom"))
        win-count (let [{: wins} (app:fetch-statistics)]
                    (CommonComponents.win-count wins
                                                {:width app.view.width
                                                 :z (app:z-index-for-layer :menubar 1)}))
        emissary (build-emissary)]
    (set app.card-id->components card-card-components)
    (table.merge app.components {: empty-fields
                                 : menubar
                                 : emissary
                                 : guide-text
                                 : game-report
                                 : card-counts
                                 : win-count
                                 : win-needed-labels
                                 :cards (table.values card-card-components)
                                 : advisor-titles
                                 })
    (update-card-counts app)))

(fn M.render [app]
  (app.view:render [app.components.empty-fields
                    app.components.advisor-titles
                    app.components.cards
                    app.components.win-needed-labels
                    [app.components.emissary
                     app.components.guide-text
                     app.components.card-counts.discard
                     app.components.card-counts.draw
                     app.components.card-counts.score
                     app.components.game-report
                     app.components.win-count
                     app.components.menubar]])
  app)

(fn M.tick [app]
  (let [now (uv.now)]
    (app:process-next-event)
    (case (. app.state.module.tick)
      f (f app)
      _ (let [adjustment (let [t []]
                           (each [key vals (pairs (or app.state.context.selected []))]
                             (each [i _ (pairs vals)]
                               (table.set t (string.fmt "%s.%s" key i) [key i])))
                           (case app.state.context.selecting
                             [key v] (table.set t (string.fmt "%s.%s" key v) [key v]))
                           ;; key -> values magic to dedup selected + selecting
                           (table.values t))]
          (each [location card (Logic.iter-cards app.game)]
            (let [comp (. app.card-id->components card.id)]
              (comp:update location card)
              (each [_ marked (ipairs adjustment)]
                (case (values location marked)
                  ([f n] [f n]) (comp:set-position {:row (- comp.row 1)})))))))
    (update-card-counts app)
    (app:request-render)))

(λ M.update-statistics [app]
  (fn update [d]
    (let [data (table.merge {:version 1 :wins 0 :games []} d)]
      (set data.wins (+ data.wins 1))
      (set data.games (table.insert data.games
                                    {:seed app.seed
                                     :time (- (or app.ended-at app.started-at) app.started-at)}))
      data))
  (App.update-statistics app update))

M
