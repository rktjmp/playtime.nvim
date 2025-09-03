(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Component (require :playtime.component))

(local M {})

(fn make-play-again-button [[text [event-ns event-name ?args]]]
  (let [width (+ 2 (string.col-width text))
        on {:click (fn [self cofx event fx]
                     (case event {:action :release} (fx.event.dispatch event-ns event-name ?args)))}]
    (Component.new {:size {: width :height 1}
                    :content [[[(string.fmt " %s " text) "@playtime.ui.menu"]]]
                    : on})))

(λ M.new [{: view-size : result : result-lines :other-lines ?other-lines :play-again ?play-again}]
  (let [border {:nw "╒" :n "═" :ne "╕"
                :w  "│"         :e "│"
                :sw "╘" :s "═" :se "╛"}
        other-lines (or ?other-lines [])
        max-len (accumulate [m 0 _ [_id text] (ipairs result-lines)]
                  (math.max m (string.col-width text)))
        max-len (accumulate [m max-len _ text (ipairs other-lines)]
                  (math.max m (string.col-width text)))
        max-len (+ max-len (string.col-width " ☑   "))
        border-color "@playtime.ui.on"
        top [[(.. border.nw (string.rep border.n max-len) border.ne) border-color]]
        empty [[(.. border.w (string.rep " " max-len) border.e) border-color]]
        bottom [[(.. border.sw (string.rep border.s max-len) border.se) border-color]]
        width (string.col-width (. top 1 1))
        height (+ 1 ;; top border
                  1 ;; empty
                  (length result-lines)
                  1 ;; empty
                  (if (< 0 (length other-lines))
                    (length other-lines) ;; other
                    0) ;; nothing
                  1 ;; empty
                  (if ?play-again 2 0) ;;button
                  1) ;; bottom border
        row 5
        col (- (math.floor (/ view-size.width 2)) (math.floor (/ width 2)))
        button (when ?play-again
                 (let [button (make-play-again-button ?play-again)]
                   (set button.position.row (+ row height -3))
                   (set button.position.col (math.ceil (+ col
                                                          (/ width 2)
                                                          (* -1 (/ button.size.width 2)))))
                   (set button.position.z 802)
                   button))
        lines (icollect [_ [id text] (ipairs result-lines)]
                (let [text (.. (if (= id result) "☑ " "☐ ") " " text)]
                  [[(.. border.w " ") border-color]
                   [text (if (= id result) "@playtime.color.yellow" "@playtime.ui.off")]
                   [(string.rep " " (- max-len (string.col-width text) 1))]
                   [(.. border.e " ") border-color]]))
        _ (do
            (table.insert lines 1 empty)
            (table.insert lines 1 top)
            (table.insert lines empty)
            (each [_ line (ipairs other-lines)]
              (table.insert lines [[(.. border.w " ") border-color]
                                   [line "@playtime.ui.on"]
                                   [(string.rep " " (- max-len (string.col-width line) 1))]
                                   [(.. border.e " ") border-color]]))
            (when button
              (table.insert lines empty)
              (table.insert lines empty))
            (table.insert lines empty)
            (table.insert lines bottom))
        component (Component.new {:position {: row : col :z 801}
                                  :size {: width : height}
                                  :content lines
                                  :children [button]})]
    component))

M
