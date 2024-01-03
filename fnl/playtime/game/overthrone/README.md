Overthrone
==

**Original design by [Mark
Tuck](https://boardgamegeek.com/boardgamedesigner/90925/mark-tuck)**.

Controls
--

Click-drag, or click-click to move.

How to play
--

See [BGG:
Overthrone](https://boardgamegeek.com/boardgame/206059/overthrone-game-cards)
for more details and thematic ruleset.

The throne is centered in the field.

You are dealt a hand of 5 cards (Note: This implementation currently only
supports the harder 5 card variant.). You may play cards into the tableau or
into the discard pile to the right.

You may play any card from an unplayed suit to an empty foundation (north,
south, east and west of the throne).

The current ruler on the throne dictates the rules for playing cards to
populated foundations.

You may *always* play an Ace onto the suits foundation, regardless of who the
current ruler is.

When the ruler is a...

- Jack
  - you may play a card of any rank, of the rulers suit, into the rulers suits
  foundation.

- Queen
  - you may play a card of any rank, of the rulers suit, into the rulers suits
  foundation.
  - you may play a card which rank matches any top card of any foundation, into
  that cards suit foundation.

- King
  - you may play a card of any rank, of the rulers suit, into the rulers suits
  foundation.
  - you may play a card which rank matches any top card of any foundation, into
  that cards suit foundation.
  - you may play a card on to another card, if the rank difference is +1 or -1,
  into the suits foundation. Aces low.

A ruler may overthrow another when,

|New Ruler|Current Ruler|Condition|
|--|--|--|
|Same Suit, higher rank|Same suit, lower rank|Unconditional|
|King|King|Unconditional|
|King|Queen|Unconditional|
|King|Jack|Unconditional|
|Queen|King|New ruler foundation outranks the current rulers foundation, Aces high|
|Queen|Queen|Unconditional|
|Queen|Jack|Unconditional|
|Jack|King|New ruler foundation is an Ace|
|Jack|Queen|New ruler foundation outranks the current rulers foundation, Aces high|
|Jack|Jack|Unconditional|

The Jester may be played onto any foundation. When in play, cards may be drawn
from the discard pile and played as per the above rules.

Scoring
--

The aim is to have the least amount of cards in hand and in the discard pile
after exhausting the draw pile.

- 0: Perfect
- 1-3: Good
- 4-7: Not so good
- 8+: Uh oh.

Other
--

Built using version 4 of the BGG rule set.
