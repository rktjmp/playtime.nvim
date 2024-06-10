(require-macros :playtime.prelude)
(prelude)

(local Error (require :playtime.error))
(local Logger (require :playtime.logger))
(local Deck (require :playtime.game.shenzhen-solitaire.deck))
(local CardGameUtils (require :playtime.common.card.utils))

(local {: location-contents : inc-moves : apply-events} CardGameUtils)

(local M {:Action {}
          :Plan {}
          :Query {}})

(set M.iter-cards (CardGameUtils.make-iter-cards-fn [:cell :flower :foundation :tableau]))
(local {: card-value : card-rank : card-suit : rank-value : suit-color : flip-face-up}
  (CardGameUtils.make-card-util-fns {:value {} :color {}}))

(fn new-game-state []
  {:foundation [[] [] []]
   :flower [[]]
   :tableau [[] [] [] [] [] [] [] []]
   :cell [[] [] []]
   :moves 0
   :locked {:red false :green false :white false}})

(λ M.build [_config ?seed]
  (math.randomseed (or ?seed (os.time)))
  (let [tableau-cards (-> (Deck.Shenzhen.build)
                          (Deck.shuffle))
        state (new-game-state)]
    (each [_ c (ipairs tableau-cards)] (flip-face-up c))
    (tset state.flower 1 tableau-cards)
    state))

(local valid-tableau-sequence?
  (CardGameUtils.make-valid-sequence?-fn
    (fn [next-card [last-card]]
      ;; You can only pick up sequences of coins, strings and myriads.
      (let [last-suit (card-suit last-card)
            last-value (card-value last-card)
            next-suit (card-suit next-card)
            next-value (card-value next-card)]
        (and (not (eq-any? next-suit [:flower :green :red :white]))
             (not (= last-suit next-suit))
             (= last-value (+ next-value 1)))))))

(local winning-foundation-sequence?
  (do
    (local valid-sequence?
      (CardGameUtils.make-valid-sequence?-fn
        (fn [next-card [last-card]]
          (values (and (= (card-suit next-card) (card-suit last-card))
                       (= (card-value next-card) (+ 1 (card-value last-card))))))))
    (fn [sequence]
      (and (= 9 (length sequence))
           (valid-sequence? sequence)))))

(local winning-flower-sequence?
  (fn [sequence]
    (case sequence
      [[:flower] nil] true
      _ false)))

(local winning-dragon-sequence?
  (do
    (local valid-sequence?
      (CardGameUtils.make-valid-sequence?-fn
        (fn [next-card [last-card]]
          (values (and (eq-any? (card-suit next-card) [:red :green :white])
                       (= (card-suit next-card) (card-suit last-card)))))))
    (fn [sequence]
      (and (= 4 (length sequence))
           (valid-sequence? sequence)))))


(fn M.Action.deal [state]
  ;; Build tableau left to right top to bottom from the deck in flower
  (let [moves (faccumulate [(moves t-col row) (values [] 1 1)
                            i (length (. state :flower 1)) 1 -1]
                (let [from [:flower 1 i]
                      to [:tableau t-col row]]
                  (values (table.insert moves [:move from to])
                          (if (= t-col 8) 1 (+ t-col 1))
                          (if (= t-col 8) (+ row 1) row))))
        (next-state moves) (apply-events (clone state) moves)]
    (values next-state moves)))

(fn check-pick-up [state pick-up-from]
  (case pick-up-from
    [:tableau col-n card-n]
    (let [(remaining held) (table.split (. state :tableau col-n) card-n)]
      (if (valid-tableau-sequence? held)
        (values held)
        (case held
          [nil] (values nil (Error "No cards to pick up from tableau column #{col-n}" {: col-n}))
          _ (values nil (Error (.. "Must pick up single dragon or flower or run of alternating suit, descending rank"))))))

    [:cell col-n 1]
    (let [(remaining held) (table.split (. state :cell col-n) 1)]
      (case (length held)
        1 (values held)
        0 (values nil (Error "No card to pick up from free cell"))
        n (values nil (Error "May only pick up one card at a time from free cell"))))

    [field] (values nil (Error "May not pick up from #{field}" {: field}))))

(fn put-down [state pick-up-from dropped-on held]
  (case (values pick-up-from dropped-on held)
    ;; ignore pick-up-put-down on same location
    (where ([field col from-n] [field col on-n] _) (= from-n (+ 1 on-n)))
    nil

    ;; Must be on a tail
    (where (_ [field col-n card-n] _) (not (= card-n (length (. state field col-n)))))
    (values nil (Error "Must place cards on the bottom of a cascade"))

    ;; Only flower to flower
    (_ [:flower 1 0] [[:flower] nil])
    (-> (clone state)
        (inc-moves)
        (apply-events [[:move pick-up-from [:flower 1 1]]]))

    (where (or (_ [:flower 1 0] _) (_ _ [[:flower]])))
    (values nil (Error "May only place flower cards in flower foundation"))

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
      _ (values nil (Error "Must build foundations same suit, 1, 2, ... 9")))

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

    ;; You can move one card to an empty cell
    (_ [:cell col-n 0] [new-card nil])
    (-> (clone state)
        (inc-moves)
        (apply-events [[:move pick-up-from [:cell col-n 1]]]))

    ;; You may re-sort the tableau by dragging from slot 1 to slot 0
    ;; without any cost
    (where ([:tableau a 1] [:tableau b 0] _) (not (= a b)))
    (let [from-col (. state :tableau a)
          moves (icollect [i _card (ipairs from-col)]
                  [:move [:tableau a i] [:tableau b i]])]
      (apply-events (clone state) moves {:unsafely? true}))

    ;; You may place many cards on a tableau when forming a alternating suit, descending rank.
    ([f-field f-col f-card-n] [:tableau t-col t-card-n] held)
    (let [moves (fcollect [i 1 (length held)]
                  [:move
                   [f-field f-col (+ f-card-n (- i 1))]
                   [:tableau t-col (+ t-card-n i)]])
          next-state (-> (clone state)
                         (inc-moves)
                         (apply-events moves {:unsafely? true}))
          (_ new-run) (table.split (. next-state :tableau t-col) t-card-n)]
      (if (valid-tableau-sequence? new-run)
        (values next-state moves)
        (values nil (Error "Must build piles in alternating suit, descending rank"))))

    ;; No op?
    _ (values nil (Error "No putdown for #{field}" {:field dropped-on}))))

