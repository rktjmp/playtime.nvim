(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local M {})
(local m {})

;; Focus Manager
;;
;; Tracks currently focused component, where focused is an abitrary state as
;; defined by the component.
;;
;; By default, mouse events outside of the focused component will attempt to
;; unfocus any focused component, where the focusec component may refuse to
;; release focus which will cause the original event to be discarded.
;;
;; Any component may capture focus during an event by calling fx.focus.capture.
;;
;; The component in focus may release focus by calling fx.focus.release.
;;
;; The infocus component may refuse to release focus by calling
;; `fx.focus.refuse-release` during a input.focus.release event. By default
;; focus will be released.
;;
;; TODO: Should we support on.focus.capture?
;;
;;    {:on {:click (fn [c ctx event fx]
;;                   (fx.focus.capture c))
;;          :focus (fn [c ctx event fx]
;;                   (case event
;;                     {:action :capture}
;;                     (c:open)
;;                     {:action :release}
;;                     (c:close)))}}
;;
;; Pro: the above is quite nice and encapsulates what happens when we focus/blur
;; Con: *more* events to track/document/remember.

;; TODO: this only works by checking down the tree from thing-in-focus
;; but a menubar has items without a tag for blank spaces. If you click
;; there you wont have any tag, so no target, so its never inside.
;; Solutions: things like menus and popups have extended height/width
;; even if there is no content to put there (must manually fill content)
;;  -- and that only should be extended when open ... hmm.
(fn event-inside-focus? [self pipeline]
  (let [{:context {:event {: target}}} pipeline]
    (and self.focusing? (self.thing-in-focus:in-tree? target))))

(fn make-release-event [self cause]
  [:input
   :focus
   {:action :release
    :target self.thing-in-focus
    :targets [self.thing-in-focus]
    :source cause}])

(fn make-capture-event [self target]
  [:input
   :focus
   {:action :capture
    :target target
    :targets [target]}])

(fn put-intra-event-metadata [self key-event key data]
  ;; save information between events for
  ;; capture-fx->release-event->capture-event chains, etc.
  (set (. self key-event) (or (. self key-event) {}))
  (set (. self key-event key) data))

(fn make-capture-effect [self pipeline]
  (fn capture [component]
    (case (and self.focusing? (not= component self.thing-in-focus))
      ;; capture focus without contest
      false (let [[ns name data] (make-capture-event self component)]
              (pipeline.effects.event.dispatch-next ns name data))
      ;; try release then focus
      true (let [[ns name data] (make-release-event self component)
                 release-event (pipeline.effects.event.dispatch-next ns name data)]
             (put-intra-event-metadata self release-event :then-dispatch-next [:capture component])))
    nil))

(fn make-release-effect [self pipeline]
  (fn release [release-source]
    (case (and self.focusing? self.thing-in-focus)
      false (error (Error "Tried to release focus when not in focus"))
      focused (let [[ns name data] (make-release-event self release-source)]
                (pipeline.effects.event.dispatch-next ns name data)))
    nil))

(fn handle-interaction-event-inside-focus [self pipeline]
  ;; events inside focus just pass through
  pipeline)

(fn handle-interaction-event-outside-focus [self pipeline]
  ;; Setup new event `focus.release` which will trigger any matching handler.
  ;; The handler can call the injected effect `fx.focus.refuse-release` to
  ;; prevent focus loss and the original event will be discarded.
  ;;
  ;; If no handler is found, we will release focus by default and
  ;; redispatch the original event.
  (let [{:context {: event}} pipeline
        [ns name data] (make-release-event self event)
        release-event (pipeline.effects.event.dispatch-next ns name data)]
    (put-intra-event-metadata self release-event :then-dispatch-next [:event event])
    (set pipeline.queue [])
    pipeline))

(fn handle-focus-capture-event [self pipeline]
  (let [{:context {: event}} pipeline]
    (set self.focusing? true)
    (set self.thing-in-focus event.target)
    (set pipeline.queue [])
    pipeline))

(fn handle-focus-release-event [self pipeline]
  ;; This is actually a pre-processor to the event, actual release is done
  ;; after the event is dispatched and the component had an opportunity to
  ;; reject release.
  (let [{:context {: event}} pipeline]
    (put-intra-event-metadata self event :release? true)
    (fn refuse-release []
      (put-intra-event-metadata self event :release? false))
    ;; TODO: Fix non-batched fx for focus.refuse-release?
    ;;
    ;; This must run before we run after, because it flips a flag that we check
    ;; *in* after.
    ;;
    ;; Since we want to default-release, we need some way to trigger that
    ;; effect unless told otherwise.
    ;;
    ;; If we queued the dispatch now and had an effect to cancel it by forcibly
    ;; removing it from the effect queue, it would be queued *after* our
    ;; dispatch, so that wont work.
    ;;
    ;; As the entire side effect is contained to this instance, in this sweep,
    ;; the "badness" is pretty constrained, it's just leaking more purity away.
    (set pipeline.effects.focus {: refuse-release})
    pipeline))

(fn identify-event [self event]
  (case (values self.focusing? event)
    (true {:ns :input :name :click}) :interaction
    ;; TODO: drag interaction may be a bit more complicated. Possibly we just
    ;; want to look for drag-start and otherwise ignore, though that will only
    ;; let us block drag-start, drag-move, drag-stop and drag-drop which are
    ;; eventually spawned from start.
    ;; drag-inside, enter, leave fire even if start never gives a payload.
    ;; Possibly we remove drag-start, just have drag-move drag-drop, where move
    ;; can give a payload at any time and drop then follows. You could give
    ;; some dummy value for a slider drag-handle etc.
    ; (true {:ns :input :name :drag}) :interaction
    (_ {:ns :input :name :focus : action}) action))

(fn before [self pipeline]
  (table.merge pipeline.effects
               {:focus {:capture (make-capture-effect self pipeline)
                        ;; TODO: only associate when has event target is focusd
                        ;;       or at least self.focusing? = true?
                        :release (make-release-effect self pipeline)}})
  (let [{:context {: event}} pipeline]
    (case (identify-event self event)
      :capture (handle-focus-capture-event self pipeline)
      :release (handle-focus-release-event self pipeline)
      :interaction (if (event-inside-focus? self pipeline)
                     (handle-interaction-event-inside-focus self pipeline)
                     (handle-interaction-event-outside-focus self pipeline)))
    pipeline))

(fn after [self pipeline]
  (let [{:context {: event}} pipeline]
    (case (. self event)
      {:release? true :then-dispatch-next ?next-event}
      (do
        (set self.focusing? false)
        (set self.thing-in-focus nil)
        (case ?next-event
          [:event event] (pipeline.effects.event.dispatch-next event)
          [:capture comp] (let [[ns name data] (make-capture-event self comp)]
                            (pipeline.effects.event.dispatch-next ns name data)))
        (set (. self event) nil))
      {:release? false}
      (set (. self event) nil))
    pipeline))

(fn M.new []
  ;; TODO: use stacked focus in focus-manager so you can push-pop for better control.
  {:id :focus
   :focusing? false
   :thing-in-focus nil
   : before
   : after})

M
