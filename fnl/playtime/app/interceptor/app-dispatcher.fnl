(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local M {})

(λ M.new [app]
  "Dispatch events to current application. Normally this is the final
  interceptor, 'last chance' dispatch after components and state. The fallback
  behaviour of ns.name, ns.* then * handler lookup."
  {:id :dispatch-to-app
   :before (fn [self pipeline]
             (let [{:context {: event}} pipeline
                   {: ns : name} event]
               (case (or (?. app :on ns name)
                         (?. app :on ns :*)
                         (?. app :on :*))
                 event-handler (let [flag {:repeat? false}]
                                 (set pipeline.effects.event.continue-propagation #(set flag.repeat? true))
                                 (event-handler app
                                                pipeline.context
                                                event
                                                pipeline.effects)
                                 (set pipeline.effects.event.continue-propagation nil)
                                 (if (not flag.repeat?)
                                   (set pipeline.queue [])))
                 _ (Logger.warn (<s> "Never found handler for #{ns}.#{name} event!"))))
             pipeline)})

M
