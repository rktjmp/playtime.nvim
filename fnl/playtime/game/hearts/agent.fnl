(require-macros :playtime.prelude)
(prelude)

(local Error (require :playtime.error))
(local Logger (require :playtime.logger))
(local SOISMCTS (require :playtime.ai.search.soismcts))
(local Logic (require :playtime.game.hearts.logic))

(local ffi (require :ffi))

(local {: PHASE_DEAL
        : PHASE_PASS
        : PHASE_TRICK_PLAY
        : PHASE_TRICK_RESOLVE
        : PHASE_RESOLVE_ROUND
        : PHASE_GAME_OVER
        : MASK_SUIT
        : MASK_RANK
        : SUIT_HEARTS
        : SUIT_SPADES
        : SUIT_CLUBS
        : SUIT_DIAMONDS
        : RANK_JACK
        : RANK_QUEEN
        : RANK_KING
        : PLAYER_NONE} Logic.Agent.constants)

(local Game {})
(local Strategy {})

(local M {})

(λ M.new [player]
  (Logger.info "\n")
  (let [agent {: player
               :other-players (fcollect [i 1 4] (if (not (= i player)) i))
               ;; see observe-event :new-deal for default memory.
               ;; TODO: probably want memory.round and memory.game
               ;; round tracks heart distribution  etc
               ;; game tracks who's in the lead so we can utility against them
               ;; winning.
               :memory {}}
        ;; We want to wrap the SOISMCTS game module interface to pass ourselves
        ;; along.
        GameProxy (collect [k v (pairs Game)]
                    (values k (fn [...] (v agent ...))))]
    (set agent.implementation (SOISMCTS.new {:game-module GameProxy
                                             :iterations 1000
                                             :strategy-module Strategy}))
    (setmetatable agent {:__index M})))

(λ M.select-action [agent game-state]
  (summark :select-action
  (SOISMCTS.select-action agent.implementation game-state agent.player)))

(λ M.observe-event [agent state event]
  (case event
    [:play-card player-n trick]
    (let [lead-suit state.trick_lead_suit
          card (. state.trick (- player-n 1) 0)
          played-suit (band MASK_SUIT card)]
      ;; when hearts or when spades, memorise seen QoS, hearts-count?
      (when (and (< 0 lead-suit) (not (= lead-suit played-suit)))
        ; (Logger.info (%s "observed player #{player-n} is out of #{lead-suit}"))
        (set (. agent.memory.short-suits player-n lead-suit) true)))
    [:resolve-trick]
    nil
    [:pass-card]
    nil
    [:new-deal]
    (set agent.memory {:unaccounted-hearts 13
                       :unaccounted-queen-of-spades 1
                       :heart-counts [0 0 0 0]
                       :short-suits (fcollect [i 1 4]
                                      {SUIT_CLUBS false SUIT_DIAMONDS false
                                       SUIT_HEARTS false SUIT_SPADES false})})
    _ (error (%s "unknown event: #{event}"))
    
    ))

;; Hash given state into a representation from the perspective of
;; observer-player. For example, include the observers hand, played history by
;; other players, but not other players actual hands.
(fn card-array->information-set [array len sort?]
  (let [cards (fcollect [i 0 (- len 1)]
                (case (. array i)
                  0 nil
                  card card))]
    (if sort? (table.sort cards))
    (table.concat cards ".")))
(λ Game.information-set [_agent state observer-player]
  ;; Known information: our own hand, cards played by other players, remaining
  ;; unplayed cards
  (let [our-hand (card-array->information-set (. state.hand (- observer-player 1)) 13 true)
        taken-cards (faccumulate [t [] player-z 0 3]
                      (let [cards (card-array->information-set (. state.round player-z) 52)]
                        (table.insert t (table.concat [player-z cards] ":"))))
        trick-cards (faccumulate [t [] player-z 0 3]
                      (let [cards (card-array->information-set (. state.trick player-z) 1)]
                      (table.insert t (table.concat [player-z cards] ":"))))
        str (.. our-hand "/" (table.concat taken-cards "_") "/" (table.concat trick-cards "v"))]
    str))

    (fn int->card [card]
      (let [suit (case (band MASK_SUIT card)
                   (where (= SUIT_HEARTS)) :hearts
                   (where (= SUIT_SPADES)) :spades
                   (where (= SUIT_CLUBS)) :clubs
                   (where (= SUIT_DIAMONDS)) :diamonds)]
        [suit (band MASK_RANK card)]))
