(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Deck (require :playtime.common.card.deck))
(local CardGameUtils (require :playtime.common.card.utils))

(local M {:Action {}
          :Plan {}
          :Query {}})

(local {: location-contents
        : inc-moves
        : apply-events} CardGameUtils)
(set M.iter-cards (CardGameUtils.make-iter-cards-fn [:draw :tableau :cell :foundation]))
(local {: card-value : card-color : card-rank
        : card-suit : rank-value : suit-color
        : card-face-up? : card-face-down?}
  (CardGameUtils.make-card-util-fns {:value {:king 13 :queen 12 :jack 11}
                                     :color {:diamonds :red :hearts :red
                                             :clubs :black :spades :black}}))

(fn new-game-state []
  {:draw [[]]
   :foundation [[] [] [] []]
   :cell [[] [] [] [] [] [] []]
   :tableau [[] [] [] [] [] [] []]
   :moves 0})

(λ M.build [_config ?seed]
  (math.randomseed (or ?seed (os.time)))
  (let [deck (-> (Deck.Standard52.build)
                 (table.shuffle))
        state (new-game-state)]
    (tset state :draw 1 deck)
    state))

(local valid-sequence?
  (CardGameUtils.make-valid-sequence?-fn
    (fn [next-card [last-card]]
      (let [last-suit (card-suit last-card)
            last-value (card-value last-card)
            next-suit (card-suit next-card)
            next-value (card-value next-card)]
        (and (= last-suit next-suit)
             (= last-value (+ next-value 1)))))))

(local winning-foundation-sequence?
  (do
    (local valid-sequence?
      (CardGameUtils.make-valid-sequence?-fn
        (fn [next-card [last-card]]
          (values (and (= (card-suit next-card) (card-suit last-card))
                       (= (card-value next-card) (+ 1 (card-value last-card))))))))
    (fn [sequence]
      (and (= (rank-value :king) (length sequence))
           (valid-sequence? sequence)))))

(fn M.Action.deal [state]
  ;; We simplify penguins logic for now, by always making the beak an ace.
  ;; This means our auto-move logic is common, and our sequence checking does
  ;; not need to wrap values.
  ;; Possibly we could ... define the card-value functions per-instance? Probably not.
  ;; Gameplay wise this isn't much of a difference, the puzzle is the same.
  (let [draw (. state :draw 1)
        beak-card-index (accumulate [first-ace-index nil i c (ipairs draw) &until first-ace-index]
                          (if (= 1 (card-value c)) i))
        beak-card (. draw beak-card-index)
        ;; remove the beak card and put it at the end
        _ (do
            (table.remove draw beak-card-index)
            (table.insert draw beak-card))
        moves (faccumulate [(moves t-col row f-col) (values [] 1 1 1)
                            i (length (. state :draw 1)) 1 -1]
                (let [card (. state :draw 1 i)
                      move (if (and (= (card-rank beak-card) (card-rank card))
                                    (not (= i (length draw))))
                             [:move [:draw 1 i] [:foundation f-col 1]]
                             [:move [:draw 1 i] [:tableau t-col row]])
                      (t-col row f-col) (case move
                                          [:move _ [:foundation]] (values t-col row (+ f-col 1))
                                          _ (values (if (= t-col 7) 1 (+ t-col 1))
                                                    (if (= t-col 7) (+ row 1) row)
                                                    f-col))]
                  (values (table.join moves [move [:face-up (table.last move)]])
                          t-col row f-col)))
        (next-state moves) (apply-events (clone state) moves)]
    (values next-state moves)))

(fn check-pick-up [state pick-up-from]
  (case pick-up-from
    [:tableau col-n card-n]
    (let [(remaining held) (table.split (. state :tableau col-n) card-n)]
      (Logger.info {: pick-up-from})
      (if (valid-sequence? held)
        (values held)
        (case held
          [nil] (values nil (<s> "No cards to pick up from tableau column #{col-n}"))
          _ (values nil (<s> "Must pick up run of same suit, descending rank")))))

    [:cell col-n 1]
    (let [(remaining held) (table.split (. state :cell col-n) 1)]
      (case (length held)
        1 (values held)
        0 (values nil (<s> "No card to pick up from free cell"))
        n (values nil (<s> "May only pick up one card at a time from free cell"))))

    [field]
    (values nil (<s> "May not pick up from #{field}"))))

