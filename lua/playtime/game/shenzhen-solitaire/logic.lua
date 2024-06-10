
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local Deck = require("playtime.game.shenzhen-solitaire.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local _local_2_ = CardGameUtils local location_contents = _local_2_["location-contents"] local inc_moves = _local_2_["inc-moves"] local apply_events = _local_2_["apply-events"]

 local M = {Action = {}, Plan = {}, Query = {}}



 M["iter-cards"] = CardGameUtils["make-iter-cards-fn"]({"cell", "flower", "foundation", "tableau"})
 local _local_3_ = CardGameUtils["make-card-util-fns"]({value = {}, color = {}}) local card_value = _local_3_["card-value"] local card_rank = _local_3_["card-rank"] local card_suit = _local_3_["card-suit"] local rank_value = _local_3_["rank-value"] local suit_color = _local_3_["suit-color"] local flip_face_up = _local_3_["flip-face-up"]


 local function new_game_state()
 return {foundation = {{}, {}, {}}, flower = {{}}, tableau = {{}, {}, {}, {}, {}, {}, {}, {}}, cell = {{}, {}, {}}, moves = 0, locked = {green = false, red = false, white = false}} end






 M.build = function(_config, _3fseed) _G.assert((nil ~= _config), "Missing argument _config on fnl/playtime/game/shenzhen-solitaire/logic.fnl:27")
 math.randomseed((_3fseed or os.time()))
 local tableau_cards = Deck.shuffle(Deck.Shenzhen.build())

 local state = new_game_state()
 for _, c in ipairs(tableau_cards) do flip_face_up(c) end
 state.flower[1] = tableau_cards
 return state end

 local valid_tableau_sequence_3f

 local function _6_(next_card, _4_) local _arg_5_ = _4_ local last_card = _arg_5_[1]

 local last_suit = card_suit(last_card)
 local last_value = card_value(last_card)
 local next_suit = card_suit(next_card)
 local next_value = card_value(next_card)
 return (not eq_any_3f(next_suit, {"flower", "green", "red", "white"}) and not (last_suit == next_suit) and (last_value == (next_value + 1))) end valid_tableau_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_6_)



 local winning_foundation_sequence_3f
 do
 local valid_sequence_3f

 local function _9_(next_card, _7_) local _arg_8_ = _7_ local last_card = _arg_8_[1]
 return ((card_suit(next_card) == card_suit(last_card)) and (card_value(next_card) == (1 + card_value(last_card)))) end valid_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_9_)

 local function _10_(sequence)
 return ((9 == #sequence) and valid_sequence_3f(sequence)) end winning_foundation_sequence_3f = _10_ end


 local winning_flower_sequence_3f
 local function _11_(sequence)
 if ((_G.type(sequence) == "table") and ((_G.type(sequence[1]) == "table") and (sequence[1][1] == "flower")) and (sequence[2] == nil)) then return true else local _ = sequence return false end end winning_flower_sequence_3f = _11_



 local winning_dragon_sequence_3f
 do
 local valid_sequence_3f

 local function _15_(next_card, _13_) local _arg_14_ = _13_ local last_card = _arg_14_[1]
 return (eq_any_3f(card_suit(next_card), {"red", "green", "white"}) and (card_suit(next_card) == card_suit(last_card))) end valid_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_15_)

 local function _16_(sequence)
 return ((4 == #sequence) and valid_sequence_3f(sequence)) end winning_dragon_sequence_3f = _16_ end



 M.Action.deal = function(state)

 local moves do local moves0, t_col, row = {}, 1, 1 for i = #state.flower[1], 1, -1 do

 local from = {"flower", 1, i}
 local to = {"tableau", t_col, row}

 local _17_ if (t_col == 8) then _17_ = 1 else _17_ = (t_col + 1) end
 local function _19_() if (t_col == 8) then return (row + 1) else return row end end moves0, t_col, row = table.insert(moves0, {"move", from, to}), _17_, _19_() end moves = moves0, t_col, row end
 local next_state, moves0 = apply_events(clone(state), moves)
 return next_state, moves0 end

 local function check_pick_up(state, pick_up_from)
 if ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "tableau") and (nil ~= pick_up_from[2]) and (nil ~= pick_up_from[3])) then local col_n = pick_up_from[2] local card_n = pick_up_from[3]

 local remaining, held = table.split(state.tableau[col_n], card_n)
 if valid_tableau_sequence_3f(held) then
 return held else
 if ((_G.type(held) == "table") and (held[1] == nil)) then
 return nil, Error("No cards to pick up from tableau column #{col-n}", {["col-n"] = col_n}) else local _ = held
 return nil, Error("Must pick up single dragon or flower or run of alternating suit, descending rank") end end elseif ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "cell") and (nil ~= pick_up_from[2]) and (pick_up_from[3] == 1)) then local col_n = pick_up_from[2]


 local remaining, held = table.split(state.cell[col_n], 1)
 local _22_ = #held if (_22_ == 1) then
 return held elseif (_22_ == 0) then
 return nil, Error("No card to pick up from free cell") elseif (nil ~= _22_) then local n = _22_
 return nil, Error("May only pick up one card at a time from free cell") else return nil end elseif ((_G.type(pick_up_from) == "table") and (nil ~= pick_up_from[1])) then local field = pick_up_from[1]

 return nil, Error("May not pick up from #{field}", {field = field}) else return nil end end

 local function put_down(state, pick_up_from, dropped_on, held)
 local _25_, _26_, _27_ = pick_up_from, dropped_on, held local function _30_() local field = _25_[1] local col = _25_[2] local from_n = _25_[3] local on_n = _26_[3] local _ = _27_ return (from_n == (1 + on_n)) end if ((((_G.type(_25_) == "table") and (nil ~= _25_[1]) and (nil ~= _25_[2]) and (nil ~= _25_[3])) and ((_G.type(_26_) == "table") and (_25_[1] == _26_[1]) and (_25_[2] == _26_[2]) and (nil ~= _26_[3])) and true) and _30_()) then local field = _25_[1] local col = _25_[2] local from_n = _25_[3] local on_n = _26_[3] local _ = _27_


 return nil else local function _31_() local _ = _25_ local field = _26_[1] local col_n = _26_[2] local card_n = _26_[3] local _0 = _27_ return not (card_n == #state[field][col_n]) end if ((true and ((_G.type(_26_) == "table") and (nil ~= _26_[1]) and (nil ~= _26_[2]) and (nil ~= _26_[3])) and true) and _31_()) then local _ = _25_ local field = _26_[1] local col_n = _26_[2] local card_n = _26_[3] local _0 = _27_



 return nil, Error("Must place cards on the bottom of a cascade") elseif (true and ((_G.type(_26_) == "table") and (_26_[1] == "flower") and (_26_[2] == 1) and (_26_[3] == 0)) and ((_G.type(_27_) == "table") and ((_G.type(_27_[1]) == "table") and (_27_[1][1] == "flower")) and (_27_[2] == nil))) then local _ = _25_



 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"flower", 1, 1}}}) else local matched_3f_28_, __29_ = nil, nil if (true and ((_G.type(_26_) == "table") and (_26_[1] == "flower") and (_26_[2] == 1) and (_26_[3] == 0)) and true) then local _ = _25_ local _0 = _27_ matched_3f_28_, __29_ = true, _0 elseif (true and true and ((_G.type(_27_) == "table") and ((_G.type(_27_[1]) == "table") and (_27_[1][1] == "flower")))) then local _ = _25_ local _0 = _26_ matched_3f_28_, __29_ = true, _0 else matched_3f_28_, __29_ = nil end if matched_3f_28_ then local _ = __29_




 return nil, Error("May only place flower cards in flower foundation") elseif (true and ((_G.type(_26_) == "table") and (_26_[1] == "foundation")) and ((_G.type(_27_) == "table") and (nil ~= _27_[1]) and (nil ~= _27_[2]))) then local _ = _25_ local multiple = _27_[1] local cards = _27_[2]




 return nil, Error("May only place cards on a foundation one at a time") elseif (true and ((_G.type(_26_) == "table") and (_26_[1] == "foundation") and (nil ~= _26_[2]) and (_26_[3] == 0)) and ((_G.type(_27_) == "table") and (nil ~= _27_[1]) and (_27_[2] == nil))) then local _ = _25_ local f_col_n = _26_[2] local card = _27_[1]



 if ((_G.type(card) == "table") and true and (card[2] == 1)) then local _suit = card[1]
 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col_n, 1}}}) else local _0 = card


 return nil, Error("Must build foundations same suit, 1, 2, ... 9") end elseif (true and ((_G.type(_26_) == "table") and (_26_[1] == "foundation") and (nil ~= _26_[2]) and (nil ~= _26_[3])) and ((_G.type(_27_) == "table") and (nil ~= _27_[1]) and (_27_[2] == nil))) then local _ = _25_ local f_col_n = _26_[2] local f_card_n = _26_[3] local new_card = _27_[1]



 local onto_card = location_contents(state, dropped_on)
 local _34_, _35_ = onto_card, new_card local function _36_() local suit = _34_[1] return (-1 == (card_value(onto_card) - card_value(new_card))) end if ((((_G.type(_34_) == "table") and (nil ~= _34_[1])) and ((_G.type(_35_) == "table") and (_34_[1] == _35_[1]))) and _36_()) then local suit = _34_[1]

 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col_n, (f_card_n + 1)}}}) else local _0 = _34_


 return nil, Error("Must build foundations in same-suit, ascending order") end elseif (true and ((_G.type(_26_) == "table") and (_26_[1] == "cell")) and ((_G.type(_27_) == "table") and (nil ~= _27_[1]) and (nil ~= _27_[2]))) then local _ = _25_ local multiple = _27_[1] local cards = _27_[2]


 return nil, Error("May only place single cards on a cell") else local function _38_() local _ = _25_ local col_n = _26_[2] local card_n = _26_[3] local _0 = _27_ return not (0 == card_n) end if ((true and ((_G.type(_26_) == "table") and (_26_[1] == "cell") and (nil ~= _26_[2]) and (nil ~= _26_[3])) and true) and _38_()) then local _ = _25_ local col_n = _26_[2] local card_n = _26_[3] local _0 = _27_

 return nil, Error("May only place single cards on a cell") elseif (true and ((_G.type(_26_) == "table") and (_26_[1] == "cell") and (nil ~= _26_[2]) and (_26_[3] == 0)) and ((_G.type(_27_) == "table") and (nil ~= _27_[1]) and (_27_[2] == nil))) then local _ = _25_ local col_n = _26_[2] local new_card = _27_[1]



 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"cell", col_n, 1}}}) else local function _39_() local a = _25_[2] local b = _26_[2] local _ = _27_ return not (a == b) end if ((((_G.type(_25_) == "table") and (_25_[1] == "tableau") and (nil ~= _25_[2]) and (_25_[3] == 1)) and ((_G.type(_26_) == "table") and (_26_[1] == "tableau") and (nil ~= _26_[2]) and (_26_[3] == 0)) and true) and _39_()) then local a = _25_[2] local b = _26_[2] local _ = _27_






 local from_col = state.tableau[a] local moves
 do local tbl_19_auto = {} local i_20_auto = 0 for i, _card in ipairs(from_col) do
 local val_21_auto = {"move", {"tableau", a, i}, {"tableau", b, i}} if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end moves = tbl_19_auto end
 return apply_events(clone(state), moves, {["unsafely?"] = true}) elseif (((_G.type(_25_) == "table") and (nil ~= _25_[1]) and (nil ~= _25_[2]) and (nil ~= _25_[3])) and ((_G.type(_26_) == "table") and (_26_[1] == "tableau") and (nil ~= _26_[2]) and (nil ~= _26_[3])) and (nil ~= _27_)) then local f_field = _25_[1] local f_col = _25_[2] local f_card_n = _25_[3] local t_col = _26_[2] local t_card_n = _26_[3] local held0 = _27_



 local moves do local tbl_19_auto = {} local i_20_auto = 0 for i = 1, #held0 do
 local val_21_auto = {"move", {f_field, f_col, (f_card_n + (i - 1))}, {"tableau", t_col, (t_card_n + i)}} if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end moves = tbl_19_auto end


 local next_state = apply_events(inc_moves(clone(state)), moves, {["unsafely?"] = true})


 local _, new_run = table.split(next_state.tableau[t_col], t_card_n)
 if valid_tableau_sequence_3f(new_run) then
 return next_state, moves else
 return nil, Error("Must build piles in alternating suit, descending rank") end else local _ = _25_


 return nil, Error("No putdown for #{field}", {field = dropped_on}) end end end end end end

 M.Action.move = function(state, pick_up_from, put_down_on)
 local function _45_(...) local _46_ = ... if (nil ~= _46_) then local held = _46_ local function _47_(...) local _48_, _49_ = ... if ((nil ~= _48_) and (nil ~= _49_)) then local next_state = _48_ local moves = _49_


 return next_state, moves else local __85_auto = _48_ return ... end end return _47_(put_down(state, pick_up_from, put_down_on, held)) else local __85_auto = _46_ return ... end end return _45_(check_pick_up(state, pick_up_from)) end

 M.Action["lock-dragon"] = function(state, dragon_color)


 local dragons do local tbl_19_auto = {} local i_20_auto = 0 for location, card in M["iter-cards"](state) do local val_21_auto
 if ((_G.type(card) == "table") and (card[1] == dragon_color)) then val_21_auto = {location, card} else val_21_auto = nil end if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end dragons = tbl_19_auto end local check_already_locked_3f
 local function _54_() return state.locked[dragon_color] end check_already_locked_3f = _54_ local check_can_move_dragons_3f
 local function _55_() local movable_3f = true for _, _56_ in ipairs(dragons) do local _each_57_ = _56_ local location = _each_57_[1] local _card = _each_57_[2] if not movable_3f then break end

 if ((_G.type(location) == "table") and (location[1] == "cell")) then movable_3f = true else local function _58_() local col_n = location[2] local card_n = location[3] return (card_n == #state.tableau[col_n]) end if (((_G.type(location) == "table") and (location[1] == "tableau") and (nil ~= location[2]) and (nil ~= location[3])) and _58_()) then local col_n = location[2] local card_n = location[3] movable_3f = true else local _0 = location movable_3f = false end end end return movable_3f end check_can_move_dragons_3f = _55_ local existing_dragon_cell





 local function _60_() local index = nil for _61_, card in M["iter-cards"](state, {"cell"}) do
 local _each_62_ = _61_ local _cell = _each_62_[1] local n = _each_62_[2] if index then break end

 if ((_G.type(card) == "table") and (card[1] == dragon_color)) then
 index = n else index = nil end end return index end existing_dragon_cell = _60_ local next_free_cell
 local function _64_() local free_i = nil for i, col in ipairs(state.cell) do if free_i then break end
 if table["empty?"](col) then free_i = i else free_i = nil end end return free_i end next_free_cell = _64_
 local function _66_(...) local _67_ = ... if (_67_ == false) then local function _68_(...) local _69_ = ... if (_69_ == true) then local function _70_(...) local _71_ = ... if (nil ~= _71_) then local into_cell = _71_



 local i_index = #state.cell[into_cell] local moves
 do local t, n = {}, 1 for i, _72_ in ipairs(dragons) do local _each_73_ = _72_ local location = _each_73_[1] local card = _each_73_[2]
 if ((_G.type(location) == "table") and (location[1] == "cell") and (location[2] == into_cell)) then
 t, n = t, n elseif ((_G.type(location) == "table") and (nil ~= location[1]) and (nil ~= location[2]) and (nil ~= location[3])) then local field = location[1] local col_n = location[2] local card_n = location[3]
 t, n = table.insert(t, {"move", location, {"cell", into_cell, (i_index + n)}}), (n + 1) else t, n = nil end end moves = t, n end


 local next_state, moves0 = apply_events(clone(state), moves)
 do end (next_state.locked)[dragon_color] = true


 next_state.moves = (#moves0 + next_state.moves)
 return next_state, moves0 else local _ = _71_

 return nil, Error("Unable to lock dragon") end end return _70_((existing_dragon_cell() or next_free_cell())) else local _ = _69_ return nil, Error("Unable to lock dragon") end end return _68_(check_can_move_dragons_3f()) else local _ = _67_ return nil, Error("Unable to lock dragon") end end return _66_(check_already_locked_3f()) end

 M.Plan["next-move-to-flower"] = function(state)
 if (0 == #state.flower[1]) then
 local speculative_state = clone(state) local check_locations
 do local tbl_19_auto = {} local i_20_auto = 0 for i = 1, 3 do local val_21_auto = {"cell", i} if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end check_locations = tbl_19_auto end local _
 do local tbl_17_auto = check_locations for i = 1, 8 do local val_18_auto = {"tableau", i} table.insert(tbl_17_auto, val_18_auto) end _ = tbl_17_auto end local from
 do local location = nil for _0, _79_ in ipairs(check_locations) do
 local _each_80_ = _79_ local field = _each_80_[1] local col = _each_80_[2] if location then break end

 local card_n = #speculative_state[field][col]
 local _81_ = speculative_state[field][col][card_n] if ((_G.type(_81_) == "table") and (_81_[1] == "flower")) then
 location = {field, col, card_n} else location = nil end end from = location end
 local to = {"flower", 1, 0}
 if from then
 local function _83_(...) local _84_ = ... if (nil ~= _84_) then local speculative_state0 = _84_

 return {from, to} else local __85_auto = _84_ return ... end end return _83_(M.Action.move(speculative_state, from, to)) else return nil end else return nil end end

 M.Plan["next-move-to-foundation"] = function(state)



 local speculative_state = clone(state) local check_locations
 do local tbl_19_auto = {} local i_20_auto = 0 for i = 1, 3 do local val_21_auto = {"cell", i} if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end check_locations = tbl_19_auto end local _
 do local tbl_17_auto = check_locations for i = 1, 8 do local val_18_auto = {"tableau", i} table.insert(tbl_17_auto, val_18_auto) end _ = tbl_17_auto end local min_value
 do local min_val = math.huge for _l, card in M["iter-cards"](speculative_state, {"cell", "tableau"}) do

 local function _89_() local suit = card[1] local val = card[2] return eq_any_3f(suit, {"coins", "myriads", "strings"}) end if (((_G.type(card) == "table") and (nil ~= card[1]) and (nil ~= card[2])) and _89_()) then local suit = card[1] local val = card[2]

 min_val = math.min(val, min_val) else local _0 = card
 min_val = min_val end end min_value = min_val end local not_dragon_3f
 local function _91_(suit) return eq_any_3f(suit, {"coins", "myriads", "strings"}) end not_dragon_3f = _91_ local source_locations
 do local tbl_19_auto = {} local i_20_auto = 0 for _0, _92_ in ipairs(check_locations) do local _each_93_ = _92_ local field = _each_93_[1] local col = _each_93_[2] local val_21_auto
 do local card_n = #speculative_state[field][col]
 local _94_ = speculative_state[field][col][card_n] if ((_G.type(_94_) == "table") and (nil ~= _94_[1]) and (nil ~= _94_[2])) then local suit = _94_[1] local val = _94_[2]
 if (not_dragon_3f(suit) and (min_value == val)) then
 val_21_auto = {field, col, card_n} else val_21_auto = nil end else val_21_auto = nil end end if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end source_locations = tbl_19_auto end local potential_moves
 do local moves = {} for _0, from in ipairs(source_locations) do
 local tbl_17_auto = moves for i = 1, 4 do local val_18_auto
 do local _98_ = speculative_state.foundation[i] if ((_G.type(_98_) == "table") and (_98_[1] == nil)) then
 val_18_auto = {from, {"foundation", i, 0}} elseif (nil ~= _98_) then local cards = _98_
 val_18_auto = {from, {"foundation", i, #cards}} else val_18_auto = nil end end table.insert(tbl_17_auto, val_18_auto) end moves = tbl_17_auto end potential_moves = moves end
 local actions = nil for _0, _100_ in ipairs(potential_moves) do local _each_101_ = _100_ local from = _each_101_[1] local to = _each_101_[2] if actions then break end
 local function _102_(...) local _103_ = ... if (nil ~= _103_) then local speculative_state0 = _103_

 return {from, to} else local __85_auto = _103_ return ... end end actions = _102_(M.Action.move(speculative_state, from, to)) end return actions end

 M.Query["liftable?"] = function(state, location)
 return not (nil == check_pick_up(state, location)) end

 M.Query["droppable?"] = function(state, location)
 if ((_G.type(location) == "table") and (nil ~= location[1])) then local field = location[1]
 return eq_any_3f(field, {"tableau", "cell", "flower", "foundation"}) else local _ = location return false end end


 M.Query["game-ended?"] = function(state)
 local foundations_3f do local won_3f = true for i = 1, 3 do
 won_3f = (won_3f and winning_foundation_sequence_3f(location_contents(state, {"foundation", i}))) end foundations_3f = won_3f end
 local flower_3f = winning_flower_sequence_3f(location_contents(state, {"flower", 1})) local dragons_3f
 do local won_3f = true for i = 1, 3 do
 won_3f = (won_3f and winning_dragon_sequence_3f(location_contents(state, {"cell", i}))) end dragons_3f = won_3f end
 return (foundations_3f and flower_3f and dragons_3f) end

 M.Query["game-result"] = function(state)
 return M.Query["game-ended?"](state) end

 return M