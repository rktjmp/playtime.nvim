(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Id (require :playtime.id))

(local M {})

(fn M.new [state-machine]
  ;; a component, but don't want to apply the mouse-up behaviour on the initial
  ;; down event. So we add a group-id to events that belong to the same uh,
  ;; group or gesture, so you can see if a mouse-up is from the same mouse-down
  ;; or not.
  {:id :input-group-id
   :current-group {:left nil :right nil}
   :before (fn [self pipeline]
             (let [{:context {: event}} pipeline]
               (case event
                 {:ns :input :name :click :action :press}
                 (let [id (Id.new)]
                   (set (. self.current-group event.button) id)
                   (set event.group-id id))
                 (where (or {:ns :input :name :click}
                            {:ns :input :name :drag}))
                 (let [id (. self.current-group event.button)]
                   (set event.group-id id))))
             pipeline)})

M
