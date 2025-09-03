(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local App (require :playtime.app))
(local Component (require :playtime.component))
(local GameReport (require :playtime.component.game-report))
(local {: State} (require :playtime.app.state-machine))
(local {: Animation :Group AnimationGroup} (require :playtime.app.animation-manager))

(local Components (require :playtime.game.set.components))
(local Logic (require :playtime.game.set.logic))

(local M (App.scaffold-module {}))

(local Playing (State.new {:id :playing}))
(local GameEnded (State.new {:id :game-ended}))

(λ Playing.on.enter [state cofx event fx]
  (set state.selection []))

(fn do-deal [action state {: app} event fx]
  (case ((. Logic.Action action) app.game)
    (next-game events) (let [on-complete (fn []
                                           (app:synchronise-components-to-game-state)
                                           (fx.interaction-lock.unlock)
                                           (fx.engine.tick)
                                           (fx.engine.render))
                             deal-animation (app:build-card-animation-from-events events on-complete)
                             duration (accumulate [sum 0 _ animation (ipairs deal-animation.animations)]
                                        (+ sum
                                           (or animation.delay 0)
                                           (or animation.duration 0)))
                             count-anmiation (Animation.new {:ease :linear
                                                             :duration duration
                                                             :component app.components.draw-count
                                                             :from (length app.game.draw)
                                                             :to (length next-game.draw)
                                                             :property :text
                                                             :apply (fn [comp value t]
                                                                      (comp:update-count
                                                                        {:draw (fcollect [_ 1 value] true)}))})]
                         (set app.game next-game)
                         (fx.interaction-lock.general-lockout)
                         (fx.animation.play deal-animation)
                         (fx.animation.play count-anmiation))
    (nil err) (app:notify err)))

(λ Playing.on.app.deal [state cofx event fx]
  (do-deal :deal state cofx event fx))

(λ Playing.on.app.deal-more [state cofx event fx]
  (do-deal :deal-more state cofx event fx))

(λ Playing.on.app.auto-select [state {: app} event fx]
  (case event
    {:action :press}
    (let [[[a b c] _] (Logic.Query.find-sets app.game)
          events (icollect [_ component (ipairs app.components.cards.children)]
                   (case component.location
                     [:deal x] (when (or (= a x) (= b x) (= c x))
                                 component)))]
      (each [i component (ipairs events)]
        (fx.event.dispatch-after (* 120) :app :click-card {:component component
                                                           :card component.card
                                                           :location component.location})))))

(λ Playing.on.app.maybe-deal-more [state {: app} event fx]
  (let [found-sets (Logic.Query.find-sets app.game)
        can-deal? (Logic.Query.can-deal-more? app.game)]
    (case (values can-deal? found-sets)
      (true [nil]) (fx.event.dispatch :app :deal-more)
      (false [nil]) (fx.state.transition GameEnded)
      _ (do
          (fx.interaction-lock.unlock)
          (fx.engine.tick)
          (fx.engine.render)))))

(λ Playing.on.app.click-card [state {: app} {: location : card : component} fx]
  ;; Toggle selection
  (let [[_ deal-index] location]
    (case (. state.selection deal-index)
      nil (do
            (set (. state.selection deal-index) {: component : deal-index})
            (component:select))
      existing (do
                 (set (. state.selection deal-index) nil)
                 (component:deselect))))
  ;; Submit selection at 3
  (let [selected-indexes (table.keys state.selection)]
    (when (= 3 (length selected-indexes))
      (case (Logic.Action.submit-set app.game selected-indexes)
        (next-game events)
        (let [on-complete (fn []
                            (each [_ {: component} (pairs state.selection)]
                              (component:deselect))
                            (set state.selection {})
                            (app:synchronise-components-to-game-state)
                            (fx.event.dispatch :app :maybe-deal-more))
              animation (app:build-card-animation-from-events events on-complete)]
          (set app.game next-game)
          (fx.interaction-lock.general-lockout)
          (fx.animation.play animation))
        (nil err)
        (let [{: Animation : Group} (require :playtime.app.animation-manager)
              animations (icollect [_ {: component} (pairs state.selection)]
                           (Animation.new
                             {: component
                              :apply (fn [component value percent]
                                       (set component.position.col (math.floor value)))
                              :property :col
                              :from component.position.col
                              :to (+ component.position.col 2)
                              :ease :oscillate-3-dampend
                              :duration 300
                              :delay 0}))
              on-complete (fn []
                            (each [_ {: component} (pairs state.selection)]
                              (component:deselect))
                            (set state.selection {})
                            (app:synchronise-components-to-game-state)
                            (fx.interaction-lock.unlock)
                            (fx.engine.tick)
                            (fx.engine.render))]
          (fx.animation.play (Group.new {: animations : on-complete})
          (fx.interaction-lock.general-lockout)
          (app:notify err))))))
  (fx.engine.tick)
  (fx.engine.render))

