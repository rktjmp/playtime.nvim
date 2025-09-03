(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local App (require :playtime.app))
(local Logic (require :playtime.game.hearts.logic))
(local Agent (require :playtime.game.hearts.agent))
(local Components (require :playtime.game.hearts.components))
(local GameReport (require :playtime.component.game-report))
(local {: State} (require :playtime.app.state-machine))
(local Component (require :playtime.component))
(local CardComponent (require :playtime.component.card))
(local {: Animation :Group AnimationGroup} (require :playtime.app.animation-manager))

; (λ _G.summark-print []
;   (let [data (icollect [name {: calls : time-ns} (pairs _G.summark)]
;                (let [time-ms (/ time-ns 1_000_000)
;                      avg-ms (/ time-ms calls)]
;                  [name {: calls : time-ns : time-ms : avg-ms}]))
;
;         by-name (fn [[name-a] [name-b]] (< name-a name-b))
;         by-time (fn [[_ {:time-ms a}] [_ {:time-ms b}]] (> a b))
;         data (table.sort data by-name)
;         lengths (accumulate [l {:name 0 :time 0 :calls 0 :avg 0} _ [name {: time-ms : avg-ms : calls}] (ipairs data)]
;                   {:name (math.max l.name (length name))
;                    :time (math.max l.time (length (.. "" time-ms)))
;                    :avg (math.max l.avg (length (.. "" avg-ms)))
;                    :calls (math.max l.calls (length (.. "" calls)))})
;         fmt-string (string.format "%%%ds | %%%ds | %%-%ds | %%%ds"
;                                   lengths.calls lengths.time lengths.name lengths.avg)
;         out (icollect [_ [name {: time-ms : calls : avg-ms}] (ipairs data)]
;               (string.format fmt-string calls time-ms name avg-ms))]
;     (Logger.info (table.concat (table.join ["DATA"] out) "\n"))))

(local GUIDE-TEXT
  {:pass {:clockwise "Select 3 cards to pass ⭦  clockwise."
          :counter-clockwise "Select 3 cards to pass ⭧  counter-clockwise."
          :across "Select 3 cards to pass ⭥  across."
          :none "No passing this round."}
   :play {:first "You must play the 2 of ♣ clubs into the first trick."
          :lead "Play any valid card."
          :hearts "Lead suit is ♥ hearts."
          :clubs "Lead suit is ♣ clubs."
          :diamonds "Lead suit is ♦ diamonds."
          :spades "Lead suit is ♠ spades."}
   :wait {1 "Waiting for George..."
          2 "Waiting for Frank..."
          3 "Waiting for Cosmo..."
          4 "Waiting for Estelle..."}})

;; New Deal -> PassPhase -> *Turn -> ResolveTrick -> *Turn -> ResolveRound -> NewDeal|GameEnded
(local NewDeal (State.new {:id :new-deal}))
(local PassPhase (State.new {:id :pass-phase}))
(local PlayerTurn (State.new {:id :player-turn-phase}))
(local AgentTurn (State.new {:id :agent-turn-phase}))
(local ResolveTrick (State.new {:id :resolve-trick}))
(local ResolveRound (State.new {:id :resolve-round}))
(local GameEnded (State.new {:id :game-ended}))

(local M (App.scaffold-module {}))

(fn state-for-next-player [state]
  (case (Logic.Query.current-player state)
    ; 1 PlayerTurn
    _ AgentTurn))

(λ NewDeal.on.enter [state {: app} event fx]
  (let [(next-game) (Logic.Action.prepare-deal app.game)
        _ (set app.game next-game)
        _ (app:synchronise-components-to-game-state)
        (next-game events) (Logic.Action.deal app.game)
        on-complete (fn []
                      (app:synchronise-components-to-game-state)
                      (fx.state.transition PassPhase)
                      (fx.engine.render))
        animation (app:build-card-animation-from-events events on-complete [13 13 13 13])]
    (app.components.guide-text:set-text "Await in suspense...")
    (set app.game next-game)
    (each [_ agent (ipairs app.agents)]
      (agent:observe-event app.game [:new-deal]))
    (fx.interaction-lock.general-lockout)
    (fx.animation.play animation)))

