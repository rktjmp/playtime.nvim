
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


 return {draw = {{}, {}, {}, {}, {}, {}}, tableau = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}}, complete = {{}, {}, {}, {}, {}, {}, {}, {}}, moves = 0, suits = nil} end






 local function build_deck(suit_count, suits) _G.assert((nil ~= suits), "Missing argument suits on fnl/playtime/game/spider/logic.fnl:33") _G.assert((nil ~= suit_count), "Missing argument suit-count on fnl/playtime/game/spider/logic.fnl:33")
 local n_decks = (8 / suit_count) local full_deck
 local function _4_() local tbl_18_auto = {} local i_19_auto = 0 for i = 1, n_decks do local val_20_auto = Deck.Standard52.build() if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto end full_deck = table.join(table.unpack(_4_()))


 local function _6_() local tbl_18_auto = {} local i_19_auto = 0 for _, c in ipairs(full_deck) do local val_20_auto
 if eq_any_3f(card_suit(c), suits) then val_20_auto = c else val_20_auto = nil end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto end return table.shuffle(_6_()) end


 M.build = function(config, _3fseed) _G.assert((nil ~= config), "Missing argument config on fnl/playtime/game/spider/logic.fnl:42")
 if ((_G.type(config) == "table") and (nil ~= config.suits)) then local suits = config.suits else local __2_auto = config error("config must match {:suits suits}") end
 math.randomseed((_3fseed or os.time()))
 local deck do local _10_ = config.suits if (_10_ == 4) then
 deck = build_deck(4, {"spades", "hearts", "clubs", "diamonds"}) elseif (_10_ == 2) then
 deck = build_deck(2, {"spades", "hearts"}) elseif (_10_ == 1) then
 deck = build_deck(1, {"spades"}) else local _ = _10_
 deck = error(Error("Unsupported suit count #{n}", {n = config.suits})) end end
 local state = new_game_state() local draws

 do local draws0, deck0 = {}, deck for _, at in ipairs({((5 * 10) + 5), 11, 11, 11, 11, 11}) do

 local take, keep = table.split(deck0, at)
 draws0, deck0 = table.insert(draws0, take), keep end draws = draws0, deck0 end
 state["draw"] = draws
 state["suits"] = config.suits
 return state end

 local valid_build_sequence_3f

 local function _14_(next_card, _12_) local _arg_13_ = _12_ local last_card = _arg_13_[1]
 local last_value = card_value(last_card)
 local next_value = card_value(next_card)
 return (last_value == (next_value + 1)) end valid_build_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_14_)

 local valid_move_sequence_3f

 local function _17_(next_card, _15_) local _arg_16_ = _15_ local last_card = _arg_16_[1]
 local last_suit = card_suit(last_card)
 local last_value = card_value(last_card)
 local next_suit = card_suit(next_card)
 local next_value = card_value(next_card)
 return (card_face_up_3f(next_card) and (last_suit == next_suit) and (last_value == (next_value + 1))) end valid_move_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_17_)



 local function complete_sequence_3f(sequence)
 return ((rank_value("king") == #sequence) and valid_move_sequence_3f(sequence)) end


 M.Action.deal = function(state)
 local moves do local moves0, t_col, row = {}, 1, 1 for i = #state.draw[1], 1, -1 do

 local from = {"draw", 1, i}
 local to = {"tableau", t_col, row}
 local move = {"move", from, to} local _3fflip
 if (((t_col <= 4) and (row == 6)) or ((5 <= t_col) and (row == 5))) then

 _3fflip = {"face-up", from} else _3fflip = nil end


 local _19_ if (t_col == 10) then _19_ = 1 else _19_ = (t_col + 1) end
 local function _21_() if (t_col == 10) then return (row + 1) else return row end end moves0, t_col, row = table.insert(table.insert(moves0, _3fflip), move), _19_, _21_() end moves = moves0, t_col, row end
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

 local function flip_bottom_cards_21(state)
 for i = 1, 10 do
 local col = state.tableau[i]
 local _25_ = table.last(col) local function _26_() local card = _25_ return card_face_down_3f(card) end if ((nil ~= _25_) and _26_()) then local card = _25_
 Deck["flip-card"](card) else end end return nil end

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
 local _31_, _32_, _33_ = pick_up_from, dropped_on, held local function _34_() local field = _31_[1] local col = _31_[2] local from_n = _31_[3] local on_n = _32_[3] local _ = _33_ return (from_n == (1 + on_n)) end if ((((_G.type(_31_) == "table") and (nil ~= _31_[1]) and (nil ~= _31_[2]) and (nil ~= _31_[3])) and ((_G.type(_32_) == "table") and (_31_[1] == _32_[1]) and (_31_[2] == _32_[2]) and (nil ~= _32_[3])) and true) and _34_()) then local field = _31_[1] local col = _31_[2] local from_n = _31_[3] local on_n = _32_[3] local _ = _33_


 return nil else local function _35_() local _ = _31_ local field = _32_[1] local col_n = _32_[2] local card_n = _32_[3] local _0 = _33_ return not (card_n == #state[field][col_n]) end if ((true and ((_G.type(_32_) == "table") and (nil ~= _32_[1]) and (nil ~= _32_[2]) and (nil ~= _32_[3])) and true) and _35_()) then local _ = _31_ local field = _32_[1] local col_n = _32_[2] local card_n = _32_[3] local _0 = _33_



 return nil, Error("Must place cards on the bottom of a cascade") else local function _36_() local a = _31_[2] local b = _32_[2] local _ = _33_ return not (a == b) end if ((((_G.type(_31_) == "table") and (_31_[1] == "tableau") and (nil ~= _31_[2]) and (_31_[3] == 1)) and ((_G.type(_32_) == "table") and (_32_[1] == "tableau") and (nil ~= _32_[2]) and (_32_[3] == 0)) and true) and _36_()) then local a = _31_[2] local b = _32_[2] local _ = _33_




 local from_col = state.tableau[a] local moves
 do local tbl_18_auto = {} local i_19_auto = 0 for i, _card in ipairs(from_col) do
 local val_20_auto = {"move", {"tableau", a, i}, {"tableau", b, i}} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end moves = tbl_18_auto end
 return apply_events(clone(state), moves, {["unsafely?"] = true}) elseif (((_G.type(_31_) == "table") and (_31_[1] == "tableau") and (nil ~= _31_[2]) and (nil ~= _31_[3])) and ((_G.type(_32_) == "table") and (_32_[1] == "tableau") and (nil ~= _32_[2]) and (nil ~= _32_[3])) and (nil ~= _33_)) then local f_col = _31_[2] local f_card_n = _31_[3] local t_col = _32_[2] local t_card_n = _32_[3] local held0 = _33_



 local moves do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, #held0 do
 local val_20_auto = {"move", {"tableau", f_col, (f_card_n + (i - 1))}, {"tableau", t_col, (t_card_n + i)}} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end moves = tbl_18_auto end


 local one_up = {"tableau", f_col, (f_card_n - 1)} local _
 do local _39_ = table["get-in"](state, one_up) if ((_G.type(_39_) == "table") and (_39_.face == "down")) then
 _ = table.insert(moves, {"face-up", one_up}) else _ = nil end end
 local next_state = apply_events(inc_moves(clone(state)), moves)


 local _0, new_run = table.split(next_state.tableau[t_col], t_card_n)
 if valid_build_sequence_3f(new_run) then
 return next_state, moves else
 return nil, Error("Must build piles in descending rank") end else local _ = _31_


 return nil, Error("No putdown for #{field}", {field = dropped_on}) end end end end

 M.Action.move = function(state, pick_up_from, put_down_on)
 local function _43_(...) local _44_ = ... if (nil ~= _44_) then local held = _44_ local function _45_(...) local _46_, _47_ = ... if ((nil ~= _46_) and (nil ~= _47_)) then local next_state = _46_ local moves = _47_


 return next_state, moves else local __84_auto = _46_ return ... end end return _45_(put_down(state, pick_up_from, put_down_on, held)) else local __84_auto = _44_ return ... end end return _43_(check_pick_up(state, pick_up_from)) end

 M.Action["remove-complete-sequence"] = function(state, sequence_starts_at)
 local function _50_(...) local _51_, _52_ = ... if (nil ~= _51_) then local held = _51_ local function _53_(...) local _54_, _55_ = ... if (_54_ == 13) then local function _56_(...) local _57_, _58_ = ... if (_57_ == true) then



 local complete_n do local index = nil for i, c in ipairs(state.complete) do if index then break end
 if (0 == #c) then index = i else index = nil end end complete_n = index end
 local _let_60_ = sequence_starts_at local f_field = _let_60_[1] local f_col = _let_60_[2] local f_card_n = _let_60_[3] local moves
 do local tbl_18_auto = {} local i_19_auto = 0 for i = (f_card_n + 12), f_card_n, -1 do
 local val_20_auto = {"move", {f_field, f_col, i}, {"complete", complete_n, ((f_card_n + 12) - (i - 1))}} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end moves = tbl_18_auto end


 local one_up = {"tableau", f_col, (f_card_n - 1)} local _
 do local _62_ = table["get-in"](state, one_up) if ((_G.type(_62_) == "table") and (_62_.face == "down")) then
 _ = table.insert(moves, {"face-up", one_up}) else _ = nil end end
 local next_state, moves0 = apply_events(clone(state), moves)
 return next_state, moves0 elseif ((_57_ == nil) and (nil ~= _58_)) then local err = _58_ else return nil end end return _56_(complete_sequence_3f(held)) elseif ((_54_ == nil) and (nil ~= _55_)) then local err = _55_ else return nil end end return _53_(#held) elseif ((_51_ == nil) and (nil ~= _52_)) then local err = _52_ else return nil end end return _50_(check_pick_up(state, sequence_starts_at)) end





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