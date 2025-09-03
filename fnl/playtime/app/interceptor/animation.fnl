(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Id (require :playtime.id))

(local M {})

(fn M.new [animation-manager]
  {:id :animation-manager-interceptor
   :before (fn [self pipeline]
             (set pipeline.effects.animation
                  {:play (fn [animations]
                           (animation-manager:add-animation animations))
                   :fast-forward (fn []
                                    (animation-manager:fast-forward-all))})
             pipeline)})

M