;; Return a *new state* where any hidden information from observer-player
;; is realistically filled. Eg: given their hand, known played cards, randomly
;; distribute remaining cards to other players.
(λ Game.determinise [agent root-state observer-player]
  (let [det-state (clone root-state)
        (all-cards sizes) (faccumulate [(cards sizes) (values [] {}) player-z 0 3]
                            (if (= (+ player-z 1) observer-player)
                              ;; Its a bit simpler to just mark observer hand
                              ;; as 0-size to prevent any distribution to it.
                              (values cards (table.set sizes player-z 0))
                              (let [hand (fcollect [i 0 12]
                                           (case (. det-state.hand player-z i)
                                             0 nil
                                             card card))]
                                (values (table.join cards hand)
                                        (table.set sizes player-z (length hand))))))
        exhausted {0 (. agent.memory.short-suits 1) 1 (. agent.memory.short-suits 2)
                   2 (. agent.memory.short-suits 3) 3 (. agent.memory.short-suits 4)}
        cards-by-suit (faccumulate [b {SUIT_SPADES [] SUIT_HEARTS []
                                       SUIT_DIAMONDS [] SUIT_CLUBS []}
                                    i 1 (length all-cards)]
                        (let [card (. all-cards i)
                              suit (band MASK_SUIT card)
                              dest (. b suit)]
                          (set (. dest (+ 1 (length dest))) card)
                          b))
        ;; sort players by how hard they will be to satisfy
        players [0 1 2 3]
        difficulties (faccumulate [d {0 0 1 0 2 0 3 0} player-z 0 3]
                       (let [difficulty (accumulate [count 0 suit cards (pairs cards-by-suit)]
                                          (if (not (. exhausted player-z suit))
                                            (+ count (length cards))
                                            count))]
                         (set (. d player-z) difficulty)
                         d))
        _ (table.sort players (fn [a b] (< (. difficulties a) (. difficulties b))))
        hands {0 [] 1 [] 2 [] 3 []}
        ;; We just one-shot try to distribute the cards starting with hardest first
        ;; which generally seems to be fine, since the contraints & initial
        ;; available cards will satisfy given they're from a "real game".
        ;; TODO: we can wrap this in n-tries pretty easily at least.
        _ (fn assign [players grouped-cards]
            (case (table.remove players 1)
              nil true ;; terminal
              player-z (let [need-count (. sizes player-z)
                             candidates (accumulate [candidates {} suit cards (pairs grouped-cards)]
                                          ;; optim: can use for and (set x (len + i) y)
                                          (if (not (. exhausted player-z suit))
                                            (icollect [_ card (ipairs cards) &into candidates] card)
                                            candidates))]
                         (if (<= need-count (length candidates))
                           (let [_ (table.shuffle candidates)
                                 a-set (fcollect [i 1 need-count] (. candidates i))
                                 ;; remove selected cards from availablity pool
                                 trimmed-grouped-cards {SUIT_SPADES []
                                                        SUIT_HEARTS []
                                                        SUIT_DIAMONDS []
                                                        SUIT_CLUBS []}
                                 _ (each [suit cards (pairs grouped-cards)]
                                     (fcollect [i 1 (length cards) &into (. trimmed-grouped-cards suit)]
                                       (if (not (faccumulate [found? false j 1 (length a-set) &until found?]
                                                  (= (. cards i) (. a-set j))))
                                         (. cards i))))]
                             (set (. hands player-z) a-set)
                             (assign players trimmed-grouped-cards))
                           ;; not enough candidates to satisfy, exit
                           (do
                             ; (Logger.info [:player-z player-z :needed need-count :got (length candidates)])
                             false)))))]
    (if (assign players cards-by-suit)
      ;; Distribute hands
      (do
        (for [player-z 0 3]
          (if (not (= observer-player (+ player-z 1)))
            (let [hand (. hands player-z)]
              ;; run 0->12 to zero out the hand at the same time.
              ;; though we should be safe given size(new) == size(old)
              (for [i 0 12]
                (set (. det-state.hand player-z i) (or (. hand (+ i 1)) 0)))))))
      ;; Could not smartly distribute, jus give out randomly
      (do
        ; (Logger.info "Could not smart-distribute cards, using random.")
        (table.shuffle all-cards)
        (accumulate [offset 0 player-z size (pairs sizes)]
          (do
            (for [i 0 (- size 1)]
              (set (. det-state.hand player-z i) (. all-cards (+ offset i 1))))
            (+ offset size)))))
    det-state))

