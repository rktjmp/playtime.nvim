(require-macros :playtime.prelude)
(prelude)

(local Error (require :playtime.error))
(local Logger (require :playtime.logger))
(local Deck (require :playtime.game.set.deck))

(local CardGameUtils (require :playtime.common.card.utils))
(local {: apply-events} CardGameUtils)

(local M {:Action {}
          :Plan {}
          :Query {}})

(fn card->vector [card]
  (let [vals {:color {:red 0 :green 1 :blue 2}
              :count {1 0 2 1 3 2}
              :style {:solid 0 :split 1 :outline 2}
              :shape {:square 0 :circle 1 :triangle 2}}
        {: color : count : style : shape} card]
    [(. vals.color color)
     (. vals.count count)
     (. vals.style style)
     (. vals.shape shape)]))

(λ set? [a b c]
  (fn vector-report [vector]
    (let [bads (icollect [i name (ipairs [:color :count :style :shape])]
                 (when (not (= 0 (. vector i)))
                   name))]
      (case bads
        [nil] nil
        bads (.. "Not a set, check " (table.concat bads ", ")))))
  (let [sum (let [[av bv cv] (icollect [_ c (ipairs [a b c])] (card->vector c))]
              (faccumulate [sum [0 0 0 0] i 1 4]
                (table.set sum i (-> (+ (. av i) (. bv i) (. cv i))
                                     (% 3)))))]
    (case sum
      [0 0 0 0] true
      sum (values false (vector-report sum)))))

(λ find-sets [cards]
  (let [sets []
        limit (length cards)]
    (for [a 1 (- limit 3)]
      (for [b (+ a 1) (- limit 1)]
        (for [c limit (+ b 1)  -1]
          (let [ca (. cards a)
                cb (. cards b)
                cc (. cards c)]
            (if (set? ca cb cc)
              (table.insert sets [ca cb cc]))))))
    sets))

(λ M.build [config ?seed]
  (math.randomseed (or ?seed (os.time)))
  (let [state {:draw (-> (Deck.Set.build)
                         (Deck.shuffle))
               :deal []
               :discard []}]
    state))

(λ M.iter-cards [state]
  (fn iter []
    (each [i card (ipairs state.draw)]
      (coroutine.yield [:draw i] card))
    ;; The deal will be 12 cards minimum until the end of the game where we
    ;; cant draw any more, at this point the list will begin to get holes in
    ;; it.
    (let [len-deal (case (length state.deal)
                     (where n (< 12 n)) n
                     _ 12)]
      (for [i 1 len-deal]
        (case (. state.deal i)
          card (coroutine.yield [:deal i] card))))
    (each [i card (ipairs state.discard)]
      (coroutine.yield [:discard i] card)))
  (coroutine.wrap iter))

(λ M.Action.generate-puzzle [state]
  (Logger.info "generate-puzzle")
  (faccumulate [cards nil _ 1 100 &until cards]
    (let [indexes (-> (table.keys state.draw)
                      (table.shuffle))
          cards (fcollect [i 1 12]
                  (. state.draw (. indexes i)))
          sets (find-sets cards)]
      (if (<= 6 (length sets))
        (do
          (Logger.info "Found 6 in  #{sets}" {: sets})
          cards)
        (Logger.info [:found (length sets)])))))

(λ M.Action.deal [state]
  (let [moves (faccumulate [moves [] _ 1 12]
                (-> moves
                    (table.insert [:move [:draw :top] [:deal :top]])
                    (table.insert [:face-up [:deal :top]])))]
    (apply-events (clone state) moves)))

(λ M.Action.deal-more [state]
  (case (values (length state.draw) (length state.deal))
    (0 _) (values nil (Error "No additional cards to deal"))
    ;; Lets be more relaxed and allow players to draw as much as they want, per
    ;; a physical game.
    ; (15 _) (values nil (Error "May not deal more than 15 cards"))
    _ (let [moves (faccumulate [moves [] _ 1 3]
                    (-> moves
                        (table.insert [:move [:draw :top] [:deal :top]])
                        (table.insert [:face-up [:deal :top]])))]
        (apply-events (clone state) moves))))

(λ M.Action.submit-set [state deal-indexes]
  (case (M.Query.set? state deal-indexes)
    true (let [moves (accumulate [moves [] _ i (ipairs deal-indexes)]
                       (-> (table.insert moves [:move [:deal i] [:discard :top]])
                           (table.insert [:face-down [:discard :top]])))
               moves (case (length state.deal)
                       (where n-dealt (< 12 n-dealt))
                       ;; Over 12 cards, fill created gaps with any extra cards,
                       ;; dont deal any new cards.
                       (let [hole-indexes (icollect [_ i (ipairs deal-indexes)]
                                            (if (<= i 12) i))
                             shift-indexes (let [discarding (table.invert deal-indexes)]
                                             (fcollect [i 13 n-dealt]
                                               (if (nil? (. discarding i))
                                                 i)))]
                         (accumulate [moves moves i _ (ipairs shift-indexes)]
                           (table.insert moves [:move
                                                [:deal (. shift-indexes i)]
                                                [:deal (. hole-indexes i)]])))
                       ;; Otherwise fill gaps with new cards if possible
                       _ (case (length state.draw)
                           0 moves
                           _ (accumulate [moves moves _ i (ipairs deal-indexes)]
                               (-> (table.insert moves [:move [:draw :top] [:deal i]])
                                   (table.insert [:face-up [:deal i]])))))]
           (apply-events (clone state) moves))
    (false ?msg) (values nil (Error (or ?msg "not a set")))))

(fn M.Query.find-sets [state]
  (let [dealt-cards (collect [loc c (M.iter-cards state)]
                      (case loc
                        [:deal] (values loc c)))
        sets (find-sets (table.values dealt-cards))
        dealt-indexes (icollect [_ a-set (ipairs sets)]
                        (icollect [_ card (ipairs a-set)]
                          (accumulate [i nil [_ n] c (pairs dealt-cards) &until i]
                            (case (values c card)
                              ({: id} {: id}) n))))]
    dealt-indexes))

(λ M.Query.set? [state dealt-indexes]
  (let [cards (icollect [_ i (ipairs dealt-indexes)] (. state.deal i))]
    (case cards
      [a b c nil] (set? a b c)
      _ false)))

(λ M.Query.hint-for-set [state dealt-indexes]
  (assert (M.Query.set? state dealt-indexes) "unable to hint set, cards are not a set!")
  (let [cards (icollect [_ i (ipairs dealt-indexes)] (. state.deal i))]
    (collect [_ key (ipairs [:shape :color :style :count])]
      (let [vals (icollect [_ card (ipairs cards)] (. card key))
            result (case vals
                     [a a a] :same
                     _ :diff)]
        (values key result)))))

(λ M.Query.game-ended? [state]
  (let [sets (M.Query.find-sets state)]
    (and (table.empty? sets)
         (table.empty? state.draw))))

(λ M.Query.game-result [state]
  {:sets (/ (length state.discard) 3)
   :remaining (length (icollect [loc _ (M.iter-cards state)]
                        (case loc
                          [:deal] true)))})

M
