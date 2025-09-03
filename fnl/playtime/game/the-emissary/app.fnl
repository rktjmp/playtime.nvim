(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local App (require :playtime.app))
(local Component (require :playtime.component))
(local CardComponent (require :playtime.component.card))
(local GameReport (require :playtime.component.game-report))
(local {: State} (require :playtime.app.state-machine))
(local {: Animation :Group AnimationGroup} (require :playtime.app.animation-manager))

(local Logic (require :playtime.game.the-emissary.logic))

(local M (App.scaffold-module {}))

(local DealPhase (State.new {:id :deal-phase}))
(local PickKingdomPhase (State.new {:id :pick-kingdom}))

(local DebateIntermission (State.new {:id :debate-intermission}))
(local DebateRulerTurn (State.new {:id :debate-ruler-turn}))
(local DebateEmissaryTurn (State.new {:id :debate-emissary-turn}))
(local DebateEnded (State.new {:id :debate-ended}))

(local AbilityPolitics (State.new {:id :ability-politics}))
(local AbilityCommerce (State.new {:id :ability-commerce}))
(local AbilityMilitary (State.new {:id :ability-miltary}))
(local AbilityDiplomacy (State.new {:id :ability-diplomacy}))

(fn suit->ability+state [suit]
  (case suit
    :hearts [:diplomacy AbilityDiplomacy]
    :clubs [:military AbilityMilitary]
    :spades [:politics AbilityPolitics]
    :diamonds [:commerce AbilityCommerce]))

(local GameEnded (State.new {:id :game-ended}))

;;;
;;; App Event Handlers
;;;

(fn M.on.app.new-game [app cofx {:seed ?seed :delay ?delay} fx]
  (let [game (Logic.build app.game-config ?seed)]
    (set app.game game)
    (app.clock:reset)
    (app:build-components)
    (app:synchronise-components-to-game-state)
    (set app.components.report nil)
    (fx.state.reset DealPhase)
    ; (fx.event.dispatch-after (or ?delay 1) :app :deal)
    (fx.interaction-lock.general-lockout)
    (fx.engine.tick)
    (fx.engine.render)))

;;;
;;; DealPhase Handlers
;;;
;;; Initial game state, we deal cards then transition to picking a kingdom.
;;;

(fn DealPhase.on.enter [state {: app} event fx]
  (let [(next-game events) (Logic.Action.deal app.game)
        on-complete (fn []
                      (app:synchronise-components-to-game-state)
                      (fx.interaction-lock.unlock)
                      (fx.state.transition PickKingdomPhase)
                      (fx.engine.render))
        animation (app:build-card-animation-from-events events on-complete (length next-game.hand))]
    (set app.game next-game)
    (app.components.score-label:unknown)
    (fx.interaction-lock.general-lockout)
    (fx.animation.play animation)
    (fx.engine.render)))

;;;
;;; PickKingdomPhase Handlers
;;;
;;; Player has hand dealt and must pick which kingdom to challenge.
;;; They may activate advisors *after* picking a kingdom, which automatically
;;; begins the debate afterwards.
;;;

(fn PickKingdomPhase.on.enter [state {: app} event fx]
  (app.components.guide-text:set-text "Select a kingdom to visit...")
  ;; You cannot interact with the advisors or continue until you pick a kingdom
  (app.components.advisor-selector:disable)
  (app.components.continue-button:show)
  (app.components.continue-button:set-state :pick-kingdom)
  (fx.engine.render))

(fn PickKingdomPhase.on.leave [state {: app} event fx]
  ;; We leave this state for an advisor ability or if the player has hit the
  ;; begin debate button. In either case we want to hide the continue button
  ;; and disable advisors.
  (app.components.continue-button:hide)
  (app.components.advisor-selector:disable)
  (fx.engine.render))

(fn PickKingdomPhase.on.app.select-kingdom [state {: app} {: location : component} fx]
  (let [emissary app.components.emissary
        [_ kingdom] location]
    (case (Logic.Action.pick-kingdom app.game kingdom)
      (next-game ?events)
      (do
        (set app.game next-game)
        ;; move emissary to kingdom
        (set emissary.position (app:location->position [:kingdom kingdom :emissary]))
        (set emissary.location location)
        (app.components.score-label:possible kingdom)
        (app.components.guide-text:set-text "Activate an Advisor, enter the court or select another kingdom.")
        ;; You can now activate advisors or begin the debate.
        (app.components.advisor-selector:enable)
        (app.components.continue-button:set-state :enter-the-court)
        (fx.engine.render))
      (nil err) (app:notify err))))

