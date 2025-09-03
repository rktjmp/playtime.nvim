(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))

(local M {})

(fn M.new [state-machine]
  {:id :interaction-lockout
   :filters []
   :before (fn [self pipeline]
             (fn add-filter [func] (table.insert self.filters func))
             (set pipeline.effects.interaction-lock
                  {:filter add-filter
                   ;; general guess, everything over 800 is uninteractable
                   ;; menubar is 1000+
                   :general-lockout (fn [] (add-filter #(case $1 {:target {:position {: z}}} (< 800 z))))
                   :unlock (fn [] (set self.filters []))})
             (case pipeline.context.event
               {:ns :input &as event} (let [deny? (accumulate [deny? false
                                                               _ filter (ipairs self.filters)
                                                               &until deny?]
                                                    (not (filter event)))]
                                        (when deny?
                                          (set pipeline.queue []))))
             pipeline)})

M
