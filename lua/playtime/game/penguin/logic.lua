
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}



 local _local_2_ = CardGameUtils local location_contents = _local_2_["location-contents"]
 local inc_moves = _local_2_["inc-moves"]
 local apply_events = _local_2_["apply-events"]
 M["iter-cards"] = CardGameUtils["make-iter-cards-fn"]({"draw", "tableau", "cell", "foundation"})
 local _local_3_ = CardGameUtils["make-card-util-fns"]({value = {king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_3_["card-value"] local card_color = _local_3_["card-color"] local card_rank = _local_3_["card-rank"]
 local card_suit = _local_3_["card-suit"] local rank_value = _local_3_["rank-value"] local suit_color = _local_3_["suit-color"]
 local card_face_up_3f = _local_3_["card-face-up?"] local card_face_down_3f = _local_3_["card-face-down?"]




 local function new_game_state()
 return {draw = {{}}, foundation = {{}, {}, {}, {}}, cell = {{}, {}, {}, {}, {}, {}, {}}, tableau = {{}, {}, {}, {}, {}, {}, {}}, moves = 0} end





 M.build = function(_config, _3fseed) _G.assert((nil ~= _config), "Missing argument _config on fnl/playtime/game/penguin/logic.fnl:30")
 math.randomseed((_3fseed or os.time()))
 local deck = table.shuffle(Deck.Standard52.build())

 local state = new_game_state()
 do end (state)["draw"][1] = deck
 return state end

 local valid_sequence_3f

 local function _6_(next_card, _4_) local _arg_5_ = _4_ local last_card = _arg_5_[1]
 local last_suit = card_suit(last_card)
 local last_value = card_value(last_card)
 local next_suit = card_suit(next_card)
 local next_value = card_value(next_card)
 return ((last_suit == next_suit) and (last_value == (next_value + 1))) end valid_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_6_)


 local winning_foundation_sequence_3f
 do
 local valid_sequence_3f0

 local function _9_(next_card, _7_) local _arg_8_ = _7_ local last_card = _arg_8_[1]
 return ((card_suit(next_card) == card_suit(last_card)) and (card_value(next_card) == (1 + card_value(last_card)))) end valid_sequence_3f0 = CardGameUtils["make-valid-sequence?-fn"](_9_)

 local function _10_(sequence)
 return ((rank_value("king") == #sequence) and valid_sequence_3f0(sequence)) end winning_foundation_sequence_3f = _10_ end


 M.Action.deal = function(state)





 local draw = state.draw[1] local beak_card_index
 do local first_ace_index = nil for i, c in ipairs(draw) do if first_ace_index then break end
 if (1 == card_value(c)) then first_ace_index = i else first_ace_index = nil end end beak_card_index = first_ace_index end
 local beak_card = draw[beak_card_index] local _

 do
 table.remove(draw, beak_card_index)
 _ = table.insert(draw, beak_card) end local moves
 do local moves0, t_col, row, f_col = {}, 1, 1, 1 for i = #state.draw[1], 1, -1 do

 local card = state.draw[1][i] local move
 if ((card_rank(beak_card) == card_rank(card)) and not (i == #draw)) then

 move = {"move", {"draw", 1, i}, {"foundation", f_col, 1}} else
 move = {"move", {"draw", 1, i}, {"tableau", t_col, row}} end local t_col0, row0, f_col0 = nil, nil, nil
 if ((_G.type(move) == "table") and (move[1] == "move") and true and ((_G.type(move[3]) == "table") and (move[3][1] == "foundation"))) then local _0 = move[2]
 t_col0, row0, f_col0 = t_col, row, (f_col + 1) else local _0 = move
 local _13_ if (t_col == 7) then _13_ = 1 else _13_ = (t_col + 1) end
 local _15_ if (t_col == 7) then _15_ = (row + 1) else _15_ = row end t_col0, row0, f_col0 = _13_, _15_, f_col end

 moves0, t_col, row, f_col = table.join(moves0, {move, {"face-up", table.last(move)}}), t_col0, row0, f_col0 end moves = moves0, t_col, row, f_col end

 local next_state, moves0 = apply_events(clone(state), moves)
 return next_state, moves0 end

 local function check_pick_up(state, pick_up_from)
 if ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "tableau") and (nil ~= pick_up_from[2]) and (nil ~= pick_up_from[3])) then local col_n = pick_up_from[2] local card_n = pick_up_from[3]

 local remaining, held = table.split(state.tableau[col_n], card_n)
 Logger.info({["pick-up-from"] = pick_up_from})
 if valid_sequence_3f(held) then
 return held else
 if ((_G.type(held) == "table") and (held[1] == nil)) then
 local function _24_() local data_5_auto = {["col-n"] = col_n} local resolve_6_auto local function _18_(name_7_auto) local _19_ = data_5_auto[name_7_auto] local function _20_() local t_8_auto = _19_ return ("table" == type(t_8_auto)) end if ((nil ~= _19_) and _20_()) then local t_8_auto = _19_ local _21_ = getmetatable(t_8_auto) if ((_G.type(_21_) == "table") and (nil ~= _21_.__tostring)) then local f_9_auto = _21_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _21_ return vim.inspect(t_8_auto) end elseif (nil ~= _19_) then local v_11_auto = _19_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _18_ return string.gsub("No cards to pick up from tableau column #{col-n}", "#{(.-)}", resolve_6_auto) end return nil, _24_() else local _ = held
 local function _31_() local data_5_auto = {} local resolve_6_auto local function _25_(name_7_auto) local _26_ = data_5_auto[name_7_auto] local function _27_() local t_8_auto = _26_ return ("table" == type(t_8_auto)) end if ((nil ~= _26_) and _27_()) then local t_8_auto = _26_ local _28_ = getmetatable(t_8_auto) if ((_G.type(_28_) == "table") and (nil ~= _28_.__tostring)) then local f_9_auto = _28_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _28_ return vim.inspect(t_8_auto) end elseif (nil ~= _26_) then local v_11_auto = _26_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _25_ return string.gsub("Must pick up run of same suit, descending rank", "#{(.-)}", resolve_6_auto) end return nil, _31_() end end elseif ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "cell") and (nil ~= pick_up_from[2]) and (pick_up_from[3] == 1)) then local col_n = pick_up_from[2]


 local remaining, held = table.split(state.cell[col_n], 1)
 local _34_ = #held if (_34_ == 1) then
 return held elseif (_34_ == 0) then
 local function _41_() local data_5_auto = {} local resolve_6_auto local function _35_(name_7_auto) local _36_ = data_5_auto[name_7_auto] local function _37_() local t_8_auto = _36_ return ("table" == type(t_8_auto)) end if ((nil ~= _36_) and _37_()) then local t_8_auto = _36_ local _38_ = getmetatable(t_8_auto) if ((_G.type(_38_) == "table") and (nil ~= _38_.__tostring)) then local f_9_auto = _38_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _38_ return vim.inspect(t_8_auto) end elseif (nil ~= _36_) then local v_11_auto = _36_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _35_ return string.gsub("No card to pick up from free cell", "#{(.-)}", resolve_6_auto) end return nil, _41_() elseif (nil ~= _34_) then local n = _34_
 local function _48_() local data_5_auto = {} local resolve_6_auto local function _42_(name_7_auto) local _43_ = data_5_auto[name_7_auto] local function _44_() local t_8_auto = _43_ return ("table" == type(t_8_auto)) end if ((nil ~= _43_) and _44_()) then local t_8_auto = _43_ local _45_ = getmetatable(t_8_auto) if ((_G.type(_45_) == "table") and (nil ~= _45_.__tostring)) then local f_9_auto = _45_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _45_ return vim.inspect(t_8_auto) end elseif (nil ~= _43_) then local v_11_auto = _43_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _42_ return string.gsub("May only pick up one card at a time from free cell", "#{(.-)}", resolve_6_auto) end return nil, _48_() else return nil end elseif ((_G.type(pick_up_from) == "table") and (nil ~= pick_up_from[1])) then local field = pick_up_from[1]


 local function _56_() local data_5_auto = {field = field} local resolve_6_auto local function _50_(name_7_auto) local _51_ = data_5_auto[name_7_auto] local function _52_() local t_8_auto = _51_ return ("table" == type(t_8_auto)) end if ((nil ~= _51_) and _52_()) then local t_8_auto = _51_ local _53_ = getmetatable(t_8_auto) if ((_G.type(_53_) == "table") and (nil ~= _53_.__tostring)) then local f_9_auto = _53_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _53_ return vim.inspect(t_8_auto) end elseif (nil ~= _51_) then local v_11_auto = _51_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _50_ return string.gsub("May not pick up from #{field}", "#{(.-)}", resolve_6_auto) end return nil, _56_() else return nil end end

 local function put_down(state, pick_up_from, dropped_on, held)
 local _58_, _59_, _60_ = pick_up_from, dropped_on, held local function _61_() local field = _58_[1] local col = _58_[2] local from_n = _58_[3] local on_n = _59_[3] local _ = _60_ return (from_n == (1 + on_n)) end if ((((_G.type(_58_) == "table") and (nil ~= _58_[1]) and (nil ~= _58_[2]) and (nil ~= _58_[3])) and ((_G.type(_59_) == "table") and (_58_[1] == _59_[1]) and (_58_[2] == _59_[2]) and (nil ~= _59_[3])) and true) and _61_()) then local field = _58_[1] local col = _58_[2] local from_n = _58_[3] local on_n = _59_[3] local _ = _60_


 return nil else local function _62_() local _ = _58_ local field = _59_[1] local col_n = _59_[2] local card_n = _59_[3] local _0 = _60_ return not (card_n == #state[field][col_n]) end if ((true and ((_G.type(_59_) == "table") and (nil ~= _59_[1]) and (nil ~= _59_[2]) and (nil ~= _59_[3])) and true) and _62_()) then local _ = _58_ local field = _59_[1] local col_n = _59_[2] local card_n = _59_[3] local _0 = _60_



 local function _69_() local data_5_auto = {} local resolve_6_auto local function _63_(name_7_auto) local _64_ = data_5_auto[name_7_auto] local function _65_() local t_8_auto = _64_ return ("table" == type(t_8_auto)) end if ((nil ~= _64_) and _65_()) then local t_8_auto = _64_ local _66_ = getmetatable(t_8_auto) if ((_G.type(_66_) == "table") and (nil ~= _66_.__tostring)) then local f_9_auto = _66_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _66_ return vim.inspect(t_8_auto) end elseif (nil ~= _64_) then local v_11_auto = _64_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _63_ return string.gsub("Must place cards on the bottom of a cascade", "#{(.-)}", resolve_6_auto) end return nil, _69_() elseif (true and ((_G.type(_59_) == "table") and (_59_[1] == "foundation")) and ((_G.type(_60_) == "table") and (nil ~= _60_[1]) and (nil ~= _60_[2]))) then local _ = _58_ local multiple = _60_[1] local cards = _60_[2]




 local function _76_() local data_5_auto = {} local resolve_6_auto local function _70_(name_7_auto) local _71_ = data_5_auto[name_7_auto] local function _72_() local t_8_auto = _71_ return ("table" == type(t_8_auto)) end if ((nil ~= _71_) and _72_()) then local t_8_auto = _71_ local _73_ = getmetatable(t_8_auto) if ((_G.type(_73_) == "table") and (nil ~= _73_.__tostring)) then local f_9_auto = _73_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _73_ return vim.inspect(t_8_auto) end elseif (nil ~= _71_) then local v_11_auto = _71_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _70_ return string.gsub("May only place cards on a foundation one at a time", "#{(.-)}", resolve_6_auto) end return nil, _76_() elseif (true and ((_G.type(_59_) == "table") and (_59_[1] == "foundation") and (nil ~= _59_[2]) and (_59_[3] == 0)) and ((_G.type(_60_) == "table") and (nil ~= _60_[1]) and (_60_[2] == nil))) then local _ = _58_ local f_col_n = _59_[2] local card = _60_[1]



 if ((_G.type(card) == "table") and true and (card[2] == 1)) then local _suit = card[1]
 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col_n, 1}}}) else local _0 = card


 local function _83_() local data_5_auto = {} local resolve_6_auto local function _77_(name_7_auto) local _78_ = data_5_auto[name_7_auto] local function _79_() local t_8_auto = _78_ return ("table" == type(t_8_auto)) end if ((nil ~= _78_) and _79_()) then local t_8_auto = _78_ local _80_ = getmetatable(t_8_auto) if ((_G.type(_80_) == "table") and (nil ~= _80_.__tostring)) then local f_9_auto = _80_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _80_ return vim.inspect(t_8_auto) end elseif (nil ~= _78_) then local v_11_auto = _78_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _77_ return string.gsub("Must build foundations same suit, 1, 2, ... 10, J, Q, K", "#{(.-)}", resolve_6_auto) end return nil, _83_() end elseif (true and ((_G.type(_59_) == "table") and (_59_[1] == "foundation") and (nil ~= _59_[2]) and (nil ~= _59_[3])) and ((_G.type(_60_) == "table") and (nil ~= _60_[1]) and (_60_[2] == nil))) then local _ = _58_ local f_col_n = _59_[2] local f_card_n = _59_[3] local new_card = _60_[1]



 local onto_card = location_contents(state, dropped_on)
 local _85_, _86_ = onto_card, new_card local function _87_() local suit = _85_[1] return (-1 == (card_value(onto_card) - card_value(new_card))) end if ((((_G.type(_85_) == "table") and (nil ~= _85_[1])) and ((_G.type(_86_) == "table") and (_85_[1] == _86_[1]))) and _87_()) then local suit = _85_[1]

 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col_n, (f_card_n + 1)}}}) else local _0 = _85_


 local function _94_() local data_5_auto = {} local resolve_6_auto local function _88_(name_7_auto) local _89_ = data_5_auto[name_7_auto] local function _90_() local t_8_auto = _89_ return ("table" == type(t_8_auto)) end if ((nil ~= _89_) and _90_()) then local t_8_auto = _89_ local _91_ = getmetatable(t_8_auto) if ((_G.type(_91_) == "table") and (nil ~= _91_.__tostring)) then local f_9_auto = _91_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _91_ return vim.inspect(t_8_auto) end elseif (nil ~= _89_) then local v_11_auto = _89_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _88_ return string.gsub("Must build foundations in same-suit, ascending order", "#{(.-)}", resolve_6_auto) end return nil, _94_() end elseif (true and ((_G.type(_59_) == "table") and (_59_[1] == "cell")) and ((_G.type(_60_) == "table") and (nil ~= _60_[1]) and (nil ~= _60_[2]))) then local _ = _58_ local multiple = _60_[1] local cards = _60_[2]


 local function _102_() local data_5_auto = {} local resolve_6_auto local function _96_(name_7_auto) local _97_ = data_5_auto[name_7_auto] local function _98_() local t_8_auto = _97_ return ("table" == type(t_8_auto)) end if ((nil ~= _97_) and _98_()) then local t_8_auto = _97_ local _99_ = getmetatable(t_8_auto) if ((_G.type(_99_) == "table") and (nil ~= _99_.__tostring)) then local f_9_auto = _99_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _99_ return vim.inspect(t_8_auto) end elseif (nil ~= _97_) then local v_11_auto = _97_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _96_ return string.gsub("May only place single cards on a cell", "#{(.-)}", resolve_6_auto) end return nil, _102_() else local function _103_() local _ = _58_ local col_n = _59_[2] local card_n = _59_[3] local _0 = _60_ return not (0 == card_n) end if ((true and ((_G.type(_59_) == "table") and (_59_[1] == "cell") and (nil ~= _59_[2]) and (nil ~= _59_[3])) and true) and _103_()) then local _ = _58_ local col_n = _59_[2] local card_n = _59_[3] local _0 = _60_

 local function _110_() local data_5_auto = {} local resolve_6_auto local function _104_(name_7_auto) local _105_ = data_5_auto[name_7_auto] local function _106_() local t_8_auto = _105_ return ("table" == type(t_8_auto)) end if ((nil ~= _105_) and _106_()) then local t_8_auto = _105_ local _107_ = getmetatable(t_8_auto) if ((_G.type(_107_) == "table") and (nil ~= _107_.__tostring)) then local f_9_auto = _107_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _107_ return vim.inspect(t_8_auto) end elseif (nil ~= _105_) then local v_11_auto = _105_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _104_ return string.gsub("May only place single cards on a cell", "#{(.-)}", resolve_6_auto) end return nil, _110_() elseif (true and ((_G.type(_59_) == "table") and (_59_[1] == "cell") and (nil ~= _59_[2]) and (_59_[3] == 0)) and ((_G.type(_60_) == "table") and (nil ~= _60_[1]) and (_60_[2] == nil))) then local _ = _58_ local col_n = _59_[2] local new_card = _60_[1]


 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"cell", col_n, 1}}}) else local function _111_() local a = _58_[2] local b = _59_[2] local _ = _60_ return not (a == b) end if ((((_G.type(_58_) == "table") and (_58_[1] == "tableau") and (nil ~= _58_[2]) and (_58_[3] == 1)) and ((_G.type(_59_) == "table") and (_59_[1] == "tableau") and (nil ~= _59_[2]) and (_59_[3] == 0)) and true) and _111_()) then local a = _58_[2] local b = _59_[2] local _ = _60_






 local from_col = state.tableau[a] local moves
 do local tbl_18_auto = {} local i_19_auto = 0 for i, _card in ipairs(from_col) do
 local val_20_auto = {"move", {"tableau", a, i}, {"tableau", b, i}} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end moves = tbl_18_auto end
 return apply_events(clone(state), moves, {["unsafely?"] = true}) elseif (((_G.type(_58_) == "table") and (nil ~= _58_[1]) and (nil ~= _58_[2]) and (nil ~= _58_[3])) and ((_G.type(_59_) == "table") and (_59_[1] == "tableau") and (nil ~= _59_[2]) and (_59_[3] == 0)) and ((_G.type(_60_) == "table") and ((_G.type(_60_[1]) == "table") and true and (_60_[1][2] == "king")))) then local f_field = _58_[1] local f_col = _58_[2] local f_card_n = _58_[3] local t_col = _59_[2] local _suit = _60_[1][1] local held0 = _60_




 local moves do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, #held0 do
 local val_20_auto = {"move", {f_field, f_col, (f_card_n + (i - 1))}, {"tableau", t_col, i}} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end moves = tbl_18_auto end


 local next_state = apply_events(inc_moves(clone(state)), moves)


 local new_run = next_state.tableau[t_col]
 if valid_sequence_3f(new_run) then
 return next_state, moves else
 local function _120_() local data_5_auto = {} local resolve_6_auto local function _114_(name_7_auto) local _115_ = data_5_auto[name_7_auto] local function _116_() local t_8_auto = _115_ return ("table" == type(t_8_auto)) end if ((nil ~= _115_) and _116_()) then local t_8_auto = _115_ local _117_ = getmetatable(t_8_auto) if ((_G.type(_117_) == "table") and (nil ~= _117_.__tostring)) then local f_9_auto = _117_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _117_ return vim.inspect(t_8_auto) end elseif (nil ~= _115_) then local v_11_auto = _115_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _114_ return string.gsub("Must build piles in same suit, descending rank", "#{(.-)}", resolve_6_auto) end return nil, _120_() end elseif (((_G.type(_58_) == "table") and (nil ~= _58_[1]) and (nil ~= _58_[2]) and (nil ~= _58_[3])) and ((_G.type(_59_) == "table") and (_59_[1] == "tableau") and (nil ~= _59_[2]) and (_59_[3] == 0)) and true) then local f_field = _58_[1] local f_col = _58_[2] local f_card_n = _58_[3] local t_col = _59_[2] local _ = _60_


 local function _128_() local data_5_auto = {} local resolve_6_auto local function _122_(name_7_auto) local _123_ = data_5_auto[name_7_auto] local function _124_() local t_8_auto = _123_ return ("table" == type(t_8_auto)) end if ((nil ~= _123_) and _124_()) then local t_8_auto = _123_ local _125_ = getmetatable(t_8_auto) if ((_G.type(_125_) == "table") and (nil ~= _125_.__tostring)) then local f_9_auto = _125_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _125_ return vim.inspect(t_8_auto) end elseif (nil ~= _123_) then local v_11_auto = _123_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _122_ return string.gsub("May only place kings in empty columns", "#{(.-)}", resolve_6_auto) end return nil, _128_() elseif (((_G.type(_58_) == "table") and (nil ~= _58_[1]) and (nil ~= _58_[2]) and (nil ~= _58_[3])) and ((_G.type(_59_) == "table") and (_59_[1] == "tableau") and (nil ~= _59_[2]) and (nil ~= _59_[3])) and (nil ~= _60_)) then local f_field = _58_[1] local f_col = _58_[2] local f_card_n = _58_[3] local t_col = _59_[2] local t_card_n = _59_[3] local held0 = _60_



 local moves do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, #held0 do
 local val_20_auto = {"move", {f_field, f_col, (f_card_n + (i - 1))}, {"tableau", t_col, (t_card_n + i)}} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end moves = tbl_18_auto end


 local next_state = apply_events(inc_moves(clone(state)), moves)


 local _, new_run = table.split(next_state.tableau[t_col], t_card_n)
 if valid_sequence_3f(new_run) then
 return next_state, moves else
 local function _136_() local data_5_auto = {} local resolve_6_auto local function _130_(name_7_auto) local _131_ = data_5_auto[name_7_auto] local function _132_() local t_8_auto = _131_ return ("table" == type(t_8_auto)) end if ((nil ~= _131_) and _132_()) then local t_8_auto = _131_ local _133_ = getmetatable(t_8_auto) if ((_G.type(_133_) == "table") and (nil ~= _133_.__tostring)) then local f_9_auto = _133_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _133_ return vim.inspect(t_8_auto) end elseif (nil ~= _131_) then local v_11_auto = _131_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _130_ return string.gsub("Must build piles in same suit, descending rank", "#{(.-)}", resolve_6_auto) end return nil, _136_() end else local _ = _58_


 local function _144_() local data_5_auto = {["dropped-on"] = dropped_on} local resolve_6_auto local function _138_(name_7_auto) local _139_ = data_5_auto[name_7_auto] local function _140_() local t_8_auto = _139_ return ("table" == type(t_8_auto)) end if ((nil ~= _139_) and _140_()) then local t_8_auto = _139_ local _141_ = getmetatable(t_8_auto) if ((_G.type(_141_) == "table") and (nil ~= _141_.__tostring)) then local f_9_auto = _141_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _141_ return vim.inspect(t_8_auto) end elseif (nil ~= _139_) then local v_11_auto = _139_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _138_ return string.gsub("No putdown for #{dropped-on}", "#{(.-)}", resolve_6_auto) end return nil, _144_() end end end end end

 M.Action.move = function(state, pick_up_from, put_down_on)
 local function _146_(...) local _147_ = ... if (nil ~= _147_) then local held = _147_ local function _148_(...) local _149_, _150_ = ... if ((nil ~= _149_) and (nil ~= _150_)) then local next_state = _149_ local moves = _150_


 return next_state, moves else local __84_auto = _149_ return ... end end return _148_(put_down(state, pick_up_from, put_down_on, held)) else local __84_auto = _147_ return ... end end return _146_(check_pick_up(state, pick_up_from)) end

 M.Plan["next-move-to-foundation"] = function(state)
 local speculative_state = clone(state) local check_locations
 do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 7 do local val_20_auto = {"cell", i} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end check_locations = tbl_18_auto end local _
 do local tbl_17_auto = check_locations for i = 1, 7 do table.insert(tbl_17_auto, {"tableau", i}) end _ = tbl_17_auto end local min_values
 do local min_vals = {spades = math.huge, hearts = math.huge, diamonds = math.huge, clubs = math.huge} for _l, card in M["iter-cards"](speculative_state, {"cell", "tableau"}) do


 local suit = card_suit(card)
 local val = card_value(card)
 min_vals = table.set(min_vals, suit, math.min(val, min_vals[suit])) end min_values = min_vals end local source_locations
 do local tbl_18_auto = {} local i_19_auto = 0 for _0, _154_ in ipairs(check_locations) do local _each_155_ = _154_ local field = _each_155_[1] local col = _each_155_[2] local val_20_auto
 do local card_n = #speculative_state[field][col]
 local _156_ = speculative_state[field][col][card_n] if (nil ~= _156_) then local card = _156_
 local suit = card_suit(card)
 if (card_value(card) == min_values[suit]) then
 val_20_auto = {field, col, card_n} else val_20_auto = nil end else val_20_auto = nil end end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end source_locations = tbl_18_auto end local potential_moves
 do local moves = {} for _0, from in ipairs(source_locations) do
 local tbl_17_auto = moves for i = 1, 4 do
 local function _161_() local _160_ = speculative_state.foundation[i] if ((_G.type(_160_) == "table") and (_160_[1] == nil)) then
 return {from, {"foundation", i, 0}} elseif (nil ~= _160_) then local cards = _160_
 return {from, {"foundation", i, #cards}} else return nil end end table.insert(tbl_17_auto, _161_()) end moves = tbl_17_auto end potential_moves = moves end
 local actions = nil for _0, _163_ in ipairs(potential_moves) do local _each_164_ = _163_ local pick_up_from = _each_164_[1] local put_down_on = _each_164_[2] if actions then break end
 local function _165_(...) local _166_ = ... if (nil ~= _166_) then local speculative_state0 = _166_

 return {pick_up_from, put_down_on} else local __84_auto = _166_ return ... end end actions = _165_(M.Action.move(clone(state), pick_up_from, put_down_on)) end return actions end

 M.Query["liftable?"] = function(state, location)
 return not (nil == check_pick_up(state, location)) end

 M.Query["droppable?"] = function(state, location)
 if ((_G.type(location) == "table") and (nil ~= location[1])) then local field = location[1]
 return eq_any_3f(field, {"tableau", "cell", "foundation"}) else local _ = location return false end end


 M.Query["game-ended?"] = function(state) local won_3f = true
 for i = 1, 4 do
 won_3f = (won_3f and winning_foundation_sequence_3f(location_contents(state, {"foundation", i}))) end return won_3f end

 M.Query["game-result"] = function(state)
 return M.Query["game-ended?"](state) end

 return M