(fn PickKingdomPhase.on.app.select-advisor [state {: app} {: location : component} fx]
  ;; Confirms kingdom, activate advisor then begin debate.
  (let [[_ suit n] location
        [action state] (suit->ability+state suit)]
    (app.components.score-label:actual 0 app.game.at-kingdom)
    (case ((. Logic.Query action) app.game n)
      true (fx.state.transition state {:advisor-n n :next-state DebateRulerTurn})
      (nil err) (app:notify err))))

(fn PickKingdomPhase.on.app.continue [state {: app} event fx]
  ;; Confirms kingdom and begins debate.
  (app.components.score-label:actual 0 app.game.at-kingdom)
  (fx.state.transition DebateRulerTurn))

;;;
;;; Debate Intermission Handlers
;;;
;;; During debates, we may activate an advisor between turn-pairs.
;;; eg ruler -> player -> intermission -> ruler ...
;;; The player may decide do not activate an advisor and continue to the ruler
;;; turn.
;;;

(fn DebateIntermission.on.enter [_state {: app} _event fx]
  (if (Logic.Query.hand-exhausted? app.game)
    (fx.state.transition DebateEnded)
    (do
      (app.components.guide-text:set-text "Activate an Advisor or continue your debate.")
      (app.components.advisor-selector:enable)
      (app.components.continue-button:show)
      (app.components.continue-button:set-state :continue-debate)
      (fx.engine.render))))

(fn DebateIntermission.on.leave [_state {: app} _event fx]
  (app.components.continue-button:hide)
  (app.components.advisor-selector:disable)
  (fx.engine.render))

(fn DebateIntermission.on.app.select-advisor [state {: app} {: location : component} fx]
  (let [[_ suit n] location
        [action state] (suit->ability+state suit)]
    (case ((. Logic.Query action) app.game n)
      true (fx.state.transition state {:advisor-n n :next-state DebateRulerTurn})
      (nil err) (app:notify err))))

(fn DebateIntermission.on.app.continue [state {: app} event fx]
  ;; User elected to not play any advisor, continue to ruler turn
  (fx.state.transition DebateRulerTurn))

;;;
;;; Debate Ended Handlers
;;;
;;; Player exhausted hand, check if game is over or begin a new deal.
;;;

(fn DebateEnded.on.enter [state {: app} event fx]
  (let [(next-game events) (Logic.Action.finish-kingdom app.game)
        on-complete (fn []
                      (app:synchronise-components-to-game-state)
                      (if (Logic.Query.game-ended? app.game)
                        (fx.state.transition GameEnded)
                        (fx.state.transition DealPhase)))
        animation (app:build-card-animation-from-events events on-complete (length next-game.hand))]
    (set app.game next-game)
    (fx.animation.play animation)))

;;;
;;; Debate Ruler Turn Handlers
;;;
;;; We are engaged in debate, its the rulers turn. Simply draw from the deck.
;;;

(fn DebateRulerTurn.on.enter [state {: app} event fx]
  ;; We can actually land here from DebateIntermission + ability, where the
  ;; ability may exhaust the player hand, in which case we should skip the ruler draw
  ;; finish the kingdom.
  (if (Logic.Query.hand-exhausted? app.game)
    (fx.state.transition DebateEnded)
    (do
      (app.components.guide-text:set-text "Ruler is acting..")
      (case (Logic.Action.draw app.game)
        (next-game events) (let [on-complete (fn []
                                               (app:synchronise-components-to-game-state)
                                               (fx.engine.render)
                                               (fx.state.transition DebateEmissaryTurn)
                                               (fx.interaction-lock.unlock))
                                 animation (app:build-card-animation-from-events events on-complete (length next-game.hand))]
                             (set app.game next-game)
                             (fx.interaction-lock.general-lockout)
                             (fx.animation.play animation))
        (nil err) (app:notify err)))))

;;;
;;; Debate Emissary Turn Handlers
;;;
;;; The ruler has drawn a card and we must respond

(fn DebateEmissaryTurn.on.enter [state {: app} event fx]
  (app.components.guide-text:set-text "Choose card to reply...")
  (fx.engine.render))

(fn DebateEmissaryTurn.on.leave [state {: app} event fx]
  (app.components.score-label:actual (length app.game.score)
                                     app.game.at-kingdom)
  (fx.engine.render))

