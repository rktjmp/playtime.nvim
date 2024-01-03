(require-macros :playtime.prelude)
(prelude)

(local Error (require :playtime.error))
(local Logger (require :playtime.logger))
(local Deck (require :playtime.common.card.deck))
(local CardGameUtils (require :playtime.common.card.utils))

(local M {:Action {}
          :Plan {}
          :Query {}})

(local {: apply-events} CardGameUtils)
(local {: card-value : card-color : card-rank : card-suit
        : rank-value
        : suit-color
        : card-face-up? : card-face-down?
        : flip-face-up : flip-face-down}
  (CardGameUtils.make-card-util-fns {:value {:king 13 :queen 12 :jack 11}
                                     :color {:diamonds :red :hearts :red
                                             :clubs :black :spades :black}}))

(fn kingdom-suit [state]
  (card-suit (. state.kingdom state.at-kingdom 1)))

(set M.card-value card-value)

(λ M.build [_config ?seed]
  (math.randomseed (or ?seed (os.time)))
  (let [deck (-> (Deck.Standard52.build)
                 (Deck.shuffle))
        (numbered court) (Deck.split deck (fn [card] (type.number? (. card 2))))
        (advisors rulers) (Deck.split court (fn [card] (= :jack (. card 2))))
        (draw _not-used) (Deck.split numbered (fn [card] (< (. card 2) 9)))
        state {:at-kingdom nil
               :kingdom [[] [] [] []
                         [] [] [] []]
               :discard []
               :score []
               :debate []
               :draw []
               :hand []
               :advisor {:hearts []
                         :diamonds []
                         :spades []
                         :clubs []}}]
    (each [i c (ipairs rulers)]
      (tset state :kingdom i 1 (flip-face-up c)))
    (each [_ c (ipairs advisors)]
      (tset state :advisor (card-suit c) 1 (flip-face-up c)))
    (tset state :draw draw)
    state))

(fn sort-hand! [hand]
  (-> (table.sort hand (fn [a b]
                         (< (card-value a)
                            (card-value b))))
      (table.sort (fn [a b]
                    (let [t {:hearts 1 :spades 2 :diamonds 3 :clubs 4}
                          a (. t (card-suit a))
                          b (. t (card-suit b))]
                      (< a b))))))

(fn moves-to-pack-hand [old-hand new-hand]
  (let [packed (faccumulate [(t to) (values [] 1) i 1 (length old-hand)]
                 (case (. new-hand i)
                   nil (values t to)
                   any (values (doto t (table.insert [i to])) (+ to 1))))]
    (icollect [_ [a b] (ipairs packed)]
      (if (not (= a b))
        [:move [:hand a] [:hand b]]))))

(λ M.Action.deal [state]
  (let [top (length state.draw)
        events (faccumulate [t [] i top (- top 7) -1]
                 (-> (table.insert t [:move [:draw i] [:hand :top]])
                     (table.insert [:face-up [:hand :top]])))
        (state events) (apply-events (clone state) events)]
    (set state.hand (sort-hand! state.hand))
    (values state events)))

(λ M.Action.pick-kingdom [state n]
  (case (. state :kingdom n)
    [{:face :up}] (table.set (clone state) :at-kingdom n)
    _ (values nil (Error "Cant pick kingdom #{n}" {: n}))))

(λ M.Action.draw [state]
  (if (not state.at-kingdom)
    (values nil (Error "Cant draw, not visiting a kingdom"))
    (let [(state moves) (if (= 0 (length state.draw))
                          (let [moves (accumulate [t [] i _ (ipairs state.discard)]
                                        (-> (table.insert t [:face-down [:discard i]])
                                            (table.insert [:move [:discard i] [:draw :top]])))
                                (state moves) (apply-events (clone state) moves)]
                            (table.shuffle state.draw)
                            (values state moves))
                          (values (clone state) []))
          (state more-moves) (apply-events state [[:move [:draw :top] [:debate :top]]
                                                  [:face-up [:debate :top]]])
          moves (icollect [_ m (ipairs more-moves) &into moves] m)]
      (values state moves))))

