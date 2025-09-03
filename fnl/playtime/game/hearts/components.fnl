(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Component (require :playtime.component))

(local M {})

(λ M.guide-text [{: size : position}]
  (Component.new {:size size
                  :position position
                  :set-text (fn [self text]
                              (let [len (length text)
                                    pad-left (math.floor (/ (- self.size.width len) 2))]
                                (set self.position.col pad-left)
                                (set self.content [[[text "@playtime.ui.off"]]])))}))

(λ M.leader-indicator [positions]
  (Component.new {:size {:width 9 :height 5}
                  :position {:row 1 :col 1 :z 99}
                  :set-leader (fn [self player]
                                (let [{: row : col} (. positions player)]
                                  (set self.position.row row)
                                  (set self.position.col (- col 1))))
                  :content [[["⸢       ⸣" "@playtime.ui.off"]]
                            [["        " "@playtime.ui.off"]]
                            [["        " "@playtime.ui.off"]]
                            [["        " "@playtime.ui.off"]]
                            [["⸤       ⸥" "@playtime.ui.off"]]] }))

(λ M.score-board [{: position : size}]
  (let [{: width} size]
    (fn update-content [self total-scores round-scores]
      (let [player-names ["You" "Frank" "Cosmo" "Estelle"]
            header (table.insert (clone player-names) 1 "Round")
            max-col-width (accumulate [max -1 _ s (ipairs player-names)]
                            (if (< max (length s)) (length s) max))
            max-col-width (+ max-col-width 2)
            line-hl "@playtime.ui.off"
            text-hl "@playtime.ui.off"
            make-border (fn [left fill join right]
                          [[left line-hl]
                           ;; round
                           [(string.rep fill max-col-width) line-hl]
                           [join line-hl]
                           ;; p1
                           [(string.rep fill max-col-width) line-hl]
                           [join line-hl]
                           ;; p2
                           [(string.rep fill max-col-width) line-hl]
                           [join line-hl]
                           ;; p3
                           [(string.rep fill max-col-width) line-hl]
                           [join line-hl]
                           ;; p4
                           [(string.rep fill max-col-width) line-hl]
                           [right line-hl]])
            left-aligned #(string.format (string.format "%%-%ds" max-col-width) $1)
            right-aligned #(string.format (string.format "%%%ds" max-col-width) $1)
            make-row (fn [bits align]
                       (accumulate [t [["│" line-hl]] _ bit (ipairs bits)]
                         (doto t
                           (table.insert [(align bit) text-hl])
                           (table.insert ["│" line-hl]))))
            head (make-border "┌" "─" "┬" "┐")
            foot (make-border "└" "─" "┴" "┘")
            breaker (make-border "├" "─" "┼" "┤")
            content [head
                     (make-row header right-aligned)
                     breaker
                     (make-row (table.insert total-scores 1 "Sum") right-aligned)
                     breaker]
            ;; we render rounds newest -> oldest, so reverse round-scores
            _ (for [i (length round-scores) 1 -1]
                (let [scores (. round-scores i)]
                  (table.insert scores 1 i)
                  (table.insert content (make-row scores right-aligned))))
            _ (table.insert content foot)]
        (set self.content content)
        (set self.size.height (length content))))
    (Component.new {:size {:width width :height 1}
                    : position
                    : update-content})))

(λ M.round-score [{: position}]
  (fn update-content [comp point-cards style]
    (let [{: heart : queen-of-spades} (accumulate [t {:heart 0 :queen-of-spades 0}
                                                    _ what (ipairs point-cards)]
                                         (do
                                           (set (. t what) (+ 1 (. t what)))
                                           t))
          hearts (if (< 0 heart)
                   (case style
                     :line (.. heart "♥")
                     :left (.. heart "♥")
                     :right (.. heart "♥"))
                   "")
          qos (if (< 0 queen-of-spades)
                (case style
                  :line " Q♠"
                  :left (string.format (string.format "%%-%ds" (length hearts)) "Q♠")
                  :right (string.format (string.format "%%%ds" (length hearts)) "Q♠"))
                "")]
      (set comp.size.height (case style :line 1 _ 2))
      (set comp.content (case style
                          :line [[[hearts "@playtime.game.card.hearts.four_colors"]
                                  [qos "@playtime.game.card.spades.four_colors"]]]
                          :right [[[hearts "@playtime.game.card.hearts.four_colors"]]
                                  [[qos "@playtime.game.card.spades.four_colors"]]]
                          :left [[[hearts "@playtime.game.card.hearts.four_colors"]]
                                  [[qos "@playtime.game.card.spades.four_colors"]]]))))

  (Component.new {: position
                  :size {:width 7 :height 2}
                  : update-content}))

M
