(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Component (require :playtime.component))
(local M {})

(λ M.cursor [LayoutImpl location]
  (-> (Component.build
        (fn [comp location]
          (let [{: row : col} (LayoutImpl.location->position location)
                z (LayoutImpl.z-index-for-layer :cursor)
                row (+ row 1)
                col (- col 2)]
            (comp:set-position {: row : col : z}))))
      (Component.set-size {:width 3 :height 1})
      (Component.set-content [[["🯁🯂🯃" :Comment]]])
      (: :update location)))

(λ M.cheating []
  (-> (Component.build)
      (Component.set-position {:row 0 :col 0 :z 150})
      (Component.set-size {:width 1 :height 1})
      (Component.set-content [[["👻" "@playtime.ui.on"]]])))

(λ M.win-count [?wins {: width : z}]
  (let [text (.. "Wins: " (or ?wins 0))]
    (-> (Component.build)
        (Component.set-position {:row 0 :col (- width (length text) 1) : z})
        (Component.set-size {:width (length text) :height 1})
        (Component.set-content [[[text "@playtime.ui.menu"]]]))))

(λ M.game-report [view-width view-height z options]
  ;; Options are ordered, so given as [[:great "Great, 1-3"]]
  (-> (Component.build
        (fn [comp result ?other-lines]
          (let [other-lines (or ?other-lines [])
                max-len (accumulate [m 0 _ [_id text] (ipairs options)]
                          (math.max m (vim.str_utfindex text)))
                max-len (accumulate [m max-len _ text (ipairs other-lines)]
                          (math.max m (vim.str_utfindex text)))
                max-len (+ max-len (vim.str_utfindex " ☑   "))
                border-color "@playtime.ui.on"
                edge "║"
                top [[(.. "╓" (string.rep "─" max-len) "╖") border-color]]
                empty [[(.. edge (string.rep " " max-len) edge) border-color]]
                bottom [[(.. "╙" (string.rep "─" max-len) "╜") border-color]]
                width (vim.str_utfindex (. top 1 1))
                height (+ 1 ;; top
                          1 ;; empty
                          (length options)
                          1 ;; empty
                          (if (< 0 (length other-lines))
                            (+ (length other-lines) 1) ;; other + empty
                            0) ;; nothing
                          1) ;; bottom
                ; row (- (math.floor (/ view-height 2)) (math.floor (/ height 2)))
                row 5
                col (- (math.floor (/ view-width 2)) (math.floor (/ width 2)))
                lines (icollect [_ [id text] (ipairs options)]
                        (let [text (.. (if (= id result) "☑ " "☐ ") " " text)]
                          [[(.. edge " ") border-color]
                           [text (if (= id result) "@playtime.color.yellow" "@playtime.ui.off")]
                           [(string.rep " " (- max-len (vim.str_utfindex text) 1))]
                           [(.. edge " ") border-color]]))]
            (table.insert lines 1 empty)
            (table.insert lines 1 top)
            (table.insert lines empty)
            (each [_ line (ipairs other-lines)]
              (table.insert lines [[(.. edge " ") border-color]
                                   [line "@playtime.ui.on"]
                                   [(string.rep " " (- max-len (vim.str_utfindex line) 1))]
                                   [(.. edge " ") border-color]]))
            (table.insert lines empty)
            (table.insert lines bottom)
            (comp:set-size {: width : height})
            (comp:set-position {: row : col : z})
            (comp:set-visible true)
            (comp:set-content lines))))
      (Component.set-visible false)))