;; Return the current player given the state, this should be a single value
;; type that supports (= x y). Eg: 1, 2, 3 or :player-1, etc.
(λ Game.current-player [_agent state]
  (Logic.Query.current-player state))

;; Generate list of available actions for given state.
;; Note that any "current player" should be implicit in the state.
;; Note that the "action" definition should support (= action-a action-b).
;; Note that Game.next-state() must support any returned action.
(λ Game.available-actions [agent state ?rollout?]
  (case state.phase
    (where (= PHASE_PASS))
    (error :not-implemented)
    (where (= PHASE_TRICK_PLAY))
    (if ?rollout?
      (Game.available-trick-actions-fast agent state)
      (Game.available-trick-actions agent state))
    (where (= PHASE_TRICK_RESOLVE))
    [[:resolve-trick]]
    phase (do
            (Logger.info [:available-actions :unknown-phase phase state])
            (error (%s "debug-generate-random-action #{phase}")))))

;; 4 suits, 2->14 ranks
;; index 0 is our 'in-hand' flag, index 1 is unused.
(local card_map_t (ffi.typeof "int8_t[4][15]"))
(local card_map_t_hearts_index 0)
(local card_map_t_clubs_index 1)
(local card_map_t_diamonds_index 2)
(local card_map_t_spades_index 3)

(fn card-map-suit-index [suit]
  (case suit
    (where (= SUIT_HEARTS)) card_map_t_hearts_index
    (where (= SUIT_CLUBS)) card_map_t_clubs_index
    (where (= SUIT_DIAMONDS)) card_map_t_diamonds_index
    (where (= SUIT_SPADES)) card_map_t_spades_index))

(fn build-played-cards-map [state current-player-z]
  ;; Mask seen suits into int, as getting keys is *slow*, when called
  ;; millions of times and we want to only process seen ones in the next step.
  (let [card-map (ffi.new card_map_t)]
    ;; Examine player hand, record the index of any card that we're holding
    ;; into a table, indexed by the card rank. Eg if clubs-3 is at index 8,
    ;; then clubs.3 = 8.
    ;; We need to track the indexes to build or final ;; actions.
    (for [i 0 12]
      (case (. state.hand current-player-z i)
        0 nil
        card (let [suit (band MASK_SUIT card)
                   rank (band MASK_RANK card)
                   suit-index (card-map-suit-index suit)]
               (when (= 0 (. card-map suit-index 0))
                 ;; mark as suit 'in-hand'
                 (set (. card-map suit-index 0) 1)
                 ;; sice 0 is a valid hand-index we need to default to -1
                 (for [i 2 14] (set (. card-map suit-index i) -1)))
               (set (. card-map suit-index rank) i))))
    ;; Mark any played cards as 255 and any cards in other players hands as -1.
    ;; Both these values are invalid hand indexes. We can ignore 255 cards when
    ;; buildng runs and must break runs when other players are holding cards.
    (for [player-z 0 3]
      ;; Previously played cards
      (for [i 0 51]
        (case (. state.round player-z i)
          0 nil
          card (let [suit (band MASK_SUIT card)
                     rank (band MASK_RANK card)
                     suit-index (card-map-suit-index suit)]
                 (set (. card-map suit-index rank) 255))))
      ;; Cards in the current trick
      (case (. state.trick player-z 0)
        0 nil
        card (let [suit (band MASK_SUIT card)
                   rank (band MASK_RANK card)
                   suit-index (card-map-suit-index suit)]
               (set (. card-map suit-index rank) 255))))
    card-map))