(fn DebateEmissaryTurn.on.app.select-hand [state {: app} {: location : component} fx]
  (let [[_ n] location]
    (case (Logic.Action.play-hand app.game n)
      (next-game events) (let [on-complete (fn []
                                             (app.components.score-label:actual (length next-game.score)
                                                                                next-game.at-kingdom)
                                             (app:synchronise-components-to-game-state)
                                             (fx.engine.render)
                                             (fx.interaction-lock.unlock)
                                             (fx.state.transition DebateIntermission))
                               animation (app:build-card-animation-from-events events on-complete (length next-game.hand))]
                           (set app.game next-game)
                           (fx.interaction-lock.general-lockout)
                           (fx.animation.play animation))
      (nil err) (let [debate-card (accumulate [c nil loc card (Logic.iter-cards app.game) &until c]
                                    (case loc [:debate 1] card))
                      component (app:find-card-component-by-card-id debate-card.id)
                      on-complete (fn []
                                    (app:notify err)
                                    (fx.interaction-lock.unlock))
                      animation (Animation.new
                                  {: component
                                   :apply (fn [component value _percent]
                                            (set component.position.col (math.floor value)))
                                   :property :col
                                   :from component.position.col
                                   :to (+ component.position.col 2)
                                   :ease :oscillate-3-dampend
                                   :duration 300
                                   :delay 0
                                   : on-complete})]
                  (fx.animation.play animation)))))

;;;
;;; Diplomacy Advisor
;;;
;;; Discard all ruler-suit cards from hand
;;;

(fn AbilityDiplomacy.on.enter [{: next-state : advisor-n} {: app} _event fx]
  (app.components.guide-text:set-text "Discarding cards in rulers suit...")
  (let [(next-game events) (Logic.Action.diplomacy app.game advisor-n)
        on-complete (fn []
                      (app:synchronise-components-to-game-state)
                      (fx.interaction-lock.unlock)
                      (fx.state.transition next-state))
        animation (app:build-card-animation-from-events events on-complete (length next-game.hand))]
    (set app.game next-game)
    (fx.animation.play animation)
    (fx.interaction-lock.general-lockout)))

;;;
;;; Military Advisor
;;;
;;; Draw card for every club in hand
;;;

(fn AbilityMilitary.on.enter [{: next-state : advisor-n} {: app} event fx]
  (app.components.guide-text:set-text "Drawing cards for each club in hand...")
  (let [(next-game events) (Logic.Action.military app.game advisor-n)
        on-complete (fn []
                      (app:synchronise-components-to-game-state)
                      (fx.interaction-lock.unlock)
                      (fx.state.transition next-state))
        animation (app:build-card-animation-from-events events on-complete (length next-game.hand))]
    (set app.game next-game)
    (fx.animation.play animation)
    (fx.interaction-lock.general-lockout)))

;;;
;;; Politics Advisor
;;;
;;; Select unvisited kingdom to swap current ruler with.
;;;

(λ AbilityPolitics.on.enter [{: next-state : advisor-n} {: app} event fx]
  (app.components.guide-text:set-text "Select kingdom ruler to swap with current ruler..."))

(fn AbilityPolitics.on.app.select-kingdom [{: next-state : advisor-n} {: app} {: location} fx]
  (let [[_ kingdom-n] location
        (next-game events) (Logic.Action.politics app.game advisor-n kingdom-n)
        on-complete (fn []
                      (app:synchronise-components-to-game-state)
                      (fx.interaction-lock.unlock)
                      (fx.state.transition next-state))
        animation (app:build-card-animation-from-events events on-complete (length next-game.hand))]
    (set app.game next-game)
    (fx.animation.play animation)
    (fx.interaction-lock.general-lockout)))

;;;
;;; Commerce Advisor
;;;
;;; Draw 2 cards, discard 2 cards
;;;

(λ AbilityCommerce.on.enter [{: next-state : advisor-n &as state} {: app} event fx]
  (app.components.guide-text:set-text "Drawing two cards, select two cards to discard...")
  (set state.selection {})
  (let [(next-game events) (Logic.Action.commerce app.game advisor-n)
        on-complete (fn []
                      (app:synchronise-components-to-game-state)
                      (fx.interaction-lock.unlock))
        animation (app:build-card-animation-from-events events on-complete (length next-game.hand))]
    (set app.game next-game)
    (fx.animation.play animation)
    (fx.interaction-lock.general-lockout)))

(fn AbilityCommerce.on.app.select-hand [{: next-state : advisor-n : selection} {: app} {: location : component} fx]
  ;; Toggle selected card-id in selection map. If we have two selected, execute ability.
  (let [{:card {: id}} component
        [_ hand-n] location]
    (case (. selection id)
      nil (do
            (set (. selection id) {: component : hand-n})
            (component:select))
      {: component} (do
                      (component:deselect)
                      (set (. selection id) nil)))
    (case (table.keys selection)
      [first second nil]
      (let [{:component first-component :hand-n first-hand-n} (. selection first)
            {:component second-component :hand-n second-hand-n} (. selection second)]
        (first-component:deselect)
        (second-component:deselect)
        (let [(next-game events) (Logic.Action.commerce app.game advisor-n [first-hand-n second-hand-n])
              on-complete (fn []
                            (app:synchronise-components-to-game-state)
                            (fx.interaction-lock.unlock)
                            (fx.state.transition next-state))
              animation (app:build-card-animation-from-events events on-complete (length next-game.hand))]
          (set app.game next-game)
          (fx.animation.play animation)
          (fx.interaction-lock.general-lockout))))
    (fx.engine.render)))

