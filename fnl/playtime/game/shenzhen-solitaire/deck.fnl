(require-macros :playtime.prelude)
(prelude)

(local Id (require :playtime.common.id))
(local Deck (require :playtime.common.card.deck))
(local M (setmetatable {:Shenzhen {}} {:__index Deck}))

(fn M.Shenzhen.build []
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
