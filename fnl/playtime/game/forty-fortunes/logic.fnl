(require-macros :playtime.prelude)
(prelude)

(local Error (require :playtime.error))
(local Logger (require :playtime.logger))
(local Deck (require :playtime.common.card.deck))
(local CardGameUtils (require :playtime.common.card.utils))

(local M {:Action {}
          :Plan {}
          :Query {}})

(local {: location-contents : inc-moves : apply-events} CardGameUtils)
(set M.iter-cards (CardGameUtils.make-iter-cards-fn [:draw :tableau :cell :foundation]))
(local {: card-value : card-color : card-rank
        : card-suit : rank-value : suit-color
        : card-face-up? : card-face-down?}
  (CardGameUtils.make-card-util-fns {:value {:king 13 :queen 12 :jack 11}
                                     :color {:diamonds :red :hearts :red
                                             :clubs :black :spades :black}}))

;; You may build up or down, consistently
(local valid-sequence?
  (CardGameUtils.make-valid-sequence?-fn
    (fn [next-card [last-card] memo]
      (let [last-value (card-value last-card)
            last-suit (card-suit last-card)
            next-value (card-value next-card)
            next-suit (card-suit next-card)
            same-suit? (= next-suit last-suit)
            memo (case memo
                   nil (case (values last-value next-value)
                         (13 1) 1 ;; 13 + 1 = "14 next value"
                         (1 13) -1
                         (l n) (case (- n l)
                                 ;; only match abs diff = 1
                                 1 1
                                 -1 -1))
                   ;; 4 - 3 = 1, ascending, 3 - 4 = -1, descending
                   dir (case (values last-value next-value dir)
                         (13 1 1) 1
                         (1 13 -1) -1
                         (l n dir) (case (- n l)
                                     (where (= dir)) dir)))]
        (values (and same-suit? memo) memo)))))

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

(fn new-game-state []
  {:draw [[]]
   :foundation [[] [] [] []
                [] [] [] []]
   :cell [[]]
   :tableau [[] [] [] [] [] []
             []
             [] [] [] [] [] []]
   :moves 0})

(λ M.build [_config ?seed]
  (math.randomseed (or ?seed (os.time)))
  (let [deck (-> (table.join (Deck.Standard52.build) (Deck.Standard52.build))
                 (table.shuffle))
        state (new-game-state)]
    (each [_ card (ipairs deck)]
      (Deck.flip-card card))
    (tset state :draw 1 deck)
    state))

(fn M.Action.deal [state]
  (let [moves (faccumulate [(moves t-col row f-col) (values [] 1 1 1)
                            i (length (. state :draw 1)) 1 -1]
                (let [card (. state :draw 1 i)
                      from [:draw 1 i]
                      to (case card
                           [_suit 1] [:foundation f-col 1]
                           _ [:tableau t-col row])
                      (t-col row f-col) (case (values t-col to)
                                          (_ [:foundation]) (values t-col row (+ 1 f-col))
                                          (13 _) (values 1 (+ 1 row) f-col) ;; wrap
                                          (6 _) (values 8 row f-col) ;; skip
                                          (n _) (values (+ n 1) row f-col))]
                  (values (table.insert moves [:move from to]) t-col row f-col)))
        (next-state moves) (apply-events (clone state) moves)]
    (values next-state moves)))

(fn check-pick-up [state pick-up-from]
    (case pick-up-from
      [:tableau col-n card-n]
      (let [(remaining held) (table.split (. state :tableau col-n) card-n)]
        (if (= 1 (length held))
          (values held)
          (case held
            [nil] (values nil (Error "No cards to pick up from tableau column #{col-n}" {: col-n}))
            _ (values nil (Error (.. "You may only pick up one card"))))))

      [:cell col-n 1]
      (let [(remaining held) (table.split (. state :cell col-n) 1)]
        (case (length held)
          1 (values held)
          0 (values nil (Error "No card to pick up from free cell"))
          n (values nil (Error "May only pick up one card at a time from free cell"))))

      [field]
      (values nil (Error "May not pick up from #{field}" {: field}))))

