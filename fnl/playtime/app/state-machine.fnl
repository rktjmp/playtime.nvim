(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))

(local M {})
(local methods {})

(set M.State {})
(λ M.State.new [{: id}]
  {: id :on {:app {} :input {}}})

(fn M.new []
  (setmetatable {:state {:module nil :context nil}}
                {:__index methods}))

(λ methods.transition-interceptor [self]
  (fn attach-effects [interceptor pipeline]
    (set pipeline.effects.state
         {:transition (fn [next-state ?context]
                        (pipeline.effects.event.dispatch-next
                          :state
                          :transition {:target next-state :context ?context}))
          :reset (fn [next-state ?context]
                        (pipeline.effects.event.dispatch-next
                          :state
                          :reset {:target next-state :context ?context}))})
    pipeline)

  (fn handle-event [interceptor pipeline]
    (let [{:context coeffects : effects} pipeline
          {: event} coeffects]
      (case event
        (where {:ns :state : name :target next-state :context ?next-context}
               (or (= name :transition) (= name :reset)))
        (let [{: machine} interceptor]
          (when (= name :transition)
            (case machine.state
              {:module {:on {: leave} &as module} : context}
              (leave context coeffects {} effects)))
          (do
            (set machine.state.module next-state)
            (set machine.state.context (or ?next-context {})))
          (case machine.state
            {:module {:on {: enter} &as module} : context}
            (enter context coeffects {} effects))
          (set pipeline.queue []))
        {:ns :state :target nil :context ?next-context}
        (let [id interceptor.machine.module.id]
          (error "Could not transition state from #{id}, target is nil!")))))

  {:id :state-machine-handle-transitions
   :machine self
   :before (fn [self pipeline]
             (attach-effects self pipeline)
             (handle-event self pipeline)
             pipeline)
   :after (fn [self pipeline] pipeline)})

(λ methods.state-coeffects-interceptor [self]
  {:id :state-machine-state-coeffects
   :machine self
   :before (fn [self pipeline]
             (let [{:machine {:state {: context}}} self]
               (set pipeline.context.state context))
             pipeline)
   :after (fn [self pipeline] pipeline)})

(λ methods.event-dispatch-interceptor [self]
  {:id :state-machine-dispatch-to-state
   :machine self
   :before (fn [self pipeline]
             (let [{:context {: event}} pipeline
                   {: ns : name} event
                   {:machine {:state {: module}}} self
                   flags {:halted? false}]
               (case (or (?. module :on ns name)
                         (?. module :on ns :*)
                         (?. module :on :*))
                 handler (do
                           (set flags.halted? true)
                           (handler self.machine.state.context
                                    pipeline.context
                                    event
                                    pipeline.effects)
                           (when flags.halted?
                             (set pipeline.queue []))))
               pipeline))
   :after (fn [self pipeline] pipeline)})

M
