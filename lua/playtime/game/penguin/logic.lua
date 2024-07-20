
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}



 local location_contents = CardGameUtils["location-contents"]
 local inc_moves = CardGameUtils["inc-moves"]
 local apply_events = CardGameUtils["apply-events"]
 M["iter-cards"] = CardGameUtils["make-iter-cards-fn"]({"draw", "tableau", "cell", "foundation"})
 local _local_2_ = CardGameUtils["make-card-util-fns"]({value = {king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_2_["card-value"] local card_color = _local_2_["card-color"] local card_rank = _local_2_["card-rank"]
 local card_suit = _local_2_["card-suit"] local rank_value = _local_2_["rank-value"] local suit_color = _local_2_["suit-color"]
 local card_face_up_3f = _local_2_["card-face-up?"] local card_face_down_3f = _local_2_["card-face-down?"]




 local function new_game_state()
 return {draw = {{}}, foundation = {{}, {}, {}, {}}, cell = {{}, {}, {}, {}, {}, {}, {}}, tableau = {{}, {}, {}, {}, {}, {}, {}}, moves = 0} end





 M.build = function(_config, _3fseed)
 math.randomseed((_3fseed or os.time()))
 local deck = table.shuffle(Deck.Standard52.build())

 local state = new_game_state()
 state["draw"][1] = deck
 return state end

 local valid_sequence_3f

 local function _4_(next_card, _3_) local last_card = _3_[1]
 local last_suit = card_suit(last_card)
 local last_value = card_value(last_card)
 local next_suit = card_suit(next_card)
 local next_value = card_value(next_card)
 return ((last_suit == next_suit) and (last_value == (next_value + 1))) end valid_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_4_)


 local winning_foundation_sequence_3f
 do
 local valid_sequence_3f0

 local function _6_(next_card, _5_) local last_card = _5_[1]
 return ((card_suit(next_card) == card_suit(last_card)) and (card_value(next_card) == (1 + card_value(last_card)))) end valid_sequence_3f0 = CardGameUtils["make-valid-sequence?-fn"](_6_)

 local function _7_(sequence)
 return ((rank_value("king") == #sequence) and valid_sequence_3f0(sequence)) end winning_foundation_sequence_3f = _7_ end


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
 local _10_ if (t_col == 7) then _10_ = 1 else _10_ = (t_col + 1) end
 local _12_ if (t_col == 7) then _12_ = (row + 1) else _12_ = row end t_col0, row0, f_col0 = _10_, _12_, f_col end

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
 local function _22_() local data_5_auto = {["col-n"] = col_n} local resolve_6_auto local function _15_(name_7_auto) local _16_ = data_5_auto[name_7_auto] local and_17_ = (nil ~= _16_) if and_17_ then local t_8_auto = _16_ and_17_ = ("table" == type(t_8_auto)) end if and_17_ then local t_8_auto = _16_ local _19_ = getmetatable(t_8_auto) if ((_G.type(_19_) == "table") and (nil ~= _19_.__tostring)) then local f_9_auto = _19_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _19_ return vim.inspect(t_8_auto) end elseif (nil ~= _16_) then local v_11_auto = _16_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _15_ return string.gsub("No cards to pick up from tableau column #{col-n}", "#{(.-)}", resolve_6_auto) end return nil, _22_() else local _ = held
 local function _30_() local data_5_auto = {} local resolve_6_auto local function _23_(name_7_auto) local _24_ = data_5_auto[name_7_auto] local and_25_ = (nil ~= _24_) if and_25_ then local t_8_auto = _24_ and_25_ = ("table" == type(t_8_auto)) end if and_25_ then local t_8_auto = _24_ local _27_ = getmetatable(t_8_auto) if ((_G.type(_27_) == "table") and (nil ~= _27_.__tostring)) then local f_9_auto = _27_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _27_ return vim.inspect(t_8_auto) end elseif (nil ~= _24_) then local v_11_auto = _24_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _23_ return string.gsub("Must pick up run of same suit, descending rank", "#{(.-)}", resolve_6_auto) end return nil, _30_() end end elseif ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "cell") and (nil ~= pick_up_from[2]) and (pick_up_from[3] == 1)) then local col_n = pick_up_from[2]


 local remaining, held = table.split(state.cell[col_n], 1)
 local _33_ = #held if (_33_ == 1) then
 return held elseif (_33_ == 0) then
 local function _41_() local data_5_auto = {} local resolve_6_auto local function _34_(name_7_auto) local _35_ = data_5_auto[name_7_auto] local and_36_ = (nil ~= _35_) if and_36_ then local t_8_auto = _35_ and_36_ = ("table" == type(t_8_auto)) end if and_36_ then local t_8_auto = _35_ local _38_ = getmetatable(t_8_auto) if ((_G.type(_38_) == "table") and (nil ~= _38_.__tostring)) then local f_9_auto = _38_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _38_ return vim.inspect(t_8_auto) end elseif (nil ~= _35_) then local v_11_auto = _35_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _34_ return string.gsub("No card to pick up from free cell", "#{(.-)}", resolve_6_auto) end return nil, _41_() elseif (nil ~= _33_) then local n = _33_
 local function _49_() local data_5_auto = {} local resolve_6_auto local function _42_(name_7_auto) local _43_ = data_5_auto[name_7_auto] local and_44_ = (nil ~= _43_) if and_44_ then local t_8_auto = _43_ and_44_ = ("table" == type(t_8_auto)) end if and_44_ then local t_8_auto = _43_ local _46_ = getmetatable(t_8_auto) if ((_G.type(_46_) == "table") and (nil ~= _46_.__tostring)) then local f_9_auto = _46_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _46_ return vim.inspect(t_8_auto) end elseif (nil ~= _43_) then local v_11_auto = _43_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _42_ return string.gsub("May only pick up one card at a time from free cell", "#{(.-)}", resolve_6_auto) end return nil, _49_() else return nil end elseif ((_G.type(pick_up_from) == "table") and (nil ~= pick_up_from[1])) then local field = pick_up_from[1]


 local function _58_() local data_5_auto = {field = field} local resolve_6_auto local function _51_(name_7_auto) local _52_ = data_5_auto[name_7_auto] local and_53_ = (nil ~= _52_) if and_53_ then local t_8_auto = _52_ and_53_ = ("table" == type(t_8_auto)) end if and_53_ then local t_8_auto = _52_ local _55_ = getmetatable(t_8_auto) if ((_G.type(_55_) == "table") and (nil ~= _55_.__tostring)) then local f_9_auto = _55_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _55_ return vim.inspect(t_8_auto) end elseif (nil ~= _52_) then local v_11_auto = _52_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _51_ return string.gsub("May not pick up from #{field}", "#{(.-)}", resolve_6_auto) end return nil, _58_() else return nil end end

 local function put_down(state, pick_up_from, dropped_on, held)
 local _60_, _61_, _62_ = pick_up_from, dropped_on, held local and_63_ = (((_G.type(_60_) == "table") and (nil ~= _60_[1]) and (nil ~= _60_[2]) and (nil ~= _60_[3])) and ((_G.type(_61_) == "table") and (_60_[1] == _61_[1]) and (_60_[2] == _61_[2]) and (nil ~= _61_[3])) and true) if and_63_ then local field = _60_[1] local col = _60_[2] local from_n = _60_[3] local on_n = _61_[3] local _ = _62_ and_63_ = (from_n == (1 + on_n)) end if and_63_ then local field = _60_[1] local col = _60_[2] local from_n = _60_[3] local on_n = _61_[3] local _ = _62_


 return nil else local and_65_ = (true and ((_G.type(_61_) == "table") and (nil ~= _61_[1]) and (nil ~= _61_[2]) and (nil ~= _61_[3])) and true) if and_65_ then local _ = _60_ local field = _61_[1] local col_n = _61_[2] local card_n = _61_[3] local _0 = _62_ and_65_ = not (card_n == #state[field][col_n]) end if and_65_ then local _ = _60_ local field = _61_[1] local col_n = _61_[2] local card_n = _61_[3] local _0 = _62_



 local function _74_() local data_5_auto = {} local resolve_6_auto local function _67_(name_7_auto) local _68_ = data_5_auto[name_7_auto] local and_69_ = (nil ~= _68_) if and_69_ then local t_8_auto = _68_ and_69_ = ("table" == type(t_8_auto)) end if and_69_ then local t_8_auto = _68_ local _71_ = getmetatable(t_8_auto) if ((_G.type(_71_) == "table") and (nil ~= _71_.__tostring)) then local f_9_auto = _71_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _71_ return vim.inspect(t_8_auto) end elseif (nil ~= _68_) then local v_11_auto = _68_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _67_ return string.gsub("Must place cards on the bottom of a cascade", "#{(.-)}", resolve_6_auto) end return nil, _74_() elseif (true and ((_G.type(_61_) == "table") and (_61_[1] == "foundation")) and ((_G.type(_62_) == "table") and (nil ~= _62_[1]) and (nil ~= _62_[2]))) then local _ = _60_ local multiple = _62_[1] local cards = _62_[2]




 local function _82_() local data_5_auto = {} local resolve_6_auto local function _75_(name_7_auto) local _76_ = data_5_auto[name_7_auto] local and_77_ = (nil ~= _76_) if and_77_ then local t_8_auto = _76_ and_77_ = ("table" == type(t_8_auto)) end if and_77_ then local t_8_auto = _76_ local _79_ = getmetatable(t_8_auto) if ((_G.type(_79_) == "table") and (nil ~= _79_.__tostring)) then local f_9_auto = _79_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _79_ return vim.inspect(t_8_auto) end elseif (nil ~= _76_) then local v_11_auto = _76_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _75_ return string.gsub("May only place cards on a foundation one at a time", "#{(.-)}", resolve_6_auto) end return nil, _82_() elseif (true and ((_G.type(_61_) == "table") and (_61_[1] == "foundation") and (nil ~= _61_[2]) and (_61_[3] == 0)) and ((_G.type(_62_) == "table") and (nil ~= _62_[1]) and (_62_[2] == nil))) then local _ = _60_ local f_col_n = _61_[2] local card = _62_[1]



 if ((_G.type(card) == "table") and true and (card[2] == 1)) then local _suit = card[1]
 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col_n, 1}}}) else local _0 = card


 local function _90_() local data_5_auto = {} local resolve_6_auto local function _83_(name_7_auto) local _84_ = data_5_auto[name_7_auto] local and_85_ = (nil ~= _84_) if and_85_ then local t_8_auto = _84_ and_85_ = ("table" == type(t_8_auto)) end if and_85_ then local t_8_auto = _84_ local _87_ = getmetatable(t_8_auto) if ((_G.type(_87_) == "table") and (nil ~= _87_.__tostring)) then local f_9_auto = _87_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _87_ return vim.inspect(t_8_auto) end elseif (nil ~= _84_) then local v_11_auto = _84_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _83_ return string.gsub("Must build foundations same suit, 1, 2, ... 10, J, Q, K", "#{(.-)}", resolve_6_auto) end return nil, _90_() end elseif (true and ((_G.type(_61_) == "table") and (_61_[1] == "foundation") and (nil ~= _61_[2]) and (nil ~= _61_[3])) and ((_G.type(_62_) == "table") and (nil ~= _62_[1]) and (_62_[2] == nil))) then local _ = _60_ local f_col_n = _61_[2] local f_card_n = _61_[3] local new_card = _62_[1]



 local onto_card = location_contents(state, dropped_on)
 local _92_, _93_ = onto_card, new_card local and_94_ = (((_G.type(_92_) == "table") and (nil ~= _92_[1])) and ((_G.type(_93_) == "table") and (_92_[1] == _93_[1]))) if and_94_ then local suit = _92_[1] and_94_ = (-1 == (card_value(onto_card) - card_value(new_card))) end if and_94_ then local suit = _92_[1]

 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col_n, (f_card_n + 1)}}}) else local _0 = _92_


 local function _103_() local data_5_auto = {} local resolve_6_auto local function _96_(name_7_auto) local _97_ = data_5_auto[name_7_auto] local and_98_ = (nil ~= _97_) if and_98_ then local t_8_auto = _97_ and_98_ = ("table" == type(t_8_auto)) end if and_98_ then local t_8_auto = _97_ local _100_ = getmetatable(t_8_auto) if ((_G.type(_100_) == "table") and (nil ~= _100_.__tostring)) then local f_9_auto = _100_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _100_ return vim.inspect(t_8_auto) end elseif (nil ~= _97_) then local v_11_auto = _97_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _96_ return string.gsub("Must build foundations in same-suit, ascending order", "#{(.-)}", resolve_6_auto) end return nil, _103_() end elseif (true and ((_G.type(_61_) == "table") and (_61_[1] == "cell")) and ((_G.type(_62_) == "table") and (nil ~= _62_[1]) and (nil ~= _62_[2]))) then local _ = _60_ local multiple = _62_[1] local cards = _62_[2]


 local function _112_() local data_5_auto = {} local resolve_6_auto local function _105_(name_7_auto) local _106_ = data_5_auto[name_7_auto] local and_107_ = (nil ~= _106_) if and_107_ then local t_8_auto = _106_ and_107_ = ("table" == type(t_8_auto)) end if and_107_ then local t_8_auto = _106_ local _109_ = getmetatable(t_8_auto) if ((_G.type(_109_) == "table") and (nil ~= _109_.__tostring)) then local f_9_auto = _109_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _109_ return vim.inspect(t_8_auto) end elseif (nil ~= _106_) then local v_11_auto = _106_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _105_ return string.gsub("May only place single cards on a cell", "#{(.-)}", resolve_6_auto) end return nil, _112_() else local and_113_ = (true and ((_G.type(_61_) == "table") and (_61_[1] == "cell") and (nil ~= _61_[2]) and (nil ~= _61_[3])) and true) if and_113_ then local _ = _60_ local col_n = _61_[2] local card_n = _61_[3] local _0 = _62_ and_113_ = not (0 == card_n) end if and_113_ then local _ = _60_ local col_n = _61_[2] local card_n = _61_[3] local _0 = _62_

 local function _122_() local data_5_auto = {} local resolve_6_auto local function _115_(name_7_auto) local _116_ = data_5_auto[name_7_auto] local and_117_ = (nil ~= _116_) if and_117_ then local t_8_auto = _116_ and_117_ = ("table" == type(t_8_auto)) end if and_117_ then local t_8_auto = _116_ local _119_ = getmetatable(t_8_auto) if ((_G.type(_119_) == "table") and (nil ~= _119_.__tostring)) then local f_9_auto = _119_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _119_ return vim.inspect(t_8_auto) end elseif (nil ~= _116_) then local v_11_auto = _116_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _115_ return string.gsub("May only place single cards on a cell", "#{(.-)}", resolve_6_auto) end return nil, _122_() elseif (true and ((_G.type(_61_) == "table") and (_61_[1] == "cell") and (nil ~= _61_[2]) and (_61_[3] == 0)) and ((_G.type(_62_) == "table") and (nil ~= _62_[1]) and (_62_[2] == nil))) then local _ = _60_ local col_n = _61_[2] local new_card = _62_[1]


 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"cell", col_n, 1}}}) else local and_123_ = (((_G.type(_60_) == "table") and (_60_[1] == "tableau") and (nil ~= _60_[2]) and (_60_[3] == 1)) and ((_G.type(_61_) == "table") and (_61_[1] == "tableau") and (nil ~= _61_[2]) and (_61_[3] == 0)) and true) if and_123_ then local a = _60_[2] local b = _61_[2] local _ = _62_ and_123_ = not (a == b) end if and_123_ then local a = _60_[2] local b = _61_[2] local _ = _62_






 local from_col = state.tableau[a] local moves
 do local tbl_21_auto = {} local i_22_auto = 0 for i, _card in ipairs(from_col) do
 local val_23_auto = {"move", {"tableau", a, i}, {"tableau", b, i}} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end moves = tbl_21_auto end
 return apply_events(clone(state), moves, {["unsafely?"] = true}) elseif (((_G.type(_60_) == "table") and (nil ~= _60_[1]) and (nil ~= _60_[2]) and (nil ~= _60_[3])) and ((_G.type(_61_) == "table") and (_61_[1] == "tableau") and (nil ~= _61_[2]) and (_61_[3] == 0)) and ((_G.type(_62_) == "table") and ((_G.type(_62_[1]) == "table") and true and (_62_[1][2] == "king")))) then local f_field = _60_[1] local f_col = _60_[2] local f_card_n = _60_[3] local t_col = _61_[2] local _suit = _62_[1][1] local held0 = _62_




 local moves do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, #held0 do
 local val_23_auto = {"move", {f_field, f_col, (f_card_n + (i - 1))}, {"tableau", t_col, i}} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end moves = tbl_21_auto end


 local next_state = apply_events(inc_moves(clone(state)), moves)


 local new_run = next_state.tableau[t_col]
 if valid_sequence_3f(new_run) then
 return next_state, moves else
 local function _134_() local data_5_auto = {} local resolve_6_auto local function _127_(name_7_auto) local _128_ = data_5_auto[name_7_auto] local and_129_ = (nil ~= _128_) if and_129_ then local t_8_auto = _128_ and_129_ = ("table" == type(t_8_auto)) end if and_129_ then local t_8_auto = _128_ local _131_ = getmetatable(t_8_auto) if ((_G.type(_131_) == "table") and (nil ~= _131_.__tostring)) then local f_9_auto = _131_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _131_ return vim.inspect(t_8_auto) end elseif (nil ~= _128_) then local v_11_auto = _128_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _127_ return string.gsub("Must build piles in same suit, descending rank", "#{(.-)}", resolve_6_auto) end return nil, _134_() end elseif (((_G.type(_60_) == "table") and (nil ~= _60_[1]) and (nil ~= _60_[2]) and (nil ~= _60_[3])) and ((_G.type(_61_) == "table") and (_61_[1] == "tableau") and (nil ~= _61_[2]) and (_61_[3] == 0)) and true) then local f_field = _60_[1] local f_col = _60_[2] local f_card_n = _60_[3] local t_col = _61_[2] local _ = _62_


 local function _143_() local data_5_auto = {} local resolve_6_auto local function _136_(name_7_auto) local _137_ = data_5_auto[name_7_auto] local and_138_ = (nil ~= _137_) if and_138_ then local t_8_auto = _137_ and_138_ = ("table" == type(t_8_auto)) end if and_138_ then local t_8_auto = _137_ local _140_ = getmetatable(t_8_auto) if ((_G.type(_140_) == "table") and (nil ~= _140_.__tostring)) then local f_9_auto = _140_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _140_ return vim.inspect(t_8_auto) end elseif (nil ~= _137_) then local v_11_auto = _137_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _136_ return string.gsub("May only place kings in empty columns", "#{(.-)}", resolve_6_auto) end return nil, _143_() elseif (((_G.type(_60_) == "table") and (nil ~= _60_[1]) and (nil ~= _60_[2]) and (nil ~= _60_[3])) and ((_G.type(_61_) == "table") and (_61_[1] == "tableau") and (nil ~= _61_[2]) and (nil ~= _61_[3])) and (nil ~= _62_)) then local f_field = _60_[1] local f_col = _60_[2] local f_card_n = _60_[3] local t_col = _61_[2] local t_card_n = _61_[3] local held0 = _62_



 local moves do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, #held0 do
 local val_23_auto = {"move", {f_field, f_col, (f_card_n + (i - 1))}, {"tableau", t_col, (t_card_n + i)}} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end moves = tbl_21_auto end


 local next_state = apply_events(inc_moves(clone(state)), moves)


 local _, new_run = table.split(next_state.tableau[t_col], t_card_n)
 if valid_sequence_3f(new_run) then
 return next_state, moves else
 local function _152_() local data_5_auto = {} local resolve_6_auto local function _145_(name_7_auto) local _146_ = data_5_auto[name_7_auto] local and_147_ = (nil ~= _146_) if and_147_ then local t_8_auto = _146_ and_147_ = ("table" == type(t_8_auto)) end if and_147_ then local t_8_auto = _146_ local _149_ = getmetatable(t_8_auto) if ((_G.type(_149_) == "table") and (nil ~= _149_.__tostring)) then local f_9_auto = _149_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _149_ return vim.inspect(t_8_auto) end elseif (nil ~= _146_) then local v_11_auto = _146_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _145_ return string.gsub("Must build piles in same suit, descending rank", "#{(.-)}", resolve_6_auto) end return nil, _152_() end else local _ = _60_


 local function _161_() local data_5_auto = {["dropped-on"] = dropped_on} local resolve_6_auto local function _154_(name_7_auto) local _155_ = data_5_auto[name_7_auto] local and_156_ = (nil ~= _155_) if and_156_ then local t_8_auto = _155_ and_156_ = ("table" == type(t_8_auto)) end if and_156_ then local t_8_auto = _155_ local _158_ = getmetatable(t_8_auto) if ((_G.type(_158_) == "table") and (nil ~= _158_.__tostring)) then local f_9_auto = _158_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _158_ return vim.inspect(t_8_auto) end elseif (nil ~= _155_) then local v_11_auto = _155_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _154_ return string.gsub("No putdown for #{dropped-on}", "#{(.-)}", resolve_6_auto) end return nil, _161_() end end end end end

 M.Action.move = function(state, pick_up_from, put_down_on)
 local function _163_(...) local _164_ = ... if (nil ~= _164_) then local held = _164_ local function _165_(...) local _166_, _167_ = ... if ((nil ~= _166_) and (nil ~= _167_)) then local next_state = _166_ local moves = _167_


 return next_state, moves else local __85_auto = _166_ return ... end end return _165_(put_down(state, pick_up_from, put_down_on, held)) else local __85_auto = _164_ return ... end end return _163_(check_pick_up(state, pick_up_from)) end

 M.Plan["next-move-to-foundation"] = function(state)
 local speculative_state = clone(state) local check_locations
 do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 7 do local val_23_auto = {"cell", i} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end check_locations = tbl_21_auto end local _
 do local tbl_19_auto = check_locations for i = 1, 7 do local val_20_auto = {"tableau", i} table.insert(tbl_19_auto, val_20_auto) end _ = tbl_19_auto end local min_values
 do local min_vals = {spades = math.huge, hearts = math.huge, diamonds = math.huge, clubs = math.huge} for _l, card in M["iter-cards"](speculative_state, {"cell", "tableau"}) do


 local suit = card_suit(card)
 local val = card_value(card)
 min_vals = table.set(min_vals, suit, math.min(val, min_vals[suit])) end min_values = min_vals end local source_locations
 do local tbl_21_auto = {} local i_22_auto = 0 for _0, _171_ in ipairs(check_locations) do local field = _171_[1] local col = _171_[2] local val_23_auto
 do local card_n = #speculative_state[field][col]
 local _172_ = speculative_state[field][col][card_n] if (nil ~= _172_) then local card = _172_
 local suit = card_suit(card)
 if (card_value(card) == min_values[suit]) then
 val_23_auto = {field, col, card_n} else val_23_auto = nil end else val_23_auto = nil end end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end source_locations = tbl_21_auto end local potential_moves
 do local moves = {} for _0, from in ipairs(source_locations) do
 local tbl_19_auto = moves for i = 1, 4 do local val_20_auto
 do local _176_ = speculative_state.foundation[i] if ((_G.type(_176_) == "table") and (_176_[1] == nil)) then
 val_20_auto = {from, {"foundation", i, 0}} elseif (nil ~= _176_) then local cards = _176_
 val_20_auto = {from, {"foundation", i, #cards}} else val_20_auto = nil end end table.insert(tbl_19_auto, val_20_auto) end moves = tbl_19_auto end potential_moves = moves end
 local actions = nil for _0, _178_ in ipairs(potential_moves) do local pick_up_from = _178_[1] local put_down_on = _178_[2] if actions then break end
 local function _179_(...) local _180_ = ... if (nil ~= _180_) then local speculative_state0 = _180_

 return {pick_up_from, put_down_on} else local __85_auto = _180_ return ... end end actions = _179_(M.Action.move(clone(state), pick_up_from, put_down_on)) end return actions end

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