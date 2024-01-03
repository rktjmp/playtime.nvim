(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Deck (require :playtime.common.card.deck))
(local CardGameUtils (require :playtime.common.card.utils))

(local M {:Action {}
          :Plan {}
          :Query {}})

(fn new-game-state []
  {:draw [[]]
   :foundation [[] [] [] []]
   :cell [[] [] [] []]
   :tableau [[] [] [] [] [] [] [] []]
   :moves 0
   :rules :freecell})

(λ M.build [config ?seed]
  (assert-match {: rules} config)
  (math.randomseed (or ?seed (os.time)))
  (let [deck (-> (Deck.Standard52.build)
                 (Deck.shuffle))
        state (new-game-state)]
    (tset state :draw 1 deck)
    (tset state :rules config.rules)

    state))

(set M.iter-cards (CardGameUtils.make-iter-cards-fn [:draw :cell :tableau :foundation]))
(local {: location-contents
        : same-location-field-column?
        : inc-moves
        : apply-events} CardGameUtils)
(local {: card-value : card-color : card-rank : card-suit : rank-value : suit-color}
  (CardGameUtils.make-card-util-fns {:value {:king 13 :queen 12 :jack 11}
                                     :color {:diamonds :red :hearts :red
                                             :clubs :black :spades :black}}))

(local valid-freecell-sequence?
  (CardGameUtils.make-valid-sequence?-fn
    (fn [next-card [last-card]]
      (let [last-color (card-color last-card)
            last-value (card-value last-card)
            next-color (card-color next-card)
            next-value (card-value next-card)]
        (and (not (= last-color next-color))
             (= last-value (+ next-value 1)))))))

