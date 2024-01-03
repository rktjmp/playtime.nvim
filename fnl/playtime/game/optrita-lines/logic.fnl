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

(fn build-path [play-loc]
  (case play-loc
     [:play :top col] (fcollect [i 1 6] [:grid i col])
     [:play :bottom col] (fcollect [i 6 1 -1] [:grid i col])
     [:play :left row] (fcollect [i 1 6] [:grid row i])
     [:play :right row] (fcollect [i 6 1 -1] [:grid row i])))

(λ M.build [config ?seed]
  (math.randomseed (or ?seed (os.time)))
  (let [config (table.merge {:score-limit {:player 31 :grid 11}} config)
        (deck _other) (-> (Deck.Standard52.build)
                          (Deck.split (fn [c] (not (= 10 (card-value c)))))
                          (Deck.shuffle))
        state {:score {:player 0 :grid 0}
               :rules {:score-limit {:grid config.score-limit.grid
                                     :player config.score-limit.player}}
               :grid [[] [] [] [] [] []]
               :trick {:player [[] [] [] [] [] []]
                       :grid [[] [] [] [] [] []]}
               :draw []
               :trump []
               :hand []}]
    (tset state :draw deck)
    state))

(λ M.iter-cards [state]
  (fn iter []
    (each [row-n row (ipairs state.grid)]
      (for [i 1 6]
        (case (. row i)
          card (coroutine.yield [:grid row-n i] card))))
    (each [side tricks (pairs state.trick)]
      (each [trick-n trick (ipairs tricks)]
        (for [i 1 2]
          (case (. trick i)
            card (coroutine.yield [:trick side trick-n i] card)))))
    (each [_ field (ipairs [:draw :hand :trump])]
      (each [card-n card (ipairs (. state field))]
        (coroutine.yield [field card-n] card))))
  (coroutine.wrap iter))

(λ M.Action.score-round [state]
  (fn sum-tricks [key]
    (accumulate [sum 0 _ trick (ipairs (. state.trick key))]
      (case trick
        [nil] sum
        _ (+ 1 sum))))
  (let [player (sum-tricks :player)
        grid (sum-tricks :grid)
        state (clone state)]
    (set state.score.player (+ state.score.player player))
    (set state.score.grid (+ state.score.grid grid))
    state))

(λ M.Action.clear-round [state]
  (fn clear-tricks! [state]
    (let [events []]
      (case state.trump
        [c] (table.join events [[:face-down [:trump 1]]
                                [:move [:trump 1] [:draw :bottom]]]))
      (each [side tricks (pairs state.trick)]
        (each [trick-n trick (ipairs tricks)]
          (each [i _ (ipairs trick)]
            (table.join events [[:face-down [:trick side trick-n i]]
                                [:move [:trick side trick-n i] [:draw :bottom]]]))))
      (apply-events state events)))

  (fn clear-rows! [state]
    (let [paths (fcollect [i 1 6] (build-path [:play :left i]))
          all-ups (icollect [_ path (ipairs paths)]
                    (if (accumulate [up? true _ p (ipairs path) &until (not up?)]
                          (case (table.get-in state p)
                            card (card-face-up? card)
                            nil true))
                      path))
          locs (table.join [] (table.unpack all-ups))
          events (accumulate [t [] _ loc (ipairs locs)]
                   (case (table.get-in state loc)
                     card (table.join t [[:face-down loc]
                                         [:move loc [:draw :bottom]]])
                     _ t))]
      (apply-events state events)))

  (fn clear-cols! [state]
    (let [paths (fcollect [i 1 6] (build-path [:play :top i]))
          all-ups (icollect [_ path (ipairs paths)]
                    (if (accumulate [up? true _ p (ipairs path) &until (not up?)]
                          (case (table.get-in state p)
                            card (card-face-up? card)
                            nil true))
                      path))
          locs (table.join [] (table.unpack all-ups))
          events (accumulate [t [] _ loc (ipairs locs)]
                   (case (table.get-in state loc)
                     card (table.join t [[:face-down loc]
                                         [:move loc [:draw :bottom]]])
                     _ t))]
      (apply-events state events)))

  (let [(state trick-events) (clear-tricks! (clone state))
        (state row-events) (clear-rows! state)
        (state col-events) (clear-cols! state)
        events (table.join trick-events row-events col-events)]
    (Deck.shuffle state.draw)
    (values state events)))

(λ M.Action.new-round [state]
  (fn fill-grid! [state]
    (let [events (accumulate [t [] row-n _ (ipairs state.grid)]
                   (do
                     (for [col 1 6]
                       (case (. state.grid row-n col)
                         nil (do
                               (table.insert t [:move [:draw :top] [:grid row-n col]])
                               ;; If score is 0/0 then we are in the first fill
                               ;; and should flip cards sw-ne otherwise just
                               ;; put any cards in empty spaces.
                               (if (and (= 0 state.score.player state.score.grid)
                                        (= (- 7 row-n) col))
                                 (table.insert t [:face-up [:grid row-n col]])))))
                     t))]
      (apply-events state events)))

  (fn draw-hand! [state]
    (let [events (faccumulate [t [] i 1 7]
                   (table.join t [[:move [:draw :top] [:hand i]]
                                  [:face-up [:hand i]]]))]
      (apply-events state events)))

  (let [(state fill-events) (fill-grid! (clone state))
        (state draw-events) (draw-hand! state)
        events (table.join fill-events draw-events)]
    ;; TODO: this could probably be a util function, possibly in
    ;; make-card-util-fns since it depends on the specific card-value function.
    ;; Would need to pass a (optional?) suit-order option.
    ;; TODO: Also possibly create a sorter (and shuffler) that can  pass events
    ;; to the UI. Both sort of rely on having a "free space", which is harder to
    ;; do with the events. Maybe use the tail of the list as the free space, or 0/-1
    ;; and specially handle that index in the ui (eg: pop it up one row as "held").
    (-> (table.sort state.hand (fn [a b]
                                 (< (card-value a)
                                    (card-value b))))
        (table.sort (fn [a b]
                      (let [t {:hearts 1 :spades 2 :diamonds 3 :clubs 4}
                            a (. t (card-suit a))
                            b (. t (card-suit b))]
                        (< a b)))))
    (values state events)))