(fn build-contiguous-blocks-from-card-map [card-map playable-indexes]
  (let [playable-n? [false false false false false
                     false false false false false
                     false false false]
        ;; convert [1 3 4] => {1 true 2 false 3 true ...}
        _ (fcollect [i 1 (length playable-indexes)]
            (set (. playable-n? (. playable-indexes i)) true))]
    (faccumulate [blocks [] suit-index 0 3]
      (if (= 1 (. card-map suit-index 0)) ;; if suit is in hand
        (let [suit (case suit-index
                     (where (= card_map_t_hearts_index)) SUIT_HEARTS
                     (where (= card_map_t_clubs_index)) SUIT_CLUBS
                     (where (= card_map_t_diamonds_index)) SUIT_DIAMONDS
                     (where (= card_map_t_spades_index)) SUIT_SPADES)
              final-run (faccumulate [current-run [] rank 2 14]
                          (let [at-index (. card-map suit-index rank)]
                            (case (values at-index suit rank)
                              ;; QoS played, so we can ignore its
                              ;; effects, keep any J K contiguous.
                              ;; Eg J 255 K, playing K can only be beaten by A
                              (where (255 (= SUIT_SPADES) (= RANK_QUEEN)))
                              (values current-run)
                              ;; QoS not played, not in hand, so start
                              ;; another run, potentially spliting J K
                              ;; Eg: J Q K, playing J may land us a Q or K.
                              (where (-1 (= SUIT_SPADES) (= RANK_QUEEN)))
                              (do
                                (when current-run (set (. blocks (+ 1 (length blocks))) current-run))
                                (values nil))
                              (where (-1 _ _))
                              ;; Encountered an unplayed card that is not in our
                              ;; hand. This terminates any current run.
                              ;; Eg given, 3 4 0 6 -> [3 4] [6] as playing 4|6 can
                              ;; be responded to with a 2, 5 or 7.
                              (do
                                (when current-run (set (. blocks (+ 1 (length blocks))) current-run))
                                (values nil))
                              ;; Encountered a played card that is not in our hand.
                              ;; We can ignore this card and retain any current
                              ;; run.
                              ;; Eg given, 3 4 255 6 -> [3 4 6] as playing 4|6 can
                              ;; only be responded to with 2 or 7.
                              (where (255 _ _))
                              (do
                                (values current-run))
                              ;; QoS not played, in hand, stop any current run
                              ;; and start a queen-only run, then end it
                              ;; immediately.
                              ;; Eg: J Q K, playing Q vs A is very different to K v A.
                              (where (hand-index-z (= SUIT_SPADES) (= RANK_QUEEN)))
                              (do
                                (when current-run (set (. blocks (+ 1 (length blocks))) current-run))
                                (when (. playable-n? (+ hand-index-z 1))
                                  (set (. blocks (+ 1 (length blocks))) [hand-index-z]))
                                (values nil))
                              ;; Card is not special, in our hand, start new
                              ;; run or add to current.
                              (where (hand-index-z _ _))
                              (do
                                (if (. playable-n? (+ hand-index-z 1))
                                  (if current-run
                                    (do
                                      (set (. current-run (+ 1 (length current-run))) hand-index-z)
                                      current-run)
                                    [hand-index-z])
                                  (values current-run))))))]
          (when final-run
            (table.insert blocks final-run))
          blocks)
        blocks))))

