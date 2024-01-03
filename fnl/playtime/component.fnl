(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Id (require :playtime.common.id))
(local uv (or vim.loop vim.uv))

(local M {})

(fn M.build [?update-fn]
  (setmetatable {:id (Id.new)
                 :visible? true
                 :children nil
                 :animation-queue []
                 :deferred-updates []}
                {:__index M
                 :__call (or ?update-fn #$1)}))

(fn M.build-with [data]
  (setmetatable (table.merge {:id (Id.new)
                              :visible? true
                              :children nil
                              :animation-queue []
                              :deferred-updates []}
                             data)
                {:__index M
                 :__call (fn [comp ...]
                           (case comp
                             {: update} (update comp ...)
                             _ comp))}))

(fn M.set-visible [c v?]
  (doto c (tset :visible? v?)))

(fn M.set-children [c ?children]
  (doto c (tset :children ?children)))

(fn M.set-tag [c tag]
  ;; dont table.merge because you should be able to tag = nil
  (table.set c :tag tag))

(fn M.set-size [c {: width : height}]
  (table.merge c {: width : height}))

(fn M.set-position [c {: row : col : z}]
  (table.merge c {: row : col : z}))

(fn M.set-content [c content]
  (fn _draw [c lines line-number]
    (or (. lines line-number)
        (error
          (Error "No line #{line-number} for component #{id}"
                 {: line-number :id c.id}))))
  (let [lines (case (type content)
                :table content
                :function (content c)
                other (error (<s> "Unsupported content type #{other}")))
        lines (icollect [i line (ipairs lines)]
                {:extmark-id (or (?. c :content i :extmark-id) (Id.new))
                 :content line})]
    (doto c
      (tset :content lines)
      (tset :content-at (fn [c line-number]
                          (_draw c c.content line-number))))))

(fn M.queue-animation [c animation]
  (table.set c :animation-queue (table.insert c.animation-queue animation)))

(fn M.update [c ...]
  ;; Ideally we could generate a proxy-table that is passed to the user update
  ;; function, which we can use to store the deferred updates to apply to the
  ;; component after any animations have completed, but we have issues with
  ;; catching "x = nil" changes.
  ;; Or, animations could be run against a "proxy component", but then the
  ;; animation callback would have to send in the proxy which feels like its
  ;; separating the component animation api a bit far from the animate api core
  ;; and you also have to be sure you run your animation against the param, not
  ;; any previously retrieved component.
  ;; So, I guess for now, if we're animating a component, we defer the update
  ;; call back until after all animations have completed. To avoid losing any
  ;; updated data we will just retain *all* update calls then bang them in one
  ;; go.
  ;; We could also extend or alternate the table type to support nils or have a
  ;; specific marker for nil values...

  (let [args (table.pack ...)
        call (fn [] (c (table.unpack args)))]
    (table.insert c.deferred-updates call)
    (when (< 0 (length c.animation-queue))
      (let [now (uv.now)
            animations (icollect [i animation (ipairs c.animation-queue)]
                         (let [{: finish-at : start-at} animation]
                           (when (<= start-at now)
                             (animation:tick now))
                           (when (< now finish-at)
                             animation)))]
        (set c.animation-queue animations)))
    (when (= 0 (length c.animation-queue))
      (each [_ deferred-update (ipairs c.deferred-updates)]
        (deferred-update))
      (set c.deferred-updates []))
    c))

M