(λ PassPhase.on.enter [state {: app} event fx]
  (let [text (. GUIDE-TEXT.pass (Logic.Query.pass-style app.game))]
    (app.components.guide-text:set-text text))
  (set app.game (faccumulate [game app.game player 2 4]
                  (let [action (Logic.Action.debug-generate-random-action game player)
                        [action player-n indexes] action]
                    ((. Logic.Action action) game player-n indexes))))
  (case (Logic.Query.pass-style app.game)
    ;; Simpler to just automatically "pass" some cards, but with no effect than
    ;; to have a separate state flow.
    :none (let [next-game (Logic.Action.pass-cards app.game 1 [1 2 3])]
            (set app.game next-game)
            (fx.state.transition (state-for-next-player app.game)))
    _ (do
        (set state.selection {})
        (fx.interaction-lock.unlock)
        (fx.engine.render))))

(λ PassPhase.on.app.select-hand [{: selection} {: app} {: location : component} fx]
  (assert (match? location [:hand 1 _] ) "can only select hand for player")
  (let [{:card {: id}} component
        [_hand _1 hand-n] location]
    (case (. selection id)
      nil (do
            (set (. selection id) {: component : hand-n})
            (component:select))
      {: component} (do
                      (component:deselect)
                      (set (. selection id) nil)))
    (case (table.keys selection)
      [first second third nil]
      (let [hand-indexes (icollect [k {: hand-n} (pairs selection)] hand-n)]
        (icollect [k {: component} (pairs selection)] (component:deselect))
        (let [(next-game events) (Logic.Action.pass-cards app.game 1 hand-indexes)
              on-complete (fn []
                            (app:synchronise-components-to-game-state)
                            (fx.engine.render)
                            (fx.interaction-lock.unlock)
                            (fx.state.transition (state-for-next-player app.game)))
              animation (app:build-card-animation-from-events events on-complete)]
          (set app.game next-game)
          (fx.animation.play animation)
          (fx.interaction-lock.general-lockout))))
    (fx.engine.render)))

(λ PlayerTurn.on.enter [state {: app} event fx]
  (let [text (case (Logic.Query.lead-suit app.game)
               suit (. GUIDE-TEXT.play suit)
               nil (if (Logic.Query.first-trick-in-round? app.game)
                     GUIDE-TEXT.play.first
                     GUIDE-TEXT.play.lead))]
    (app.components.guide-text:set-text text)
    (when (Logic.Query.first-card-in-trick? app.game)
      (app.components.leader-indicator:set-leader 1)
      (set app.components.leader-indicator.visible? true))
    (fx.interaction-lock.unlock)
    (fx.engine.render)))

(λ PlayerTurn.on.app.select-hand [state {: app} {: location : component} fx]
  (assert (match? location [:hand 1]) "can only select from player hand")
  (let [[_hand _1 index] location]
    (case (Logic.Action.play-card app.game 1 index)
      (next-game events) (let [on-complete (fn []
                                             (app:synchronise-components-to-game-state)
                                             (fx.engine.render)
                                             (fx.interaction-lock.unlock)
                                             (if (Logic.Query.trick-ended? app.game)
                                               (fx.state.transition ResolveTrick)
                                               (fx.state.transition AgentTurn)))
                               animation (app:build-card-animation-from-events events on-complete)]
                           (when (Logic.Query.first-card-in-trick? app.game)
                             (app.components.leader-indicator:set-leader 1)
                             (set app.components.leader-indicator.visible? true))
                           (set app.game next-game)
                           (each [_ agent (ipairs app.agents)]
                             (agent:observe-event app.game [:play-card 1 index]))
                           (fx.animation.play animation)
                           (fx.interaction-lock.general-lockout))
      (nil err) (do
                  (component:deselect)
                  (fx.engine.render)
                  (app:notify err)))))

(λ AgentTurn.on.enter [state {: app} event fx]
  (let [text (. GUIDE-TEXT.wait (Logic.Query.current-player app.game))]
    (app.components.guide-text:set-text text))
  (let [current-player (Logic.Query.current-player app.game)]
    (when (Logic.Query.first-card-in-trick? app.game)
      (app.components.leader-indicator:set-leader current-player)
      (set app.components.leader-indicator.visible? true)))
  (fx.interaction-lock.general-lockout)
  (fx.engine.render)
  ;; start agent thinking
  ;; queue stop thinking event
  (fx.event.dispatch-after (math.random 30 50) :app :agent-stop)
  )

