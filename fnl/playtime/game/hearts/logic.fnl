(require-macros :playtime.prelude)
(prelude)

(local ffi (require :ffi))

(local Error (require :playtime.error))
(local Logger (require :playtime.logger))

(local M {:Action {} :Agent {} :Query {}})

(fn assert-player-turn [struct player-n]
  (let [real-player-n (+ (. struct.turn 0) 1)]
    (case (values player-n real-player-n)
      (nil 256) true
      (nil other) (assert false (%s "Must be no players turn but got #{other}"))
      (same same) true
      (want got) (assert false (%s "Must be player #{want} turn but got #{got}")))))

(fn assert-phase [struct phase]
  (case struct.phase
    (where (= phase)) true
    other (assert false (%s "Must be phase #{phase}, instead got #{other}"))))

;; For performance reasons we use a C-struct instead of a table for the game
;; state, which implies we encode our cards into integers instead of
;; {string,int,...} tables. Using a c-struct cuts computer thinking time by
;; 3-4x.
;;
;; We have elected to use an uint8_t for each card, the top 4 bits for the
;; suit, the bottom 4 bits for the rank. Ranks are 2-14 (ace high). a zero
;; value indicates the there is no card at that index.
;;
;;             7   6   5   4   3   2   1   0
;;         +---+---+---+---+---+---+---+---+
;;         |    Suit       |     Rank      |
;;         +---+---+---+---+---+---+---+---+
;;
;; The UI needs to render some cards face up and face down, as well as
;; transitioning from face-down to face-up as they're played, but luckily
;; the rules are simple: any card in player-1's hand (the human player) is face
;; up, any card in the trick is face up, any other card is face down, so we do
;; not have to track any of this and can generate it on the fly when iterating
;; cards for the UI.
;;
;; Since we're using a C struct, all internal indexing is zero based. Where it
;; matters, a `-z` (zero) `-n` (one) is postfixed to variable names to distinguish.
;;
;; Any values going out to, or in from, the UI are one-indexed, so expect Query
;; functions to use one-indexing, with the caveat that any function prefixed
;; with * is zero-based or 'int-card' based.
;;
;; Some notes on optimisation, from the perspective of running tens or hundreds
;; of thounsands of calls:
;;
;;  - Prefer `for player, for index, set player index 0` over `for player set player []`.
;;  - Prefer fcollect over ipairs.
;;

