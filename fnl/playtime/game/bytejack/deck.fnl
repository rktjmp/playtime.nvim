(require-macros :playtime.prelude)
(prelude)

(local Id (require :playtime.id))
(local Deck (require :playtime.game.shared.french-deck))
(local M (setmetatable {:Item {} :Enemy {} :Attack {}}
                       {:__index Deck}))



(local items {:reset 3
              :recovery 3
              :over_pressure 3
              :block 3
              :exile 3
              ; :flip 3
              :alpha 3
              :buff 3
              :prepare 3
              :tutor 3})

(fn M.Item.build []
  (fn new-card [suit rank]
    {1 suit 2 rank :id (Id.new) :face :down})
  (let [dragons [:red :green :white] ;; zhong fa bai
        suits [:strings :coins :myriads]
        pips [1 2 3 4 5 6 7 8 9]
        cards []]
    (each [_ suit (ipairs suits)]
      (icollect [_ pip (ipairs pips) &into cards]
        (new-card suit pip)))
    (each [_ dragon (ipairs dragons)]
      (fcollect [i 1 4 &into cards]
        (new-card dragon i)))
    (table.insert cards (new-card :flower 1)))) ;; chun

M