(λ AgentTurn.on.app.agent-stop [state {: app} event fx]
  (let [current-player (Logic.Query.current-player app.game)
        agent (. app.agents current-player)
        action (agent:select-action app.game)
        [action-fn & action-args] action
        (next-game events) ((. Logic.Action action-fn) app.game (table.unpack action-args))
        on-complete (fn []
                      (case (Logic.Query.current-player app.game)
                        nil (fx.state.transition ResolveTrick)
                        _ (fx.state.transition (state-for-next-player app.game)))
                      (app:synchronise-components-to-game-state)
                      (fx.engine.render))
        animation (app:build-card-animation-from-events events on-complete)]
    (set app.game next-game)
    (each [_ agent (ipairs app.agents)]
      (agent:observe-event app.game action))
    (fx.animation.play animation)
    (fx.interaction-lock.general-lockout)))

(λ ResolveTrick.on.enter [state {: app} event fx]
  (app:synchronise-components-to-game-state)
  (fx.event.dispatch-after 10 :app :resolve-trick)
  (fx.interaction-lock.general-lockout)
  (fx.engine.render))

(λ ResolveTrick.on.app.resolve-trick [state {: app} event fx]
  (let [(next-game events) (Logic.Action.resolve-trick app.game)
        on-complete (fn []
                      (app:synchronise-components-to-game-state)
                      (if (Logic.Query.round-ended? app.game)
                        (fx.state.transition ResolveRound)
                        (fx.state.transition (state-for-next-player app.game)))
                      (fx.engine.render))
        animation (app:build-card-animation-from-events events on-complete)]
    (set app.game next-game)
    (fx.animation.play animation)
    (fx.interaction-lock.general-lockout)))

(λ ResolveRound.on.enter [state {: app} event fx]
  ;; Update score board
  (if (and false (Logic.Query.game-ended? app.game))
    (do)
    (let [(next-game _events) (Logic.Action.resolve-round app.game)]
      ;; update scoreboard
      (set app.game next-game)
      (fx.state.transition NewDeal))))

(λ M.build-card-animation-from-events [app events on-complete ?hand-sizes]
  ;; since the app.game in hearts is a more opaque struct than normal, we can't
  ;; just reach in and grab cards at a given location, we can create a lookup
  ;; table though.
  (let [location-key #(table.concat $1 ".")
        location->card-id-lookup (collect [location card (Logic.iter-cards app.game)]
                                   (values (location-key location) card.id))
        get-component-at-location (fn [location]
                                    (-> (. location->card-id-lookup (location-key location))
                                        (app:find-card-component-by-card-id)))
        flip-duration 1
        move-duration 180
        animations (icollect [i event (ipairs events)]
                     (case event
                       (where (or [:face-up location] [:face-down location]))
                       (let [component (get-component-at-location location)]
                         (Animation.new
                           {: component
                            :apply (fn [component value t]
                                     (when (<= 1 t)
                                       (case event
                                         [:face-up] (component:flip-face-up)
                                         [:face-down] (component:flip-face-down))))
                            :property :visible-face
                            :from 0
                            :to 1
                            :ease :linear
                            :duration flip-duration
                            :delay 10}))
                       (where [:move from to])
                       (let [component (get-component-at-location from)
                             {:position {:z default-z}} component]
                         (case (values from to)
                           (where (or ([:hand] [:trick])
                                      ([:draw] [:hand])))
                           (do
                             ;; hand->trick has a flip [trick ...] event so we need
                             ;; to be able to find the trick card later. but doing
                             ;; this lookup manipulation will break passing cards.
                             (set (. location->card-id-lookup (location-key from)) nil)
                             (set (. location->card-id-lookup (location-key to)) component.card.id)))
                         (Animation.new
                           {: component
                            :apply (fn [component value percent]
                                     (set component.position {:row (math.ceil value.row)
                                                              :col (math.ceil value.col)
                                                              ;; TODO: deal specific z setting, have two animation fs
                                                              ;; move & deal.
                                                              :z (+ 200 (. (app:location->position to ?hand-sizes) :z))}))
                            :property :position
                            :from (app:location->position from ?hand-sizes)
                            :to (app:location->position to ?hand-sizes)
                            :ease :ease-out-quad
                            :duration move-duration
                            :delay (* i 30)}))
                       _ (error (%s "unknown animation event #{event}"))))]
    (AnimationGroup.new {: animations : on-complete})))

