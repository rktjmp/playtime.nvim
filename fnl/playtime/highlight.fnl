(require-macros :playtime.prelude)
(prelude)

(local {:api {: nvim_set_hl : nvim_get_hl}} vim)

(local M {})

(fn to-hex [c]
  (let [{: tohex} (require :bit)]
    (string.format "#%s" (tohex c 6))))

(fn M.define-highlights []
  (fn fetch-fg [hl-name & rest]
    ;; So, some themes (everforest) defines DiagnosticError as having its own
    ;; fg AND links it to ErrorText for underlining, so we...
    (case-try
      ;; get the highlight group data assuming thats the best option
      (nvim_get_hl 0 {:name hl-name :link false}) {:fg nil}
      ;; fallback to the link data if present
      (nvim_get_hl 0 {:name hl-name :link true}) {:fg nil}
      (case rest
        ;; Some base groups just define changes over Normal
        [next & rest] (fetch-fg next (table.unpack rest))
        ;; return a default hot-pink because white/black may be seen as "correct"
        [nil] {:fg :#FF00DD})
      (catch
        {: fg} {:fg (to-hex fg)})))
  (fn define-hl-if-missing [ns hl-name hl-data]
    ;; Dont clobber existing highlights.
    ;; link=true has the behaviour of returning an empty table for @x.y even if
    ;; @x is defined, otherwise @x.y falls back to @x.
    (when (table.empty? (nvim_get_hl 0 {:name hl-name :link true}))
      (nvim_set_hl ns hl-name hl-data)))
  (fn hl [name data] (define-hl-if-missing 0 name data))
  (fn link [name to] (define-hl-if-missing 0 name {:link to}))

  (let [core-hls [[:PlaytimeHiddenCursor {:blend 100 :reverse true}]
                  [:PlaytimeNormal (fetch-fg :NormalFloat :Normal)]
                  [:PlaytimeMuted (fetch-fg :Comment)]
                  [:PlaytimeWhite (fetch-fg :NormalFloat :Normal)]
                  [:PlaytimeBlack (fetch-fg :Comment)]
                  [:PlaytimeRed (fetch-fg :DiagnosticError)]
                  [:PlaytimeGreen (fetch-fg :DiagnosticOk)]
                  [:PlaytimeYellow {:fg :#fcd34d}]
                  [:PlaytimeOrange (fetch-fg :DiagnosticWarn)]
                  [:PlaytimeBlue (fetch-fg :DiagnosticInfo)]
                  [:PlaytimeMagenta {:fg :#e879f9}]
                  [:PlaytimeCyan {:fg :#22d3ee}]]]

    (each [_ [name data] (ipairs core-hls)] (hl name data))

    (link "@playtime.ui.on" :PlaytimeNormal)
    (link "@playtime.ui.off" :PlaytimeMuted)
    (link "@playtime.ui.menu" :PmenuSBar)

    (link "@playtime.color.white" :PlaytimeWhite)
    (link "@playtime.color.red" :PlaytimeRed)
    (link "@playtime.color.green" :PlaytimeGreen)
    (link "@playtime.color.yellow" :PlaytimeYellow)
    (link "@playtime.color.orange" :PlaytimeOrange)
    (link "@playtime.color.blue" :PlaytimeBlue)
    (link "@playtime.color.magenta" :PlaytimeMagenta)
    (link "@playtime.color.cyan" :PlaytimeCyan)
    (link "@playtime.color.black" :PlaytimeBlack)

    (link "@playtime.game.card.empty" :PlaytimeMuted)
    (link "@playtime.game.card.back" :PlaytimeMuted)

    (link "@playtime.game.card.hearts" :PlaytimeRed)
    (link "@playtime.game.card.diamonds" :PlaytimeRed)
    (link "@playtime.game.card.clubs" :PlaytimeBlue)
    (link "@playtime.game.card.spades" :PlaytimeBlue)

    (link "@playtime.game.card.hearts.four_colors" :PlaytimeRed)
    (link "@playtime.game.card.diamonds.four_colors" :PlaytimeYellow)
    ;(link "@playtime.game.card.diamonds.four_colors" :PlaytimeRedBright)
    (link "@playtime.game.card.clubs.four_colors" :PlaytimeGreen)
    (link "@playtime.game.card.spades.four_colors" :PlaytimeBlue)
    ;(link "@playtime.game.card.spades.four_colors" :PlaytimeBlueBright)


    (link "@playtime.game.set.selected" :PlaytimeYellow)
    (link "@playtime.game.set.red" :PlaytimeRed)
    (link "@playtime.game.set.green" :PlaytimeGreen)
    (link "@playtime.game.set.blue" :PlaytimeBlue)

    (link "@playtime.game.for_northwood.flowers" :PlaytimeMagenta)
    (link "@playtime.game.for_northwood.claws" :PlaytimeCyan)
    (link "@playtime.game.for_northwood.leaves" :PlaytimeYellow)
    (link "@playtime.game.for_northwood.eyes" :PlaytimeBlue)

    (link "@playtime.game.shenzhen.coins" :PlaytimeYellow)
    (link "@playtime.game.shenzhen.myriads" :PlaytimeCyan)
    (link "@playtime.game.shenzhen.strings" :PlaytimeBlue)
    (link "@playtime.game.shenzhen.flower" :PlaytimeMagenta)
    (link "@playtime.game.shenzhen.dragon.green" :PlaytimeGreen)
    (link "@playtime.game.shenzhen.dragon.red" :PlaytimeRed)
    (link "@playtime.game.shenzhen.dragon.white" :PlaytimeWhite)

    ; (hl "@playtime.game.sweeper.block" {})
    ; (hl "@playtime.game.sweeper.mine" {})
    ; (hl "@playtime.game.sweeper.flag" {})
    ; (hl "@playtime.game.sweeper.maybe" {})
    ; (hl "@playtime.game.sweeper.count" {})
    ; (hl "@playtime.game.sweeper.count.1" {})
    ; (hl "@playtime.game.sweeper.count.2" {})
    ; (hl "@playtime.game.sweeper.count.3" {})
    ; (hl "@playtime.game.sweeper.count.4" {})
    ; (hl "@playtime.game.sweeper.count.5" {})
    ; (hl "@playtime.game.sweeper.count.6" {})
    ; (hl "@playtime.game.sweeper.count.7" {})
    ; (hl "@playtime.game.sweeper.count.8" {})
    ))

M
