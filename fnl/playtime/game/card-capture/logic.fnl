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
  (CardGameUtils.make-card-util-fns {:value {1 14 :king 13 :queen 12 :jack 11}
                                     :color {:diamonds :red :hearts :red
                                             :clubs :black :spades :black}}))

(fn M.iter-cards [state]
  (fn iter []
    (each [_ side (ipairs [:enemy :player])]
      (each [_ field (ipairs [:draw :discard])]
        (each [card-n card (ipairs (or (. state side field) []))]
          (coroutine.yield [side field card-n] card)))
      (for [i 1 4]
        (let [card (. state side :hand i)]
          (if card
            (coroutine.yield [side :hand i] card))))))
  (coroutine.wrap iter))

(fn new-game-state []
  {:enemy {:draw []
           :hand []
           :discard []}
   :player {:draw []
            :hand []
            :discard []}
   :moves 0
   :winner false})

(λ M.build [_config ?seed]
  (fn ensure-no-faces-in-enemy-hand [enemy]
    ;; The rules say we should deal, then put any faces at the end of the deck
    ;; but we can just ensure the lead deal has no faces in it and we can do it
    ;; in the most dumb way possible.
    (macro not-a-face? [n] `(<= (card-value (. enemy ,n)) 10))
    (let [top (length enemy)
          no-faces? (faccumulate [ok? true i top (- top 4) -1]
                      (and ok? (<= (card-value (. enemy i)) 10)))]
      (if no-faces?
        enemy
        (ensure-no-faces-in-enemy-hand (table.shuffle enemy)))))
  (math.randomseed (or ?seed (os.time)))
  (let [deck (-> (Deck.Standard54.build)
                 (table.shuffle))
        (enemy player) (accumulate [(e p) (values [] []) _ c (ipairs deck)]
                         (if (or (<= (card-value c) 4) (= :joker (card-suit c)))
                           (values e (table.insert p c))
                           (values (table.insert e c) p)))
        enemy (ensure-no-faces-in-enemy-hand enemy)
        state (new-game-state)]
    (tset state :enemy :draw enemy)
    (tset state :player :draw player)
    state))

(λ fetch-by-index [seq indexes]
  (icollect [_ i (ipairs indexes)]
    (. seq i)))

(λ sum-hand [hand]
  (let [(hand-values joker-count) (accumulate [(vs js) (values [] 0)
                                               _ c (ipairs hand)]
                                    (case (card-suit c)
                                      :joker (values vs (+ js 1))
                                      _ (values (table.insert vs (card-value c)) js)))
        max (math.max 0 (table.unpack hand-values))
        sum (accumulate [sum 0 _ v (ipairs hand-values)] (+ sum v))]
    (+ sum (* max joker-count))))

(λ maybe-set-winner [state]
  ;; Enemy wins if the enemy discard contains any faces or aces
  ;; Player wins if the enemy draw and hand contains no cards.
  (let [discard-poisoned? (accumulate [die false
                                       _ c (ipairs state.enemy.discard)
                                       &until die]
                            (and (not (= :joker (card-suit c)))
                                 (< 10 (card-value c))))
        draw-empty? (= 0 (length state.enemy.draw))
        hand-empty? (= 0 (length (fcollect [i 1 4] (. state.enemy.hand i))))
        winner (if discard-poisoned? :enemy
                 (and draw-empty? hand-empty?) :player)]
    (table.set state :winner winner)))

(λ M.Action.both-draw [state]
  ;; The first deal has both sides draw, then the player may discard, then draw
  ;; again. Normally the player only discards from the previous hand then
  ;; draws.
  (case-try
    (M.Action.enemy-draw state) (next-state moves)
    (M.Action.player-draw next-state) (next-state more-moves)
    (let [moves (icollect [_ m (ipairs more-moves) &into moves] m)]
      (values next-state moves))))


(fn describe-pack-left-indexes [seq]
  (faccumulate [(seq moves) (values seq [])
                i 1 4]
    (case (. seq i)
      nil (let [pull (faccumulate [index nil i (+ i 1) 4 &until index]
                       (if (not (= nil (. seq i))) i))]
            (when pull
              (tset seq i (. seq pull))
              (tset seq pull nil)
              (table.insert moves [pull i]))
            (values seq moves))
      _ (values seq moves))))

(λ M.Action.enemy-draw [state]
  ;; Pack cards towards "exiting", then fill upto 4 cards.
  (let [next-state (clone state)
        (hand hand-moves) (describe-pack-left-indexes next-state.enemy.hand)
        moves (accumulate [t [] _ [from to] (ipairs hand-moves)]
                (table.insert t [:move [:enemy :hand from] [:enemy :hand to]]))
        len-draw (length next-state.enemy.draw)
        draw-moves (fcollect [i 1 (math.min len-draw (math.max 0 (- 4 (length hand))))]
                     [(- len-draw (- i 1)) (+ (length hand) i)])
        _ (accumulate [t moves _ [from to] (ipairs draw-moves)]
            (table.join t [[:move [:enemy :draw from] [:enemy :hand to]]
                           [:face-up [:enemy :hand to]]]))
        (next-state moves) (apply-events (clone state) moves {:unsafely? true})]
    (values next-state moves)))

(λ M.Action.player-draw [state]
  ;; Possibly flip & shuffle discard into draw, pull upto 4 cards.
  (let [state (clone state)
        missing-indexes (fcollect [i 1 4] (if (not (. state.player.hand i)) i))
        n-draw (length state.player.draw)
        ;; pull as many from draw as we can
        fill (faccumulate [t [] i 1 (math.min (length state.player.draw)
                                              (length missing-indexes))]
               (table.join t [[:move
                               [:player :draw (- (length state.player.draw) (- i 1))]
                               [:player :hand (. missing-indexes i)]]
                              [:face-up [:player :hand (. missing-indexes i)]]]))
        (state moves) (apply-events state fill {:unsafely? true})
        ;; find any still empty in hand indexes
        missing-indexes (fcollect [i 1 4] (if (not (. state.player.hand i)) i))
        ;; and if we have any, flip the discard and continue drawing
        (state moves) (if (< 0 (length missing-indexes))
                        (let [shift (faccumulate [t [] i (length state.player.discard) 1 -1]
                                      (table.insert t [:move
                                                       [:player :discard i]
                                                       [:player :draw :top]]))
                              (state shift) (apply-events state shift {:unsafely? true})
                              _ (table.join moves shift)
                              ;; TODO: this shuffle effects the future app game, not the
                              ;; current game, so when we draw the "draw to hand" animation,
                              ;; we'll pull the top n cards out, then swap to the shuffled deck
                              ;; which will show a different set of cards.
                              ;; Kind of complicated to fix perhaps, besides
                              ;; having an actual set of shuffle actions - which would need a way to skip
                              ;; any time lining, or we could shuffle, then find the ids in the old
                              ;; deck and the *old* locations?
                              ;; Alternatively we can deal these face down,
                              ;; then trigger another action to flip the faces
                              ;; which will happen after the game state is
                              ;; refreshed
                              _ (table.shuffle state.player.draw)
                              ;; We can build the shuffle, but now to skip this in the animation?
                              ; shuffle (let [swaps (table.shuffle (table.keys state.player.draw))]
                              ;           (accumulate [t [] i _ (ipairs state.player.draw)]
                              ;             (table.join t [[:move [:player :draw i] [:player :draw 0]]
                              ;                          [:move [:player :draw (. swaps i)] [:player :draw i]]
                              ;                          [:move [:player :draw 0] [:player :draw (. swaps i)]]])))
                              ; (state shuffle) (apply-events state shuffle {:unsafely? true})
                              ; _ (icollect [_ m (ipairs shuffle) &into moves] m)
                              fill (faccumulate [t [] i 1 (math.min (length state.player.draw)
                                                                    (length missing-indexes))]
                                     (table.join t [[:move
                                                     [:player :draw (- (length state.player.draw) (- i 1))]
                                                     [:player :hand (. missing-indexes i)]]
                                                    [:face-up [:player :hand (. missing-indexes i)]]]))
                              (state fill) (apply-events state fill {:unsafely? true})
                              _ (table.join moves fill)]
                          (values state moves))
                        (values state moves))]
    (values state moves)))

(λ M.Action.discard [state hand-cards]
  ;; Discard cards from player hand, then draw again
  (let [moves (accumulate [t [] i hand-i (ipairs hand-cards)]
                (-> (table.insert t [:move
                                     [:player :hand hand-i]
                                     [:player :discard :top]])
                    (table.insert [:face-down [:player :discard :top]])))
        (next-state moves) (apply-events (clone state) moves {:unsafely? true})]
    (values next-state moves)))

(λ M.Action.capture [state hand-indexes enemy-index]
  (let [hand-cards (fetch-by-index state.player.hand hand-indexes)
        [enemy-card] (fetch-by-index state.enemy.hand [enemy-index])
        hand-suits (-> (collect [_ c (ipairs hand-cards)]
                         (case (card-suit c)
                           :joker nil
                           suit (values suit true)))
                       (table.keys))
        hand-value (sum-hand hand-cards)
        enemy-suit (card-suit enemy-card)
        enemy-value (card-value enemy-card)]
    (if (and (= 1 (length hand-suits))
             (= enemy-suit (. hand-suits 1))
             (<= enemy-value hand-value))
      (let [moves (accumulate [t [] _ i (ipairs hand-indexes)]
                    (-> (table.insert t [:move
                                         [:player :hand i]
                                         [:player :discard :top]])
                        (table.insert [:face-down [:player :discard :top]])))
            _ (-> (table.insert moves [:move
                                       [:enemy :hand enemy-index]
                                       [:player :discard :top]])
                  (table.insert [:face-down [:player :discard :top]]))
            (state moves) (apply-events (clone state) moves {:unsafely? true})
            state (maybe-set-winner state)]
        (values state moves))
      (values nil (Error "Must select same suit and equal or greater combined value for capture")))))

(λ M.Action.yield [state hand-indexes]
  (if (= 1 (length hand-indexes))
    (let [moves (accumulate [t [] _ i (ipairs hand-indexes)]
                  (-> (table.insert t [:move
                                       [:player :hand i]
                                       [:enemy :discard :top]])
                      (table.insert [:face-down [:enemy :discard :top]])))
          _ (-> (table.insert moves [:move
                                     [:enemy :hand 1]
                                     [:enemy :discard :top]])
                (table.insert [:face-down [:enemy :discard :top]]))
          (state moves) (apply-events (clone state) moves {:unsafely? true})
          state (maybe-set-winner state)]
      (values state moves))
    (values nil (Error "Must select only one card to yield"))))

(λ M.Action.sacrifice [state hand-indexes enemy-index]
  (if (= 2 (length hand-indexes))
    (let [moves (accumulate [t [] _ i (ipairs hand-indexes)]
                  (-> (table.insert t [:move
                                       [:player :hand i]
                                       [:enemy :discard :top]])
                      (table.insert [:face-down [:enemy :discard :top]])))
          _ (-> (table.insert moves [:move
                                     [:enemy :hand enemy-index]
                                     [:enemy :draw :bottom]])
                (table.insert [:face-down [:enemy :draw :bottom]]))
          (state moves) (apply-events (clone state) moves {:unsafely? true})
          state (maybe-set-winner state)]
      (values state moves))
    (values nil (Error "Must select two cards to sacrifice"))))

(λ M.Query.game-ended? [state]
  state.winner)

(λ M.Query.game-result [state]
  state.winner)

M
