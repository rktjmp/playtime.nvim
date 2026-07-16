(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Deck (require :playtime.game.shared.french-deck))
(local CardGameUtils (require :playtime.game.shared.card-utils))

(local M {:Action {}
          :Plan {}
          :Query {}})

(local {: inc-moves
        : apply-events} CardGameUtils)
(set M.iter-cards (CardGameUtils.make-iter-cards-fn [:foundation :tableau :draw]))
(local {: card-value : card-color : card-rank
        : card-suit : rank-value : suit-color
        : card-face-up? : card-face-down?
        : flip-face-up}
  (CardGameUtils.make-card-util-fns {:value {:king 13 :queen 12 :jack 11}
                                     :color {:diamonds :red :hearts :red
                                             :clubs :black :spades :black}}))

(fn new-game-state []
  {:draw [[]]
   :foundation [[] [] [] []]
   :tableau [[] [] [] [] []]
   :moves 0})

(λ M.build [_config ?seed]
  (math.randomseed (or ?seed (os.time)))
  (let [deck (-> (Deck.Standard52.build)
                 (table.shuffle))
        ;; pull off the first ace 2 3 4
        ;; put them back on the top of the deck ready for dealing.
        (deck head) (accumulate [(d h) (values [] [])
                                 _ c (ipairs deck)]
                      (case (card-value c)
                        1 (case h
                            [nil] (values d (table.set h 1 c))
                            _ (values (table.insert d c) h))
                        2 (case h
                            [_ nil] (values d (table.set h 2 c))
                            _ (values (table.insert d c) h))
                        3 (case h
                            [_ _ nil] (values d (table.set h 3 c))
                            _ (values (table.insert d c) h))
                        4 (case h
                            [_ _ _ nil] (values d (table.set h 4 c))
                            _ (values (table.insert d c) h))
                        n (values (table.insert d c) h)))
        state (new-game-state)]
    (icollect [_ c (ipairs head) &into deck] c)
    (tset state :draw 1 deck)
    state))

(fn M.Action.deal [state]
  (let [moves (faccumulate [t [] i 4 1 -1]
                (table.join t [[:face-up [:draw 1 :top]]
                               [:move [:draw 1 :top] [:foundation i :top]]]))]
    (table.join moves [[:face-up [:draw 1 :top]]])
    (apply-events (clone state) moves)))

(fn check-pick-up [state pick-up-from]
  (case pick-up-from
    [:draw 1 n] [(table.last (. state :draw 1))]
    [:tableau col-n card-n] (if (= card-n (length (. state :tableau col-n)))
                              [(table.last (. state :tableau col-n))])
    [field] (values nil (<s> "May not pick up from #{field}"))))

(fn put-down [state pick-up-from dropped-on held]
  (case (values pick-up-from dropped-on held)
    ;; ignore pick-up-put-down on same location
    (where ([field col from-n] [field col on-n] _) (= from-n (+ 1 on-n)))
    nil

    ;; You may not shuffle between tableaus
    ([:tableau] [:tableau] _)
    nil
    ;; For cheating
    ; ([:tableau a b] [:tableau c d] _)
    ; (let [moves [[:move [:tableau a b] [:tableau c :top]]]]
    ;   (-> (clone state)
    ;       (inc-moves)
    ;       (apply-events moves)))

    ;; We ignore the card-n and just drop onto the tail
    ([:draw] [:tableau t-col _] [held-card])
    (let [moves [[:move [:draw 1 :top] [:tableau t-col :top]]]
          _ (if (< 1 (length (. state :draw 1)))
              (table.insert moves [:face-up [:draw 1 :top]]))]
      (-> (clone state)
          (inc-moves)
          (apply-events moves)))

    ;; Must be moving the last card from the tableau or hand,
    ;; must be building according to the foundation column
    (_ [:foundation f-col f-card] [held-card])
    (let [onto-card (. state :foundation f-col f-card)
          want-value (case (% (+ f-col (card-value onto-card)) 13)
                       0 13
                       n n)]
      (if (= 13 (card-value onto-card))
        (values nil (<s> "Foundation is complete"))
        (if (= (card-value held-card) want-value)
          (let [moves [[:move pick-up-from [:foundation f-col :top]]]
                _ (case pick-up-from
                    [:draw] (if (< 1 (length (. state :draw 1)))
                               (table.insert moves [:face-up [:draw 1 :top]])))]
            (-> (clone state)
                (inc-moves)
                (apply-events moves)))
          (values nil (<s> "Foundation wants a #{want-value}")))))))

(fn M.Action.move [state pick-up-from put-down-on]
  (case-try
    (check-pick-up state pick-up-from) held
    (put-down state pick-up-from put-down-on held) (next-state moves)
    (values next-state moves)))

(fn M.Query.moveable? [state from-location to-location]
  (not (nil? (M.Action.move state from-location to-location))))

(fn M.Query.automatic-action [state]
  ;; has no valid automatic actions
  nil)

(fn M.Query.liftable? [state location]
  (not (nil? (check-pick-up state location))))

(fn M.Query.droppable? [state location]
  (case location
    [field] (eq-any? field [:foundation :tableau])
    _ false))

(fn M.Query.game-ended? [state]
  (faccumulate [won? true i 1 4]
    (and won? (-> (table.last (. state.foundation i))
                  (card-value)
                  (= 13)))))

(fn M.Query.game-result [state]
  (M.Query.game-ended? state))

M