(λ Game.available-trick-actions [agent state]
  ;; We compress contiguous runs of cards (in hand + played) because
  ;; the game outcomes are the same. Eg, given 10 Q in hand and J K A in
  ;; played, it does not matter if we play 10 or Q, there will never be a
  ;; card that can beat it.
  ;;
  ;; We have special rules for Queen of Spades as given J Q K in hand, playing
  ;; J or K to win a trick is very diffrent to playing Q. If Q has already been
  ;; played, J K can be considered contiguous.
  (let [player-n (Logic.Query.current-player state)
        player-z (- player-n 1)
        ;; :find-playable-cards -> baseline
        ;; :build-played-cards-map -> 1.6x
        ;; build-contiguous-blocks-from-card-map -> 2.3x
        playable-index-ns (Logic.Agent.find-playable-cards state player-n)
        ;; Played map tells us if any card was played in a previous round or
        ;; the current trick, which we can use do decide if gaps are "filled"
        ;; or not when building contiguous runs from our hand.
        card-map (build-played-cards-map state player-z)
        ;; We now know if a card has been played or exists in our hand or
        ;; someone elses hand. We want to convert any contiguous runs of cards
        ;; that are in our hand or already played.
        ;; Now examine each suit and build contiguous blocks of cards
        blocks (build-contiguous-blocks-from-card-map card-map playable-index-ns)]
    ;; Initially we were going to generate abstract actions from the card set,
    ;; eg: {low,high}-{short,longest}-suit, dump-hearts, etc but we need
    ;; an action for every block we have. Eg, given clubs 1,2,3,5,king, we have
    ;; three blocks, [1,2,3],[5],[king]. We can make high & low abstract
    ;; actions but will still need one for 5, so in the end all the blocks will
    ;; cover any abstract action so we just make the blocks actions.
    ;;
    ;; We just pick one consistent cart from each block as they're effectively
    ;; identical in play.
    ;;
    ;; Also keep in mind that our blocks are hand-indexes not card values.
    ;; each block that is at least one element long and any element is
    ;; equivalent to any other in the same block, so we can immediately grab
    ;; the first element.
    ;;
    ;; Blocks will be something like [[] [] [1 2 3] ...] where we will have
    ;; empty tables for suits that were not in hand, so we'll check for
    ;; nil-indexes but otherwise we are free to take the first index of any
    ;; block and treat it as equivalent to any other in that block.
    (fcollect [i 1 (length blocks)]
      (case (. blocks i)
        [hand-index] [:play-card player-n (+ hand-index 1)]))))

;; during rollout we can skip some classicication work for actions and just
;; pick any random card rather than a random trimmed action.
;; Trimming the action space is important when building the tree as it cuts our
;; exploration space down but ultimately any card in a action-set is the same,
;; so if we're just picking something randomly, we can pick randomly from the
;; full set.
(λ Game.available-trick-actions-fast [agent state]
  (let [player-n (Logic.Query.current-player state)
        playable-index-ns (Logic.Agent.find-playable-cards state player-n)]
    (when (= 0 (length playable-index-ns))
      (Logger.info [:noting-playable state])
      (error :bad))
    (fcollect [i 1 (length playable-index-ns)]
      [:play-card player-n i])))

;; Apply action (as generated by available-actions)
(λ Game.next-state [agent state action]
  (case action
    [:play-card player hand]
    (let [next-state (Logic.Agent.play-card state player hand)]
      ;; We are never interested in the "resolve-trick" state. Either we want
      ;; to play a card or score the entire round so instead of running the
      ;; entire available-action -> next-state cylce we just shortcut that
      ;; immediately.
      (case next-state.phase
        (where (= PHASE_TRICK_RESOLVE)) (Logic.Agent.resolve-trick next-state)
        _ next-state))
    _ (error (%s "not valid agent action #{action}"))))