(fn put-down [state pick-up-from dropped-on held]
  (case (values pick-up-from dropped-on held)
    ;; ignore pick-up-put-down on same location
    (where ([field col from-n] [field col on-n] _) (= from-n (+ 1 on-n)))
    nil

    ;; Must be on a tail
    (where (_ [field col-n card-n] _) (not (= card-n (length (. state field col-n)))))
    (values nil (<s> "Must place cards on the bottom of a cascade"))

    ;; You may place single cards on a foundation when forming a same-suit
    ;; ascending run.
    (_ [:foundation] [multiple cards])
    (values nil (<s> "May only place cards on a foundation one at a time"))

    ;; Starting a new foundation, we only care for aces
    (_ [:foundation f-col-n 0] [card nil])
    (case card
      [_suit 1] (-> (clone state)
                    (inc-moves)
                    (apply-events [[:move pick-up-from [:foundation f-col-n 1]]]))
      _ (values nil (<s> "Must build foundations same suit, 1, 2, ... 10, J, Q, K")))

    ;; Continuing a foundation, must be the same suit and +1 rank
    (_ [:foundation f-col-n f-card-n] [new-card nil])
    (let [onto-card (location-contents state dropped-on)]
      (case (values onto-card new-card)
        (where ([suit] [suit]) (= -1 (- (card-value onto-card) (card-value new-card))))
        (-> (clone state)
            (inc-moves)
            (apply-events [[:move pick-up-from [:foundation f-col-n (+ f-card-n 1)]]]))
        _ (values nil (<s> "Must build foundations in same-suit, ascending order"))))

    (_ [:cell] [multiple cards])
    (values nil (<s> "May only place single cards on a cell"))
    (where (_ [:cell col-n card-n] _) (not (= 0 card-n)))
    (values nil (<s> "May only place single cards on a cell"))

    (_ [:cell col-n 0] [new-card nil])
    (-> (clone state)
        (inc-moves)
        (apply-events [[:move pick-up-from [:cell col-n 1]]]))

    ;; You may re-sort the tableau by dragging from slot 1 to slot 0
    ;; without any cost or max-move checks
    (where ([:tableau a 1] [:tableau b 0] _) (not (= a b)))
    (let [from-col (. state :tableau a)
          moves (icollect [i _card (ipairs from-col)]
                  [:move [:tableau a i] [:tableau b i]])]
      (-> (clone state)
          (apply-events moves {:unsafely? true})))

    ;; Empty tableau columns can be filled by a king only
    ([f-field f-col f-card-n] [:tableau t-col 0] [[_suit :king] &as held])
    (let [moves (fcollect [i 1 (length held)]
                  [:move
                   [f-field f-col (+ f-card-n (- i 1))]
                   [:tableau t-col i]])
          next-state (-> (clone state)
                         (inc-moves)
                         (apply-events moves))
          new-run (. next-state :tableau t-col)]
      (if (valid-sequence? new-run)
        (values next-state moves)
        (values nil (<s> "Must build piles in same suit, descending rank"))))

    ([f-field f-col f-card-n] [:tableau t-col 0] _)
    (values nil (<s> "May only place kings in empty columns"))

    ;; Otherwise just move cards
    ([f-field f-col f-card-n] [:tableau t-col t-card-n] held)
    (let [moves (fcollect [i 1 (length held)]
                  [:move
                   [f-field f-col (+ f-card-n (- i 1))]
                   [:tableau t-col (+ t-card-n i)]])
          next-state (-> (clone state)
                         (inc-moves)
                         (apply-events moves))
          (_ new-run) (table.split (. next-state :tableau t-col) t-card-n)]
      (if (valid-sequence? new-run)
        (values next-state moves)
        (values nil (<s> "Must build piles in same suit, descending rank"))))

    ;; No op?
    _ (values nil (<s> "No putdown for #{dropped-on}"))))

(fn M.Action.move [state pick-up-from put-down-on]
  (case-try
    (check-pick-up state pick-up-from) held
    (put-down state pick-up-from put-down-on held) (next-state moves)
    (values next-state moves)))

(fn M.Plan.next-move-to-foundation [state]
  (let [speculative-state (clone state)
        check-locations (fcollect [i 1 7] [:cell i])
        _ (fcollect [i 1 7 &into check-locations] [:tableau i])
        min-values (accumulate [min-vals {:spades math.huge :hearts math.huge
                                          :diamonds math.huge :clubs math.huge}
                                _l card (M.iter-cards speculative-state [:cell :tableau])]
                     (let [suit (card-suit card)
                           val (card-value card)]
                       (table.set min-vals suit (math.min val (. min-vals suit)))))
        source-locations (icollect [_ [field col] (ipairs check-locations)]
                           (let [card-n (length (. speculative-state field col))]
                             (case (. speculative-state field col card-n)
                               card (let [suit (card-suit card)]
                                      (if (= (card-value card) (. min-values suit))
                                        [field col card-n])))))
        potential-moves (accumulate [moves [] _ from (ipairs source-locations)]
                          (fcollect [i 1 4 &into moves]
                            (case (. speculative-state :foundation i)
                              [nil] [from [:foundation i 0]]
                              cards [from [:foundation i (length cards)]])))]
    (accumulate [actions nil _ [pick-up-from put-down-on] (ipairs potential-moves) &until actions]
      (case-try
        (M.Action.move (clone state) pick-up-from put-down-on) speculative-state
        [pick-up-from put-down-on]))))

(fn M.Query.liftable? [state location]
  (not (nil? (check-pick-up state location))))

(fn M.Query.droppable? [state location]
  (case location
    [field] (eq-any? field [:tableau :cell :foundation])
    _ false))

(fn M.Query.game-ended? [state]
  (faccumulate [won? true i 1 4]
    (and won? (winning-foundation-sequence? (location-contents state [:foundation i])))))

(fn M.Query.game-result [state]
  (M.Query.game-ended? state))

M
