(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local M {})
(local m {})

(fn M.new []
  {:id :drag
   :dragging? false
   :button nil
   :thing-being-dragged nil
   :last-over nil
   :peek {:timeout nil
          :targets nil
          :button nil}
   :before M.before
   :after M.after})

(fn make-effects [self]
  {:accept
   (fn [component] (set self.thing-being-dragged component))})

(fn M.before [self pipeline]
  (let [{:context {: event}} pipeline]
    (case (m.identify-event self event)
      :peek (m.process-drag-peek self pipeline event)
      :start (m.process-drag-start self pipeline event)
      :expand (m.process-drag-expand self pipeline event)
      :stop (m.process-drag-stop self pipeline event)
      :add-effects (case event
                    {:action :start}
                    (set pipeline.effects.drag
                         {:accept (fn [c] (set self.thing-being-dragged c))})))
    (case event
      (where (or {:ns :input :name :click} {:ns :input :name :drag}))
      (when self.peek.tick (self.peek.tick)))
    pipeline))

(fn m.identify-event [drag-manager event]
  (case event
    ;; Raw drag events from the window are always relevant
    {:ns :input :name :drag :action :raw}
    (case drag-manager.dragging?
      false :start
      true :expand)
    ;; not a raw drag, so we can just add our drag effects
    {:ns :input :name :drag}
    :add-effects
    ;; mouse pressed when not dragging, peek click for possible drag next.
    (where {:ns :input :name :click :action :press}
           (and (not drag-manager.dragging?)))
    :peek
    ;; Mouse releases are relevant if we were dragging with the same button
    (where {:ns :input :name :click :action :release : button}
           (and drag-manager.dragging? (= button drag-manager.button)))
    :stop
    _ false))

(fn m.process-drag-peek [self interceptors event]
  ;; Given the cells,
  ;;
  ;;    --- ---
  ;;   | A | B |
  ;;    --- ---
  ;;
  ;; You may click on the center edge, inside A, then drag into B. Because
  ;; events are only generated as the cursor crosses row/col boundaries, the
  ;; drag event from neovim will be in cell B, but the user *wanted* to drag
  ;; cell A.
  ;;
  ;; To avoid bad-feelings we peek at clicks and track if they had a target.
  ;;
  ;; If the next immediate event we see is a (raw) drag event, we artificially
  ;; target the `drag-start` at the peeked target, then generate a `drag-move`
  ;; into B.
  ;;
  ;; If the original click was on the left edge of A, and the drag is still
  ;; within A, we still do the same thing, as the effect is identical.
  ;;
  ;; Multi-button drag events are kind of screwy, if you left, drag, right;
  ;; left will be "stuck" dragging (in neovim, not here). For now we'll just
  ;; kinda ignore mess like that as it will probably never be something we
  ;; intentionally care about.
  (when (and (not self.dragging?) event.target)
    ;; 2, one tick for peek-event, 1 tick for next event
    (var timeout 2)
    (set self.peek.tick (fn []
                          (set timeout (- timeout 1))
                          (when (= timeout 0)
                            (set self.peek {}))))
    (set self.peek.targets event.targets)
    (set self.peek.button event.button))
  interceptors)

(fn m.process-drag-start [self interceptors event]
  ;; Drag start is the first <LeftDrag> event we get given, as drag.raw. This
  ;; occurs *after* <LeftPressed>, so we do not have to create the mouse down
  ;; event.
  ;;
  ;; We want to create two events for drag start:
  ;;
  ;; - input.drag.start
  ;; - input.drag.inside
  ;;
  ;; input.drag.start is more of a "configuration" event, where the receiver
  ;; can accept the drag event and provide some payload to be dragged, eg: drag
  ;; a card around.
  ;;
  ;; input.drag.inside is more general, that the cursor has dragged at row/col
  ;; inside a component. input.drag.inside will trigger as needed during the
  ;; rest of the drag, i.e. during the drag expand function, so generating one
  ;; here lets components just listen for the drag.inside event if that's all
  ;; they care about.
  ;;
  ;; We split like this because some components will wont actually want to
  ;; "drag" anything, but do want to know if a mouse drags around inside it
  ;; e.g. to put a button into a "primed" state.
  (let [[target &as targets] (case self.peek
                               {: targets} targets
                               _ event.targets)
        new-events [{:ns :input :name :drag
                     :action :start :button event.button
                     :row event.row :col event.col
                     :target target :targets targets}]]
    (set self.button event.button)
    (set self.dragging? true)
    (when target
      (table.insert new-events {:ns :input :name :drag
                                :action :inside :button event.button
                                :row event.row :col event.col
                                :target target :targets targets})
      (set self.last-over target))
    (interceptors.__internal__.queue-events-immediately new-events)
    ;; kill any more processing.
    (set interceptors.queue [])
    interceptors))

