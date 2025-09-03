(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local M {})
(local m {})

(fn M.new []
  "Dispatch events to components"
  {:id :dispatch-to-component
   :before (fn [self pipeline]
             (let [{:context {: event : app}} pipeline
                   {: target : ns : name} event]
               (case (?. target :on name)
                 event-handler (let [flag {:repeat? false}]
                                 (set pipeline.effects.event.continue-propagation #(set flag.repeat? true))
                                 (event-handler target
                                                pipeline.context
                                                event
                                                pipeline.effects)
                                 (set pipeline.effects.event.continue-propagation nil)
                                 (if (not flag.repeat?)
                                   (set pipeline.queue [])))))
             pipeline)})

M