(local valid-bakers-sequence?
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

(fn valid-sequence? [rules sequence]
  (case rules
    :freecell (valid-freecell-sequence? sequence)
    :bakers (valid-bakers-sequence? sequence)))

(λ build-move-plan [cur-state from to]
  (λ find-empty-cells [state]
    (fcollect [i 1 4]
      (if (table.empty? (location-contents state [:cell i]))
        [:cell i 1])))

  (λ find-empty-columns [state]
    (fcollect [i 1 8]
      (if (table.empty? (location-contents state [:tableau i]))
        [:tableau i 1])))

  (λ stack-unstack-move [cur-state [from-f from-c from-n &as from] [to-f to-c to-n &as to]]
    ;; Move from->to by unstacking any cards under from-n into free columns,
    ;; then restacking on the destination.
    (let [next-state (clone cur-state)
          from-t (. next-state from-f from-c)
          to-t (. next-state to-f to-c)
          total-cards-to-move (- (length from-t) (- from-n 1))
          ;; We dont have to "hold" the final card, it moves directly to the destination
          num-cards-to-hold (- total-cards-to-move 1)
          holding-locs (let [t []]
                         (icollect [_ l (ipairs (find-empty-cells next-state)) &into t] l)
                         (icollect [_ l (ipairs (find-empty-columns next-state)) &into t] l)
                         (icollect [_ l (ipairs t)]
                           (if (not (same-location-field-column? to l)) l)))]
      (if (<= num-cards-to-hold (length holding-locs))
        (let [(unstack restack) (faccumulate [(unstack restack) (values [] [])
                                              i 1 num-cards-to-hold]
                                  (let [[hold-f hold-c hold-n] (. holding-locs i)
                                        ;; from locations are the card itself, to locations are the card 
                                        ;; we're placing "onto".
                                        from-loc [from-f from-c (- (length from-t) (- i 1))]
                                        ;; +1 for the top card we move directly.
                                        to-loc [to-f to-c (+ (length to-t) 1 (- num-cards-to-hold i) 1)]
                                        unstack-move [:move from-loc [hold-f hold-c hold-n]]
                                        restack-move [:move [hold-f hold-c hold-n] to-loc]]
                                    ;; Given k q j, unstack moves j q k
                                    ;; then restack moves k q j.
                                    (table.insert unstack unstack-move)
                                    (table.insert restack 1 restack-move)
                                    (values unstack restack)))]
          (table.insert unstack [:move from to])
          (icollect [_ re (ipairs restack) &into unstack] re))
        (values nil (<s> "Unable to plan move for #{total-cards-to-move} cards, not enough holding spaces")))))

  (let [next-state (clone cur-state)]
    (case (stack-unstack-move next-state from to)
      ;; Can move with current state
      moves moves
      ;; Cant move, but may be able to move sub-stacks separately, but
      ;; doing that requires at least one empty column.
      (nil err) (let [[from-f from-c from-n] from
                      [to-f to-c to-n] to
                      sub-stack-to (-> (icollect [_ l (ipairs (find-empty-columns next-state))]
                                         (if (not (same-location-field-column? to l)) l))
                                       (table.first))]
                  (if sub-stack-to
                    (let [holding-locs (let [t []]
                                         (icollect [_ l (ipairs (find-empty-cells next-state)) &into t] l)
                                         (icollect [_ l (ipairs (find-empty-columns next-state)) &into t] l)
                                         (icollect [_ [f c &as l] (ipairs t)]
                                           (if (and (not (same-location-field-column? to l))
                                                    (not (same-location-field-column? sub-stack-to l)))
                                             l)))
                          from-t (. next-state from-f from-c)
                          sub-stack-from [from-f from-c (- (length from-t) (length holding-locs))]]
                      (case (build-move-plan next-state sub-stack-from sub-stack-to)
                        ;; We could move the substack, apply the moves to the state, then try
                        ;; to move the remaining cards (which may generate another substack move)
                        moves
                        (let [next-state (apply-events next-state moves)]
                          (case (build-move-plan next-state from to)
                            next-moves (let [next-state (apply-events next-state next-moves)
                                             sub-stack-from sub-stack-to
                                             sub-stack-to [to-f to-c (+ 1 (length (. next-state to-f to-c)))]
                                             unwind-moves (stack-unstack-move next-state sub-stack-from sub-stack-to)]
                                         (icollect [_ move (ipairs next-moves) &into moves] move)
                                         (icollect [_ move (ipairs unwind-moves) &into moves] move))
                            nil (values nil (<s> "Cannot plan #{from} -> #{to}, not enough spaces"))))
                        (nil err)
                        (values nil (<s> "Cannot plan #{from} -> #{to}, not enough spaces"))))
                    (values nil (<s> "Cannot plan #{from} -> #{to}, no free columns")))))))

(fn M.Action.deal [state]
  (let [moves (faccumulate [(moves t-col row) (values [] 1 1)
                            i (length (. state :draw 1)) 1 -1]
                (let [from [:draw 1 i]
                      to [:tableau t-col row]]
                  (values (-> moves
                              (table.insert [:move from to])
                              (table.insert [:face-up to]))
                          (if (= t-col 8) 1 (+ t-col 1))
                          (if (= t-col 8) (+ row 1) row))))
        (next-state moves) (apply-events (clone state) moves)]
    (values next-state moves)))

(fn check-pick-up [state pick-up-from]
    (case pick-up-from
      [:tableau col-n card-n]
      (let [(remaining held) (table.split (. state :tableau col-n) card-n)]
        (if (valid-sequence? state.rules held)
          (values held)
          (case held
            [nil] (values nil (<s> "No cards to pick up from tableau column #{col-n}"))
            _ (values nil (<s> "Must pick up run of alternating suit, descending rank")))))

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

    (_ [:tableau t-col t-card-n] _)
    (case (build-move-plan state pick-up-from [:tableau t-col (+ 1 t-card-n)])
      moves (let [next-state (-> (clone state)
                                 (inc-moves (length moves))
                                 (apply-events moves))
                  (_ new-run) (table.split (. next-state :tableau t-col) t-card-n)]
              (if (valid-sequence? state.rules new-run)
                (values next-state moves)
                ;; TODO: custom error message for bakers
                (values nil (<s> "Must build piles in alternating color, descending rank"))))
      _ (values nil (<s> "Not enough spaces to move #{len} cards" {:len (length held)})))

    ;; No op?
    _ (values nil (<s> "No putdown for #{dropped-on}"))))

(fn M.Action.move [state pick-up-from put-down-on]
  (case-try
    (check-pick-up state pick-up-from) held
    (put-down state pick-up-from put-down-on held) (next-state moves)
    (values next-state moves)))

(fn freecell-plan-next-move-to-foundation [state]
  ;; We stack on alternating colors, so we can safely move a card to a
  ;; foundation only if that card would no longer be put on a card +1 rank, in
  ;; alternate color. So we find the minimum value both colors, then check the
  ;; movable cards for any that are below the minimum value of the opposite
  ;; color. Since aces always move to the foundation, our actual "safe to move"
  ;; floor is 2
  (let [speculative-state (clone state)
        check-locations (fcollect [i 1 4] [:cell i])
        _ (fcollect [i 1 8 &into check-locations] [:tableau i])
        min-values (accumulate [min-vals {:red math.huge :black math.huge}
                                _l card (M.iter-cards speculative-state [:cell :tableau])]
                     (let [color (card-color card)
                           val (card-value card)]
                       (table.set min-vals color (math.min val (. min-vals color)))))
        source-locations (icollect [_ [field col] (ipairs check-locations)]
                           (let [card-n (length (. speculative-state field col))]
                             (case (. speculative-state field col card-n)
                               card (let [alt-color (if (= :red (card-color card)) :black :red)
                                          val (card-value card)]
                                      (if (or (<= (card-value card) (. min-values alt-color))
                                              (= 2 val))
                                        [field col card-n])))))]
    (accumulate [moves [] _ from (ipairs source-locations)]
      (fcollect [i 1 4 &into moves]
        (case (. speculative-state :foundation i)
          [nil] [from [:foundation i 0]]
          cards [from [:foundation i (length cards)]])))))

(fn bakers-plan-next-move-to-foundation [state]
  ;; Since bakers is built in suit, we can always move the lowest available
  ;; card in any suit to the foundations.
  (let [speculative-state (clone state)
        check-locations (fcollect [i 1 4] [:cell i])
        _ (fcollect [i 1 8 &into check-locations] [:tableau i])
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
                                        [field col card-n])))))]
    (accumulate [moves [] _ from (ipairs source-locations)]
      (fcollect [i 1 4 &into moves]
        (case (. speculative-state :foundation i)
          [nil] [from [:foundation i 0]]
          cards [from [:foundation i (length cards)]])))))

(fn M.Plan.next-move-to-foundation [state]
  (let [potential-moves (case state.rules
                         :freecell (freecell-plan-next-move-to-foundation state)
                         :bakers (bakers-plan-next-move-to-foundation state))]
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
