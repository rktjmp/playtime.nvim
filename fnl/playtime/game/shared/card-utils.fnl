(require-macros :playtime.prelude)
(prelude)

(local Error (require :playtime.error))
(local Logger (require :playtime.logger))

(local M {})

(fn M.make-iter-cards-fn [default-fields]
  ;; TODO: this is maybe too specific to the way we layout patience game
  ;; data structures [field col/n card] to be in here vs app.patience.
  ;; Alternatively we expand the field spec do be something like
  ;; [[:foundation #(length $1) #(length $1)] [:hand [:player :grid] ..]]
  ;; #(length $1) *could* just be length as its pretty common.
  ;; Probably it should actually be #(ipairs $1) or #(some-for-generator) etc.
  (fn [state ?fields]
    (fn iter []
      (each [_ field (ipairs (or ?fields default-fields))]
        (each [col-n column (ipairs (. state field))]
          (each [card-n card (ipairs column)]
            (coroutine.yield [field col-n card-n] card)))))
    (coroutine.wrap iter)))

;; TODO: superseded by table.get-in, but without the nil fallback (could add to get-in)
(λ M.location-contents [state location]
  (case location
    [field nil] (?. state field)
    [field col nil] (?. state field col)
    [field col card-n] (?. state field col card-n)
    _ (error (Error "invalid location #{location}" {: location}))))

(fn M.same-location-field? [a b]
  (case (values a b)
    ([f] [f]) true
    _ false))

(fn M.same-location-field-column? [a b]
  (case (values a b)
    ([f c] [f c]) true
    _ false))

(fn M.same-location-field-column-card? [a b]
  (case (values a b)
    ([f c n] [f c n]) true
    _ false))

(λ M.make-card-util-fns [spec]
  (assert spec.value "must provide card value spec")
  (assert spec.color "must provide card color spec")
  (local fns {})
  (macro fail [] `(error (Error "invalid card #{card}" {:card ,(sym :card)})))

  (fn fns.flip-face-up [card]
    (doto card
      (tset :face :up)))

  (fn fns.flip-face-down [card]
    (doto card
      (tset :face :down)))

  (fn fns.card-face-up? [card]
    (case card
      {:face :up} true
      {:face :down} false
      _ (error (<s> "Not a card: #{card}"))))

  (fn fns.card-face-down? [card]
    (not (fns.card-face-up? card)))

  (fn fns.card-value [card]
    (case card
      ;; TODO: setting 1 = 14 (ace high) will causes jokers to have that value too.
      [_suit rank] (or (. spec :value rank) rank)
      _ (fail)))

  (fn fns.card-color [card]
    (case card
      [suit rank] (or (. spec :color suit) (fail))
      _ (fail)))

  (fn fns.card-rank [card]
    (case card
      [_suit rank] rank
      _ (fail)))

  (fn fns.card-suit [card]
    (case card
      [suit] suit
      _ (fail)))

  (fn fns.rank-value [rank]
    (fns.card-value [:any rank]))

  (fn fns.suit-color [suit]
    (fns.card-color [suit :any]))

  fns)

;; TODO: Smell? We never check the first card via comparitor-fn, which
;; makes sense because we're checking a sequence, eg to check b in a, b, c
;; we need a + b, and checking a on its own is a bit weird, but it does mean
;; we don't enforce stuff on the top card (eg: must be face up).
(λ M.make-valid-sequence?-fn [comparitor-fn]
  (fn [sequence]
    (case sequence
      [top-card & other-cards]
      (accumulate [(ok? checked-cards memo) (values true [top-card] nil)
                   _ card (ipairs other-cards)
                   &until (not ok?)]
        (let [(ok? memo) (comparitor-fn card checked-cards memo)]
          (if ok?
            (values true (table.insert checked-cards 1 card) memo)
            (values false))))
      _ false)))

(fn M.inc-moves [state ?count]
  (doto state
    (tset :moves (+ (or ?count 1) state.moves))))

;; TODO: making this actually recursive would probably simplify [a b :top]
;; stuff, where we just operate on the actual state given instead of having to
;; track the "state" and "true state" stuff.
(λ M.apply-events [state events]
  (accumulate [(state true-events) (values state [])
               event-num event (ipairs events)]
    (case event
      (where (or [:face-up location] [:face-down location]))
      (let [index (case (table.last location)
                    :top (length (table.get-in state (table.split location -1)))
                    :bottom 1
                    n n)
            [face-where _] event
            location (table.set (clone location) (length location) index)]
        (case (table.get-in state location)
          card (case face-where
                 :face-up (set card.face :up)
                 :face-down (set card.face :down))
          _ (error (<s> "apply-events: no card, cannot apply #{event-num}: #{event}, #{events}")))
        (values state (table.insert true-events [face-where location])))
      [:swap a b]
      (let [a-index (case (table.last a)
                      :bottom 1
                      :top (length (table.get-in state (table.split a -1)))
                      n n)
            b-index (case (table.last b)
                      :bottom 1
                      :top (length (table.get-in state (table.split b -1)))
                      n n)
            a (-> (clone a)
                  (table.set (length a) a-index))
            b (-> (clone b)
                  (table.set (length b) b-index))
            temp (table.get-in state b)]
        (table.set-in state b (table.get-in state a))
        (table.set-in state a temp)
        (values state (table.insert true-events [:swap a b])))
      [:move from to]
      (let [from-index (case (table.last from)
                         :bottom 1
                         :top (length (table.get-in state (table.split from -1)))
                         n n)
            (mod-fn to-index) (case (table.last to)
                                :bottom (values table.insert-in 1)
                                :top (values table.set-in (+ 1 (length (table.get-in state (table.split to -1)))))
                                n (values table.set-in n))
            from (-> (clone from)
                     (table.set (length from) from-index))
            to (-> (clone to)
                   (table.set (length to) to-index))]
        (mod-fn state to (table.get-in state from))
        (table.set-in state from nil)
        (values state (table.insert true-events [:move from to])))
      _ (error (Error "apply-events: unknown event #{event}" {: event})))))

M
