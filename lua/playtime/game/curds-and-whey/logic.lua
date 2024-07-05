
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}



 local _local_2_ = CardGameUtils local inc_moves = _local_2_["inc-moves"]
 local apply_events = _local_2_["apply-events"]
 M["iter-cards"] = CardGameUtils["make-iter-cards-fn"]({"draw", "tableau", "complete"})
 local _local_3_ = CardGameUtils["make-card-util-fns"]({value = {king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_3_["card-value"] local card_color = _local_3_["card-color"] local card_rank = _local_3_["card-rank"]
 local card_suit = _local_3_["card-suit"] local rank_value = _local_3_["rank-value"] local suit_color = _local_3_["suit-color"]
 local card_face_up_3f = _local_3_["card-face-up?"] local card_face_down_3f = _local_3_["card-face-down?"]




 local function new_game_state()
 return {draw = {{}}, tableau = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}}, complete = {{}, {}, {}, {}}, moves = 0} end






 M.build = function(config, _3fseed) _G.assert((nil ~= config), "Missing argument config on fnl/playtime/game/curds-and-whey/logic.fnl:31")
 math.randomseed((_3fseed or os.time()))
 local deck = Deck.shuffle(Deck.Standard52.build())

 local state = new_game_state()
 do end (state)["draw"][1] = deck
 state["suits"] = config.suits
 return state end

 local valid_build_sequence_3f, valid_move_sequence_3f = nil, nil
 do local same_rank_any_suit local function _6_(next_card, _4_) local _arg_5_ = _4_ local last_card = _arg_5_[1]
 local last_value = card_value(last_card)
 local next_value = card_value(next_card)
 return (last_value == next_value) end same_rank_any_suit = _6_ local desc_rank_same_suit
 local function _9_(next_card, _7_) local _arg_8_ = _7_ local last_card = _arg_8_[1]
 local last_value = card_value(last_card)
 local next_value = card_value(next_card)
 local last_suit = card_suit(last_card)
 local next_suit = card_suit(next_card)
 return ((last_suit == next_suit) and (last_value == (next_value + 1))) end desc_rank_same_suit = _9_ local build_3f


 local function _10_(next_card, other_cards)
 return (same_rank_any_suit(next_card, other_cards) or desc_rank_same_suit(next_card, other_cards)) end build_3f = CardGameUtils["make-valid-sequence?-fn"](_10_) local move_3f

 local function _11_(sequence)
 local a = CardGameUtils["make-valid-sequence?-fn"](same_rank_any_suit)
 local b = CardGameUtils["make-valid-sequence?-fn"](desc_rank_same_suit)
 return (a(sequence) or b(sequence)) end move_3f = _11_
 valid_build_sequence_3f, valid_move_sequence_3f = build_3f, move_3f end

 local function complete_sequence_3f(sequence)
 return ((rank_value("king") == #sequence) and valid_move_sequence_3f(sequence)) end


 M.Action.deal = function(state)
 local moves do local moves0, t_col, row = {}, 1, 1 for i = #state.draw[1], 1, -1 do

 local from = {"draw", 1, i}
 local to = {"tableau", t_col, row}
 local move = {"move", from, to}
 local flip = {"face-up", from}


 local _12_ if (t_col == 13) then _12_ = 1 else _12_ = (t_col + 1) end
 local function _14_() if (t_col == 13) then return (row + 1) else return row end end moves0, t_col, row = table.insert(table.insert(moves0, flip), move), _12_, _14_() end moves = moves0, t_col, row end
 local next_state, moves0 = apply_events(clone(state), moves)
 return next_state, moves0 end

 local function check_pick_up(state, pick_up_from)
 if ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "tableau") and (nil ~= pick_up_from[2]) and (nil ~= pick_up_from[3])) then local col_n = pick_up_from[2] local card_n = pick_up_from[3]

 local remaining, held = table.split(state.tableau[col_n], card_n)
 if valid_move_sequence_3f(held) then
 return held else
 if ((_G.type(held) == "table") and (held[1] == nil)) then
 return nil, Error("No cards to pick up from tableau column #{col-n}", {["col-n"] = col_n}) else local _ = held
 return nil, Error("Must pick up run of same suit, descending rank, or any suit, same rank") end end elseif ((_G.type(pick_up_from) == "table") and (nil ~= pick_up_from[1])) then local field = pick_up_from[1]


 return nil, Error("May not pick up from #{field}", {field = field}) else return nil end end

 local function put_down(state, pick_up_from, dropped_on, held)
 local _18_, _19_, _20_ = pick_up_from, dropped_on, held local function _21_() local field = _18_[1] local col = _18_[2] local from_n = _18_[3] local on_n = _19_[3] local _ = _20_ return (from_n == (1 + on_n)) end if ((((_G.type(_18_) == "table") and (nil ~= _18_[1]) and (nil ~= _18_[2]) and (nil ~= _18_[3])) and ((_G.type(_19_) == "table") and (_18_[1] == _19_[1]) and (_18_[2] == _19_[2]) and (nil ~= _19_[3])) and true) and _21_()) then local field = _18_[1] local col = _18_[2] local from_n = _18_[3] local on_n = _19_[3] local _ = _20_


 return nil else local function _22_() local _ = _18_ local field = _19_[1] local col_n = _19_[2] local card_n = _19_[3] local _0 = _20_ return not (card_n == #state[field][col_n]) end if ((true and ((_G.type(_19_) == "table") and (nil ~= _19_[1]) and (nil ~= _19_[2]) and (nil ~= _19_[3])) and true) and _22_()) then local _ = _18_ local field = _19_[1] local col_n = _19_[2] local card_n = _19_[3] local _0 = _20_



 return nil, Error("Must place cards on the bottom of a cascade") else local function _23_() local a = _18_[2] local b = _19_[2] local _ = _20_ return not (a == b) end if ((((_G.type(_18_) == "table") and (_18_[1] == "tableau") and (nil ~= _18_[2]) and (_18_[3] == 1)) and ((_G.type(_19_) == "table") and (_19_[1] == "tableau") and (nil ~= _19_[2]) and (_19_[3] == 0)) and true) and _23_()) then local a = _18_[2] local b = _19_[2] local _ = _20_




 local from_col = state.tableau[a] local moves
 do local tbl_19_auto = {} local i_20_auto = 0 for i, _card in ipairs(from_col) do
 local val_21_auto = {"move", {"tableau", a, i}, {"tableau", b, i}} if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end moves = tbl_19_auto end
 return apply_events(clone(state), moves, {["unsafely?"] = true}) elseif (((_G.type(_18_) == "table") and (_18_[1] == "tableau") and (nil ~= _18_[2]) and (nil ~= _18_[3])) and ((_G.type(_19_) == "table") and (_19_[1] == "tableau") and (nil ~= _19_[2]) and (nil ~= _19_[3])) and (nil ~= _20_)) then local f_col = _18_[2] local f_card_n = _18_[3] local t_col = _19_[2] local t_card_n = _19_[3] local held0 = _20_



 local moves do local tbl_19_auto = {} local i_20_auto = 0 for i = 1, #held0 do
 local val_21_auto = {"move", {"tableau", f_col, (f_card_n + (i - 1))}, {"tableau", t_col, (t_card_n + i)}} if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end moves = tbl_19_auto end


 local one_up = {"tableau", f_col, (f_card_n - 1)} local _
 do local _26_ = table["get-in"](state, one_up) if ((_G.type(_26_) == "table") and (_26_.face == "down")) then
 _ = table.insert(moves, {"face-up", one_up}) else _ = nil end end
 local next_state = apply_events(inc_moves(clone(state)), moves)


 local _0, new_run = table.split(next_state.tableau[t_col], t_card_n)
 local _28_, _29_ = t_card_n, held0[1] if ((_28_ == 0) and ((_G.type(_29_) == "table") and true and (_29_[2] == "king"))) then local _suit = _29_[1]
 return next_state, moves elseif ((_28_ == 0) and true) then local _1 = _29_
 return nil, Error("May only place kings in empty slots") else local _1 = _28_
 if valid_build_sequence_3f(new_run) then
 return next_state, moves else
 return nil, Error("Must build piles in same suit, descending rank or any suit, same rank") end end else local _ = _18_


 return nil, Error("No putdown for #{field}", {field = dropped_on}) end end end end

 M.Action.move = function(state, pick_up_from, put_down_on)
 local function _33_(...) local _34_ = ... if (nil ~= _34_) then local held = _34_ local function _35_(...) local _36_, _37_ = ... if ((nil ~= _36_) and (nil ~= _37_)) then local next_state = _36_ local moves = _37_


 return next_state, moves else local __85_auto = _36_ return ... end end return _35_(put_down(state, pick_up_from, put_down_on, held)) else local __85_auto = _34_ return ... end end return _33_(check_pick_up(state, pick_up_from)) end

 M.Action["remove-complete-sequence"] = function(state, sequence_starts_at)
 local function _40_(...) local _41_, _42_ = ... if (nil ~= _41_) then local held = _41_ local function _43_(...) local _44_, _45_ = ... if (_44_ == 13) then local function _46_(...) local _47_, _48_ = ... if (_47_ == true) then



 local complete_n do local index = nil for i, c in ipairs(state.complete) do if index then break end
 if (0 == #c) then index = i else index = nil end end complete_n = index end
 local _let_50_ = sequence_starts_at local f_field = _let_50_[1] local f_col = _let_50_[2] local f_card_n = _let_50_[3] local moves
 do local tbl_19_auto = {} local i_20_auto = 0 for i = (f_card_n + 12), f_card_n, -1 do
 local val_21_auto = {"move", {f_field, f_col, i}, {"complete", complete_n, ((f_card_n + 12) - (i - 1))}} if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end moves = tbl_19_auto end


 local one_up = {"tableau", f_col, (f_card_n - 1)} local _
 do local _52_ = table["get-in"](state, one_up) if ((_G.type(_52_) == "table") and (_52_.face == "down")) then
 _ = table.insert(moves, {"face-up", one_up}) else _ = nil end end
 local next_state, moves0 = apply_events(clone(state), moves)
 return next_state, moves0 elseif ((_47_ == nil) and (nil ~= _48_)) then local err = _48_ else return nil end end return _46_(complete_sequence_3f(held)) elseif ((_44_ == nil) and (nil ~= _45_)) then local err = _45_ else return nil end end return _43_(#held) elseif ((_41_ == nil) and (nil ~= _42_)) then local err = _42_ else return nil end end return _40_(check_pick_up(state, sequence_starts_at)) end





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