(λ M.you-died []
  (local raw-lines
    ["db    db  .d88b.  db    db      d8888b. d888888b d88888b d8888b."
     "`8b  d8' .8P  Y8. 88    88      88  `8D   `88'   88'     88  `8D"
     " `8bd8'  88    88 88    88      88   88    88    88ooooo 88   88"
     "   88    88    88 88    88      88   88    88    88~~~~~ 88   88"
     "   88    `8b  d8' 88b  d88      88  .8D   .88.   88.     88  .8D"
     "   YP     `Y88P'  ~Y8888P'      Y8888D' Y888888P Y88888P Y8888D'"])
  (local raw-lines
    ["                                                ,,                 ,,   "
     "`YMM'   `MM'                     `7MM\"\"\"Yb.     db               `7MM   "
     "  VMA   ,V                         MM    `Yb.                      MM   "
     "   VMA ,V ,pW\"Wq.`7MM  `7MM        MM     `Mb `7MM  .gP\"Ya    ,M\"\"bMM   "
     "    VMMP 6W'   `Wb MM    MM        MM      MM   MM ,M'   Yb ,AP    MM   "
     "     MM  8M     M8 MM    MM        MM     ,MP   MM 8M\"\"\"\"\"\" 8MI    MM   "
     "     MM  YA.   ,A9 MM    MM        MM    ,dP'   MM YM.    , `Mb    MM   "
     "   .JMML. `Ybmd9'  `Mbod\"YML.    .JMMmmmdP'   .JMML.`Mbmmd'  `Wbmd\"MML. "
     "                                                                        "])

  (local raw-lines
    [".                                                            ."
     " dP    dP                      888888ba  oo                dP "
     " Y8.  .8P                      88    `8b                   88 "
     "  Y8aa8P  .d8888b. dP    dP    88     88 dP .d8888b. .d888b88 "
     "    88    88'  `88 88    88    88     88 88 88ooood8 88'  `88 "
     "    88    88.  .88 88.  .88    88    .8P 88 88.  ... 88.  .88 "
     "    dP    `88888P' `88888P'    8888888P  dP `88888P' `88888P8 "
     ".                                                            ."])

  (local lines
    (icollect [_ line (ipairs raw-lines)]
      (accumulate [parts []  lw letters tw (string.gmatch line "(%s*)(%S+)(%s*)")]
        (doto parts
          (table.insert [lw])
          (table.insert [letters "@playtime.color.red"])
          (table.insert [tw])))))
    (-> (Component.build)
        (Component.set-position {:row 3 :col 3})
        (Component.set-size {:width 64 :height (length raw-lines)})
        (Component.set-content lines)))

(λ M.menubar [menu-structure {:width view-width : z}]
  (λ pad-text [text] (.. " " text " "))
  (λ fill-text-width [text width]
    (.. text (string.rep " " (- width (length text)))))
  (local hl "@playtime.ui.menu")

  (λ make-menubar-top-menu [text tag {: row : col} ?children]
    (-> (Component.build
          (fn [self open?]
            (self:set-content [[[text hl]]])
            (each [_ c (ipairs (or self.children []))]
              (c:set-visible open?))))
        (Component.set-content [[[text hl]]])
        (Component.set-tag tag)
        (Component.set-size {:height 1 :width (length text)})
        (Component.set-position {: row : col :z (+ z 2)})
        (Component.set-children ?children)))

  (λ make-menubar-menu-entry [text ?tag {: row : col} width]
    (-> (Component.build)
        (Component.set-content [[[(fill-text-width (pad-text text) width) hl]]])
        (Component.set-tag ?tag)
        (Component.set-position {: row : col :z (+ z 2)})
        (Component.set-size {:height 1 :width (length (fill-text-width (pad-text text) width))})
        (Component.set-visible false)))

  (let [top-menu-items (accumulate [(top-items col) (values [] 1)
                                    top-index [text _event ?children] (ipairs menu-structure)]
                         (let [top-text (pad-text text)
                               widest-child (accumulate [w (length top-text) _ [text ] (ipairs (or ?children []))]
                                              (math.max w (length (pad-text text))))
                               children (icollect [child-index [text _event] (ipairs (or ?children []))]
                                          (make-menubar-menu-entry text
                                                                   [:menu top-index child-index]
                                                                   {:row child-index :col (- col 1)}
                                                                   widest-child))
                               item (make-menubar-top-menu text
                                                           [:menu top-index]
                                                           {:row 0 : col} children)]
                           (values (table.insert top-items item)
                                   (+ col 2 (length text)))))
        menubar (-> (Component.build)
                    (Component.set-content [[[(string.rep " " view-width) hl]]])
                    (Component.set-position {:row 0 :col 0 :z (+ z 1)})
                    (Component.set-size {:height 1 :width view-width})
                    (Component.set-children top-menu-items))]
    (tset menubar :menu menu-structure)
    menubar))

M
