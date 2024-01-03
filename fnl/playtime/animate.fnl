(require-macros :playtime.prelude)
(prelude)

(local M {})
(local uv (or vim.loop vim.uv))

(λ M.timeline [config]
  (let [(animations after-start-at) (accumulate [(animations max-finish-at) (values [] -1)
                                                 delay spec (pairs config)]
                                      (if (type.number? delay)
                                        (let [[f duration tick] spec
                                              ani (f (+ (uv.now) delay) duration tick)]
                                          (values (table.insert animations ani)
                                                  (math.max max-finish-at ani.finish-at)))
                                        (values animations max-finish-at)))]
    (if config.after
      (table.insert animations (M.linear after-start-at 0 #(config.after))))
    animations))

(fn animation [easing start-at duration on-tick]
  (fn tick [ani now]
    (let [{: start-at : duration} ani
          percent (-> (math.clamp (/ (- now start-at) duration) 0 1)
                      (easing))]
      (on-tick percent)))
  {: start-at
   :finish-at (+ start-at duration)
   : tick
   : duration})

(λ M.linear [...]
  (animation (fn [percent] (math.max 0 (math.min 1 percent))) ...))

(λ M.ease-out-quad [...]
  (animation (fn [percent] (- 1 (* (- 1 percent) (- 1 percent)))) ...))

(λ M.ease-in-quad [...]
  (animation (fn [percent] (* percent percent)) ...))

(λ M.ease-in-back [...]
  (local c1 1.70156)
  (local c3 (+ c1 1))
  (animation #(- (* c3 $1 $1 $1) (* c1 $1 $1)) ...))

(λ M.ease-out-back [...]
  (local c1 1.70156)
  (local c3 (+ c1 1))
  (animation #(+ 1 (* c3 (math.pow (- $1 1) 3)) (* c1 (math.pow (- $1 1) 2))) ...))

(λ M.ease-in-out-back [...]
  (local c1 1.70156)
  (local c2 (* c1 1.525))
  (fn f [x]
    (if (< x 0.5)
      (/ (* (math.pow (* 2 x) 2) (- (* (+ c2 1) (* 2 x)) c2)) 2)
      (/ (+ (* (math.pow (- (* 2 x) 2) 2) (+ (* (+ c2 1) (- (* x 2) 2)) c2)) 2) 2)))
  (animation f ...))

M
