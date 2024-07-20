
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}



 local location_contents = CardGameUtils["location-contents"]
 local inc_moves = CardGameUtils["inc-moves"]
 local apply_events = CardGameUtils["apply-events"]
 M["iter-cards"] = CardGameUtils["make-iter-cards-fn"]({"foundation", "tableau", "stock"})
 local _local_2_ = CardGameUtils["make-card-util-fns"]({value = {king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_2_["card-value"] local card_color = _local_2_["card-color"] local card_rank = _local_2_["card-rank"]
 local card_suit = _local_2_["card-suit"] local rank_value = _local_2_["rank-value"] local suit_color = _local_2_["suit-color"]
 local card_face_up_3f = _local_2_["card-face-up?"] local card_face_down_3f = _local_2_["card-face-down?"]
 local flip_face_up = _local_2_["flip-face-up"]




 local winning_foundation_sequence_3f
 do
 local valid_sequence_3f

 local function _4_(next_card, _3_) local last_card = _3_[1]
 return ((card_suit(next_card) == card_suit(last_card)) and (card_value(next_card) == (1 + card_value(last_card)))) end valid_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_4_)


 local function _5_(sequence)
 return ((rank_value("king") == #sequence) and valid_sequence_3f(sequence)) end winning_foundation_sequence_3f = _5_ end


 local function new_game_state()
 return {stock = {{}}, foundation = {{}, {}, {}, {}}, tableau = {{}, {}, {}, {}, {}}, discard = {{}}, hand = {{}}, moves = 0} end






 M.build = function(_config, _3fseed)
 math.randomseed((_3fseed or os.time()))
 local deck = table.shuffle(Deck.Standard52.build()) local deck0, head = nil, nil



 do local d, h = {}, {} for _, c in ipairs(deck) do

 local _6_ = card_value(c) if (_6_ == 1) then
 if ((_G.type(h) == "table") and (h[1] == nil)) then
 d, h = d, table.set(h, 1, c) else local _0 = h
 d, h = table.insert(d, c), h end elseif (_6_ == 2) then
 if ((_G.type(h) == "table") and true and (h[2] == nil)) then local _0 = h[1]
 d, h = d, table.set(h, 2, c) else local _0 = h
 d, h = table.insert(d, c), h end elseif (_6_ == 3) then
 if ((_G.type(h) == "table") and true and true and (h[3] == nil)) then local _0 = h[1] local _1 = h[2]
 d, h = d, table.set(h, 3, c) else local _0 = h
 d, h = table.insert(d, c), h end elseif (_6_ == 4) then
 if ((_G.type(h) == "table") and true and true and true and (h[4] == nil)) then local _0 = h[1] local _1 = h[2] local _2 = h[3]
 d, h = d, table.set(h, 4, c) else local _0 = h
 d, h = table.insert(d, c), h end elseif (nil ~= _6_) then local n = _6_
 d, h = table.insert(d, c), h else d, h = nil end end deck0, head = d, h end
 local state = new_game_state()
 do local tbl_19_auto = deck0 for _, c in ipairs(head) do local val_20_auto = c table.insert(tbl_19_auto, val_20_auto) end end
 state["stock"][1] = deck0
 return state end

 M.Action.deal = function(state)
 local moves do local t = {} for i = 4, 1, -1 do
 t = table.join(t, {{"face-up", {"stock", 1, "top"}}, {"move", {"stock", 1, "top"}, {"foundation", i, "top"}}}) end moves = t end

 table.join(moves, {{"face-up", {"stock", 1, "top"}}})
 return apply_events(clone(state), moves) end

 local function check_pick_up(state, pick_up_from)
 if ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "stock") and (pick_up_from[2] == 1) and (nil ~= pick_up_from[3])) then local n = pick_up_from[3]
 return {table.last(state.stock[1])} elseif ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "tableau") and (nil ~= pick_up_from[2]) and (nil ~= pick_up_from[3])) then local col_n = pick_up_from[2] local card_n = pick_up_from[3]
 if (card_n == #state.tableau[col_n]) then
 return {table.last(state.tableau[col_n])} else return nil end elseif ((_G.type(pick_up_from) == "table") and (nil ~= pick_up_from[1])) then local field = pick_up_from[1]
 local function _20_() local data_5_auto = {field = field} local resolve_6_auto local function _13_(name_7_auto) local _14_ = data_5_auto[name_7_auto] local and_15_ = (nil ~= _14_) if and_15_ then local t_8_auto = _14_ and_15_ = ("table" == type(t_8_auto)) end if and_15_ then local t_8_auto = _14_ local _17_ = getmetatable(t_8_auto) if ((_G.type(_17_) == "table") and (nil ~= _17_.__tostring)) then local f_9_auto = _17_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _17_ return vim.inspect(t_8_auto) end elseif (nil ~= _14_) then local v_11_auto = _14_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _13_ return string.gsub("May not pick up from #{field}", "#{(.-)}", resolve_6_auto) end return nil, _20_() else return nil end end

 local function put_down(state, pick_up_from, dropped_on, held)
 local _22_, _23_, _24_ = pick_up_from, dropped_on, held local and_25_ = (((_G.type(_22_) == "table") and (nil ~= _22_[1]) and (nil ~= _22_[2]) and (nil ~= _22_[3])) and ((_G.type(_23_) == "table") and (_22_[1] == _23_[1]) and (_22_[2] == _23_[2]) and (nil ~= _23_[3])) and true) if and_25_ then local field = _22_[1] local col = _22_[2] local from_n = _22_[3] local on_n = _23_[3] local _ = _24_ and_25_ = (from_n == (1 + on_n)) end if and_25_ then local field = _22_[1] local col = _22_[2] local from_n = _22_[3] local on_n = _23_[3] local _ = _24_


 return nil elseif (((_G.type(_22_) == "table") and (_22_[1] == "tableau")) and ((_G.type(_23_) == "table") and (_23_[1] == "tableau")) and true) then local _ = _24_



 return nil elseif (((_G.type(_22_) == "table") and (_22_[1] == "stock")) and ((_G.type(_23_) == "table") and (_23_[1] == "tableau") and (nil ~= _23_[2]) and true) and ((_G.type(_24_) == "table") and (nil ~= _24_[1]))) then local t_col = _23_[2] local _ = _23_[3] local held_card = _24_[1]



 local moves = {{"move", {"stock", 1, "top"}, {"tableau", t_col, "top"}}} local _0
 if (1 < #state.stock[1]) then
 _0 = table.insert(moves, {"face-up", {"stock", 1, "top"}}) else _0 = nil end
 return apply_events(inc_moves(clone(state)), moves) elseif (true and ((_G.type(_23_) == "table") and (_23_[1] == "foundation") and (nil ~= _23_[2]) and (nil ~= _23_[3])) and ((_G.type(_24_) == "table") and (nil ~= _24_[1]))) then local _ = _22_ local f_col = _23_[2] local f_card = _23_[3] local held_card = _24_[1]






 local onto_card = state.foundation[f_col][f_card] local want_value
 do local _28_ = ((f_col + card_value(onto_card)) % 13) if (_28_ == 0) then want_value = 1 elseif (nil ~= _28_) then local n = _28_

 want_value = n else want_value = nil end end
 Logger.info({"held", card_value(held_card), "onto", card_value(onto_card), "want", want_value})


 if (13 == card_value(onto_card)) then
 local function _37_() local data_5_auto = {} local resolve_6_auto local function _30_(name_7_auto) local _31_ = data_5_auto[name_7_auto] local and_32_ = (nil ~= _31_) if and_32_ then local t_8_auto = _31_ and_32_ = ("table" == type(t_8_auto)) end if and_32_ then local t_8_auto = _31_ local _34_ = getmetatable(t_8_auto) if ((_G.type(_34_) == "table") and (nil ~= _34_.__tostring)) then local f_9_auto = _34_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _34_ return vim.inspect(t_8_auto) end elseif (nil ~= _31_) then local v_11_auto = _31_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _30_ return string.gsub("Foundation is complete", "#{(.-)}", resolve_6_auto) end return nil, _37_() else
 if (card_value(held_card) == want_value) then
 local moves = {{"move", pick_up_from, {"foundation", f_col, "top"}}} local _0
 if ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "stock")) then
 if (2 < #state.stock[1]) then
 _0 = table.insert(moves, {"face-up", {"stock", 1, "top"}}) else _0 = nil end else _0 = nil end
 return apply_events(inc_moves(clone(state)), moves) else


 local function _47_() local data_5_auto = {["want-value"] = want_value} local resolve_6_auto local function _40_(name_7_auto) local _41_ = data_5_auto[name_7_auto] local and_42_ = (nil ~= _41_) if and_42_ then local t_8_auto = _41_ and_42_ = ("table" == type(t_8_auto)) end if and_42_ then local t_8_auto = _41_ local _44_ = getmetatable(t_8_auto) if ((_G.type(_44_) == "table") and (nil ~= _44_.__tostring)) then local f_9_auto = _44_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _44_ return vim.inspect(t_8_auto) end elseif (nil ~= _41_) then local v_11_auto = _41_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _40_ return string.gsub("Foundation wants a #{want-value}", "#{(.-)}", resolve_6_auto) end return nil, _47_() end end else return nil end end

 M.Action.move = function(state, pick_up_from, put_down_on)
 local function _51_(...) local _52_ = ... if (nil ~= _52_) then local held = _52_ local function _53_(...) local _54_, _55_ = ... if ((nil ~= _54_) and (nil ~= _55_)) then local next_state = _54_ local moves = _55_


 return next_state, moves else local __85_auto = _54_ return ... end end return _53_(put_down(state, pick_up_from, put_down_on, held)) else local __85_auto = _52_ return ... end end return _51_(check_pick_up(state, pick_up_from)) end

 M.Query["liftable?"] = function(state, location)
 return not (nil == check_pick_up(state, location)) end

 M.Query["droppable?"] = function(state, location)
 if ((_G.type(location) == "table") and (nil ~= location[1])) then local field = location[1]
 return eq_any_3f(field, {"foundation", "tableau"}) else local _ = location return false end end


 M.Query["game-ended?"] = function(state) local won_3f = true
 for i = 1, 4 do
 won_3f = (won_3f and winning_foundation_sequence_3f(state.foundation[i])) end return won_3f end

 M.Query["game-result"] = function(state)
 return M.Query["game-ended?"](state) end

 return M