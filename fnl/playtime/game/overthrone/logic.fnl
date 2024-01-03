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
(set M.iter-cards (CardGameUtils.make-iter-cards-fn [:foundation :throne :draw :hand :discard]))
(local {: card-value : card-color : card-rank
        : card-suit : rank-value : suit-color
        : card-face-up? : card-face-down?
        : flip-face-up}
  (CardGameUtils.make-card-util-fns {:value {:king 13 :queen 12 :jack 11}
                                     :color {:diamonds :red :hearts :red
                                             :clubs :black :spades :black}}))

(fn new-game-state [hand-size]
  {:draw [[]]
   :foundation [[] [] [] []]
   :hand (fcollect [i 1 hand-size] [])
   :throne [[]]
   :discard [[]]
   :moves 0})

(λ M.build [config ?seed]
  (math.randomseed (or ?seed (os.time)))
  (let [deck (-> (Deck.Standard54.build)
                 (table.shuffle))
        ;; find first court and put on throne, drop one joker
        (deck lead) (accumulate [(t l) (values [] nil) _ c (ipairs deck)]
                      (case c
                        [:joker 2] (values t l)
                        (where c (< 10 (card-value c))) (if (nil? l)
                                                          (values t c)
                                                          (values (table.insert t c) l))
                        _ (values (table.insert t c) l)))
        state (new-game-state config.hand-size)]
    (flip-face-up lead)
    (tset state :draw 1 deck)
    (tset state :throne 1 [lead])
    state))

(fn M.Action.deal [state]
  (let [moves (faccumulate [t [] i (length state.hand) 1 -1]
                (table.join t [[:face-up [:draw 1 :top]]
                               [:move [:draw 1 :top] [:hand i 1]]]))]
    (apply-events (clone state) moves)))

(fn M.Action.draw [state]
  (let [empty (fcollect [i 1 (length state.hand)]
                (case (. state :hand i)
                  [nil] i))
        draw-count (math.min (length (. state :draw 1)) (length empty))
        moves (faccumulate [t [] i draw-count 1 -1]
                (table.join t [[:face-up [:draw 1 :top]]
                               [:move [:draw 1 :top] [:hand (. empty i) 1]]]))]
    (apply-events (clone state) moves)))

(fn check-pick-up [state pick-up-from]
  (case pick-up-from
    [:hand col-n 1] (. state :hand col-n)
    [:discard col-n card-n] (case (table.get-in state pick-up-from)
                              card (let [joker? (faccumulate [joker? false i 1 4 &until joker?]
                                                  (case (table.last (. state :foundation i))
                                                    [:joker] true))]
                                     (if joker?
                                       [card]
                                       (values nil (<s> "May only pick up from discard when joker is in play"))))
                              _ (values nil (<s> "Nothing to pick up")))
    [field]
    (values nil (<s> "May not pick up from #{field}"))))