(fn filter-targets [targets root]
  (case root
    nil targets
    _ (icollect [_ target (ipairs targets)]
        (if (not (root:in-tree? target))
          target))))

(fn m.process-drag-expand [self interceptors event]
  ;; If we have a historic drag-over, and we are now not dragging over it
  ;; create a drag-leave event.
  ;; If we are over any component, create a drag-enter.
  ;; If we are over the same component, create a drag-over. Also generate a
  ;; drag event for the dragged component
  ;; Note that we ignore any target that matches anything in the currently
  ;; dragged set, as they may or may not be under the cursor during animation.
  ;; We also kill the current event and the rest of the interceptor queue
  ;; to skip to the next event, that we queued.
  (let [;; filter any components we are actually dragging, as they may be
        ;; under the cursor but should not get any enter/leave/inside events.
        drag-over-targets (filter-targets event.targets self.thing-being-dragged)
        [drag-over-target] drag-over-targets
        new-events []]
    ;; We may have a drag mouse event without actually dragging anything, eg
    ;; you can drag on the sweeper grid to update the target square, but
    ;; nothing is actually "dragged".

    (when self.thing-being-dragged
      ;; We have an actual payload that we're dragging around, so send
      ;; that a 'dragged' event.
      (table.insert new-events {:ns :input
                                :name :drag
                                :action :move
                                :button event.button
                                :row event.row
                                :col event.col
                                :target self.thing-being-dragged
                                :targets [self.thing-being-dragged]
                                :over-target drag-over-target
                                :over-targets drag-over-targets}))

    (case (values self.last-over drag-over-target)
      (same same)
      (table.insert new-events {:ns :input
                                :name :drag
                                :action :inside
                                :button event.button
                                :row event.row
                                :col event.col
                                :target drag-over-target
                                :targets drag-over-targets})
      (?was-over ?now-over)
      (do
        (when ?was-over
          (table.insert new-events {:ns :input
                                    :name :drag
                                    :action :leave
                                    :button event.button
                                    :row event.row
                                    :col event.col
                                    :target ?was-over
                                    :targets [?was-over]})
          (set self.last-over nil))
        (when ?now-over
          (table.insert new-events {:ns :input
                                    :name :drag
                                    :action :enter
                                    :button event.button
                                    :row event.row
                                    :col event.col
                                    :target ?now-over
                                    :targets [?now-over]})
          (set self.last-over ?now-over))))
    (interceptors.__internal__.queue-events-immediately new-events)
    (set interceptors.queue [])
    interceptors))

(fn m.process-drag-stop [self interceptors event]
  (let [drag-over-targets (filter-targets event.targets self.thing-being-dragged)
        [drag-over-target] drag-over-targets
        new-events []]
    (when (and drag-over-target self.thing-being-dragged)
      (table.insert new-events {:ns :input
                                :name :drag
                                :action :drop
                                :button event.button
                                :row event.row
                                :col event.col
                                :drag-target self.thing-being-dragged
                                :drag-targets [self.thing-being-dragged]
                                :target drag-over-target
                                :targets drag-over-targets}))
    (when self.thing-being-dragged
      ;; We have an actual payload that we're dragging around, so send
      ;; that component a 'drag.stop' event.
      ;; See also drag.release.
      (table.insert new-events {:ns :input
                                :name :drag
                                :action :stop
                                :button event.button
                                :row event.row
                                :col event.col
                                :drop-target drag-over-target
                                :drop-targets drag-over-targets
                                :target self.thing-being-dragged
                                :targets [self.thing-being-dragged]}))
    ;; we still want the release event, but need to ignore any drag payload
    ;; This is for something that may track drag.enter/drag.leave and wants to
    ;; know if a drag (with or without payload) has "stopped inside" but we
    ;; dont want to use the same event name as what the payload receives.
    ;; So we use "release", analogous to "click.release"
    (table.insert new-events {:ns :input
                              :name :drag
                              :action :release
                              :button event.button
                              :row event.row
                              :col event.col
                              :target drag-over-target
                              :targets drag-over-targets})
    (interceptors.__internal__.queue-events-immediately new-events)
    (set self.dragging? false)
    (set self.button nil)
    (set self.thing-being-dragged nil)
    (set interceptors.queue [])
    interceptors))

M
