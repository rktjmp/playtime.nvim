
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}



 local inc_moves = CardGameUtils["inc-moves"]
 local apply_events = CardGameUtils["apply-events"]
 M["iter-cards"] = CardGameUtils["make-iter-cards-fn"]({"draw", "tableau", "complete"})
 local _local_2_ = CardGameUtils["make-card-util-fns"]({value = {king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_2_["card-value"] local card_color = _local_2_["card-color"] local card_rank = _local_2_["card-rank"]
 local card_suit = _local_2_["card-suit"] local rank_value = _local_2_["rank-value"] local suit_color = _local_2_["suit-color"]
 local card_face_up_3f = _local_2_["card-face-up?"] local card_face_down_3f = _local_2_["card-face-down?"]




 local function new_game_state()


 return {draw = {{}, {}, {}, {}, {}, {}}, tableau = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}}, complete = {{}, {}, {}, {}, {}, {}, {}, {}}, moves = 0, suits = nil} end






 local function build_deck(suit_count, suits) _G.assert((nil ~= suits), "Missing argument suits on fnl/playtime/game/spider/logic.fnl:33") _G.assert((nil ~= suit_count), "Missing argument suit-count on fnl/playtime/game/spider/logic.fnl:33")
 local n_decks = (8 / suit_count) local full_deck
 local function _3_() local tbl_21_auto = {} local i_22_auto = 0 for i = 1, n_decks do local val_23_auto = Deck.Standard52.build() if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end full_deck = table.join(table.unpack(_3_()))


 local function _5_() local tbl_21_auto = {} local i_22_auto = 0 for _, c in ipairs(full_deck) do local val_23_auto
 if eq_any_3f(card_suit(c), suits) then val_23_auto = c else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end return table.shuffle(_5_()) end


 M.build = function(config, _3fseed) _G.assert((nil ~= config), "Missing argument config on fnl/playtime/game/spider/logic.fnl:42")
 if ((_G.type(config) == "table") and (nil ~= config.suits)) then local suits = config.suits else local __2_auto = config error("config must match {:suits suits}") end
 math.randomseed((_3fseed or os.time()))
 local deck do local _9_ = config.suits if (_9_ == 4) then
 deck = build_deck(4, {"spades", "hearts", "clubs", "diamonds"}) elseif (_9_ == 2) then
 deck = build_deck(2, {"spades", "hearts"}) elseif (_9_ == 1) then
 deck = build_deck(1, {"spades"}) else local _ = _9_
 deck = error(Error("Unsupported suit count #{n}", {n = config.suits})) end end
 local state = new_game_state() local draws

 do local draws0, deck0 = {}, deck for _, at in ipairs({((5 * 10) + 5), 11, 11, 11, 11, 11}) do

 local take, keep = table.split(deck0, at)
 draws0, deck0 = table.insert(draws0, take), keep end draws = draws0, deck0 end
 state["draw"] = draws
 state["suits"] = config.suits
 return state end

 local valid_build_sequence_3f

 local function _12_(next_card, _11_) local last_card = _11_[1]
 local last_value = card_value(last_card)
 local next_value = card_value(next_card)
 return (card_face_up_3f(last_card) and card_face_up_3f(next_card) and (last_value == (next_value + 1))) end valid_build_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_12_)



 local valid_move_sequence_3f

 local function _14_(next_card, _13_) local last_card = _13_[1]
 local last_suit = card_suit(last_card)
 local last_value = card_value(last_card)
 local next_suit = card_suit(next_card)
 local next_value = card_value(next_card)
 return (card_face_up_3f(last_card) and card_face_up_3f(next_card) and (last_suit == next_suit) and (last_value == (next_value + 1))) end valid_move_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_14_)




 local function complete_sequence_3f(sequence)
 if ((_G.type(sequence) == "table") and (nil ~= sequence[1])) then local top_card = sequence[1] local _rest = {select(2, (table.unpack or _G.unpack)(sequence))}
 return ((13 == #sequence) and (rank_value("king") == card_value(top_card)) and valid_move_sequence_3f(sequence)) else local _ = sequence return false end end




 M.Action.deal = function(state)
 local moves do local moves0, t_col, row = {}, 1, 1 for i = #state.draw[1], 1, -1 do

 local from = {"draw", 1, i}
 local to = {"tableau", t_col, row}
 local move = {"move", from, to} local _3fflip
 if (((t_col <= 4) and (row == 6)) or ((5 <= t_col) and (row == 5))) then

 _3fflip = {"face-up", from} else _3fflip = nil end


 local _17_ if (t_col == 10) then _17_ = 1 else _17_ = (t_col + 1) end
 local function _19_() if (t_col == 10) then return (row + 1) else return row end end moves0, t_col, row = table.insert(table.insert(moves0, _3fflip), move), _17_, _19_() end moves = moves0, t_col, row end
 local next_state, moves0 = apply_events(clone(state), moves)
 return next_state, moves0 end

 M.Action.draw = function(state)
 local draw_index do local d = nil for i, draw in ipairs(state.draw) do if d then break end
 if not table["empty?"](draw) then d = i else d = nil end end draw_index = d end local any_empty_columns_3f
 do local yes_3f = false for _, col in ipairs(state.tableau) do if yes_3f then break end
 yes_3f = table["empty?"](col) end any_empty_columns_3f = yes_3f end local num_cards_in_tableu
 do local sum = 0 for _, col in ipairs(state.tableau) do
 sum = (sum + #col) end num_cards_in_tableu = sum end


 if (any_empty_columns_3f and (#state.tableau < num_cards_in_tableu)) then
 return nil, Error("Cannot draw with empty columns") else
 if draw_index then
 local moves do local t = {} for i, card in ipairs(state.draw[draw_index]) do

 local from = {"draw", draw_index, i}
 local to = {"tableau", i, (1 + #state.tableau[i])}
 t = table.insert(table.insert(t, {"face-up", from}), {"move", from, to}) end moves = t end

 local next_state, moves0 = apply_events(clone(state), moves)
 return next_state, moves0 else
 return nil, Error("No more draws") end end end

 local function check_pick_up(state, pick_up_from)
 if ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "tableau") and (nil ~= pick_up_from[2]) and (nil ~= pick_up_from[3])) then local col_n = pick_up_from[2] local card_n = pick_up_from[3]

 local remaining, held = table.split(state.tableau[col_n], card_n)
 if valid_move_sequence_3f(held) then
 return held else
 if ((_G.type(held) == "table") and (held[1] == nil)) then
 return nil, Error("No cards to pick up from tableau column #{col-n}", {["col-n"] = col_n}) else local _ = held
 return nil, Error("Must pick up run of same suit, descending rank") end end elseif ((_G.type(pick_up_from) == "table") and (nil ~= pick_up_from[1])) then local field = pick_up_from[1]


 return nil, Error("May not pick up from #{field}", {field = field}) else return nil end end

 local function put_down(state, pick_up_from, dropped_on, held)
 local _26_, _27_, _28_ = pick_up_from, dropped_on, held local and_29_ = (((_G.type(_26_) == "table") and (nil ~= _26_[1]) and (nil ~= _26_[2]) and (nil ~= _26_[3])) and ((_G.type(_27_) == "table") and (_26_[1] == _27_[1]) and (_26_[2] == _27_[2]) and (nil ~= _27_[3])) and true) if and_29_ then local field = _26_[1] local col = _26_[2] local from_n = _26_[3] local on_n = _27_[3] local _ = _28_ and_29_ = (from_n == (1 + on_n)) end if and_29_ then local field = _26_[1] local col = _26_[2] local from_n = _26_[3] local on_n = _27_[3] local _ = _28_


 return nil else local and_31_ = (true and ((_G.type(_27_) == "table") and (nil ~= _27_[1]) and (nil ~= _27_[2]) and (nil ~= _27_[3])) and true) if and_31_ then local _ = _26_ local field = _27_[1] local col_n = _27_[2] local card_n = _27_[3] local _0 = _28_ and_31_ = not (card_n == #state[field][col_n]) end if and_31_ then local _ = _26_ local field = _27_[1] local col_n = _27_[2] local card_n = _27_[3] local _0 = _28_



 return nil, Error("Must place cards on the bottom of a cascade") else local and_33_ = (((_G.type(_26_) == "table") and (_26_[1] == "tableau") and (nil ~= _26_[2]) and (_26_[3] == 1)) and ((_G.type(_27_) == "table") and (_27_[1] == "tableau") and (nil ~= _27_[2]) and (_27_[3] == 0)) and true) if and_33_ then local a = _26_[2] local b = _27_[2] local _ = _28_ and_33_ = not (a == b) end if and_33_ then local a = _26_[2] local b = _27_[2] local _ = _28_




 local from_col = state.tableau[a] local moves
 do local tbl_21_auto = {} local i_22_auto = 0 for i, _card in ipairs(from_col) do
 local val_23_auto = {"move", {"tableau", a, i}, {"tableau", b, i}} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end moves = tbl_21_auto end
 return apply_events(clone(state), moves, {["unsafely?"] = true}) elseif (((_G.type(_26_) == "table") and (_26_[1] == "tableau") and (nil ~= _26_[2]) and (nil ~= _26_[3])) and ((_G.type(_27_) == "table") and (_27_[1] == "tableau") and (nil ~= _27_[2]) and (nil ~= _27_[3])) and (nil ~= _28_)) then local f_col = _26_[2] local f_card_n = _26_[3] local t_col = _27_[2] local t_card_n = _27_[3] local held0 = _28_



 local moves do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, #held0 do
 local val_23_auto = {"move", {"tableau", f_col, (f_card_n + (i - 1))}, {"tableau", t_col, (t_card_n + i)}} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end moves = tbl_21_auto end


 local one_up = {"tableau", f_col, (f_card_n - 1)} local _
 do local _37_ = table["get-in"](state, one_up) if ((_G.type(_37_) == "table") and (_37_.face == "down")) then
 _ = table.insert(moves, {"face-up", one_up}) else _ = nil end end
 local next_state = apply_events(inc_moves(clone(state)), moves)


 local _0, new_run = table.split(next_state.tableau[t_col], t_card_n)
 if valid_build_sequence_3f(new_run) then
 return next_state, moves else
 return nil, Error("Must build piles in descending rank") end else local _ = _26_


 return nil, Error("No putdown for #{field}", {field = dropped_on}) end end end end

 M.Action.move = function(state, pick_up_from, put_down_on)
 local function _41_(...) local _42_ = ... if (nil ~= _42_) then local held = _42_ local function _43_(...) local _44_, _45_ = ... if ((nil ~= _44_) and (nil ~= _45_)) then local next_state = _44_ local moves = _45_


 return next_state, moves else local __87_auto = _44_ return ... end end return _43_(put_down(state, pick_up_from, put_down_on, held)) else local __87_auto = _42_ return ... end end return _41_(check_pick_up(state, pick_up_from)) end

 M.Action["remove-complete-sequence"] = function(state, sequence_starts_at)
 local function _48_(...) local _49_, _50_ = ... if (nil ~= _49_) then local held = _49_ local function _51_(...) local _52_, _53_ = ... if (_52_ == 13) then local function _54_(...) local _55_, _56_ = ... if (_55_ == true) then



 local complete_n do local index = nil for i, c in ipairs(state.complete) do if index then break end
 if (0 == #c) then index = i else index = nil end end complete_n = index end
 local f_field = sequence_starts_at[1] local f_col = sequence_starts_at[2] local f_card_n = sequence_starts_at[3] local moves
 do local tbl_21_auto = {} local i_22_auto = 0 for i = (f_card_n + 12), f_card_n, -1 do
 local val_23_auto = {"move", {f_field, f_col, i}, {"complete", complete_n, ((f_card_n + 12) - (i - 1))}} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end moves = tbl_21_auto end


 local one_up = {"tableau", f_col, (f_card_n - 1)} local _
 do local _59_ = table["get-in"](state, one_up) if ((_G.type(_59_) == "table") and (_59_.face == "down")) then
 _ = table.insert(moves, {"face-up", one_up}) else _ = nil end end
 local next_state, moves0 = apply_events(clone(state), moves)
 return next_state, moves0 elseif ((_55_ == nil) and (nil ~= _56_)) then local err = _56_ else return nil end end return _54_(complete_sequence_3f(held)) elseif ((_52_ == nil) and (nil ~= _53_)) then local err = _53_ else return nil end end return _51_(#held) elseif ((_49_ == nil) and (nil ~= _50_)) then local err = _50_ else return nil end end return _48_(check_pick_up(state, sequence_starts_at)) end





 M.Plan["next-complete-sequence"] = function(state)
 local from do local start_at = nil for col_n, col in ipairs(state.tableau) do if start_at then break end





 local index = math.max(1, (#col - 12))
 local _, run = table.split(col, index)
 if complete_sequence_3f(run) then


 start_at = {"tableau", col_n, index} else start_at = nil end end from = start_at end
 return from end

 M.Query["liftable?"] = function(state, location)
 return not (nil == check_pick_up(state, location)) end

 M.Query["droppable?"] = function(state, location)
 if ((_G.type(location) == "table") and (nil ~= location[1])) then local field = location[1]
 return eq_any_3f(field, {"tableau"}) else local _ = location return false end end


 M.Query["game-ended?"] = function(state) local won_3f = true
 for _, stack in ipairs(state.complete) do
 won_3f = (won_3f and (13 == #stack)) end return won_3f end

 M.Query["game-result"] = function(state)
 return M.Query["game-ended?"](state) end

 return M