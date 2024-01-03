FreeCell
==

An open information patience game invented by Paul Alfille, made popular by
Microsoft Windows. Most FreeCell deals are solvable.

Controls
--

Click-drag, or click-click to move.

How to play
--

See [Wikipedia](https://en.wikipedia.org/wiki/FreeCell).

- Build descending rank, alternating color sequences.
- You may move single cards to any of the top 4 free cells.
- You may move *one* card at a time between tableau columns.
  - The Playtime implementation (and nearly all other digital implementations)
    gives the illusory impression of moving more than one card at a time, but
    internally a sequence of single-card moves are planned and executed.
  - This means: You move N cards in one command, *if* you have the required
    free space to move N cards.

Variants
--

**Baker's Game**

A historic patience game invented by C.L. Baker.

How to play
--

Build sequences in descending, same-suit instead of alternating color.

See [Wikipedia](https://en.wikipedia.org/wiki/Baker%27s_Game).
