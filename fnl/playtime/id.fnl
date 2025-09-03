(fn build-counter []
  (setmetatable {:v 0}
                {:__call (fn [t] (set t.v (+ t.v 1)) t.v)}))
(local id (build-counter))
(local ns-id {})

(fn next-id [?namespace]
  "Generate unique integer id for each call, optionally in a namespace.
  Ids between namespaces may not be unique."
  (case (values ?namespace (. ns-id ?namespace))
    (nil _) (id)
    (ns nil) (do
               (tset ns-id ns (build-counter))
               ((. ns-id ns)))
    (ns_ c) (c)))

{:new next-id}