(fn GameEnded.on.enter [state {: app} event fx]
  (let [result (Logic.Query.game-result app.game)
        top-line-result (case result
                          {:remaining 0} :perfect
                          _ :great-job)
        other-lines [(string.fmt "Sets found: %d" result.sets)
                     (string.fmt "Remaining cards: %d" result.remaining)
                     (string.format "Time: %s" (app.clock:elapsed-time))]
        report (GameReport.new {:view-size app.view.size
                                :play-again ["Play Again?" [:app :new-game]]
                                :result top-line-result
                                :result-lines (case top-line-result
                                                :perfect [[:perfect "Perfect!"]]
                                                :great-job [[:great-job "Great Job!"]])
                                : other-lines})]
    (set app.components.report report)
    (fx.interaction-lock.general-lockout)
    (fx.engine.render)))

(fn M.location->position [app location]
  (let [{:glyph-config {: card-width}} app
        card-height 5
        deal-start-col (+ 4 card-width)
        deal-start-row 2]
    (case location
      [:draw :count] {:row (+ deal-start-row (- card-height 1))
                      :col (- deal-start-col 2 3)
                      :z 500}
      [:draw n] {:row deal-start-row
                 :col (- deal-start-col (+ card-width 2))
                 :z n}
      [:discard :count] {:row (+ deal-start-row card-height -1)
                         :col (+ deal-start-col
                                 (+ 1 (* (- 5 1) (+ card-width 1)))
                                 (- card-width 3))
                         :z 500}
      [:discard n] {:row deal-start-row
                    :col (+ (* (+ card-width 1) 5) 4)
                    :z n}
      [:deal n] (let [row (+ 1 (math.modf (/ (- n 1) 4)))
                      col (+ 1 (% (- n 1) 4))]
                  {:row (+ 2 (* (- row 1) 5))
                   :col (+ deal-start-col (* (- col 1) (+ card-width 1)))
                   :z 1})
      _ (error (Error (<s> "Unable to convert location to position, unknown location #{location}"))))))

(fn M.build-components [app]
  (let [{:glyph-config {: card-width}} app
        cards (icollect [location card (Logic.iter-cards app.game)]
                (let [position (app:location->position location)]
                  (Components.card {: card
                                    : card-width
                                    : location
                                    : position})))
        slots (icollect [_ location (ipairs [[:discard 0] [:draw 0]])]
                (Components.slot {:position (app:location->position location)
                                  : card-width}))
        discard-count (Component.new {:position (app:location->position [:discard :count])
                                      :size {:width 3 :height 1}
                                      :update-count (fn [self game]
                                                      (set self.content
                                                           [[[(string.format "%02d" (/ (length game.discard) 3))
                                                             "@playtime.ui.off"]]]))})
        draw-count (Component.new {:position (app:location->position [:draw :count])
                                   :size {:width 3 :height 1}
                                   :update-count (fn [self game]
                                                      (set self.content
                                                           [[[(string.format "%02d" (length game.draw))
                                                             "@playtime.ui.off"]]]))})
        deal-more-button (let [position (app:location->position [:draw 200])
                               size {:width card-width :height 5}
                               click (fn [self cofx event fx]
                                       (case event
                                         {:button :left :action :press}
                                         (fx.event.dispatch :app :deal-more)))]
                           (Component.new {: position
                                           : size
                                           :on {: click}}))
        discard-trap-button (let [position (app:location->position [:discard 200])
                                  size {:width card-width :height 5}
                                  click (fn [self cofx event fx])]
                              (Component.new {: position
                                              : size
                                              :on {: click}}))]
    (draw-count:update-count app.game)
    (discard-count:update-count app.game)
    (table.merge app.components {: deal-more-button
                                 : discard-trap-button
                                 : discard-count
                                 : draw-count
                                 :slots (Component.new {:children slots})
                                 :cards (Component.new {:children cards})})))

