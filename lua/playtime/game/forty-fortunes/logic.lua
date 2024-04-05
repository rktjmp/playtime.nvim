
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}



 local _local_2_ = CardGameUtils local location_contents = _local_2_["location-contents"] local inc_moves = _local_2_["inc-moves"] local apply_events = _local_2_["apply-events"]
 M["iter-cards"] = CardGameUtils["make-iter-cards-fn"]({"draw", "tableau", "cell", "foundation"})
 local _local_3_ = CardGameUtils["make-card-util-fns"]({value = {king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_3_["card-value"] local card_color = _local_3_["card-color"] local card_rank = _local_3_["card-rank"]
 local card_suit = _local_3_["card-suit"] local rank_value = _local_3_["rank-value"] local suit_color = _local_3_["suit-color"]
 local card_face_up_3f = _local_3_["card-face-up?"] local card_face_down_3f = _local_3_["card-face-down?"]





 local valid_sequence_3f

 local function _6_(next_card, _4_, memo) local _arg_5_ = _4_ local last_card = _arg_5_[1]
 local last_value = card_value(last_card)
 local last_suit = card_suit(last_card)
 local next_value = card_value(next_card)
 local next_suit = card_suit(next_card)
 local same_suit_3f = (next_suit == last_suit) local memo0
 if (memo == nil) then
 local _7_, _8_ = last_value, next_value if ((_7_ == 13) and (_8_ == 1)) then memo0 = 1 elseif ((_7_ == 1) and (_8_ == 13)) then memo0 = -1 elseif ((nil ~= _7_) and (nil ~= _8_)) then local l = _7_ local n = _8_


 local _9_ = (n - l) if (_9_ == 1) then memo0 = 1 elseif (_9_ == -1) then memo0 = -1 else memo0 = nil end else memo0 = nil end elseif (nil ~= memo) then local dir = memo




 local _12_, _13_, _14_ = last_value, next_value, dir if ((_12_ == 13) and (_13_ == 1) and (_14_ == 1)) then memo0 = 1 elseif ((_12_ == 1) and (_13_ == 13) and (_14_ == -1)) then memo0 = -1 elseif ((nil ~= _12_) and (nil ~= _13_) and (nil ~= _14_)) then local l = _12_ local n = _13_ local dir0 = _14_


 local _15_, _16_ = (n - l) if (_15_ == dir0) then
 memo0 = dir0 else memo0 = nil end else memo0 = nil end else memo0 = nil end
 return (same_suit_3f and memo0), memo0 end valid_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_6_)

 local winning_foundation_sequence_3f
 do
 local valid_sequence_3f0

 local function _22_(next_card, _20_) local _arg_21_ = _20_ local last_card = _arg_21_[1]
 return ((card_suit(next_card) == card_suit(last_card)) and (card_value(next_card) == (1 + card_value(last_card)))) end valid_sequence_3f0 = CardGameUtils["make-valid-sequence?-fn"](_22_)


 local function _23_(sequence)
 return ((rank_value("king") == #sequence) and valid_sequence_3f0(sequence)) end winning_foundation_sequence_3f = _23_ end


 local function new_game_state()
 return {draw = {{}}, foundation = {{}, {}, {}, {}, {}, {}, {}, {}}, cell = {{}}, tableau = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}}, moves = 0} end








 M.build = function(_config, _3fseed) _G.assert((nil ~= _config), "Missing argument _config on fnl/playtime/game/forty-fortunes/logic.fnl:69")
 math.randomseed((_3fseed or os.time()))
 local deck = table.shuffle(table.join(Deck.Standard52.build(), Deck.Standard52.build()))

 local state = new_game_state()
 for _, card in ipairs(deck) do
 Deck["flip-card"](card) end
 state["draw"][1] = deck
 return state end

 M.Action.deal = function(state)
 local moves do local moves0, t_col, row, f_col = {}, 1, 1, 1 for i = #state.draw[1], 1, -1 do

 local card = state.draw[1][i]
 local from = {"draw", 1, i} local to
 if ((_G.type(card) == "table") and true and (card[2] == 1)) then local _suit = card[1]
 to = {"foundation", f_col, 1} else local _ = card
 to = {"tableau", t_col, row} end local t_col0, row0, f_col0 = nil, nil, nil
 do local _25_, _26_ = t_col, to if (true and ((_G.type(_26_) == "table") and (_26_[1] == "foundation"))) then local _ = _25_
 t_col0, row0, f_col0 = t_col, row, (1 + f_col) elseif ((_25_ == 13) and true) then local _ = _26_
 t_col0, row0, f_col0 = 1, (1 + row), f_col elseif ((_25_ == 6) and true) then local _ = _26_
 t_col0, row0, f_col0 = 8, row, f_col elseif ((nil ~= _25_) and true) then local n = _25_ local _ = _26_
 t_col0, row0, f_col0 = (n + 1), row, f_col else t_col0, row0, f_col0 = nil end end
 moves0, t_col, row, f_col = table.insert(moves0, {"move", from, to}), t_col0, row0, f_col0 end moves = moves0, t_col, row, f_col end
 local next_state, moves0 = apply_events(clone(state), moves)
 return next_state, moves0 end

 local function check_pick_up(state, pick_up_from)
 if ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "tableau") and (nil ~= pick_up_from[2]) and (nil ~= pick_up_from[3])) then local col_n = pick_up_from[2] local card_n = pick_up_from[3]

 local remaining, held = table.split(state.tableau[col_n], card_n)
 if (1 == #held) then
 return held else
 if ((_G.type(held) == "table") and (held[1] == nil)) then
 return nil, Error("No cards to pick up from tableau column #{col-n}", {["col-n"] = col_n}) else local _ = held
 return nil, Error("You may only pick up one card") end end elseif ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "cell") and (nil ~= pick_up_from[2]) and (pick_up_from[3] == 1)) then local col_n = pick_up_from[2]


 local remaining, held = table.split(state.cell[col_n], 1)
 local _30_ = #held if (_30_ == 1) then
 return held elseif (_30_ == 0) then
 return nil, Error("No card to pick up from free cell") elseif (nil ~= _30_) then local n = _30_
 return nil, Error("May only pick up one card at a time from free cell") else return nil end elseif ((_G.type(pick_up_from) == "table") and (nil ~= pick_up_from[1])) then local field = pick_up_from[1]


 return nil, Error("May not pick up from #{field}", {field = field}) else return nil end end

 local function put_down(state, pick_up_from, dropped_on, held)
 local _33_, _34_, _35_ = pick_up_from, dropped_on, held local function _36_() local field = _33_[1] local col = _33_[2] local from_n = _33_[3] local on_n = _34_[3] local _ = _35_ return (from_n == (1 + on_n)) end if ((((_G.type(_33_) == "table") and (nil ~= _33_[1]) and (nil ~= _33_[2]) and (nil ~= _33_[3])) and ((_G.type(_34_) == "table") and (_33_[1] == _34_[1]) and (_33_[2] == _34_[2]) and (nil ~= _34_[3])) and true) and _36_()) then local field = _33_[1] local col = _33_[2] local from_n = _33_[3] local on_n = _34_[3] local _ = _35_


 return nil else local function _37_() local _ = _33_ local field = _34_[1] local col_n = _34_[2] local card_n = _34_[3] local _0 = _35_ return not (card_n == #state[field][col_n]) end if ((true and ((_G.type(_34_) == "table") and (nil ~= _34_[1]) and (nil ~= _34_[2]) and (nil ~= _34_[3])) and true) and _37_()) then local _ = _33_ local field = _34_[1] local col_n = _34_[2] local card_n = _34_[3] local _0 = _35_



 return nil, Error("Must place cards on the bottom of a cascade") elseif (true and ((_G.type(_34_) == "table") and (_34_[1] == "foundation")) and ((_G.type(_35_) == "table") and (nil ~= _35_[1]) and (nil ~= _35_[2]))) then local _ = _33_ local multiple = _35_[1] local cards = _35_[2]




 return nil, Error("May only place cards on a foundation one at a time") elseif (true and ((_G.type(_34_) == "table") and (_34_[1] == "foundation") and (nil ~= _34_[2]) and (_34_[3] == 0)) and ((_G.type(_35_) == "table") and (nil ~= _35_[1]) and (_35_[2] == nil))) then local _ = _33_ local f_col_n = _34_[2] local card = _35_[1]



 if ((_G.type(card) == "table") and true and (card[2] == 1)) then local _suit = card[1]
 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col_n, 1}}}) else local _0 = card


 return nil, Error("Must build foundations same suit, 1, 2, ... 10, J, Q, K") end elseif (true and ((_G.type(_34_) == "table") and (_34_[1] == "foundation") and (nil ~= _34_[2]) and (nil ~= _34_[3])) and ((_G.type(_35_) == "table") and (nil ~= _35_[1]) and (_35_[2] == nil))) then local _ = _33_ local f_col_n = _34_[2] local f_card_n = _34_[3] local new_card = _35_[1]



 local onto_card = location_contents(state, dropped_on)
 local _39_, _40_ = onto_card, new_card local function _41_() local suit = _39_[1] return (-1 == (card_value(onto_card) - card_value(new_card))) end if ((((_G.type(_39_) == "table") and (nil ~= _39_[1])) and ((_G.type(_40_) == "table") and (_39_[1] == _40_[1]))) and _41_()) then local suit = _39_[1]

 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col_n, (f_card_n + 1)}}}) else local _0 = _39_


 return nil, Error("Must build foundations in same-suit, ascending order") end elseif (true and ((_G.type(_34_) == "table") and (_34_[1] == "cell")) and ((_G.type(_35_) == "table") and (nil ~= _35_[1]) and (nil ~= _35_[2]))) then local _ = _33_ local multiple = _35_[1] local cards = _35_[2]


 return nil, Error("May only place single cards on a cell") else local function _43_() local _ = _33_ local col_n = _34_[2] local card_n = _34_[3] local _0 = _35_ return not (0 == card_n) end if ((true and ((_G.type(_34_) == "table") and (_34_[1] == "cell") and (nil ~= _34_[2]) and (nil ~= _34_[3])) and true) and _43_()) then local _ = _33_ local col_n = _34_[2] local card_n = _34_[3] local _0 = _35_

 return nil, Error("May only place single cards on a cell") elseif (true and ((_G.type(_34_) == "table") and (_34_[1] == "cell") and (nil ~= _34_[2]) and (_34_[3] == 0)) and ((_G.type(_35_) == "table") and (nil ~= _35_[1]) and (_35_[2] == nil))) then local _ = _33_ local col_n = _34_[2] local new_card = _35_[1]


 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"cell", col_n, 1}}}) elseif (((_G.type(_33_) == "table") and (nil ~= _33_[1]) and (nil ~= _33_[2]) and (nil ~= _33_[3])) and ((_G.type(_34_) == "table") and (_34_[1] == "tableau") and (nil ~= _34_[2]) and (nil ~= _34_[3])) and ((_G.type(_35_) == "table") and (nil ~= _35_[1]) and (_35_[2] == nil))) then local f_field = _33_[1] local f_col = _33_[2] local f_card_n = _33_[3] local t_col = _34_[2] local t_card_n = _34_[3] local one_card = _35_[1]















 local top_card_n do local top_i, cont_3f = 1, true for i = f_card_n, 1, -1 do if not cont_3f then break end


 local _, seq = table.split(state[f_field][f_col], i)
 if valid_sequence_3f(seq) then
 top_i, cont_3f = i, true else
 top_i, cont_3f = top_i, false end end top_card_n = top_i, cont_3f end local moves
 do local tbl_19_auto = {} local i_20_auto = 0 for i = f_card_n, top_card_n, -1 do
 local val_21_auto = {"move", {f_field, f_col, i}, {"tableau", t_col, (t_card_n + (f_card_n - i) + 1)}} if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end moves = tbl_19_auto end


 local next_state = apply_events(inc_moves(clone(state), #moves), moves) local seq




 if (t_card_n == 0) then
 seq = {next_state.tableau[t_col][1]} elseif (nil ~= t_card_n) then local n = t_card_n
 seq = {next_state.tableau[t_col][n], next_state.tableau[t_col][(n + 1)]} else seq = nil end
 if valid_sequence_3f(seq) then
 return next_state, moves else
 return nil, Error("Must build in same suit, ascending or descending rank") end else local _ = _33_


 return nil, Error("No putdown for #{field}", {field = dropped_on}) end end end end

 M.Action.move = function(state, pick_up_from, put_down_on)
 local function _49_(...) local _50_ = ... if (nil ~= _50_) then local held = _50_ local function _51_(...) local _52_, _53_ = ... if ((nil ~= _52_) and (nil ~= _53_)) then local next_state = _52_ local moves = _53_


 return next_state, moves else local __85_auto = _52_ return ... end end return _51_(put_down(state, pick_up_from, put_down_on, held)) else local __85_auto = _50_ return ... end end return _49_(check_pick_up(state, pick_up_from)) end

 M.Plan["next-move-to-foundation"] = function(state)
 local speculative_state = clone(state) local check_locations
 do local tbl_19_auto = {} local i_20_auto = 0 for i = 1, 1 do local val_21_auto = {"cell", i} if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end check_locations = tbl_19_auto end local _
 do local tbl_17_auto = check_locations for i = 1, 13 do local val_18_auto = {"tableau", i} table.insert(tbl_17_auto, val_18_auto) end _ = tbl_17_auto end local min_values
 do local min_vals = {spades = math.huge, hearts = math.huge, diamonds = math.huge, clubs = math.huge} for _l, card in M["iter-cards"](speculative_state, {"cell", "tableau"}) do


 local suit = card_suit(card)
 local val = card_value(card)
 min_vals = table.set(min_vals, suit, math.min(val, min_vals[suit])) end min_values = min_vals end local source_locations
 do local tbl_19_auto = {} local i_20_auto = 0 for _0, _57_ in ipairs(check_locations) do local _each_58_ = _57_ local field = _each_58_[1] local col = _each_58_[2] local val_21_auto
 do local card_n = #speculative_state[field][col]
 local _59_ = speculative_state[field][col][card_n] if (nil ~= _59_) then local card = _59_
 local suit = card_suit(card)
 if (card_value(card) == min_values[suit]) then
 val_21_auto = {field, col, card_n} else val_21_auto = nil end else val_21_auto = nil end end if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end source_locations = tbl_19_auto end local potential_moves
 do local moves = {} for _0, from in ipairs(source_locations) do
 local tbl_17_auto = moves for i = 1, 8 do local val_18_auto
 do local _63_ = speculative_state.foundation[i] if ((_G.type(_63_) == "table") and (_63_[1] == nil)) then
 val_18_auto = {from, {"foundation", i, 0}} elseif (nil ~= _63_) then local cards = _63_
 val_18_auto = {from, {"foundation", i, #cards}} else val_18_auto = nil end end table.insert(tbl_17_auto, val_18_auto) end moves = tbl_17_auto end potential_moves = moves end
 local actions = nil for _0, _65_ in ipairs(potential_moves) do local _each_66_ = _65_ local pick_up_from = _each_66_[1] local put_down_on = _each_66_[2] if actions then break end
 local function _67_(...) local _68_ = ... if (nil ~= _68_) then local speculative_state0 = _68_

 return {pick_up_from, put_down_on} else local __85_auto = _68_ return ... end end actions = _67_(M.Action.move(clone(state), pick_up_from, put_down_on)) end return actions end

 M.Query["liftable?"] = function(state, location)
 return not (nil == check_pick_up(state, location)) end

 M.Query["droppable?"] = function(state, location)
 if ((_G.type(location) == "table") and (nil ~= location[1])) then local field = location[1]
 return eq_any_3f(field, {"tableau", "cell", "foundation"}) else local _ = location return false end end


 M.Query["game-ended?"] = function(state) local won_3f = true
 for i = 1, 8 do
 won_3f = (won_3f and winning_foundation_sequence_3f(location_contents(state, {"foundation", i}))) end return won_3f end

 M.Query["game-result"] = function(state)
 return M.Query["game-ended?"](state) end

 return M