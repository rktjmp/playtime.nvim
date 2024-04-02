(require-macros :playtime.prelude)
(prelude)

(local Id (require :playtime.common.id))
(local Deck (require :playtime.common.card.deck))
(local M (setmetatable {:Set {}} {:__index Deck}))

(fn M.Set.build []
  (let [colors [:red :green :blue]
        counts [1 2 3]
        styles [:solid :split :outline]
        shapes [:square :circle :triangle]
        cards []]
    (each [_color-index color (ipairs colors)]
      (each [_style-index style (ipairs styles)]
        (each [_count-index count (ipairs counts)]
          (each [_shape-index shape (ipairs shapes)]
            (let [card {:id (Id.new)
                        : color
                        : style
                        : count
                        : shape
                        :face :down}]
             (table.insert cards card))))))
    cards))

M
