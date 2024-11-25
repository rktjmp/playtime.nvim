(require-macros :playtime.prelude)
(prelude)

(fn get-hl [ns-id name link?]
  ;; The create option defaults to true in 0.10, but I don't think we ever want
  ;; this, so wrap get_hl and always set it to false.
  ;;
  ;; Note the created group is returned as an empty dict, does *not* appear in
  ;; tab-completion for `hi` but does show up in `hi` output list.
  ;;
  ;; Version check for 0.9.5 https://github.com/rktjmp/playtime.nvim/issues/5
  ;; as passing unknown options to the function raises.
  (let [create (if (vim.version.ge (vim.version) [0 10 0]) false)
        opts {:name name :link link? :create create}]
    (vim.api.nvim_get_hl ns-id opts)))

(fn set-hl [ns-id name data]
  (vim.api.nvim_set_hl ns-id name data))

(local M {})

(fn to-hex [c]
  (let [{: tohex} (require :bit)]
    (string.format "#%s" (tohex c 6))))

(fn fetch-fg [hl-name & rest]
  ;; So, some themes (everforest) defines DiagnosticError as having its own
  ;; fg AND links it to ErrorText for underlining, so we...
  (case-try
    ;; get the highlight group data assuming thats the best option
    (get-hl 0 hl-name false) {:fg nil}
    ;; fallback to the link data if present
    (get-hl 0 hl-name true) {:fg nil}
    (case rest
      ;; Some base groups just define changes over Normal
      [next & rest] (fetch-fg next (table.unpack rest))
      ;; return hot-pink on failure because white/black may be seen as "correct"
      [nil] {:fg :#FF00DD})
    (catch
      {: fg} {:fg (to-hex fg)})))

(fn define-hl-if-missing [hl-name hl-data]
  ;; Uh... This historic comment does not make a lot of sense. link=true is
  ;; default. I guess there was some issue with ...hearts and
  ;; ...hearts.four_colors?
  ;;
  ;;    link=true has the behaviour of returning an empty table for @x.y even
  ;;    if @x is defined, otherwise @x.y falls back to @x.
  ;;
  ;; We have the option of defining our highlights in their own namespace but
  ;; this reduces user-discoverability because you can't tab-complete or
  ;; inspect non-global highlights easily.
  ;;
  ;; So instead we define globally and hope our own groups have been cleared by
  ;; something else whenever define-highlights is re-called, for example, after
  ;; a colorscheme change.
  (when (table.empty? (get-hl 0 hl-name true))
    (set-hl 0 hl-name hl-data)))

(fn hl [name data]
  (define-hl-if-missing name data))

(fn link [name to]
  (define-hl-if-missing name {:link to}))

(fn M.define-highlights []
  (hl :PlaytimeHiddenCursor {:blend 100 :reverse true})
  (hl :PlaytimeNormal (fetch-fg :NormalFloat :Normal))
  (hl :PlaytimeMuted (fetch-fg :Comment))
  (hl :PlaytimeWhite (fetch-fg :NormalFloat :Normal))
  (hl :PlaytimeBlack (fetch-fg :Comment))
  (hl :PlaytimeRed (fetch-fg :DiagnosticError))
  (hl :PlaytimeGreen (fetch-fg :DiagnosticOk))
  (hl :PlaytimeYellow {:fg :#fcd34d})
  (hl :PlaytimeOrange (fetch-fg :DiagnosticWarn))
  (hl :PlaytimeBlue (fetch-fg :DiagnosticInfo))
  (hl :PlaytimeMagenta {:fg :#e879f9})
  (hl :PlaytimeCyan {:fg :#22d3ee})
  (link :PlaytimeBackground :NormalFloat)
  (link :PlaytimeMenu :PmenuSBar)

  (link "@playtime.ui.on" :PlaytimeNormal)
  (link "@playtime.ui.off" :PlaytimeMuted)
  (link "@playtime.ui.menu" :PlaytimeMenu)

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
  (link "@playtime.game.card.clubs.four_colors" :PlaytimeGreen)
  (link "@playtime.game.card.spades.four_colors" :PlaytimeBlue)

  (link "@playtime.game.set.selected" :PlaytimeYellow)
  (link "@playtime.game.set.red" :PlaytimeRed)
  (link "@playtime.game.set.green" :PlaytimeGreen)
  (link "@playtime.game.set.blue" :PlaytimeBlue)

  (link "@playtime.game.shenzhen.coins" :PlaytimeYellow)
  (link "@playtime.game.shenzhen.myriads" :PlaytimeCyan)
  (link "@playtime.game.shenzhen.strings" :PlaytimeBlue)
  (link "@playtime.game.shenzhen.flower" :PlaytimeMagenta)
  (link "@playtime.game.shenzhen.dragon.green" :PlaytimeGreen)
  (link "@playtime.game.shenzhen.dragon.red" :PlaytimeRed)
  (link "@playtime.game.shenzhen.dragon.white" :PlaytimeWhite))

M
