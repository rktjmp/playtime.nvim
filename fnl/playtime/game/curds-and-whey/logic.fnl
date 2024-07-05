(require-macros :playtime.prelude)
(prelude)

(local Error (require :playtime.error))
(local Logger (require :playtime.logger))
(local Deck (require :playtime.common.card.deck))
(local CardGameUtils (require :playtime.common.card.utils))

(local M {:Action {}
          :Plan {}
          :Query {}})

(local {: inc-moves
        : apply-events} CardGameUtils)
(set M.iter-cards (CardGameUtils.make-iter-cards-fn [:draw :tableau :complete]))
(local {: card-value : card-color : card-rank
        : card-suit : rank-value : suit-color
        : card-face-up? : card-face-down?}
  (CardGameUtils.make-card-util-fns {:value {:king 13 :queen 12 :jack 11}
                                     :color {:diamonds :red :hearts :red
                                             :clubs :black :spades :black}}))

(fn new-game-state []
  {:draw [[]]
   :tableau [[] [] [] [] []
             [] [] [] [] []
             [] [] []]
   :complete [[] [] [] []]
   :moves 0})

(λ M.build [config ?seed]
  (math.randomseed (or ?seed (os.time)))
  (let [deck (-> (Deck.Standard52.build)
                 (Deck.shuffle))
        state (new-game-state)]
    (tset state :draw 1 deck)
    (tset state :suits config.suits)
    state))

(local (valid-build-sequence? valid-move-sequence?)
  (let [same-rank-any-suit (fn [next-card [last-card]]
                             (let [last-value (card-value last-card)
                                   next-value (card-value next-card)]
                               (= last-value next-value)))
        desc-rank-same-suit (fn [next-card [last-card]]
                              (let [last-value (card-value last-card)
                                    next-value (card-value next-card)
                                    last-suit (card-suit last-card)
                                    next-suit (card-suit next-card)]
                                (and (= last-suit next-suit)
                                     (= last-value (+ next-value 1)))))
        build? (CardGameUtils.make-valid-sequence?-fn
                 (fn [next-card other-cards]
                   (or (same-rank-any-suit next-card other-cards)
                       (desc-rank-same-suit next-card other-cards))))
        move? (fn [sequence]
                (let [a (CardGameUtils.make-valid-sequence?-fn same-rank-any-suit)
                      b (CardGameUtils.make-valid-sequence?-fn desc-rank-same-suit)]
                  (or (a sequence) (b sequence))))]
    (values build? move?)))

(fn complete-sequence? [sequence]
  (and (= (rank-value :king) (length sequence))
       (valid-move-sequence? sequence)))

(fn M.Action.deal [state]
  (let [moves (faccumulate [(moves t-col row) (values [] 1 1)
                            i (length (. state :draw 1)) 1 -1]
                (let [from [:draw 1 i]
                      to [:tableau t-col row]
                      move [:move from to]
                      flip [:face-up from]]
                  (values (-> (table.insert moves flip)
                              (table.insert move))
                          (if (= t-col 13) 1 (+ t-col 1))
                          (if (= t-col 13) (+ row 1) row))))
        (next-state moves) (apply-events (clone state) moves)]
    (values next-state moves)))

(fn check-pick-up [state pick-up-from]
  (case pick-up-from
    [:tableau col-n card-n]
    (let [(remaining held) (table.split (. state :tableau col-n) card-n)]
      (if (valid-move-sequence? held)
        (values held)
        (case held
          [nil] (values nil (Error "No cards to pick up from tableau column #{col-n}" {: col-n}))
          _ (values nil (Error (.. "Must pick up run of same suit, descending rank, or any suit, same rank"))))))

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

    ;; You may re-sort the tableau by dragging from slot 1 to slot 0
    ;; without any cost or max-move checks
    (where ([:tableau a 1] [:tableau b 0] _) (not (= a b)))
    (let [from-col (. state :tableau a)
          moves (icollect [i _card (ipairs from-col)]
                  [:move [:tableau a i] [:tableau b i]])]
      (-> (clone state)
          (apply-events moves {:unsafely? true})))

    ([:tableau f-col f-card-n] [:tableau t-col t-card-n] held)
    (let [moves (fcollect [i 1 (length held)]
                  [:move
                   [:tableau f-col (+ f-card-n (- i 1))]
                   [:tableau t-col (+ t-card-n i)]])
          one-up [:tableau f-col (- f-card-n 1)]
          _ (case (table.get-in state one-up)
              {:face :down} (table.insert moves [:face-up one-up]))
          next-state (-> (clone state)
                         (inc-moves)
                         (apply-events moves))
          (_ new-run) (table.split (. next-state :tableau t-col) t-card-n)]
      (case (values t-card-n (. held 1))
        (0 [_suit :king]) (values next-state moves)
        (0 _) (values nil (Error "May only place kings in empty slots"))
        _ (if (valid-build-sequence? new-run)
            (values next-state moves)
            (values nil (Error "Must build piles in same suit, descending rank or any suit, same rank")))))

    ;; No op?
    _ (values nil (Error "No putdown for #{field}" {:field dropped-on}))))

(fn M.Action.move [state pick-up-from put-down-on]
  (case-try
    (check-pick-up state pick-up-from) held
    (put-down state pick-up-from put-down-on held) (next-state moves)
    (values next-state moves)))

(fn M.Action.remove-complete-sequence [state sequence-starts-at]
  (case-try
    (check-pick-up state sequence-starts-at) held
    (length held) 13
    (complete-sequence? held) true
    (let [complete-n (accumulate [index nil i c (ipairs state.complete) &until index]
                       (if (= 0 (length c)) i))
          [f-field f-col f-card-n] sequence-starts-at
          moves (fcollect [i (+ f-card-n 12) f-card-n -1]
                  [:move
                   [f-field f-col i]
                   [:complete complete-n (- (+ f-card-n 12) (- i 1))]])
          one-up [:tableau f-col (- f-card-n 1)]
          _ (case (table.get-in state one-up)
              {:face :down} (table.insert moves [:face-up one-up]))
          (next-state moves) (apply-events (clone state) moves)]
      (values next-state moves))
    (catch
      ;; this should only be auto-triggerd, so probably we dont want to notify
      ;; on a lift fail etc.
      (nil err) (do))))

(fn M.Plan.next-complete-sequence [state]
  (let [from (accumulate [start-at nil
                          col-n col (ipairs state.tableau)
                          &until start-at]
               (let [index (math.max 1 (- (length col) 12))
                     (_ run) (table.split col index)]
                 (if (complete-sequence? run)
                   [:tableau col-n index])))]
    from))

(fn M.Query.liftable? [state location]
  (not (nil? (check-pick-up state location))))

(fn M.Query.droppable? [state location]
  (case location
    [field] (eq-any? field [:tableau])
    _ false))

(fn M.Query.game-ended? [state]
  (accumulate [won? true _ stack (ipairs state.complete)]
    (and won? (= 13 (length stack)))))

(fn M.Query.game-result [state]
  (M.Query.game-ended? state))

M
