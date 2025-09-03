(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))

(local M {})
(local m {})

(λ M.new [{: chain : context}]
  ;; copy chain into new list since we modify it
  ;; Note you can totally break interceptors by modifying them, so dont do
  ;; that. This is called every tick so we want to avoid deep cloning, though
  ;; they are generally pretty small?
  (let [chain (setmetatable {:queue (icollect [_ interceptor (ipairs chain)]
                                      interceptor)
                             :stack []
                             :effects {}
                             :__effect-queue []
                             : context}
                            {:__index  M})
        make-effect (fn [func]
                      (table.insert chain.__effect-queue func))]
    (set chain.make-effect make-effect)
    chain))

(fn M.run [chain]
  (fn sweep-back [chain]
    (case chain.stack
      [nil] chain
      _ (let [current-interceptor (table.remove chain.stack)
              updated-chain (case current-interceptor
                              {: after} (after current-interceptor chain)
                              _ chain)]
          (sweep-back updated-chain))))

  (fn sweep-forward [chain]
    (case chain.queue
      [nil] chain
      _ (let [current-interceptor (table.remove chain.queue 1)
              _ (table.insert chain.stack current-interceptor)
              updated-chain (case current-interceptor
                              {: before} (before current-interceptor chain)
                              _ chain)]
          (sweep-forward updated-chain))))

  (fn do-effects [chain]
    (each [_ fx (ipairs chain.__effect-queue)]
      (fx chain))
    chain)

  (-> (sweep-forward chain)
      (sweep-back)
      (do-effects)))

M