(λ M.start [runtime-config game-config ?seed]
  (let [app (App.new {:module M
                      :name "Hearts"
                      :app-id :hearts
                      :view {:width 59 :height 40}
                      :menu [["Hearts"]]}
                     runtime-config)]
    (set app.game-config game-config)
    (app.view:open)
    (app:queue-event :app :new-game (table.merge game-config {:seed ?seed}))
    app))

(λ M.on.app.new-game [app cofx {:seed ?seed} fx]
  (let [game (Logic.build {} ?seed)
        agents (fcollect [player 1 4]
                 ;; player 1 is the human player, so agent-1 is never
                 ;; actually used, but adding a non-nil 1 value makes
                 ;; iteration simpler.
                 (Agent.new player))]
    (summark-reset)
    (set app.game game)
    (set app.agents agents)
    (app.clock:reset)
    (app:build-components)
    (set app.components.report nil)
    (app:synchronise-components-to-game-state)
    (fx.state.reset NewDeal)
    (fx.interaction-lock.general-lockout)
    (app:request-tick)
    (app:request-render)))

(λ M.build-components [app]
  (let [cards (icollect [location card (Logic.iter-cards app.game)]
                (let [position (app:location->position location)]
                  (CardComponent.card {:stacking-orientation :horizontal
                                       : location
                                       : position
                                       : card
                                       :on {:click (fn [self cofx event fx]
                                                     (case self.location
                                                       [:hand 1]
                                                       (case event
                                                         {:action :press :button :left}
                                                         (do (self:hover) (fx.engine.render))
                                                         {:action :release :button :left}
                                                         (do
                                                           ;; We intentionally do not call render after deselection
                                                           ;; so the card does not wiggle.
                                                           (self:unhover)
                                                           (fx.event.dispatch :app :select-hand {:location self.location
                                                                                                 :component self})))))
                                            :drag (fn [self cofx event fx]
                                                    (case self.location
                                                      [:hand 1]
                                                      (case event
                                                        {:action :enter :button :left}
                                                        (do (self:hover) (fx.engine.render))
                                                        {:action :leave :button :left}
                                                        (do (self:unhover) (fx.engine.render))
                                                        {:action :release :button :left}
                                                        (do
                                                          (self:unhover)
                                                          (fx.event.dispatch :app :select-hand {:location self.location
                                                                                                :component self})))))}
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
                                       :color-count 4})))
        score-tags (Component.new
                     {:children (fcollect [i 1 4]
                                  (Components.round-score
                                    {:position (app:location->position [:score-tag i])}))})
        hand (app:location->position [:hand 1 1])
        score-board (Components.score-board {:size {:width app.view.size.width :height 1}
                                             ;; note z is high to hide player cards underneath
                                             :position {:row (+ hand.row 7) :col 4 :z 200}})

        leader-indicator (Components.leader-indicator
                           (fcollect [i 1 4] (app:location->position [:trick i 1])))
        guide-text (let [hand (app:location->position [:hand 1 1])]
                     (Components.guide-text {:size {:width app.view.size.width :height 1}
                                             :position {:row (+ hand.row 5) :col 1 :z 100}}))]
    (set leader-indicator.visible? false)
    (table.merge app.components {: guide-text
                                 : score-tags
                                 : leader-indicator
                                 : score-board
                                 :cards (Component.new {:children cards})})))

