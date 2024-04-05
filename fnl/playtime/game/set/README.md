SET
==

A logic puzzle game designed by Marsha Falco in 1974. Physical copies of SET
can be purchased from [Play Monster](https://www.playmonster.com/product/set/).

The Playtime implementation of SET is single player without any AI opponent and
is intended as a more medatative experience, compared to the proper physical
card game where players race for points.


Controls
--

Click cards to select or deselect them, select 3 cards to confirm a set.

Click the draw deck to deal an additional 3 cards if you are unable to find a
set. Playtime will automatically draw additional cards if there is no set in
the currently dealt cards.

The menu contains a hint option, which will tell you the number of sets in the
current deal and a hint on the attributes of a randomly chosen set.

How to play
--

Each card has 4 attributes, *color*, *shape*, *style* and *count*.

Select 3 cards (a set), where for each attribute, cards have all the same value
*or* all different values. Each attribute is exclusive.

For example, 3 cards where each attribute is:

- red, red, red
- square, triangle, circle
- outline, outline, outline
- 2, 3, 1

is a set. Each color is the *same*, each shape is *different*, each style is
the *same* and each card has *different* numbers of symbols.

Alternatively

- red, red, red
- square, triangle, circle
- outline, outline, outline
- 2, 2, 1

is *not* a set because the count attribute is not all the same, or all different.

See also [Wikipedia](https://en.wikipedia.org/wiki/Set_(card_game))