(fn M.Action.move [state pick-up-from put-down-on]
  (case-try
    (check-pick-up state pick-up-from) held
    (put-down state pick-up-from put-down-on held) (next-state moves)
    (values next-state moves)))

(fn M.Action.lock-dragon [state dragon-color]
  ;; To lock a dragon, we must have access to all 4 cards, and either a free
  ;; cell, or one of the dragons must be in a cell.
  (let [dragons (icollect [location card (M.iter-cards state)]
                  (case card (where [(= dragon-color)]) [location card]))
        check-already-locked? #(. state.locked dragon-color)
        check-can-move-dragons? #(accumulate [movable? true _ [location _card] (ipairs dragons)
                                              &until (not movable?)]
                                   (case location
                                     ;; Already in a cell is fine
                                     [:cell] true
                                     ;; Must be the last card in a tableau column
                                     (where [:tableau col-n card-n] (= card-n (length (. state.tableau col-n)))) true
                                     _ false))
        existing-dragon-cell #(accumulate [index nil
                                           [_cell n] card (M.iter-cards state [:cell])
                                           &until index]
                                (case card
                                  (where [(= dragon-color)]) n))
        next-free-cell #(accumulate [free-i nil i col (ipairs state.cell) &until free-i]
                          (if (table.empty? col) i))]
    (case-try
      (check-already-locked?) false
      (check-can-move-dragons?) true
      (or (existing-dragon-cell) (next-free-cell)) into-cell
      (let [i-index (length (. state :cell into-cell))
            moves (accumulate [(t n) (values [] 1) i [location card] (ipairs dragons)]
                    (case location
                      (where [:cell (= into-cell)]) (values t n)
                      [field col-n card-n] (values
                                             (table.insert t [:move location [:cell into-cell (+ i-index n)]])
                                             (+ n 1))))
            (next-state moves) (apply-events (clone state) moves)]
        (tset next-state.locked dragon-color true)
        ;; Since moving one dragon to a cell is 1 move, locking the dragons is
        ;; +1 move for each dragon.
        (set next-state.moves (+ (length moves) next-state.moves))
        (values next-state moves))
      (catch
        _ (values nil (Error "Unable to lock dragon"))))))

(fn M.Plan.next-move-to-flower [state]
  (if (= 0 (length (. state :flower 1)))
    (let [speculative-state (clone state)
          check-locations (fcollect [i 1 3] [:cell i])
          _ (fcollect [i 1 8 &into check-locations] [:tableau i])
          from (accumulate [location nil
                            _ [field col] (ipairs check-locations)
                            &until location]
                 (let [card-n (length (. speculative-state field col))]
                   (case (. speculative-state field col card-n)
                     [:flower] [field col card-n])))
          to [:flower 1 0]]
      (if from
        (case-try
          (M.Action.move speculative-state from to) speculative-state
          [from to])))))

(fn M.Plan.next-move-to-foundation [state]
  ;; Find the lowest value still playable, if any movable non-dragon card is
  ;; that value, we can safely move it to the foundation.
  ;; Check left to right, cells then tableau.
  (let [speculative-state (clone state)
        check-locations (fcollect [i 1 3] [:cell i])
        _ (fcollect [i 1 8 &into check-locations] [:tableau i])
        min-value (accumulate [min-val math.huge
                               _l card (M.iter-cards speculative-state [:cell :tableau])]
                    (case card
                      (where [suit val] (eq-any? suit [:coins :myriads :strings]))
                      (math.min val min-val)
                      _ min-val))
        not-dragon? (fn [suit] (eq-any? suit [:coins :myriads :strings]))
        source-locations (icollect [_ [field col] (ipairs check-locations)]
                           (let [card-n (length (. speculative-state field col))]
                             (case (. speculative-state field col card-n)
                               [suit val] (if (and (not-dragon? suit) (= min-value val))
                                            [field col card-n]))))
        potential-moves (accumulate [moves [] _ from (ipairs source-locations)]
                          (fcollect [i 1 4 &into moves]
                            (case (. speculative-state :foundation i)
                              [nil] [from [:foundation i 0]]
                              cards [from [:foundation i (length cards)]])))]
    (accumulate [actions nil _ [from to] (ipairs potential-moves) &until actions]
      (case-try
        (M.Action.move speculative-state from to) speculative-state
        [from to]))))

(fn M.Query.liftable? [state location]
  (not (nil? (check-pick-up state location))))

(fn M.Query.droppable? [state location]
  (case location
    [field] (eq-any? field [:tableau :cell :flower :foundation])
    _ false))

(fn M.Query.game-ended? [state]
  (let [foundations? (faccumulate [won? true i 1 3]
                       (and won? (winning-foundation-sequence? (location-contents state [:foundation i]))))
        flower? (winning-flower-sequence? (location-contents state [:flower 1]))
        dragons? (faccumulate [won? true i 1 3]
                   (and won? (winning-dragon-sequence? (location-contents state [:cell i]))))]
    (and foundations? flower? dragons?)))

(fn M.Query.game-result [state]
  (M.Query.game-ended? state))

M