(fn put-down [state pick-up-from dropped-on held]
  (case (values pick-up-from dropped-on held)
    ;; ignore pick-up-put-down on same location
    (where ([field col from-n] [field col on-n] _) (= from-n (+ 1 on-n)))
    nil

    ;; Must be on a tail
    (where (_ [field col-n card-n] _) (not (= card-n (length (. state field col-n)))))
    (values nil (Error "Must place cards on the bottom of a cascade"))

    ;; You may place single cards on a foundation when forming a same-suit
    ;; ascending run.
    (_ [:foundation] [multiple cards])
    (values nil (Error "May only place cards on a foundation one at a time"))

    ;; Starting a new foundation, we only care for aces
    (_ [:foundation f-col-n 0] [card nil])
    (case card
      [_suit 1] (-> (clone state)
                    (inc-moves)
                    (apply-events [[:move pick-up-from [:foundation f-col-n 1]]]))
      _ (values nil (Error "Must build foundations same suit, 1, 2, ... 10, J, Q, K")))

    ;; Continuing a foundation, must be the same suit and +1 rank
    (_ [:foundation f-col-n f-card-n] [new-card nil])
    (let [onto-card (location-contents state dropped-on)]
      (case (values onto-card new-card)
        (where ([suit] [suit]) (= -1 (- (card-value onto-card) (card-value new-card))))
        (-> (clone state)
            (inc-moves)
            (apply-events [[:move pick-up-from [:foundation f-col-n (+ f-card-n 1)]]]))
        _ (values nil (Error "Must build foundations in same-suit, ascending order"))))

    (_ [:cell] [multiple cards])
    (values nil (Error "May only place single cards on a cell"))
    (where (_ [:cell col-n card-n] _) (not (= 0 card-n)))
    (values nil (Error "May only place single cards on a cell"))

    (_ [:cell col-n 0] [new-card nil])
    (-> (clone state)
        (inc-moves)
        (apply-events [[:move pick-up-from [:cell col-n 1]]]))

    ; ;; You may re-sort the tableau by dragging from slot 1 to slot 0
    ; ;; without any cost or max-move checks
    ; (where ([:tableau a 1] [:tableau b 0] _) (not (= a b)))
    ; (let [from-col (. state :tableau a)
    ;       moves (icollect [i _card (ipairs from-col)]
    ;               [[:tableau a i] [:tableau b i]])]
    ;   (-> (clone state)
    ;       (apply-moves moves {:unsafely? true})))

    ;; You may drop a card on a valid position, when dropping, we check the
    ;; cards above and move any valid sequence on top of the moved card.
    ([f-field f-col f-card-n] [:tableau t-col t-card-n] [one-card nil])
    (let [top-card-n (faccumulate [(top-i cont?) (values 1 true)
                                   i f-card-n 1 -1
                                   &until (not cont?)]
                       (let [(_ seq) (table.split (. state f-field f-col) i)]
                         (if (valid-sequence? seq)
                           (values i true)
                           (values top-i false))))
          moves (fcollect [i f-card-n top-card-n -1]
                  [:move
                   [f-field f-col i]
                   [:tableau t-col (+ t-card-n (- f-card-n i) 1)]])
          next-state (-> (clone state)
                         (inc-moves (length moves))
                         (apply-events moves))
          ;; Note we *move* sequences, but only check the two main cards are
          ;; valid for a move. This lets you build j q k q j.
          seq (case t-card-n
                0 [(. next-state :tableau t-col 1)]
                n [(. next-state :tableau t-col n) (. next-state :tableau t-col (+ n 1))])]
      (if (valid-sequence? seq)
        (values next-state moves)
        (values nil (Error "Must build in same suit, ascending or descending rank"))))

    ;; No op?
    _ (values nil (Error "No putdown for #{field}" {:field dropped-on}))))

(fn M.Action.move [state pick-up-from put-down-on]
  (case-try
    (check-pick-up state pick-up-from) held
    (put-down state pick-up-from put-down-on held) (next-state moves)
    (values next-state moves)))

(fn M.Plan.next-move-to-foundation [state]
  (let [speculative-state (clone state)
        check-locations (fcollect [i 1 1] [:cell i])
        _ (fcollect [i 1 13 &into check-locations] [:tableau i])
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
                          (fcollect [i 1 8 &into moves]
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
  (faccumulate [won? true i 1 8]
    (and won? (winning-foundation-sequence? (location-contents state [:foundation i])))))

(fn M.Query.game-result [state]
  (M.Query.game-ended? state))

M