(λ M.Action.play-hand [state hand-n]
  (let [against-card (table.last state.debate)
        against-suit (card-suit against-card)
        against-value (card-value against-card)
        played-card (. state.hand hand-n)
        played-suit (card-suit played-card)
        played-value (card-value played-card)
        has-suit? (accumulate [yes? false _ c (ipairs state.hand) &until yes?]
                    (= against-suit (card-suit c)))
        playing-suit? (= against-suit played-suit)]
    (if (and has-suit? (not playing-suit?))
      (values nil (Error "Must follow suit if you can, you have a #{suit} in hand" {:suit against-suit}))
      (let [trump-suit (card-suit (. state.kingdom state.at-kingdom 1)) ;; todo nicer
            won? (case (values against-suit against-value played-suit played-value)
                   ;; Same suit, including trump suit, must have higher value
                   (suit against suit played) (< against played)
                   ;; Otherwise any trump is a win
                   (where (_ _ (= trump-suit) _)) true
                   _ false)
            moves [[:move [:hand hand-n] [:debate :top]]]
            moves (if won?
                    (-> moves
                        (table.insert [:move [:debate 2] [:score :top]])
                        (table.insert [:move [:debate 1] [:discard :top]]))
                    (-> moves
                        (table.insert [:move [:debate 2] [:discard :top]])
                        (table.insert [:move [:debate 1] [:discard :top]])))
            moves (fcollect [i (+ hand-n 1) (length state.hand) &into moves]
                    [:move [:hand i] [:hand (- i 1)]])]
        (apply-events (clone state) moves {:unsafely? true})))))

(λ M.Action.finish-kingdom [state]
  (let [wins-wanted state.at-kingdom
        wins-count (length state.score)
        advisor-moves (if (= wins-count wins-wanted)
                        [[:move [:kingdom wins-wanted 1] [:advisor (kingdom-suit state) :top]]]
                        [[:face-down [:kingdom wins-wanted 1]]])
        draw-moves (let [into-draw []]
                     (each [i _ (ipairs state.discard)]
                       (table.join into-draw [[:move [:discard i] [:draw :top]]
                                              [:face-down [:draw :top]]]))
                     (each [i _ (ipairs state.score)]
                       (table.join into-draw [[:move [:score i] [:draw :top]]
                                              [:face-down [:draw :top]]]))
                     into-draw)
        refresh-moves (let [refresh []]
                        (each [_ suit (ipairs [:hearts :clubs :spades :diamonds])]
                          (each [i c (ipairs (. state.advisor suit))]
                            (if (= :jack (card-rank c))
                              (table.join refresh [[:face-up [:advisor suit i]]]))))
                        refresh)
        events (table.join advisor-moves draw-moves refresh-moves)
        (next-state events) (apply-events (clone state) events)]
    (set next-state.at-kingdom nil)
    (each [_ suit (ipairs [:hearts :clubs :spades :diamonds])]
      (table.sort (. next-state.advisor suit)
                  ;; king down
                  (fn [a b] (< (card-value b) (card-value a)))))
    (table.shuffle next-state.draw)
    (values next-state events)))

(λ M.Action.diplomacy [state advisor-n]
  ; Discard all cards in your hand that match the current kingdom's trump suit.
  (case-try
    (M.Query.diplomacy state advisor-n) true
    (let [moves (icollect [i c (ipairs state.hand)]
                  (if (= (card-suit c) (kingdom-suit state))
                    [:move [:hand i] [:discard :top]]))
          (next-state discard-events) (apply-events (clone state) moves)
          moves (moves-to-pack-hand state.hand next-state.hand)
          (next-state hand-events) (apply-events next-state moves)
          (next-state exhausted) (apply-events next-state [[:face-down [:advisor :hearts advisor-n]]])]
      (values next-state (table.join discard-events hand-events exhausted)))))

(λ M.Action.military [state advisor-n]
  ; Draw a card for each club in your hand.
  (case-try
    (M.Query.military state advisor-n) true
    (let [count (accumulate [sum 0 _ c (ipairs state.hand)]
                  (if (= :clubs (card-suit c))
                    (+ sum 1) sum))
          pull (math.min count (length state.draw))
          moves (faccumulate [t [] i 1 pull]
                  (table.join t [[:move [:draw :top] [:hand :top]]
                                 [:face-up [:hand :top]]]))
          (next-state draw-events) (apply-events (clone state) moves)
          (next-state exhausted) (apply-events next-state [[:face-down [:advisor :clubs advisor-n]]])]
      (sort-hand! next-state.hand)
      (values next-state (table.join draw-events exhausted)))))