(λ Game.rollout [agent initial-struct]
  (summark :rollout
  (let [{:Agent {: resolve-trick : play-card}
         :Query {: round-ended?}} Logic
        {: random} math]
    ;; For whatever reason (better to jit for loops?) this accumulate #true
    ;; loop is reliably about 15ms faster average select action over the
    ;; identical while loop.
    (accumulate [struct initial-struct _ #true &until (round-ended? struct)]
      (case struct.phase
        (where (= PHASE_TRICK_RESOLVE))
        (resolve-trick struct)
        (where (= PHASE_TRICK_PLAY))
        (let [actions (Game.available-actions agent struct true)
              [_play-card player-z index-z] (. actions (random (length actions)))]
          (play-card struct player-z index-z))
        phase (error (%s "unhandled phase during rollout #{phase}")))))))

;; Is the given state game-over in any way?
(λ Game.terminal? [_agent state]
  (case state.phase
    (where (= PHASE_RESOLVE_ROUND)) true
    _ false))

;; Score the given state for the observer.
;; Should be between 0 (worst outcome) and 1 (best outcome)
;;
;; Logistic distance:
;;
;; U = 1/(1 + e^(k*dist))
;; U = (1)/(1 + (e^(k*(score - best))))
;; k = curve gradient
;;
;; Using this naively, score - best, gives sort of bad values, eg if best is 0
;; and score is 0, then your utility is 0.5, when really it should be 1.
;;
;; We can adjust for this by normalising the player score (score / max) and
;; using a large k, eg
;;
;; U = 1 / (1 + e^(10 * ((score/max) - 0.5)))
;;
;; A k of 5 will get us very close to score = 0, utility = 1 and anything after
;; that sharpens the transition curve. 10 seems sort of reasonable, but at this
;; point, its sort of, uh what *should* the curve look like, really? Might as
;; well just do a linear scale from best score to worst: (1 - (score / higest))
;; where highest may be 26 (higest possible) or highest among the round?
;;
(fn find-min-max [total-points]
  (accumulate [(min minp max maxp) (values math.huge nil -1 nil)
               player points (ipairs total-points)]
    (values (if (< points min) points min)
            (if (< points min) player minp)
            (if (< max points) points max)
            (if (< max points) player maxp))))

(λ Game.utility [_agent state observer-player]
  ;; Specific conditions we want to track:
  ;;
  ;; - Did we lose the match? 0 utility.
  ;; - Did we win the match? 1 utility.
  ;; - Did we shoot the moon? +bonus utility.
  ;; - Did they shoot the moon? -bonus utility.
  ;;
  ;; Otherwise we sum the round score to any ongoing match score and basically
  ;; draw a straight line from "least points to most points" where least points
  ;; gets you 0.9 utility and most points gets you 0.1 utility. We leave the
  ;; outer edges of the range for our win(1)/lose(0) meta utility values and a
  ;; small shoot the moon modifier.
  ;;
  ;; There are other aspects we might want to consider, eg if we're in the lead
  ;; by -1 point, vs another outcome where we're in the lead by -20 points, one
  ;; of those is a better goal to aim for. Also how spread all players are, a
  ;; close game is better unless we're way out in front.
  ;;
  (let [round-points (Logic.Query.score-round state)
        match-points (Logic.Query.score-match state)
        total-points (fcollect [i 1 4] (+ (. round-points i) (. match-points i)))
        (min-points min-player max-points max-player) (find-min-max total-points)
        loser (if (<= state.rule_score_limit max-points) max-player)
        winner (if loser min-player)]
    (if
      (= winner observer-player) 1
      (= loser observer-player) 0
      (let [moon-shot-modifier (let [moon-shot? (= (* 26 3) (accumulate [sum 0 _ p (ipairs round-points)]
                                                              (+ sum p)))
                                     we-moon-shot? (and moon-shot? (= 0 (. round-points observer-player)))]
                                 (if moon-shot?
                                   (if we-moon-shot? 0.04 -0.03)
                                   0.0))
            our-score (. total-points observer-player)
            match-utility (let [hi 0.95
                                lo 0.05
                                ratio (/ (- our-score min-points)
                                         (math.max 1e-06 (- max-points min-points)))]
                            (+ lo (* (- hi lo) (- 1 ratio))))]
        (+ match-utility moon-shot-modifier)))))

(λ Strategy.select-action [actions]
  ; (Logger.info [:Strategy.select-action actions])
  (. actions (math.random 1 (length actions))))

M