;;;
;;; Game Ended
;;;

(fn GameEnded.on.enter [state {: app} event fx]
  (let [result (Logic.Query.game-result app.game)
        other-lines [(string.fmt "Score: %d/16" result.score)
                     (string.fmt "Allies: %d/8" result.allies)
                     (string.fmt "Unused Advisors: %d/8" result.unused)
                     (string.format "Time: %s" (app.clock:elapsed-time))]
        result (if
                 (= 16 result.score) :perfect
                 (= 8 result.allies) :win
                 (< result.allies 7) :loss)
        report (GameReport.new {:view-size app.view.size
                                :play-again ["Play Again?" [:app :new-game]]
                                : result
                                :result-lines [[:perfect "Perfect!"]
                                               [:win "You gathered the support of everyone."]
                                               [:loss "Some kingdoms do not support you."]]
                                : other-lines})]
    (set app.components.report report)
    (fx.interaction-lock.general-lockout)
    (fx.engine.render)))

;;;
;;; App functions
;;;

(λ M.start [runtime-config game-config ?seed]
  (let [app (App.new {:module M
                      :name "The Emissary"
                      :app-id :the-emissary
                      :view {:width 83 :height 32}
                      :features {:save-load false}
                      :menu [["The Emissary" [["New Game" [:app :new-game]]]]]}
                     runtime-config)]
    (set app.game-config game-config)
    (app.view:open)
    (app:queue-event :app :new-game (table.merge game-config {:seed ?seed}))
    (app:request-render)
    app))

(λ M.on.app.save [app cofx event fx]
  (app:save :user-save app.game))

(λ M.on.app.load [app cofx event fx]
  (set app.game (app:load :user-save))
  (app:build-components)
  (app:synchronise-components-to-game-state)
  (fx.engine.tick)
  (fx.engine.render))

(λ M.synchronise-components-to-game-state [app]
  (each [location card (Logic.iter-cards app.game)]
    (let [component (app:find-card-component-by-card-id card.id)
          position (app:location->position location)]
      (case card
        {:face :up} (component:flip-face-up)
        {:face :down} (component:flip-face-down))
      (set component.location location)
      (set component.position position)))
  (each [_ label (ipairs app.components.kingdom-win-requirements.children)]
    (case label
      {:location [:kingdom n]} (case (. app.game.kingdom n)
                                 [{:face :down}] (label:lost)
                                 [{:face :up}] (label:available)
                                 [nil] (label:won))))
  app)

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