(fn put-down [state pick-up-from dropped-on held]
  (case (values pick-up-from dropped-on held)
    ;; ignore pick-up-put-down on same location
    (where ([field col from-n] [field col on-n] _) (= from-n (+ 1 on-n)))
    nil

    ;; can drop on the discard
    ([:hand] [:discard])
    (let [moves [[:move pick-up-from [:discard 1 :top]]]]
      (-> (clone state)
          (inc-moves)
          (apply-events moves {:unsafely? true})))

    ;; Ascendance
    ([_] [:throne] [held-card])
    (let [throne-card (table.last (. state :throne 1))
          find-rank (fn [against]
                      (faccumulate [rank nil i 1 4 &until rank]
                        (case (table.last (. state :foundation i))
                          c (if (= (card-suit against) (card-suit c))
                              (card-value c)))))
          throne-rank (or (find-rank throne-card) 0)
          held-rank (or (find-rank held-card) 0)
          (ok? msg) (case (values (card-rank held-card) (card-rank throne-card))
                      ;; Kings may overthrow anyone
                      (:king _) true
                      ;; Queens may overthrow a king if their foundation is higher rank
                      (:queen :king) (values (or (= held-rank 1)
                                                 (< throne-rank held-rank))
                                             "Queens may overthrow Kings when their foundation is a higher rank")
                      ;; Queens may overthrow any jack
                      (:queen _) true
                      ;; Jacks may overthrow kings it their foundation is an ace
                      (:jack :king) (values (= 1 held-rank)
                                            "Jacks may overthrow Kings when their foundation is an Ace")
                      ;; Jacks may overthrow queens if their foundation is higher rank
                      (:jack :queen) (values (or (= 1 held-rank)
                                                 (< throne-rank held-rank))
                                             "Jacks may overthrow Queens when their foundation is a higher rank")
                      (:jack _) true)]
      (if ok?
        (let [moves [[:move pick-up-from [:throne 1 :top]]]]
          (-> (clone state)
              (inc-moves)
              (apply-events moves {:unsafely? true})))
        (values nil msg)))

    ;; Can start a foundation with any card, as long as the suit
    ;; is not in any other foundation.
    ([_] [:foundation f-col 0] [held-card])
    (let [suits (fcollect [i 1 4 &into [:joker]]
                  (case (. state :foundation i 1)
                    c (card-suit c)))]
      (if (not (eq-any? (card-suit held-card) suits))
        (let [moves [[:move pick-up-from [:foundation f-col 1]]]]
          (-> (clone state)
              (inc-moves)
              (apply-events moves {:unsafely? true})))
        (values nil (<s> "Can only start new foundations if suit not used"))))

    ([_] [:foundation f-col n] [[:joker]])
    (-> (clone state)
        (inc-moves)
        (apply-events [[:move pick-up-from [:foundation f-col (+ 1 n)]]]))


    ([_] [:foundation f-col n] [held-card])
    (let [lead-card (. state :foundation f-col 1)
          lead-suit (card-suit lead-card)
          throne-card (table.last (. state :throne 1))
          when-jack (fn []
                      ;; Aces are played into foundations irrespective of who
                      ;; is on the throne or any associated rules.
                      ;; May place same suit.
                      (or (= 1 (card-rank held-card))
                          (= (card-suit held-card) (card-suit throne-card))))
          when-queen (fn []
                       ;; May place if same value exist already.
                       (or (when-jack)
                           (let [vals (fcollect [i 1 4]
                                        (case (table.last (. state :foundation i))
                                          c (card-value c)))]
                             (eq-any? (card-value held-card) vals))))
          when-king (fn []
                      ;; May place +1 or -1 cards in same suit.
                      (or (when-jack)
                          (when-queen)
                          (let [on-card (table.get-in state dropped-on)
                                on-value (card-value on-card)
                                one-up (+ on-value 1)
                                ;; wrap jokers (0) to 13 (kings)
                                one-down (case (- on-value 1) -1 13 n n)]
                            (eq-any? (card-value held-card) [one-up one-down]))))
          check-fn (case (card-rank throne-card)
                     :king when-king
                     :queen when-queen
                     :jack when-jack)]
      (if (and (= (card-suit held-card) lead-suit) (check-fn))
        (let [moves [[:move pick-up-from [:foundation f-col (+ n 1)]]]]
          (-> (clone state)
              (inc-moves)
              (apply-events moves {:unsafely? true})))
        (case (card-rank throne-card)
          :king (values nil "Must play same suit as throne, or any matching rank, or +1 -1 rank")
          :queen (values nil "Must play same suit as throne, or any matching rank")
          :jack (values nil "Must play same suit as throne"))))))

(fn M.Action.move [state pick-up-from put-down-on]
  (case-try
    (check-pick-up state pick-up-from) held
    (put-down state pick-up-from put-down-on held) (next-state moves)
    (values next-state moves)))

(fn M.Query.liftable? [state location]
  (not (nil? (check-pick-up state location))))

(fn M.Query.droppable? [state location]
  (case location
    [field] (eq-any? field [:foundation :throne :discard])
    _ false))

(fn M.Query.game-result [state]
  (let [count (+ (length (. state.discard 1))
                 (accumulate [sum 0 _ t (ipairs state.hand)]
                   (+ sum (length t))))]
    count))

(fn M.Query.game-ended? [state]
  (let [count (+ (length (. state.draw 1))
                 (accumulate [sum 0 _ t (ipairs state.hand)]
                   (+ sum (length t))))]
    (= 0 count)))

M