(λ M.synchronise-components-to-game-state [app]
  (each [location card (Logic.iter-cards app.game)]
    (let [comp (app:find-card-component-by-card-id card.id)
          position (app:location->position location)]
      (case card
        {:face :up} (comp:flip-face-up)
        {:face :down} (comp:flip-face-down))
      (set comp.location location)
      (set comp.position position)))

  ;; Note: score-match does not include current round, so we need to manually
  ;; insert that if enabled.
  ;; TODO: dont update the "current round" if game is over
  (let [(totals by-round) (Logic.Query.score-match app.game)
        ;; append blank current round
        _ (table.insert by-round [:- :- :- :-])]
    (app.components.score-board:update-content totals by-round))

  ;; "in-round score"
  (each [i comp (ipairs app.components.score-tags.children)]
    (comp:update-content (Logic.Query.held-point-cards app.game i)
                         (case i
                           1 :line
                           2 :left
                           3 :line
                           4 :right)))
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

(λ M.location->position [app location ?hand-sizes]
  ;; for centering maths to work, view width should be an odd number so we have
  ;; a definite "center cell", then since our cards are odd-width'd too, we can
  ;; center both on the same cell.
  (let [hand-sizes (or ?hand-sizes (fcollect [i 1 4] (Logic.Query.hand-size app.game i)))
        view-center-col (math.ceil (/ app.view.size.width 2))
        view-center-row (math.ceil (/ app.view.size.height 2))
        center-card-col (- view-center-col (math.ceil (/ 7 2)))
        center-card-row (- view-center-row (math.ceil (/ 5 2)) 4)]
    (case location
      ;; Player is always player 1, so always at bottom of screen
      ;; then we go clockwise around.
      ;; Centering maths is a little weird, our cards are 7ch wide, but we
      ;; overlap them in hand, so a set of 3 cards will "compress" into 2*3 + 7
      ;; as the last card is shown in full.
      ;; Get the total width of the hand, then split it in half, subtract that
      ;; half from the view center col for the hand start, then just lay left
      ;; to right.
      ;; We also have N E S W players, so two players hands are vertical, two
      ;; are horizontal.
      [:hand p n] (if (math.odd? p)
                    ;; horizontal
                    (let [hand-span (+ (* (- (. hand-sizes p) 1) 3) 7)
                          start-col (- view-center-col (math.ceil (/ hand-span 2)))
                          col (+ start-col (* (- n 1) 3))
                          row (case p 1 24 3 2)
                          z (+ (case p 1 150 _ 100) n)]
                      {: row : col : z})
                    ;; vertical
                    (let [hand-span (+ (* (- (. hand-sizes p) 1) 1) 7)
                          start-row (- (- view-center-row (math.ceil (/ hand-span 2))) 3)
                          row (+ start-row (* (- n 1) 1))
                          col (case p 2 2 4 50)
                          z (+ 100 n)]
                      {: row : col : z}))
      ;; similarly tricks are south west north east
      [:trick 1 n] {:row (+ center-card-row 5) :col center-card-col :z 101}
      [:trick 2 n] {:row center-card-row :col (- center-card-col 8) :z 101}
      [:trick 3 n] {:row (- center-card-row 5)  :col center-card-col :z 101}
      [:trick 4 n] {:row center-card-row :col (+ center-card-col 8) :z 101}
      ;; collected cards during the round, per player
      ; [:round 1 n] {:row (+ center-card-row 6) :col (- center-card-col 9) :z (+ 101 n)}
      ; [:round 2 n] {:row (- center-card-row 4) :col (- center-card-col 16) :z (+ 101 n)}
      ; [:round 3 n] {:row (- center-card-row 6) :col (+ center-card-col 9) :z (+ 101 n)}
      ; [:round 4 n] {:row (+ center-card-row 4) :col (+ center-card-col 16) :z (+ 101 n)}
      [:round 1 n] {:row (+ 24 8) :col center-card-col :z (+ 101 n)}
      [:round 2 n] {:row center-card-row :col -7 :z (+ 101 n)}
      [:round 3 n] {:row -8 :col center-card-col :z (+ 101 n)}
      [:round 4 n] {:row center-card-row :col (+ app.view.size.width 7) :z (+ 101 n)}
      ;; draw disappears after play, so its in the center
      [:draw 1 n] {:row center-card-row :col center-card-col :z (+ 100 n)}
      [:score-tag 1] {:row 23 :col center-card-col :z 80}
      [:score-tag 2] {:row center-card-row :col (- center-card-col 16) :z 80}
      [:score-tag 3] {:row (- center-card-row 6) :col center-card-col :z 80}
      [:score-tag 4] {:row center-card-row :col (+ center-card-col 20) :z 80}
      _ (error (<s> "unknown location #{location}"))
      )))

M
