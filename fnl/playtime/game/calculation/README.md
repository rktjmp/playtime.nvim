Calculation
==

A strategic patience game that relies on careful planning.

Controls
--

Click-drag, or click-click to move.

How to play
--

This implementation follows the game as described on
[Wikipedia](https://en.wikipedia.org/wiki/Calculation_(solitaire)), where suits
are not considered.

- Build four foundations Ace to King, regardless of suit, following the progression as described:
  - A, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K (by 1s)
  - 2, 4, 6, 8, 10, Q, A, 3, 5, 7, 9, J, K (by 2s)
  - 3, 6, 9, Q, 2, 5, 8, J, A, 4, 7, 10, K (by 3s)
  - 4, 8, Q, 3, 7, J, 2, 6, 10, A, 5, 9, K (by 4s)

- Draw cards one by one. If a card cannot immediately go to a foundation, it
  *must* be placed onto one of the four tableau columns.
- There are four tableau piles, Any card from the stock can be placed into the
  tableau, regardless of its value or value. Only the most recent card of each
  tableau columns is available for play to the foundations. Once a card is
  placed in a tableau column, it cannot be moved to another tableau column.
