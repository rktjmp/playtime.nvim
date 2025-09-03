(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Id (require :playtime.id))

(local M {:Animation {} :Group {}})

(fn make-oscillate [n ?damping]
  (let [damping (or ?damping 0)]
  (fn [t]
    (* (math.sin (* 2 math.pi n t))
       (math.pow (- 1 t) damping)))))

(local ease-fns
  {:threshold-50 (fn [t] (if (< t 0.5) 0 1))
   :linear (fn [t] (math.max 0 (math.min 1 t)))
   :oscillate-1 (make-oscillate 1)
   :oscillate-3 (make-oscillate 3)
   :oscillate-3-dampend (make-oscillate 3 1)
   :ease-out-quad (fn [t] (- 1 (* (- 1 t) (- 1 t))))
   :ease-in-quad (fn [t] (* t t))
   :ease-in-back (fn [t]
                   (let [c1 1.70156
                         c3 (+ c1 1)]
                     (- (* c3 t t t) (* c1 t t))))
   :ease-out-back (fn [t]
                    (let [c1 1.70156
                          c3 (+ c1 1)]
                      (+ 1 (* c3 (math.pow (- t 1) 3)) (* c1 (math.pow (- t 1) 2)))))
   :ease-in-out-back (fn [t]
                       (let [c1 1.70156
                             c2 (* c1 1.525)]
                         (if (< t 0.5)
                           (/ (* (math.pow (* 2 t) 2) (- (* (+ c2 1) (* 2 t)) c2)) 2)
                           (/ (+ (* (math.pow (- (* 2 t) 2) 2) (+ (* (+ c2 1) (- (* t 2) 2)) c2)) 2) 2))))})

(fn M.new []
  (setmetatable {:active []} {:__index M}))

(fn M.add-animation [self animation]
  (table.insert self.active animation)
  self)

(fn M.tick [self dt]
  ;; TODO: on-complete callbacks
  ;; drop finished animations from active
  ;; throttle tick rate?
  (let [active (icollect [_ animation (ipairs self.active)]
                 (do
                   (animation:tick dt)
                   (when (not animation.complete?)
                     animation)))]
    (set self.active active))
  self)

(fn M.fast-forward-all [self]
  (each [_ a (ipairs self.active)]
    (a:fast-forward))
  (set self.active []))

(fn M.active? [self]
  (< 0 (length self.active)))

(fn lerp [from to percent]
  (case (type from)
    :table (collect [k _ (pairs from)]
             ;; for every key, lerp between the keys from and to values.
             (values k (lerp (. from k) (. to k) percent)))
    :number (+ from (* (- to from) percent))
    t (error (<s> "Cannot lerp #{t}"))))

(λ M.Animation.new [{: component : from : to : property : duration &as data}]
  (let [{: ease : delay : apply} data
        delay (or delay 0)
        ease-fn (case (. ease-fns (or ease :linear))
                  func func
                  nil (error (<s> "Unknown ease #{ease}")))
        apply (or apply (fn [component value]
                          (set (. component property) value)))]
    (fn tick [self dt]
      (set self.elapsed (+ self.elapsed dt))
      (when (and (< 0 self.elapsed) (not self.complete?))
        (let [percent (math.min (/ self.elapsed self.duration) 1)]
          (case (ease-fn percent)
            1 (apply component to 1)
            eased-percent (apply component (lerp from to eased-percent) eased-percent))
          (when (<= 1 percent)
            (set self.complete? true)
            (self.on-complete)))))
    (fn fast-forward [self]
      (apply component to 1)
      (set self.complete? true)
      (self.on-complete))

    {:id (Id.new)
     : component
     : property
     : duration
     :elapsed (* -1 delay)
     : from
     : to
     : tick
     : apply
     : fast-forward
     :complete? false
     :on-complete (or data.on-complete #nil)
     : ease-fn}))

(λ M.Group.new [{: animations &as data}]
  (fn tick [group dt]
    (let [complete? (accumulate [complete? true
                                 _ animation (ipairs group.animations)]
                      (do
                        (animation:tick dt)
                        (and complete? animation.complete?)))]
      (when (and complete? (not group.complete?))
        (set group.complete? true)
        (group.on-complete))))

  (fn fast-forward [group]
    (each [_ animation (ipairs group.animations)]
      (animation:fast-forward))
    (set group.complete? true)
    (group.on-complete))

  {:id (Id.new)
   : animations
   : tick
   : fast-forward
   :on-complete (or data.on-complete #nil)})

M
