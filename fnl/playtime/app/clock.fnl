(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local uv (or vim.loop vim.uv))

(local M {})
(local m {})

(fn sum-intervals [intervals]
  (accumulate [total 0 _ val (ipairs intervals)]
    (case val
      {: started-at} (+ total (- (uv.now) started-at))
      elapsed (+ total elapsed))))

(fn M.new []
  {:intervals []
   :paused? (fn [self]
              (case self.intervals
                [{: started-at}] false
                _ true))
   :reset (fn [self]
            (set self.intervals [{:started-at (uv.now)}])
            self)
   :pause (fn [self]
            (case self.intervals
              [{: started-at}] (let [elapsed (- (uv.now) started-at)]
                                 (set (. self.intervals  1) elapsed))
              _ (Logger.warn "Tried to pause paused timer"))
            self)
   :resume (fn [self]
             (case self.intervals
               [{: started-at}] (Logger.warn "tried to resume running timer")
               _ (table.insert self.intervals 1 {:started-at (uv.now)}))
             self)
   :elapsed-milliseconds (fn [self] (sum-intervals self.intervals))
   :elapsed-seconds (fn [self] (/ (self:elapsed-milliseconds) 1000))
   :elapsed-time (fn [self]
                   (let [elapsed-seconds (self:elapsed-seconds)
                         hours (math.floor (/ elapsed-seconds 3600))
                         minutes (math.floor (/ (% elapsed-seconds 3600) 60))
                         seconds (% elapsed-seconds 60)]
                     (if
                       (< 0 hours) (string.format "%dh%02dm%02ds" hours minutes seconds)
                       (< 0 minutes) (string.format "%dm%02ds" minutes seconds)
                       (string.format "%ds" seconds))))})

M