(λ M.Action.politics [state advisor-n kingdom-n]
  ; Swap the current ruler with the ruler of an unvisited kingdom. This changes
  ; the trump suit for all debates of this kingdom moving forward, and also for
  ; that other kingdom when you visit it. This ability does nothing when you’re
  ; visiting the final kingdom.
  (case-try
    (M.Query.politics state advisor-n) true
    (. state :kingdom kingdom-n 1) card
    (card-face-up? card) true
    (let [events [[:swap
                   [:kingdom state.at-kingdom 1]
                   [:kingdom kingdom-n 1]]]
          (next-state swap-events) (apply-events (clone state) events)
          (next-state exhausted) (apply-events next-state [[:face-down [:advisor :spades advisor-n]]])]
      (values next-state (table.join swap-events exhausted)))
    (catch
      (nil err) (values nil err)
      false (values nil (<s> "cant swap with an exhausted kingdom"))
      nil (values nil (<s> "cant swap with kingdom")))))

(λ M.Action.commerce [state advisor-n ?discards]
  ; Diamonds (commerce) - Draw two cards, then choose and discard two cards from your hand.
  (case-try
    (M.Query.commerce state advisor-n) true
    (case ?discards
      ;; first time, just draw
      nil (let [pull (math.min 2 (length state.draw))
                moves (faccumulate [t [] i 1 pull]
                        (table.join t [[:move [:draw :top] [:hand :top]]
                                       [:face-up [:hand :top]]]))
                (next-state draw-events) (apply-events (clone state) moves)]
            (sort-hand! next-state.hand)
            (values next-state draw-events))
      ;; second time, discards
      [a b] (let [moves [[:move [:hand a] [:discard :top]]
                         [:move [:hand b] [:discard :top]]]
                  (next-state discard-events) (apply-events (clone state) moves)
                  moves (moves-to-pack-hand state.hand next-state.hand)
                  (next-state hand-events) (apply-events next-state moves)
                  (next-state exhausted) (apply-events next-state [[:face-down [:advisor :diamonds advisor-n]]])]
              (values next-state (table.join discard-events hand-events exhausted))))))

(fn check-advisor [state suit advisor-n]
  (case (. state :advisor suit advisor-n)
    card (if (card-face-up? card)
           true
           (values nil (<s> "advisor exhausted")))
    nil (values nil (<s> "no advisor at #{advisor-n}"))))

(λ M.Query.diplomacy [state advisor-n]
  (check-advisor state :hearts advisor-n))

(λ M.Query.military [state advisor-n]
  (check-advisor state :clubs advisor-n))

(λ M.Query.politics [state advisor-n]
  (check-advisor state :spades advisor-n))

(λ M.Query.commerce [state advisor-n]
  (check-advisor state :diamonds advisor-n))

(λ M.iter-cards [state ?fields]
  (fn iter []
    (each [_ field (ipairs (or ?fields [:kingdom]))]
      (each [col-n column (ipairs (. state field))]
        (each [card-n card (ipairs column)]
          (coroutine.yield [field col-n card-n] card))))
    (each [_ suit (ipairs [:hearts :clubs :spades :diamonds])]
      (each [i card (ipairs (. state :advisor suit))]
        (coroutine.yield [:advisor suit i] card)))
    (each [_ field (ipairs [:draw :debate :discard :score :hand])]
      (each [card-n card (ipairs (. state field))]
        (coroutine.yield [field card-n] card))))
  (coroutine.wrap iter))

(λ M.Query.hand-exhausted? [state]
  (= 0 (length state.hand)))


(λ M.Query.game-ended? [state]
  ;; Ended when we've visited all and won (card now in advisors)
  ;; or lost (card face down)
  (accumulate [yes? true _ k (ipairs state.kingdom) &until (not yes?)]
    (case k
      [nil] true
      [c] (card-face-down? c))))

(λ M.Query.game-result [state]
  ;; A win is support of all 8 kingdoms, score bonus awarded per un-unsed kingdom
  (let [supporting (icollect [_ k (ipairs state.kingdom)]
                     (case k
                       [nil] true))
        unused []
        _ (each [suit t (pairs state.advisor)]
            (each [_ c (ipairs t)]
              (if (and (not (= :jack (card-rank c)))
                       (card-face-up? c))
                (table.insert unused true))))
        won? (= 8 (length supporting))
        score? (+ (length supporting) (length unused))]
    [won? score?]))

M
