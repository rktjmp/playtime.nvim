;; event-event-queue.fnl
(require-macros :playtime.prelude)
(prelude)

(local Id (require :playtime.id))
(local Logger (require :playtime.logger))

(local M {})

(set M.Event {})

(λ M.Event.new [ns name ?details]
  "Create an event with `ns`, `name` and details. Details may be a table,
  which has is merged with `{: ns : name}` or any other value type, stored
  under `{: ns : name : value}`."
  (case (type ?details)
    :table (table.merge {:id (Id.new) : ns : name} ?details
                        (fn [key] (error (<s> "Cannot create event, #{key} key collision."))))
    value {:id (Id.new) : ns : name : value}))

(fn M.new [{: on-enqueued}]
  (setmetatable {: on-enqueued
                 :events []}
                {:__index M}))

(fn M.enqueue [event-queue event]
  "Enqueue `event` into `event-queue`"
  ;; Drag inputs are generated at a higher rate than we'll ever set our tick
  ;; rate, debounce drag events, if the last event was also a drag with the
  ;; same properties, just replace it with the new event.
  (case event-queue
    {:hold list} (table.insert list event)
    _ (let [last-event (table.last event-queue.events)]
        (case (values event last-event)
          ({:ns :input :name :drag : action : button} {:ns :input :name :drag : action : button})
          (tset event-queue.events (length event-queue.events) event)
          _
          (table.insert event-queue.events event))
        ;; notify that an event is waiting
        (event-queue.on-enqueued)))
  event-queue)

(fn M._force-next-immediate-dequeue [event-queue event]
  "Forcibly put given event at the front of the current queue for immediate
  dequeue. This is needed for some events like say focus, where we want it to
  jump queue so other events (eg drag or release) land in the focused
  component."
  (table.insert event-queue.events 1 event)
  event-queue)

(fn M.dequeue [event-queue]
  (table.remove event-queue.events 1))

(fn M.empty? [event-queue]
  (table.empty? event-queue.events))

(fn M.hold-new-events [event-queue]
  (set event-queue.hold [])
  event-queue)

(fn M.release-new-events [event-queue]
  (case event-queue
    {: hold} (do
               (set event-queue.hold nil)
               (each [_ event (ipairs hold)]
                 (event-queue:enqueue event))))
  event-queue)

M