(fn M.build-components [app]
  (let [emissary (Component.new {:size {:width 2 :height 1}
                                  :position {:row 7 :col 41 :z 500}
                                  :content [[["🮲🮳" "@playtime.ui.on"]]]})
        guide-text (Component.new {:size {:width app.view.size.width :height 1}
                                   :position {:row 13 :col 1 :z 100}
                                   :set-text (fn [self text]
                                               (let [len (length text)
                                                     pad-left (math.floor (/ (- self.size.width len) 2))]
                                                 (set self.position.col pad-left)
                                                 (set self.content [[[text "@playtime.ui.off"]]])))})
        continue-button (let [enter-the-court (Component.new {:size {:width 5 :height 3}
                                                              :position {:row 9 :col 39 :z 200}
                                                              :visible? false
                                                              :content [[["ENTER" "@playtime.ui.on"]]
                                                                        [[" THE " "@playtime.ui.on"]]
                                                                        [["COURT" "@playtime.ui.on"]]]})
                              continue-debate (Component.new {:size {:width 8 :height 2}
                                                              :position {:row 9 :col 37 :z 200}
                                                              :visible? false
                                                              :content [[["CONTINUE" "@playtime.ui.on"]]
                                                                        [[" DEBATE " "@playtime.ui.on"]]]})

                              button (Component.new {:size {:width 39 :height 11} ;; 35
                                                     :position {:row 8 :col 22 :z 300}
                                                     :_continue (fn [self fx]
                                                                  (case self.children
                                                                    [child] (when (or enter-the-court.visible?
                                                                                      continue-debate.visible?)
                                                                              (fx.event.dispatch :app :continue))))
                                                     :on {:click (fn [self cofx event fx]
                                                                   (case event
                                                                     {:button :left :action :release}
                                                                     (self:_continue fx)))
                                                          :drag (fn [self cofx event fx]
                                                                  (case event
                                                                    {:button :left :action :release}
                                                                    (self:_continue fx)))}
                                                     :children [enter-the-court
                                                                continue-debate
                                                                ;; block any card interaction, the hand can be wider
                                                                ;; than the button area we want clickable.
                                                                (Component.new {:size {:width app.view.size.width :height 5}
                                                                                :position {:row 14 :col 2 :z 299}
                                                                                :on {:click #nil :drag #nil}})]
                                                     :set-state (fn [self state]
                                                                  (case state
                                                                    :pick-kingdom (do
                                                                                    (set enter-the-court.visible? false)
                                                                                    (set continue-debate.visible? false))
                                                                    :enter-the-court (do
                                                                                       (set enter-the-court.visible? true)
                                                                                       (set continue-debate.visible? false))
                                                                    :continue-debate (do
                                                                                       (set enter-the-court.visible? false)
                                                                                       (set continue-debate.visible? true))
                                                                    _ (error state)))
                                                     :show (fn [self] (set self.visible? true))
                                                     :hide (fn [self] (set self.visible? false))})]
                          button)
        advisor-selector (Component.new {:size {:width 37 :height 9}
                                         :position {:row 20 :col 23 :z 300}
                                         ;; note, enable hides this element, we
                                         ;; call it 'advisor-selector' but its
                                         ;; actually an interaction block.
                                         ;; Labelling it 'advisor-selector'
                                         ;; makes enable/disable code in states
                                         ;; read more logically.
                                         :enable (fn [self] (set self.visible? false))
                                         :disable (fn [self] (set self.visible? true))
                                         :on {:click #nil :drag #nil}})
        kingdom-win-requirements (fcollect [n 1 8]
                                   (Component.new {:size {:width 3 :height 1}
                                                   :location [:kingdom n]
                                                   :position (doto (app:location->position [:kingdom n :requirement])
                                                               (table.update-in [:row] #(+ $1 4))
                                                               (table.update-in [:col] #(+ $1 2)))
                                                   :update (fn [self hl] (set self.content [[[(string.fmt " %d " n) hl]]]))
                                                   :lost (fn [self] (self:update "@playtime.ui.off"))
                                                   :won (fn [self] (self:update "@playtime.ui.off"))
                                                   :available (fn [self] (self:update "@playtime.ui.on"))
                                                   :content [[[(string.fmt " %d " n) "@playtime.ui.on"]]]}))
        kingdom-win-scores (fcollect [n 1 8]
                             (Component.new {:size {:width 2 :height 1}
                                             :location [:kingdom n]
                                             :position (doto (app:location->position [:kingdom n :score])
                                                         (table.update-in [:row] #(+ $1 2))
                                                         (table.update-in [:col] #(+ $1 2)))
                                             :content [[[(string.fmt "+1" n) "@playtime.color.yellow"]]]}))
        advisor-labels (icollect [suit name (pairs {:hearts :dip. :clubs :mil. :spades :pol. :diamonds :com.})]
                         (Component.new {:size {:width 4 :height 1}
                                         :location [:advisor suit :label]
                                         :position (app:location->position [:advisor suit :label])
                                         :content [[[name "@playtime.ui.off"]]]}))
        score-label (Component.new {:size {:width 3 :height 1}
                                    :position (app:location->position [:score :label])
                                    :unknown (fn [self] (set self.content [[["?/?" "@playtime.ui.off"]]]))
                                    :possible (fn [self want]
                                                (set self.content
                                                     [[[(string.format "?/%d" want) "@playtime.ui.off"]]]))
                                    :actual (fn [self have want]
                                              (let [content (if (= have want)
                                                              [[[(string.format "%d/%d" have want) "@playtime.color.green"]]]
                                                              [[[(string.format "%d/%d" have want) "@playtime.color.red"]]])]
                                                (set self.content content)))
                                    :content [[["?/?" "@playtime.ui.off"]]]})
        cards (icollect [location card (Logic.iter-cards app.game)]
                (let [position (app:location->position location)
                      card-type (case card
                                  (where (or [_ :king] [_ :queen] [_ :jack])) :ruler
                                  _ :regular)
                      stacking-orientation (case card-type
                                             :ruler :vertical
                                             :regular :horizontal)
                      on (case card-type
                           :ruler
                           {:click (fn [self cofx event fx]
                                     (case event
                                       {:action :press :button :left}
                                       (do (self:hover) (fx.engine.render))
                                       {:action :release :button :left}
                                       (do
                                         (self:unhover)
                                         (fx.engine.render)
                                         (case (values self.card.face self.location)
                                           (:up [:kingdom]) (fx.event.dispatch :app :select-kingdom {:location self.location
                                                                                                     :component self})
                                           (:up [:advisor]) (fx.event.dispatch :app :select-advisor {:location self.location
                                                                                                     :component self})))))
                            :drag (fn [self cofx event fx]
                                    (case event
                                      {:action :enter :button :left}
                                      (do (self:hover) (fx.engine.render))
                                      {:action :leave :button :left}
                                      (do (self:unhover) (fx.engine.render))
                                      {:action :release :button :left}
                                      (do
                                        (self:unhover)
                                        (fx.engine.render)
                                        (case (values self.card.face self.location)
                                          (:up [:kingdom]) (fx.event.dispatch :app :select-kingdom {:location self.location
                                                                                                    :component self})
                                          (:up [:advisor]) (fx.event.dispatch :app :select-advisor {:location self.location
                                                                                                    :component self})))))}
                           :regular
                           {:click (fn [self cofx event fx]
                                     (case self.location
                                       [:hand]
                                       (case event
                                         {:action :press :button :left}
                                         (do (self:hover) (fx.engine.render))
                                         {:action :release :button :left}
                                         (do
                                           ;; We intentionally do not call render after deselection
                                           ;; so the card does not wiggle down then up into the debate.
                                           (self:unhover)
                                           (fx.event.dispatch :app :select-hand {:location self.location
                                                                                 :component self})))))
                            :drag (fn [self cofx event fx]
                                    (case self.location
                                      [:hand]
                                      (case event
                                        {:action :enter :button :left}
                                        (do (self:hover) (fx.engine.render))
                                        {:action :leave :button :left}
                                        (do (self:unhover) (fx.engine.render))
                                        {:action :release :button :left}
                                        (do
                                          (self:unhover)
                                          (fx.event.dispatch :app :select-hand {:location self.location
                                                                                :component self})))))})]
                  (CardComponent.card {: stacking-orientation
                                       : on
                                       ;; hover & select are separated as a hack around
                                       ;; "hover selection" for picking a card
                                       ;; and "select 2 selection" for commerce
                                       ;; ability.
                                       :hover (fn [self]
                                                (when (= nil self.__select-row)
                                                  (set self.__hover-row self.position.row)
                                                  (set self.position.row (- self.position.row 1))
                                                  ;; As the card hovers up, we
                                                  ;; may move it up past the
                                                  ;; mouse cursor, so when the
                                                  ;; mouse is released, its
                                                  ;; sitting over the card that
                                                  ;; was behind the hovered
                                                  ;; card.
                                                  ;; We can extend the hover
                                                  ;; card height so we remain
                                                  ;; on it.
                                                  (set self.size.height (+ self.size.height 1))
                                                  (self:invalidate-content-cache)))
                                       :unhover (fn [self]
                                                  (when (and (= nil self.__select-row) self.__hover-row)
                                                    (set self.position.row self.__hover-row)
                                                    (set self.__hover-row nil)
                                                    (set self.size.height (- self.size.height 1))
                                                    (self:invalidate-content-cache)))
                                       :select (fn [self]
                                                 (when (= nil self.__select-row)
                                                   (set self.__select-row self.position.row)
                                                   (set self.position.row (- self.position.row 1))))
                                       :deselect (fn [self]
                                                 (when self.__select-row
                                                   (set self.position.row self.__select-row)
                                                   (set self.__select-row nil)))
                                       :color-count 4
                                       : card : location : position})))
        slots (accumulate [slots [] location count (pairs {:kingdom 8 :draw 1 :discard 1 :score 1})]
                (fcollect [i 1 count &into slots]
                  (CardComponent.slot {:location [location i]
                                       :position (app:location->position [location i 0])})))]
    (table.merge app.components {: emissary
                                 : guide-text
                                 : advisor-selector
                                 : score-label
                                 : continue-button
                                 :advisor-labels (Component.new {:children advisor-labels})
                                 :kingdom-win-requirements (Component.new {:children kingdom-win-requirements})
                                 :kingdom-win-scores (Component.new {:children kingdom-win-scores})
                                 :cards (Component.new {:children cards})
                                 :slots (Component.new {:children slots})
                                 })
    app))


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
                      n (set hand.col (- draw.col (* 2 (- n 1)))))]
    (case location
      [:kingdom n :emissary] {:row (+ kingdom.row 1)
                              :col (- (+ kingdom.col (* card-col-step (- n 1))) 2)
                              :z (+ 101)}
      [:kingdom n ?c] {:row kingdom.row
                      :col (+ kingdom.col (* card-col-step (- n 1)))
                      :z (case ?c
                           0 100 ;; slot
                           :score 102 ;; +1
                           1 103 ;; card
                           :requirement 105 ;; 1-8
                           c (+ 100 c))}
      [:hand n]  {:row hand.row
                  :col (+ hand.col (* 4 (- n 1)))
                  :z (+ 100 n)}
      [:debate c] {:row debate.row
                   :col (case c
                          1 (- debate.col 2)
                          2 (+ debate.col 2)
                          _ 0)
                   :z (+ 200 c)}
      [:discard c] {:row discard.row
                    :col discard.col
                    :z (+ 100 c)}
      [:draw c] {:row discard.row
                 :col discard.col
                 :z (+ 132 c)}
      [:score :label] {:row (+ score.row config.card.height -1)
                      :col (+ score.col config.card.width -4)
                      :z 200}
      [:score c] {:row score.row
                  :col score.col
                  :z (+ 100 c)}
      [:advisor :hearts :label] {:row (- advisor.row 0)
                                 :col (+ advisor.col 1)
                                 :z 101}
      [:advisor :hearts n] {:row (+ advisor.row (* (- n 1) 2))
                            :col advisor.col
                            :z n}

      [:advisor :clubs :label] {:row (- advisor.row 0)
                                :col (+ advisor.col (* 1 card-col-step) 1)
                                :z 101}
      [:advisor :clubs n] {:row (+ advisor.row (* (- n 1) 2))
                           :col (+ advisor.col (* 1 card-col-step))
                           :z n}

      [:advisor :spades :label] {:row (- advisor.row 0)
                                 :col (+ advisor.col 1 (* 2 card-col-step))
                                 :z 101
                                 }
      [:advisor :spades n] {:row (+ advisor.row (* (- n 1) 2))
                            :col (+ advisor.col (* 2 card-col-step))
                            :z n}

      [:advisor :diamonds :label] {:row (- advisor.row 0)
                                   :col (+ advisor.col 1 (* 3 card-col-step))
                                   :z 101}
      [:advisor :diamonds n] {:row (+ advisor.row (* (- n 1) 2))
                              :col (+ advisor.col (* 3 card-col-step))
                              :z n}

      _ (error (Error "Unable to convert location to position, unknown location #{location}" {: location})))))

(fn M.build-card-animation-from-events [app events on-complete ?hand-length]
  (let [{: Animation : Group} (require :playtime.app.animation-manager)
        flip-duration 1
        move-duration 120
        ;; because we have some "fast" moves our delay is not linear to the move index
        ;; so we need to have some state...
        delay-data {:i 0}
        move-delay (fn [dont-increment?]
                     (when (not dont-increment?)
                       (set delay-data.i (+ delay-data.i 1)))
                     (* (- delay-data.i 1) 50))
        flip-delay (fn [i] (+ (move-delay true) (/ move-duration 1)))
        ;; Event locations may include "transient" card locations, eg
        ;; a card is moved from discard -> deck -> hand, but our current state
        ;; only has the card in discard, and the future state has it in hand.
        ;; So we maintain a cache of the location -> cards during the event
        ;; stream so we can resolve transient locations to cards.
        move-location-cache {}
        find-card-by-location (fn [location]
                                (case location
                                  [f c n] (or (?. move-location-cache f c n)
                                              (. app.game f c n))
                                  [f n nil] (or (?. move-location-cache f n)
                                            (. app.game f n))))
        save-card-move-to-cache (fn [card location]
                                  (case location
                                    [f c n] (do
                                              (table.update-in move-location-cache [f] #(or $1 {}))
                                              (table.update-in move-location-cache [f c] #(or $1 {}))
                                              (table.update-in move-location-cache [f c n] #card))
                                    [f n nil] (do
                                              (table.update-in move-location-cache [f] #(or $1 {}))
                                              (table.update-in move-location-cache [f n] #card))))
        _ (fn process-events [events into want-shuffle]
            (case events
              [[:move [:discard] [:draw] &as move] [:face-down [:draw] &as flip] & rest-events]
              (process-events rest-events
                              (doto into
                                (table.insert (doto (clone move) (table.insert :fast)))
                                (table.insert (doto (clone flip) (table.insert :fast))))
                              true)
              [[:move [:score] [:draw] &as move] [:face-down [:draw] &as flip] & rest-events]
              (process-events rest-events
                              (doto into
                                (table.insert move)
                                (table.insert flip))
                              true)
              [event & rest-events]
              (do
                (when want-shuffle
                  (table.insert into [:shuffle]))
                (process-events rest-events (table.insert into event)))
              [nil]
              into))
        events (process-events events [])
        ;; shuffle must wait for all cards to move from score -> draw
        ;; discard->draw are converted to fast, so they take no time.
        shuffle {:delay 0}
        animations (icollect [i event (ipairs events)]
                     (case event
                       (where (or [:face-up location] [:face-down location]))
                       (let [card (find-card-by-location location)
                             component (app:find-card-component-by-card-id card.id)
                             (duration delay) (case event
                                                [_face-up_face-down _location :fast] (values 1 0)
                                                _ (values flip-duration (flip-delay i)))]
                         ; (set shuffle.delay (+ shuffle.delay duration delay))
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
                       (let [card (find-card-by-location from)
                             _ (save-card-move-to-cache card to)
                             component (app:find-card-component-by-card-id card.id)
                             (duration delay) (case event
                                                [:move _from _to :fast] (values 1 0)
                                                _ (values move-duration (move-delay)))
                             {:position {:z default-z}} component]
                         (set shuffle.delay (+ duration delay))
                         (Animation.new
                           {: component
                            :apply (fn [component value percent]
                                     (set component.position {:row (math.ceil value.row)
                                                              :col (math.ceil value.col)
                                                              ;; TODO: deal specific z setting, have two animation fs
                                                              ;; move & deal.
                                                              :z (+ 200 (. (app:location->position to) :z))}))
                            :property :position
                            :from (app:location->position from ?hand-length)
                            :to (app:location->position to ?hand-length)
                            :ease :ease-out-quad
                            : duration
                            : delay}))
                       [:shuffle]
                       ;; Find the top 3 cards in the draw pile and wiggle
                       ;; them. We dont do any moving between discard -> draw
                       ;; and rely on synchronise-components-to-game-state to
                       ;; fix any discrepancy.
                       ;; Since we dont do any moves, we just start at what
                       ;; might be the highest draw card and work down until we
                       ;; have 3.
                       (let [draw-cards (fcollect [i 32 1 -1]
                                          (case (find-card-by-location [:draw i])
                                            card {: card :location [:draw i]}))
                             animations (fcollect [i 1 3]
                                          (let [{: card : location} (. draw-cards i)
                                                ;; The components position when
                                                ;; this code executes is its
                                                ;; original position, so we
                                                ;; need to lookup the future
                                                ;; position after the move as
                                                ;; animated, before the
                                                ;; shuffle.
                                                {: col} (app:location->position location)
                                                component (app:find-card-component-by-card-id card.id)]
                                            (Animation.new
                                              {: component
                                               :apply (fn [component value percent]
                                                        (set component.position.col (math.floor value)))
                                               :property :col
                                               :from col
                                               :to (+ col (math.random 2 (* 2 i)))
                                               :ease :oscillate-3-dampend
                                               :duration (+ 200 (* i 33))
                                               :delay (+ shuffle.delay 120)})))]
                         (AnimationGroup.new {: animations}))
                       [:swap from to]
                       (let [card-1 (find-card-by-location from)
                             card-2 (find-card-by-location to)
                             comp-1 (app:find-card-component-by-card-id card-1.id)
                             comp-2 (app:find-card-component-by-card-id card-2.id)
                             _ (save-card-move-to-cache card-1 to)
                             _ (save-card-move-to-cache card-2 from)
                             {:position {:z default-z}} comp-1
                             ani-1 (Animation.new
                                     {:component comp-1
                                      :apply (fn [component value percent]
                                               (set component.position {:row (math.ceil value.row)
                                                                        :col (math.ceil value.col)
                                                                        ;; TODO: deal specific z setting, have two animation fs
                                                                        ;; move & deal.
                                                                        :z (+ 200 (. (app:location->position to) :z))}))
                                      :property :position
                                      :from (app:location->position from ?hand-length)
                                      :to (app:location->position to ?hand-length)
                                      :ease :ease-out-quad
                                      :duration move-duration
                                      :delay (move-delay)})
                             ani-2 (Animation.new
                                     {:component comp-2
                                      :apply (fn [component value percent]
                                               (set component.position {:row (math.ceil value.row)
                                                                        :col (math.ceil value.col)
                                                                        ;; TODO: deal specific z setting, have two animation fs
                                                                        ;; move & deal.
                                                                        :z (+ 200 (. (app:location->position to) :z))}))
                                      :property :position
                                      :from (app:location->position to ?hand-length)
                                      :to (app:location->position from ?hand-length)
                                      :ease :ease-out-quad
                                      :duration move-duration
                                      :delay (move-delay)})]
                         (Group.new {:animations [ani-1 ani-2]}))))]
    (Group.new {: animations : on-complete})))

M