(λ M.synchronise-components-to-game-state [app]
  (set app.components.deal-more-button.visible? (Logic.Query.can-deal-more? app.game))
  (each [location card (Logic.iter-cards app.game)]
    (let [comp (app:find-card-component-by-card-id card.id)
          position (app:location->position location)]
      (case card
        {:face :up} (comp:flip-face-up)
        {:face :down} (comp:flip-face-down))
      (set comp.location location)
      (set comp.position position)))
    (app.components.draw-count:update-count app.game)
    (app.components.discard-count:update-count app.game)
  app)

(λ M.start [runtime-config _game-config ?seed]
  (let [{:game {:set {:font-glyph-width font-glyph-width}}} runtime-config
        view-width (case font-glyph-width
                     :wide 71
                     _ 65)
        glyph-config {:glyph-width font-glyph-width
                      :card-width (case font-glyph-width
                                    :wide 10
                                    _ 9)}
        app (App.new {:module M
                      :name "SET"
                      :app-id :set
                      :view {:width view-width :height 25}
                      :menu [["SET"
                              [["New Game" [:app :new-game]]
                               ["Hint" [:app :hint]]]]]}
                     runtime-config)]
    (set app.glyph-config glyph-config)
    (app.view:open)
    (app:queue-event :app :new-game {:delay 200 :seed ?seed})
    (app:request-tick)
    (app:request-render)
    app))

(λ M.on.app.new-game [app cofx {:seed ?seed :delay ?delay} fx]
  (let [game (Logic.build {} ?seed)]
    (app.clock:reset)
    (set app.game game)
    (app:build-components)
    (set app.components.report nil)
    (fx.state.reset Playing)
    (fx.event.dispatch-after (or ?delay 1) :app :deal)
    (fx.interaction-lock.general-lockout)
    (fx.engine.render)
    (fx.engine.tick)))

(λ M.on.app.hint [app cofx event fx]
  (case (Logic.Query.find-sets app.game)
    [nil] (app:notify "No sets to hint!")
    sets (let [[a-set] (table.shuffle sets)
               logic-hint (Logic.Query.hint-for-set app.game a-set)
               {: same : diff} (accumulate [h {:same [] :diff []}
                                            k v (pairs logic-hint)]
                                 (table.set h v (table.insert (. h v) k)))
               single-hint (case (values same diff)
                             ([nil] _) "everything different"
                             (_ [nil]) "everything identical"
                             (sames diffs) (string.fmt "identical %s and different %s"
                                                       (table.concat sames ", ")
                                                       (table.concat diffs ", ")))
               [verb-1 verb-2 count noun] (case (length sets)
                                            1 [:is :it 1 :set]
                                            n [:are :One n :sets])
               msg (<s> "There #{verb-1} #{count} possible #{noun}. #{verb-2} has #{single-hint}.")]
           (app:notify msg))))

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

(fn M.build-card-animation-from-events [app events on-complete]
  (let [{: Animation : Group} (require :playtime.app.animation-manager)
        flip-duration 1
        move-duration 120
        move-delay (fn [i] (* (- i 1) 50))
        flip-delay (fn [i] (+ (move-delay i) (/ move-duration 1)))
        ;; Event locations may include "transient" card locations, eg
        ;; a card is moved from discard -> deck -> hand, but our current state
        ;; only has the card in discard, and the future state has it in hand.
        ;; So we maintain a cache of the location -> cards during the event
        ;; stream so we can resolve transient locations to cards.
        move-location-cache {}
        find-card-by-location (fn [[f n]]
                                (case (?. move-location-cache f n)
                                  card card
                                  nil (. app.game f n)))
        save-card-move-to-cache (fn [card [f n]]
                                  (case (. move-location-cache f)
                                    nil (set (. move-location-cache f) {}))
                                  (set (. move-location-cache f n) card))
        animations (icollect [i event (ipairs events)]
                     (case event
                       (where (or [:face-up location] [:face-down location]))
                       (let [card (find-card-by-location location)
                             component (app:find-card-component-by-card-id card.id)]
                             (Animation.new
                                    {: component
                                     :apply (fn [component _value percent]
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
                             {:position {:z _default-z}} component]
                             (Animation.new
                                    {: component
                                     :apply (fn [component value _percent]
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
