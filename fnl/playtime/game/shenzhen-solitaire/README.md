
Spider
==

A unique FreeCell-like, from the game Shenzhen I/O by Zachtronics.

[Buy Shenzhen I/O](https://www.zachtronics.com/shenzhen-io/) or [Zachtronics Solitaire Collection](https://www.zachtronics.com/solitaire-collection/)

Controls
--

Click-drag, or click-click to move.

How to play
--

There are 40 cards,

- 3x9 "suited" cards, `Coin`, `String` and `Myriad`.
- 3x4 "dragon" cards, ~~`Trogdor Š`~~ `Red Š`, `Green Ñ` and `White Õ`.
- 1 "flower" card, `ƒ`.

Shenzhen Solitaire is similar to FreeCell, with a majhong deck instead. The
goal is to place all suited cards in the top right foundations and all dragon
cards in the top left cells.

The top row has 3 cells that may hold one card at a time, of any kind.

The next 4 slots are foundations which must build sequences from 1 to 9 in the
same suit, except the first slot may only hold the `ƒ` card.

The tableau operates under normal solitaire rules, you may only place cards in
descending, alternating suit sequences except when the column is empty. Empty
columns accept any card.

Note that by these rules, you can not build off or use dragons cards in a
sequence!

When 4 dragon cards of the same type (`Š`, `Ñ` or `Õ`) are accessible (either
in the tableau or cells), you may activate the appropriate button to shift all
cards of that type to an unoccupied cell. Once this is done that cell is locked.
