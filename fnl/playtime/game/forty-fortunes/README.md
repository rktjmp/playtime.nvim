Forty Fortunes
===

A new (?) patience game inspired by Fortunes Foundation by Zachtronics.

The name comes from *Forty Theives* and *Fortunes Foundation*, though the deal
is not so much like Forty Theives any more.

Alternative names: *Serpent* (because the cards slither around), *Serpents
Fang* (the cell is the fang?), *Oroborus* (because they slither around and you
build up and down in a circle). *Everest* (because of the mountain of cards
dealt).

I believe a high percentage of deals, if not all, are solvable with good
planning.

<!-- 1703079542 - 372 moves, difficult. -->

Controls
--

Click-drag, or click-click to move.

Layout
--

- 8 foundations
- 13 columns in the tableau
- 1 free cell

Deal
--

- Deal 2 packs of 52 cards into the tableau. Fill the columns left to right,
  top to bottom, but skip column 7.
  - variant: Remove the face cards for an easier game.
- During the deal, any aces are placed in the foundations, they are not placed
  in the tableau.

You should have 6 columns of 8 cards, an empty column, then 6 more columns of 8
cards, and an ace in every foundation.

Play
--

- You may move the bottom card of a cascade.
- Build sequences in same suit, ascending *or* descending rank.
- If the card you are moving is part of a valid sequence, the sequence will be
  moved too, but stacking in the reverse order.
  Eg: Given `[9 8 2 1 2 3] []`, moving `3` to another cascade will result in `[9 8 2] [3 2 1]`
  - default: The cascade *always* moves. You must utilise the empty cell to break sequences.
  - variant: You may elect to move a single card without any attached sequence.

Tips
--

- Having at least one free column to reverse sequences is critical to success,
  but harder deals require temporarily giving it up, for 1 or more moves.
  - Dont forget you may be able to leverage cards in other columns too.
- Remember you can build up and down from a single card, Eg, the `1` in  `[3 2 1 2 3]`.
  - Building "mirrors" is important to create space.
- Some moves are much better than others, try to plan a few steps ahead,
  especially when moving to the free cell or an empty column.
- The auto-move algorithm is pessimistic and wont move a card to a foundation
  unless its provably safe to do so. You may be able to apply your judgement
  and intuition and move a card to the foundation earlier than it would.
- Dont be too hasty to put cards into the foundation,
  Eg: Given `[3 K Q J] [9 10 J]`, you may want to only move the first `J`
  (instead of `J Q K`) to a foundation, then use the `3 K Q` to hold the `J 10 9`
  to free up that column.

Critique
--

- The nature of double suits means "safe auto-moves" rarely play into long
  strings of "free moves" which removes some of the joy of re-ordering a
  sequence and having all the cards move to foundation.
- There is some amount of busy work flipping card orders around.

Variant ideas
--

- Remove all faces but one (eg: Queen of Hearts). The queen must be placed in
  the free cell at the end of the game to win. Once placed in the cell, you may
  not remove it.
  - Gives us 97 cards to deal instead of 96, so the tableau would be uneven.
- Ouroboros: You dont build into foundations, but like spider, must build a full "circle" in the tableau:
  `[1 2 3 .. 9 10 9 .. 3 2 1]`. (Hard!)
- Occupied cell disables foundations
  - Per Fortunes Foundation but probably pushes the game into "often impossible".
