(require-macros :playtime.prelude)
(prelude)

(local Id (require :playtime.common.id))
(local M {:Standard54 {} :Standard52 {}})
(setmetatable M.Standard52 {:__index M})
(setmetatable M.Standard54 {:__index M})

(fn M.shuffle [deck]
  "Build new deck from given decks cards, in a randomised order."
  (table.shuffle (clone deck)))

(fn M.split [deck pred]
  "Split deck in two by predicate function.

  Predicate is called with (f card card-index).

  Returns (values true-deck false-deck)."
  (accumulate [(td fd) (values [] []) i card (ipairs deck)]
    (if (pred card i)
      (values (table.insert td card) fd)
      (values td (table.insert fd card)))))

(fn M.slice [deck n]
  "Slice the deck at card n"
  (error :TODO?))

;; TODO: This modifies the card, which is ... debatable but more convenient?
(fn M.flip-card [card]
  (case card.face
    :up (doto card (tset :face :down))
    :down (doto card (tset :face :up))))

(fn M.Standard54.build []
  (fn new-card [suit rank]
    {1 suit 2 rank
     :id (Id.new)
     :face :down})

  (let [suits [:spades :clubs :hearts :diamonds]
        faces [:jack :queen :king]
        pips [1 2 3 4 5 6 7 8 9 10]
        cards []]
    (each [_ suit (ipairs suits)]
      (each [_ pip (ipairs pips)]
        (table.insert cards (new-card suit pip)))
      (each [i face (ipairs faces)]
        (table.insert cards (new-card suit face))))
    (table.insert cards (new-card :joker 1))
    (table.insert cards (new-card :joker 2))
    cards))

(fn M.Standard52.build []
  (icollect [_ card (ipairs (M.Standard54.build))]
    (case card
      [:joker] nil
      _ card)))

M