(λ M.Action.pick-trump [state hand-n]
  (let [events [[:move [:hand hand-n] [:trump :top]]]
        events (fcollect [i (+ hand-n 1) (length state.hand) &into events]
                 [:move [:hand i] [:hand (- i 1)]])]
    (apply-events (clone state) events)))

(λ M.Action.play-trick [state hand-n play-loc]
  (fn no-nil-cards? [path]
    (accumulate [ok? true _ p (ipairs path) &until (not ok?)]
      (not (nil? (table.get-in state p)))))

  (fn play-path [path]
    (let [trump-suit (card-suit (. state.trump 1))
          trick-player-n (+ 1 (length (fcollect [i 1 6] (. state.trick.player i 1))))
          trick-grid-n (+ 1 (length (fcollect [i 1 6] (. state.trick.grid i 1))))
          player-card (. state.hand hand-n)
          player-suit (card-suit player-card)
          player-value (card-value player-card)
          (events won?) (accumulate [(events result) (values [] nil)
                                     _ p (ipairs path)
                                     &until (not (nil? result))]
                          (let [grid-card (table.get-in state p)
                                grid-suit (card-suit grid-card)
                                grid-value (card-value grid-card)]
                            (table.insert events [:face-up p])
                            (case (values grid-suit grid-value player-suit player-value)
                              ;; same suit, higher value, we won
                              (where (suit against suit played) (< against played))
                              (let [moves [[:move [:hand hand-n] [:trick :player trick-player-n :top]]
                                           [:move p [:trick :player trick-player-n :top]]]]
                                (values (table.join events moves) true))
                              ;; same suit, lower value, we lost
                              (where (suit against suit played) (< played against))
                              (let [moves [[:move [:hand hand-n] [:trick :grid trick-grid-n :top]]
                                           [:move p [:trick :grid trick-grid-n :top]]]]
                                (values (table.join events moves) false))
                              ;; different suit keep going
                              _ (values events nil))))
          (events won?) (if (nil? won?)
                          ;; No winner, try to find trump card and assign win to grid
                          ;; otherwise continue returning a nil-win
                          (let [trumps (-> (icollect [i p (ipairs path)]
                                             (let [grid-card (table.get-in state p)]
                                               (if (= trump-suit (card-suit grid-card))
                                                 [p (card-value grid-card)])))
                                           (table.sort (fn [[_ a] [_ b]] (< a b))))
                                ?trump-moves (case trumps
                                               [[p _card]] [[:move [:hand hand-n] [:trick :grid trick-grid-n :top]]
                                                            [:move p [:trick :grid trick-grid-n :top]]])]
                            (if ?trump-moves
                              (values (table.join events ?trump-moves) false)
                              ;; still no winner, player must pick card
                              (values events nil)))
                          (values events won?))]
      (if (nil? won?)
        (values events nil)
        (do
          ;; fix hand gaps
          (fcollect [i (+ hand-n 1) (length state.hand) &into events]
            [:move [:hand i] [:hand (- i 1)]])
          (values events won?)))))

  (fn do-play [path]
    (if (not (no-nil-cards? path))
      (values nil (<s> "cant play a row or column with empty spaces"))
      (case (play-path path)
        (events player-won?) (let [(next-state events) (apply-events (clone state) events)]
                               ;; TODO: Actually, dont score until after round is finished?
                               ; (if player-won?
                               ;   (set next-state.score.player (+ next-state.score.player 1))
                               ;   (set next-state.score.grid (+ next-state.score.grid 1)))
                               (values next-state events))
        ;; user must pick a card, we rely on the app inspecting the game
        ;; state in some way (no move to trick? score did not change?)
        ;; to perform the correct action. Could be specific "phase" but would
        ;; be only non-default phase at present.
        (events nil) (apply-events (clone state) events))))

  (if (nil? (. state.hand hand-n))
    (values nil (<s> "No card at hand #{hand-n} to play"))
    (case play-loc
      [:play] (do-play (build-path play-loc))
      _ (values nil (<s> "Cant play tricks to #{play-loc}")))))

(λ M.Action.force-trick [state hand-n play-loc]
  (let [trick-n (accumulate [n nil i t (ipairs state.trick.player) &until n]
                  (if (table.empty? t) i))
        events [[:move [:hand hand-n] [:trick :player trick-n :top]]
                [:move play-loc [:trick :player trick-n :top]]]
        _ (fcollect [i (+ hand-n 1) (length state.hand) &into events]
            [:move [:hand i] [:hand (- i 1)]])]
    (apply-events (clone state) events)))

(λ M.Query.game-ended? [state]
  (or (<= state.rules.score-limit.player state.score.player)
      (<= state.rules.score-limit.grid state.score.grid)))

(λ M.Query.game-result [state]
  (if (<= state.rules.score-limit.grid state.score.grid)
    :grid
    (<= state.rules.score-limit.player state.score.player)
    :player
    :unfinished))

(λ M.Query.round-ended? [state]
  (= 0 (length state.hand)))

M