(local hearts_state_t
  (ffi.typeof
    "struct {
      // typed as doubles to match lua native type which should be fine,
      // it will support any seed given and score wont ever be all that big.
      double  seed;
      double  rule_score_limit;
      bool    rule_queen_of_spades_breaks_hearts;

      uint8_t phase; // rotated through deal, pass, trick..., score
      uint8_t pass_style; // rotated through cw ccw across none
      uint8_t round_number; // 0 -> n

      uint8_t draw[1][52]; // [1][52] to match other field location style
      uint8_t pass[4][3]; // hand indexes of cards to pass at pass phase completion
      uint8_t hand[4][13];
      uint8_t trick[4][1];
      uint8_t turn[4]; // queue of zero-indexed players, 255/PLAYER_NONE = no turn
      // cards won during a round, at most you might win all cards, 52 max.
      uint8_t round[4][52]; 

      // hard limit of 100 rounds, should be exceedingly excessive.
      // note this is [round][player] unlike most other [player][x] fields.
      uint8_t score_rounds[100][4];

      bool    round_hearts_broken;
      uint8_t trick_lead_suit;
    }"))
(set _G.__playtime_ffi {:clone {hearts_state_t true}})

(local [SUIT_HEARTS SUIT_CLUBS SUIT_DIAMONDS SUIT_SPADES]
  [(lshift 1 4) (lshift 1 5) (lshift 1 6) (lshift 1 7)])

(local [RANK_2 RANK_3 RANK_4 RANK_5 RANK_6 RANK_7 RANK_8 RANK_9
        RANK_10 RANK_JACK RANK_QUEEN RANK_KING RANK_ACE]
  [2 3 4 5 6 7 8 9
   10 11 12 13 14])

(local MASK_SUIT 0xF0)
(local MASK_RANK 0x0F)

(local [PHASE_DEAL
        PHASE_PASS
        PHASE_TRICK_PLAY PHASE_TRICK_RESOLVE
        PHASE_RESOLVE_ROUND
        PHASE_GAME_OVER]
  (fcollect [i 0 8]
    (lshift 1 i)))

(local (PASS_CW PASS_CCW PASS_ACROSS PASS_NONE)
  (values 0 1 2 3))

(local [PLAYER_1 PLAYER_2 PLAYER_3 PLAYER_4 PLAYER_NONE]
  [0 1 2 3 255])

(fn int->suit [int]
  (case int
    (where (= SUIT_HEARTS)) :hearts
    (where (= SUIT_SPADES)) :spades
    (where (= SUIT_DIAMONDS)) :diamonds
    (where (= SUIT_CLUBS)) :clubs
    _ (error (%s "could not convert int to suit #{int}"))))

(fn suit->int [suit]
  (case suit
    :hearts SUIT_HEARTS
    :spades SUIT_SPADES
    :diamonds SUIT_DIAMONDS
    :clubs SUIT_CLUBS
    _ (error (%s "could not convert suit to int #{suit}"))))

(fn rank->int [rank]
  (case rank
    14 14 ;; ace
    :king 13
    :queen 12
    :jack 11
    n n))

(fn int->rank [int]
  (case int
    14 14 ;; ace
    13 :king
    12 :queen
    11 :jack
    n n))

(fn first-trick-in-round? [struct]
  ;; First trick in round if no players have a card in round list
  (faccumulate [no-card? true player-z 0 3 &until (not no-card?)]
    (= 0 (. struct.round player-z 0))))

(fn first-card-in-trick? [struct]
  ;; First card if nothing in the trick yet
  (faccumulate [first? true player-z 0 3 &until (not first?)]
    (= 0 (. struct.trick player-z 0))))

(fn has-suit? [struct player-z want-suit-int]
  (faccumulate [has? false i 0 12 &until has?]
    (< 0 (band want-suit-int (. struct.hand player-z i)))))

(fn *card->suit [card]
  (-> (band MASK_SUIT card)
      (int->suit)))

(fn *card->rank [card]
  (-> (band MASK_RANK card)
      (int->rank)))

(fn only-has-hearts? [struct player-z]
  (faccumulate [only-hearts? true i 0 12 &until (not only-hearts?)]
    (= 0 (band (bor SUIT_CLUBS SUIT_SPADES SUIT_DIAMONDS)
               (. struct.hand player-z i)))))

(fn hearts-broken? [struct]
  (= true struct.round_hearts_broken))

(fn sort-player-hand! [struct]
  (let [hand (fcollect [i 0 12] (. struct.hand 0 i))
        ;; hand is inherently sortable as ints.
        _ (table.sort hand)]
    (set (. struct.hand 0) hand)
    struct))

(fn shuffle-hand! [struct player-z]
  (let [hand (fcollect [i 0 12] (. struct.hand player-z i))
        _ (table.shuffle hand)]
    (set (. struct.hand player-z) hand)
    struct))

(fn next-passing-style! [struct]
  (set struct.pass_style (case struct.pass_style
                           (where (= PASS_CW)) PASS_CCW
                           (where (= PASS_CCW)) PASS_ACROSS
                           (where (= PASS_ACROSS)) PASS_NONE
                           (where (= PASS_NONE)) PASS_CW))
  struct)

(fn all-hands-empty? [struct]
  (= 0 (+ (. struct.hand 0 0)
          (. struct.hand 1 0)
          (. struct.hand 2 0)
          (. struct.hand 3 0))))

(fn score-limit-exceeded? [struct]
  (let [max-score (accumulate [max -1 p score (ipairs (M.Query.score-match struct))]
                    (if (<= max score) score max))]
    (<= struct.rule_score_limit max-score)))

(fn next-phase! [struct]
  (set struct.phase (case struct.phase
                      (where (= PHASE_DEAL)) PHASE_PASS
                      (where (= PHASE_PASS)) PHASE_TRICK_PLAY
                      (where (= PHASE_TRICK_PLAY)) (case (. struct.turn 0)
                                                     (where (= PLAYER_NONE)) PHASE_TRICK_RESOLVE
                                                     _ PHASE_TRICK_PLAY)
                      (where (= PHASE_TRICK_RESOLVE)) (if (all-hands-empty? struct)
                                                        PHASE_RESOLVE_ROUND
                                                        PHASE_TRICK_PLAY)
                      (where (= PHASE_RESOLVE_ROUND))
                      (if (score-limit-exceeded? struct)
                        PHASE_GAME_OVER
                        PHASE_DEAL)))
  struct)

(fn next-turn! [struct]
  (for [i 1 3]
    (set (. struct.turn (- i 1)) (. struct.turn i)))
  (set (. struct.turn 3) PLAYER_NONE)
  struct)

(fn generate-turn-list [leader-z]
  (fcollect [i (+ leader-z 1) (+ leader-z 3) &into [leader-z]]
    (% i 4)))

(fn validate-first-trick-leader [struct player-z card-int]
  ;; first trick leader must be 2 of clubs
  (if (and (= SUIT_CLUBS (band MASK_SUIT card-int))
           (= 2 (band MASK_RANK card-int)))
    true
    (values false :must-2-clubs)))

(fn validate-any-trick-leader [struct player-z card-int]
  ;; Must not be hearts unless no other suits in hand or hearts is broken.
  ;; You may lead with QoS after the first trick.
  (if (= SUIT_HEARTS (band MASK_SUIT card-int))
    (if (or (hearts-broken? struct)
            (only-has-hearts? struct player-z))
      true
      (values false :no-lead-hearts))
    true))

(fn validate-any-trick-follow [struct player-z card-int]
  ;; Must follow suit if able, otherwise you may play any suit.
  (assert (< 0 struct.trick_lead_suit)
          "must have lead suit to validate validate-any-trick-follow")
  (let [lead-suit struct.trick_lead_suit]
    (case (band MASK_SUIT card-int)
      (where (= lead-suit)) true
      (where _other-suit (not (has-suit? struct player-z lead-suit))) true
      _ (values false :must-follow))))

(fn validate-first-trick-follow [struct player-z card-int]
  ;; We can use validate-any-trick-follow with the extra constraint of no-hearts
  (case (validate-any-trick-follow struct player-z card-int)
    ;; played valid card, but may be that you could not follow
    ;; so must check that you're not playing a heart unless thats all you have.
    true (if (= SUIT_HEARTS (band MASK_SUIT card-int))
           (if (only-has-hearts? struct player-z)
             true
             (values false :no-first-hearts))
           true)
    ;; played some invalid card when you could follow
    (false msg) (values false msg)))

(fn validate-play-card [struct player-z card-int]
  (case (values (first-trick-in-round? struct) (first-card-in-trick? struct))
    (true true) (validate-first-trick-leader struct player-z card-int)
    (false true) (validate-any-trick-leader struct player-z card-int)
    (true false) (validate-first-trick-follow struct player-z card-int)
    (false false) (validate-any-trick-follow struct player-z card-int)))

(fn struct->table [struct]
  ;; mostly for debugging
  (fn table-cards [field n len ?nocard]
    (fcollect [i 0 (- n 1)]
      (fcollect [ii 0 (- len 1)]
        (case (. struct field i ii)
          0 ?nocard
          card [(*card->suit card) (*card->rank card)]))))

  {:seed struct.seed
   :rule_score_limit struct.rule_score_limit
   :rule_queen_of_spades_breaks_hearts struct.rule_queen_of_spades_breaks_hearts
   :phase (M.Query.phase struct)
   :pass_style (M.Query.pass-style struct)
   ;; indexes not cards
   :pass (fcollect [i 0 3]
           (fcollect [j 0 2]
             (. struct.pass i j)))
   :draw (table-cards :draw 1 52)
   :hand (table-cards :hand 4 13 :no-card)
   :trick (table-cards :trick 4 1 :no-card)
   :round (table-cards :round 4 52)
   :turn (fcollect [i 0 3] (. struct.turn i))
   :round_hearts_broken struct.round_hearts_broken
   :trick_lead_suit struct.trick_lead_suit})

(ffi.metatype hearts_state_t {:__tostring (fn [cdata]
                                            (let [t (struct->table cdata)
                                                  func (case (pcall require :fennel)
                                                         (true {: view}) view
                                                         _ vim.inspect)]
                                              (func t)))})

(fn new-game-state [seed]
  (local seed 1764243885)
  (math.randomseed seed)
  (Logger.info [:hearts.new-game-state seed])
  (let [struct (ffi.new hearts_state_t {:seed seed
                                        :round_number 0
                                        :rule_queen_of_spades_breaks_hearts false
                                        :rule_score_limit 100
                                        :pass_style PASS_CW
                                        :phase PHASE_DEAL})
        suits [SUIT_HEARTS SUIT_CLUBS SUIT_SPADES SUIT_DIAMONDS]
        cards (accumulate [cards [] _ suit (ipairs suits)]
                (fcollect [rank 2 14 &into cards]
                  (bor suit rank)))]
    (set (. struct.draw 0) cards)
    struct))

(λ M.build [_config ?seed]
  (let [seed (or ?seed (os.time))]
    (new-game-state seed)))

(λ M.iter-cards [struct ?fields]
  ;; Note we convert player and indexes to one-indexing
  (let [fields (or ?fields [:draw :trick :hand :round])
        sizes {:draw [1 52] :trick [4 1] :hand [4 13] :round [4 52]}]
    (fn iter []
      (each [_ field (ipairs fields)]
        (let [[field-len col-len] (. sizes field)]
          (for [i 0 (- field-len 1)]
            (for [j 0 (- col-len 1)]
              (case (. struct field i j)
                0 nil
                card-int (let [card {1 (*card->suit card-int)
                                     2 (*card->rank card-int)
                                     :id card-int ;; technically not globally unique id but ok
                                     :face (case (values field i j)
                                             (:hand 0) :up
                                             (:trick) :up
                                             _ :down)}]
                           (coroutine.yield [field (+ 1 i) (+ 1 j)] card))))))))
    (coroutine.wrap iter)))

(fn reset-round [struct]
  (error :todo)
  ;; reset round_hearts_broken
  ;; reset draw = round + trick + hand
  )

(λ M.Action.prepare-deal [struct]
  (assert-phase struct PHASE_DEAL)
  ;; Note: this is separate to the actual deal so we can sync components to
  ;; match the shuffled draw pile order before actually getting the deal
  ;; events.
  (let [struct (clone struct)
        draw (-> (fcollect [i 0 51] (. struct.draw 0 i))
                 (table.shuffle))]
    (set (. struct.draw 0) draw)
    struct))

(λ M.Action.deal [state]
  (assert-phase state PHASE_DEAL)
  (let [next-state (clone state)
        moves (faccumulate [(t player-z hand-z) (values [] 0 0) i 51 0 -1]
                (let [move [:move [:draw 1 (+ i 1)] [:hand (+ player-z 1) (+ hand-z 1)]]]
                  (set (. next-state.hand player-z hand-z) (. next-state.draw 0 i))
                  (set (. next-state.draw 0 i) 0)
                  (table.insert t move)
                  (if (= 0 player-z)
                    (table.insert t [:face-up [:hand (+ player-z 1) (+ hand-z 1)]]))
                  (values t (% (+ player-z 1) 4) (if (= 3 player-z)
                                                   (+ hand-z 1)
                                                   hand-z))))]
    (sort-player-hand! next-state)
    (next-phase! next-state)
    (values next-state moves)))

(fn apply-passes! [next-state]
  (let [passing-cards (faccumulate [t [] player-z 0 3]
                        (table.set t player-z (fcollect [i 0 2]
                                                (let [pass-index (. next-state.pass player-z i)
                                                      pass-card (. next-state.hand player-z pass-index)]
                                                  (set (. next-state.hand player-z pass-index) 0)
                                                  {:index pass-index :card pass-card}))))
        ;; we only map swaps, so build manually, then iterate the keys
        from-to-swap-pairs (fcollect [player-z 0 3]
                             (case next-state.pass_style
                               (where (= PASS_CW)) (% (+ 1 player-z) 4)
                               (where (= PASS_CCW)) (% (+ 3 player-z) 4)
                               (where (= PASS_ACROSS)) (% (+ 2 player-z) 4)
                               (where (= PASS_NONE)) nil
                               v (error (%s "unknown passing style #{v}"))))
        moves (accumulate [t [] from-player-n to-player-z (ipairs from-to-swap-pairs)]
                (let [from-player-z (- from-player-n 1)
                      to-player-n (+ to-player-z 1)]
                  (icollect [i {: index : card} (ipairs (. passing-cards from-player-z)) &into t]
                    (let [from-index-z index
                          to-index-z (. passing-cards to-player-z i :index)]
                      (set (. next-state.hand to-player-z to-index-z) card)
                      [:move
                       [:hand from-player-n (+ from-index-z 1)]
                       [:hand to-player-n (+ 1 to-index-z)]]))))]
    (values next-state moves)))

(λ M.Action.pass-cards [state player-n hand-indexes]
  (assert-phase state PHASE_PASS)
  (assert (= 3 (length hand-indexes)) "must give 3 cards to pass")
  ;; We actually run this even when in PASS_NONE style, we just automate the
  ;; picking of 3 cards for the player. This affords some delay in the UI too.
  (let [player-z (- player-n 1)
        next-state (clone state)
        ;; save pass choice
        _ (set (. next-state.pass player-z)
               (icollect [_ index (ipairs hand-indexes)]
                 (- index 1)))
        ;; check if we're waiting on any more passes or not
        all-done? (faccumulate [done? true i 0 3 &until (not done?)]
                    ;; note: pass values are hand indexes, so a zero-value is
                    ;; valid but we pass 3 cards, at least one card must be
                    ;; over 0.
                    (< 0 (+ (. next-state.pass i 0)
                            (. next-state.pass i 1)
                            (. next-state.pass i 2))))]
    (if all-done?
      (let [(next-state events) (if (~= PASS_NONE next-state.pass_style)
                                  (apply-passes! next-state)
                                  (values next-state []))
            player-z-with-2-clubs (faccumulate [p nil player-z 0 3 &until p]
                                    (faccumulate [p nil i 0 12 &until p]
                                      (let [card (. next-state.hand player-z i)]
                                        (if (and (= SUIT_CLUBS (band MASK_SUIT card))
                                                 (= 2 (band MASK_RANK card)))
                                          player-z))))]
        (next-passing-style! next-state)
        (next-phase! next-state)
        (set next-state.turn (generate-turn-list player-z-with-2-clubs))
        (set next-state.pass [[] [] [] []])
        (for [i 1 3] (shuffle-hand! next-state i))
        (sort-player-hand! next-state)
        (values next-state events))
      ;; all passes set, actually perform the pass
      ;; Pull cards out of hand
      ;; Match from -> to players
      ;; For each card pulled from player-from, insert at zero-value cards in playe-to
      ;; shuffle all
      ;; sort player
      
      ;; otherwise, not all passes done, just save progress.
      (values next-state []))))

(λ M.Action.play-card [state player-n hand-index]
  (assert-phase state PHASE_TRICK_PLAY)
  (assert-player-turn state player-n)
  (case (M.Query.playable-card? state player-n hand-index)
      true (let [next-state (M.Agent.play-card (clone state) player-n hand-index)
                 moves [[:move
                         [:hand player-n hand-index]
                         [:trick player-n 1]]
                        [:face-up [:trick player-n 1]]]]
             (values next-state moves))
      (false err) (values nil err)))

(fn resolve-trick-winner [state]
  (faccumulate [(player top) (values nil -1) player-z 0 3]
    (let [played-card (. state.trick player-z 0)
          suit (band MASK_SUIT played-card)
          rank (band MASK_RANK played-card)]
      (if (and (= suit state.trick_lead_suit) (< top rank))
        (values player-z rank)
        (values player top)))))

(λ M.Action.resolve-trick [state]
  (assert-phase state PHASE_TRICK_RESOLVE)
  (assert-player-turn state nil)
  (let [winner-z (resolve-trick-winner state)
        round-offset-z (faccumulate [index nil i 0 52 &until index]
                         (case (. state.round winner-z i)
                           0 i
                           _ nil))
        moves (fcollect [i 1 4]
                ;; note i already has `+1` to round-offset-z
                [:move [:trick i 1] [:round (+ winner-z 1) (+ round-offset-z i)]])
        next-state (M.Agent.resolve-trick (clone state))]
    (values next-state moves)))

(λ M.Action.resolve-round [struct]
  (assert-phase struct PHASE_RESOLVE_ROUND)
  ;; score each player, add scores into score_rounds array.
  ;; if any player over score limit, end game otherwise reset cards for new deal
  (let [struct (clone struct)]
    (let [current-round struct.round_number
          round-scores (M.Query.score-round struct)]
      (each [player-n score (ipairs round-scores)]
        (set (. struct.score_rounds current-round (- player-n 1)) score)))
    (set struct.round_number (+ 1 struct.round_number))
    ;; reset cards
    (let [cards (faccumulate [t [] p 0 3]
                  (fcollect [c 0 51 &into t]
                    (let [card (. struct.round p c)]
                      (set (. struct.round p c) 0)
                      (case card
                        0 nil
                        _ card))))]
      (set (. struct.draw 0) cards))
  (next-phase! struct)))

;;;
;;; Agent
;;;
;;; Agent functions are speed optimised for many iterations which means they do
;;; not clone state, perform less safety checks or generate UI information
;;; (moves, message strings, etc)
;;;
;;; Generally Action.x should call Agent.x internally and wrap the call with
;;; appropriate safety checks, clones and produce any additional data.
;;;

;; Expose internal contants to agent since it needs direct inspection of state.
(set M.Agent.constants {:PHASE_DEAL PHASE_DEAL
                        :PHASE_PASS PHASE_PASS
                        :PHASE_TRICK_PLAY PHASE_TRICK_PLAY
                        :PHASE_TRICK_RESOLVE PHASE_TRICK_RESOLVE
                        :PHASE_RESOLVE_ROUND PHASE_RESOLVE_ROUND
                        :PHASE_GAME_OVER PHASE_GAME_OVER
                        :MASK_SUIT MASK_SUIT
                        :MASK_RANK MASK_RANK
                        :SUIT_HEARTS SUIT_HEARTS
                        :SUIT_SPADES SUIT_SPADES
                        :SUIT_CLUBS SUIT_CLUBS
                        :SUIT_DIAMONDS SUIT_DIAMONDS
                        :RANK_2 RANK_2
                        :RANK_3 RANK_3
                        :RANK_4 RANK_4
                        :RANK_5 RANK_5
                        :RANK_6 RANK_6
                        :RANK_7 RANK_7
                        :RANK_8 RANK_8
                        :RANK_9 RANK_9
                        :RANK_10 RANK_10
                        :RANK_JACK RANK_JACK
                        :RANK_QUEEN RANK_QUEEN
                        :RANK_KING RANK_KING
                        :RANK_ACE RANK_ACE
                        :PLAYER_NONE PLAYER_NONE})

(λ M.Agent.resolve-trick [state]
  (let [winner-z (resolve-trick-winner state)
        round-offset-z (faccumulate [index nil i 0 52 &until index]
                         (case (. state.round winner-z i)
                           0 i
                           _ nil))]
    ;; copy trick cards into winner round list
    (for [i 0 3]
      (set (. state.round winner-z (+ i round-offset-z)) (. state.trick i 0))
      (set (. state.trick i 0) 0))
    (set state.trick_lead_suit 0)
    (set state.turn (generate-turn-list winner-z))
    (next-phase! state)))

(fn pack-hand! [state player-z lowest-index]
  ;; When we play a card we need to move all cards above that index down
  ;; as we do this in the UI and we want selected indexes to match up.
  ;; Technically you could skip this during agent play, but by doing this
  ;; we can optimise other checks by assuming checking index 0 == checking all
  ;; indexes.
  (for [i lowest-index 12]
    (set (. state.hand player-z i) (. state.hand player-z (+ i 1))))
  (set (. state.hand player-z 12) 0))

(λ M.Agent.play-card [state player-n hand-index]
  (let [player-z (- player-n 1)
        index-z (- hand-index 1)
        played-card (. state.hand player-z index-z)]
    ;; apply rules
    (if (= 0 state.trick_lead_suit)
      (set state.trick_lead_suit (band MASK_SUIT played-card)))
    (case (values (band MASK_SUIT played-card) (band MASK_RANK played-card))
      (where (= SUIT_HEARTS)) (set state.round_hearts_broken true)
      (where ((= SUIT_SPADES) (= RANK_QUEEN))) (when state.rule_queen_of_spades_breaks_hearts
                                                 (set state.round_hearts_broken true)))
    ;; increment game state
    (set (. state.trick player-z 0) (. state.hand player-z index-z))
    (set (. state.hand player-z index-z) 0)
    (pack-hand! state player-z index-z)
    (next-turn! state)
    (next-phase! state)))

(λ M.Agent.find-playable-cards [struct player-n]
  (let [player-z (- player-n 1)]
    (fcollect [i 0 12]
      (case (. struct.hand player-z i)
        0 nil ;; not a card
        card-int (when (validate-play-card struct player-z card-int)
                   (+ i 1))))))


(λ M.Query.playable-card? [state player-n hand-index ?no-messages]
  (assert-phase state PHASE_TRICK_PLAY)
  (assert-player-turn state player-n)
  (let [messages {:must-2-clubs #"Leader of the first trick must play 2 of Clubs"
                  :no-hearts-first-trick #"May not play hearts on first trick"
                  :no-lead-hearts #"Must not lead trick with hearts unless Hearts are broken"
                  :no-first-hearts #"Must not play hearts on the first trick"
                  :must-follow #(%s "Must follow lead suit of #{lead-suit}"
                                    {:lead-suit (int->suit state.trick_lead_suit)})
                  :no-lead-qos #"Must not lead trick with Queen of Spades unless Hearts are broken"}
        player-z (- player-n 1)
        card (. state.hand player-z (- hand-index 1))]
    (case (validate-play-card state player-z card)
      true true
      (false msg-code) (if (not (= true ?no-messages))
                         (let [msg (or ((. messages msg-code))
                                       (error (%s "Unknown reason for validation failure: #{msg-code}")))]
                           (values false msg))))))

(λ M.Query.trick-ended? [struct]
  ;; If every player has played a card, then the trick is over,
  ;; so we can just check all cards are non-zero.
  (and (< 0 (. struct.trick 0 0))
       (< 0 (. struct.trick 1 0))
       (< 0 (. struct.trick 2 0))
       (< 0 (. struct.trick 3 0))))

(λ M.Query.round-ended? [struct]
  ;; Since we pack hands down, if the first card in each players hand is 0, we
  ;; know every other hand above it is also zero, so if the sum of all first
  ;; cards is zero, no one has any cards to play and the round is over.
  (= 0 (+ (. struct.hand 0 0)
          (. struct.hand 1 0)
          (. struct.hand 2 0)
          (. struct.hand 3 0))))

(λ M.Query.score-round [state]
  (let [player-n-points (fcollect [player-z 0 3]
                          (faccumulate [sum 0 i 0 51]
                            (let [card (. state.round player-z i)
                                  suit (band MASK_SUIT card)
                                  rank (band MASK_RANK card)]
                              (case (values suit rank)
                                (where ((= SUIT_HEARTS) _)) (+ sum 1)
                                (where ((= SUIT_SPADES) (= RANK_QUEEN))) (+ sum 13)
                                ;; no card or non-score card
                                _ sum))))
        moon-shooter-n (faccumulate [who nil i 1 4 &until who]
                       (if (= 26 (. player-n-points i)) i))
        points (if moon-shooter-n
                 (fcollect [player-n 1 4] (if (= player-n moon-shooter-n) 0 26))
                 player-n-points)]
    points))

(λ M.Query.score-match [struct]
  ;; Note we never include the current round in a match score, its up to the caller to ensure
  ;; struct.round_number is where they want (+1 if resolving a round)
  (let [all (case struct.round_number
              0 []
              current-round-number (fcollect [r 0 (- current-round-number 1)]
                                     (fcollect [p 0 3]
                                       (. struct.score_rounds r p))))
        sums (accumulate [players [0 0 0 0] _ round (ipairs all)]
               (do
                 (for [i 1 4]
                   (set (. players i) (+ (. players i) (. round i))))
                 players))]
    (values sums all)))

(λ M.Query.held-point-cards [struct player]
  (fcollect [i 0 51]
    (let [card (. struct.round (- player 1) i)
          suit (band MASK_SUIT card)
          rank (band MASK_RANK card)]
      (case (values suit rank)
        (where ((= SUIT_HEARTS) _)) :heart
        (where ((= SUIT_SPADES) (= RANK_QUEEN))) :queen-of-spades))))

(λ M.Query.pass-style [struct]
  (case struct.pass_style
    (where (= PASS_CW)) :clockwise
    (where (= PASS_CCW)) :counter-clockwise
    (where (= PASS_ACROSS)) :across
    (where (= PASS_NONE)) :none))

(λ M.Query.current-player [struct]
  (case (. struct.turn 0)
    (where (= PLAYER_NONE)) nil
    n (+ n 1)))

(λ M.Query.next-player [struct]
  (case (. struct.turn 1)
    (where (= PLAYER_NONE)) nil
    n (+ n 1)))

(λ M.Query.first-trick-in-round? [struct]
  (first-trick-in-round? struct))

(λ M.Query.first-card-in-trick? [struct]
  (first-card-in-trick? struct))

(λ M.Query.lead-suit [struct]
  (let [lead-suit struct.trick_lead_suit]
    (case struct.trick_lead_suit
      (where (= SUIT_CLUBS)) :clubs
      (where (= SUIT_HEARTS)) :hearts
      (where (= SUIT_DIAMONDS)) :diamonds
      (where (= SUIT_SPADES)) :spades
      _ nil)))

(λ M.Query.phase [struct]
  (case struct.phase
    (where (= PHASE_DEAL)) :deal
    (where (= PHASE_PASS)) :pass
    (where (= PHASE_TRICK_PLAY)) :trick
    (where (= PHASE_TRICK_RESOLVE)) :resolve
    (where (= PHASE_RESOLVE_ROUND)) :score
    (where (= PHASE_GAME_OVER)) :game-over))

(λ M.Query.hand-size [struct player-n]
  (let [player-z (- player-n 1)]
    (faccumulate [count 0 i 0 12]
      (case (. struct.hand player-z i)
        0 count
        n (+ count 1)))))

(λ M.Action.debug-generate-random-action [state player-n]
  (case state.phase
    (where (= PHASE_PASS))
    (let [indexes (fcollect [i 0 12] (+ i 1))
          [a b c] (table.shuffle indexes)]
      [:pass-cards player-n [a b c]])
    (where (= PHASE_TRICK_PLAY))
    (let [valid-indexes (M.Query.find-playable-cards state player-n)
          _ (assert (< 0 (length valid-indexes)) "no playable")
          [a] (table.shuffle valid-indexes)]
      [:play-card player-n a])
    phase (do
            ; (_G.summark-print)
            (error (%s "debug-generate-random-action #{phase} #{state}")))))

M
