(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Component (require :playtime.component))
(local Card (require :playtime.component.card))

(local M {})

(set M.slot Card.slot)
(set M.base-card Card.base-card)

(λ M.card [options]
  (Card.card (table.merge {:color-count 2} options)))

(λ M.card-4-colors [options]
  (Card.card (table.merge {:color-count 4} options)))

(λ M.card-2-colors [options]
  (Card.card (table.merge {:color-count 2} options)))

M
