
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}



 local function new_game_state()
 return {draw = {{}}, foundation = {{}, {}, {}, {}}, cell = {{}, {}, {}, {}}, tableau = {{}, {}, {}, {}, {}, {}, {}, {}}, moves = 0, rules = "freecell"} end






 M.build = function(config, _3fseed) _G.assert((nil ~= config), "Missing argument config on fnl/playtime/game/freecell/logic.fnl:20")
 if ((_G.type(config) == "table") and (nil ~= config.rules)) then local rules = config.rules else local __2_auto = config error("config must match {:rules rules}") end
 math.randomseed((_3fseed or os.time()))
 local deck = Deck.shuffle(Deck.Standard52.build())

 local state = new_game_state()
 state["draw"][1] = deck
 state["rules"] = config.rules

 return state end

 M["iter-cards"] = CardGameUtils["make-iter-cards-fn"]({"draw", "cell", "tableau", "foundation"})
 local location_contents = CardGameUtils["location-contents"]
 local same_location_field_column_3f = CardGameUtils["same-location-field-column?"]
 local inc_moves = CardGameUtils["inc-moves"]
 local apply_events = CardGameUtils["apply-events"]
 local _local_3_ = CardGameUtils["make-card-util-fns"]({value = {king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_3_["card-value"] local card_color = _local_3_["card-color"] local card_rank = _local_3_["card-rank"] local card_suit = _local_3_["card-suit"] local rank_value = _local_3_["rank-value"] local suit_color = _local_3_["suit-color"]




 local valid_freecell_sequence_3f

 local function _5_(next_card, _4_) local last_card = _4_[1]
 local last_color = card_color(last_card)
 local last_value = card_value(last_card)
 local next_color = card_color(next_card)
 local next_value = card_value(next_card)
 return (not (last_color == next_color) and (last_value == (next_value + 1))) end valid_freecell_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_5_)


 local valid_bakers_sequence_3f

 local function _7_(next_card, _6_) local last_card = _6_[1]
 local last_suit = card_suit(last_card)
 local last_value = card_value(last_card)
 local next_suit = card_suit(next_card)
 local next_value = card_value(next_card)
 return ((last_suit == next_suit) and (last_value == (next_value + 1))) end valid_bakers_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_7_)


 local winning_foundation_sequence_3f
 do
 local valid_sequence_3f

 local function _9_(next_card, _8_) local last_card = _8_[1]
 return ((card_suit(next_card) == card_suit(last_card)) and (card_value(next_card) == (1 + card_value(last_card)))) end valid_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_9_)


 local function _10_(sequence)
 return ((rank_value("king") == #sequence) and valid_sequence_3f(sequence)) end winning_foundation_sequence_3f = _10_ end


 local function valid_sequence_3f(rules, sequence)
 if (rules == "freecell") then
 return valid_freecell_sequence_3f(sequence) elseif (rules == "bakers") then
 return valid_bakers_sequence_3f(sequence) else return nil end end

 local function build_move_plan(cur_state, from, to) _G.assert((nil ~= to), "Missing argument to on fnl/playtime/game/freecell/logic.fnl:78") _G.assert((nil ~= from), "Missing argument from on fnl/playtime/game/freecell/logic.fnl:78") _G.assert((nil ~= cur_state), "Missing argument cur-state on fnl/playtime/game/freecell/logic.fnl:78")
 local function find_empty_cells(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/freecell/logic.fnl:79")
 local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 4 do local val_23_auto
 if table["empty?"](location_contents(state, {"cell", i})) then
 val_23_auto = {"cell", i, 1} else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end

 local function find_empty_columns(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/freecell/logic.fnl:84")
 local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 8 do local val_23_auto
 if table["empty?"](location_contents(state, {"tableau", i})) then
 val_23_auto = {"tableau", i, 1} else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end

 local function stack_unstack_move(cur_state0, _16_, _17_) local from_f = _16_[1] local from_c = _16_[2] local from_n = _16_[3] local from0 = _16_ local to_f = _17_[1] local to_c = _17_[2] local to_n = _17_[3] local to0 = _17_ _G.assert((nil ~= to0), "Missing argument to on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= to_n), "Missing argument to-n on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= to_c), "Missing argument to-c on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= to_f), "Missing argument to-f on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= from0), "Missing argument from on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= from_n), "Missing argument from-n on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= from_c), "Missing argument from-c on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= from_f), "Missing argument from-f on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= cur_state0), "Missing argument cur-state on fnl/playtime/game/freecell/logic.fnl:89")


 local next_state = clone(cur_state0)
 local from_t = next_state[from_f][from_c]
 local to_t = next_state[to_f][to_c]
 local total_cards_to_move = (#from_t - (from_n - 1))

 local num_cards_to_hold = (total_cards_to_move - 1) local holding_locs
 do local t = {}
 do local tbl_19_auto = t for _, l in ipairs(find_empty_cells(next_state)) do local val_20_auto = l table.insert(tbl_19_auto, val_20_auto) end end
 do local tbl_19_auto = t for _, l in ipairs(find_empty_columns(next_state)) do local val_20_auto = l table.insert(tbl_19_auto, val_20_auto) end end
 local tbl_21_auto = {} local i_22_auto = 0 for _, l in ipairs(t) do local val_23_auto
 if not same_location_field_column_3f(to0, l) then val_23_auto = l else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end holding_locs = tbl_21_auto end
 if (num_cards_to_hold <= #holding_locs) then
 local unstack, restack = nil, nil do local unstack0, restack0 = {}, {} for i = 1, num_cards_to_hold do

 local _let_20_ = holding_locs[i] local hold_f = _let_20_[1] local hold_c = _let_20_[2] local hold_n = _let_20_[3]


 local from_loc = {from_f, from_c, (#from_t - (i - 1))}

 local to_loc = {to_f, to_c, (#to_t + 1 + (num_cards_to_hold - i) + 1)}
 local unstack_move = {"move", from_loc, {hold_f, hold_c, hold_n}}
 local restack_move = {"move", {hold_f, hold_c, hold_n}, to_loc}


 table.insert(unstack0, unstack_move)
 table.insert(restack0, 1, restack_move)
 unstack0, restack0 = unstack0, restack0 end unstack, restack = unstack0, restack0 end
 table.insert(unstack, {"move", from0, to0})
 local tbl_19_auto = unstack for _, re in ipairs(restack) do local val_20_auto = re table.insert(tbl_19_auto, val_20_auto) end return tbl_19_auto else
 local function _28_() local data_5_auto = {["total-cards-to-move"] = total_cards_to_move} local resolve_6_auto local function _21_(name_7_auto) local _22_ = data_5_auto[name_7_auto] local and_23_ = (nil ~= _22_) if and_23_ then local t_8_auto = _22_ and_23_ = ("table" == type(t_8_auto)) end if and_23_ then local t_8_auto = _22_ local _25_ = getmetatable(t_8_auto) if ((_G.type(_25_) == "table") and (nil ~= _25_.__tostring)) then local f_9_auto = _25_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _25_ return vim.inspect(t_8_auto) end elseif (nil ~= _22_) then local v_11_auto = _22_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _21_ return string.gsub("Unable to plan move for #{total-cards-to-move} cards, not enough holding spaces", "#{(.-)}", resolve_6_auto) end return nil, _28_() end end

 local next_state = clone(cur_state)
 local _30_, _31_ = stack_unstack_move(next_state, from, to) if (nil ~= _30_) then local moves = _30_

 return moves elseif ((_30_ == nil) and (nil ~= _31_)) then local err = _31_


 local from_f = from[1] local from_c = from[2] local from_n = from[3]
 local to_f = to[1] local to_c = to[2] local to_n = to[3] local sub_stack_to
 local function _32_() local tbl_21_auto = {} local i_22_auto = 0 for _, l in ipairs(find_empty_columns(next_state)) do local val_23_auto
 if not same_location_field_column_3f(to, l) then val_23_auto = l else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end sub_stack_to = table.first(_32_())

 if sub_stack_to then
 local holding_locs do local t = {}
 do local tbl_19_auto = t for _, l in ipairs(find_empty_cells(next_state)) do local val_20_auto = l table.insert(tbl_19_auto, val_20_auto) end end
 do local tbl_19_auto = t for _, l in ipairs(find_empty_columns(next_state)) do local val_20_auto = l table.insert(tbl_19_auto, val_20_auto) end end
 local tbl_21_auto = {} local i_22_auto = 0 for _, _35_ in ipairs(t) do local f = _35_[1] local c = _35_[2] local l = _35_ local val_23_auto
 if (not same_location_field_column_3f(to, l) and not same_location_field_column_3f(sub_stack_to, l)) then

 val_23_auto = l else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end holding_locs = tbl_21_auto end
 local from_t = next_state[from_f][from_c]
 local sub_stack_from = {from_f, from_c, (#from_t - #holding_locs)}
 local _38_, _39_ = build_move_plan(next_state, sub_stack_from, sub_stack_to) if (nil ~= _38_) then local moves = _38_



 local next_state0 = apply_events(next_state, moves)
 local _40_ = build_move_plan(next_state0, from, to) if (nil ~= _40_) then local next_moves = _40_
 local next_state1 = apply_events(next_state0, next_moves)
 local sub_stack_from0 = sub_stack_to
 local sub_stack_to0 = {to_f, to_c, (1 + #next_state1[to_f][to_c])}
 local unwind_moves = stack_unstack_move(next_state1, sub_stack_from0, sub_stack_to0)
 do local tbl_19_auto = moves for _, move in ipairs(next_moves) do local val_20_auto = move table.insert(tbl_19_auto, val_20_auto) end end
 local tbl_19_auto = moves for _, move in ipairs(unwind_moves) do local val_20_auto = move table.insert(tbl_19_auto, val_20_auto) end return tbl_19_auto elseif (_40_ == nil) then
 local function _48_() local data_5_auto = {from = from, to = to} local resolve_6_auto local function _41_(name_7_auto) local _42_ = data_5_auto[name_7_auto] local and_43_ = (nil ~= _42_) if and_43_ then local t_8_auto = _42_ and_43_ = ("table" == type(t_8_auto)) end if and_43_ then local t_8_auto = _42_ local _45_ = getmetatable(t_8_auto) if ((_G.type(_45_) == "table") and (nil ~= _45_.__tostring)) then local f_9_auto = _45_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _45_ return vim.inspect(t_8_auto) end elseif (nil ~= _42_) then local v_11_auto = _42_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _41_ return string.gsub("Cannot plan #{from} -> #{to}, not enough spaces", "#{(.-)}", resolve_6_auto) end return nil, _48_() else return nil end elseif ((_38_ == nil) and (nil ~= _39_)) then local err0 = _39_

 local function _57_() local data_5_auto = {from = from, to = to} local resolve_6_auto local function _50_(name_7_auto) local _51_ = data_5_auto[name_7_auto] local and_52_ = (nil ~= _51_) if and_52_ then local t_8_auto = _51_ and_52_ = ("table" == type(t_8_auto)) end if and_52_ then local t_8_auto = _51_ local _54_ = getmetatable(t_8_auto) if ((_G.type(_54_) == "table") and (nil ~= _54_.__tostring)) then local f_9_auto = _54_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _54_ return vim.inspect(t_8_auto) end elseif (nil ~= _51_) then local v_11_auto = _51_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _50_ return string.gsub("Cannot plan #{from} -> #{to}, not enough spaces", "#{(.-)}", resolve_6_auto) end return nil, _57_() else return nil end else
 local function _66_() local data_5_auto = {from = from, to = to} local resolve_6_auto local function _59_(name_7_auto) local _60_ = data_5_auto[name_7_auto] local and_61_ = (nil ~= _60_) if and_61_ then local t_8_auto = _60_ and_61_ = ("table" == type(t_8_auto)) end if and_61_ then local t_8_auto = _60_ local _63_ = getmetatable(t_8_auto) if ((_G.type(_63_) == "table") and (nil ~= _63_.__tostring)) then local f_9_auto = _63_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _63_ return vim.inspect(t_8_auto) end elseif (nil ~= _60_) then local v_11_auto = _60_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _59_ return string.gsub("Cannot plan #{from} -> #{to}, no free columns", "#{(.-)}", resolve_6_auto) end return nil, _66_() end else return nil end end

 M.Action.deal = function(state)
 local moves do local moves0, t_col, row = {}, 1, 1 for i = #state.draw[1], 1, -1 do

 local from = {"draw", 1, i}
 local to = {"tableau", t_col, row}



 local _69_ if (t_col == 8) then _69_ = 1 else _69_ = (t_col + 1) end
 local function _71_() if (t_col == 8) then return (row + 1) else return row end end moves0, t_col, row = table.insert(table.insert(moves0, {"move", from, to}), {"face-up", to}), _69_, _71_() end moves = moves0, t_col, row end
 local next_state, moves0 = apply_events(clone(state), moves)
 return next_state, moves0 end

 local function check_pick_up(state, pick_up_from)
 if ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "tableau") and (nil ~= pick_up_from[2]) and (nil ~= pick_up_from[3])) then local col_n = pick_up_from[2] local card_n = pick_up_from[3]

 local remaining, held = table.split(state.tableau[col_n], card_n)
 if valid_sequence_3f(state.rules, held) then
 return held else
 if ((_G.type(held) == "table") and (held[1] == nil)) then
 local function _79_() local data_5_auto = {["col-n"] = col_n} local resolve_6_auto local function _72_(name_7_auto) local _73_ = data_5_auto[name_7_auto] local and_74_ = (nil ~= _73_) if and_74_ then local t_8_auto = _73_ and_74_ = ("table" == type(t_8_auto)) end if and_74_ then local t_8_auto = _73_ local _76_ = getmetatable(t_8_auto) if ((_G.type(_76_) == "table") and (nil ~= _76_.__tostring)) then local f_9_auto = _76_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _76_ return vim.inspect(t_8_auto) end elseif (nil ~= _73_) then local v_11_auto = _73_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _72_ return string.gsub("No cards to pick up from tableau column #{col-n}", "#{(.-)}", resolve_6_auto) end return nil, _79_() else local _ = held
 local function _87_() local data_5_auto = {} local resolve_6_auto local function _80_(name_7_auto) local _81_ = data_5_auto[name_7_auto] local and_82_ = (nil ~= _81_) if and_82_ then local t_8_auto = _81_ and_82_ = ("table" == type(t_8_auto)) end if and_82_ then local t_8_auto = _81_ local _84_ = getmetatable(t_8_auto) if ((_G.type(_84_) == "table") and (nil ~= _84_.__tostring)) then local f_9_auto = _84_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _84_ return vim.inspect(t_8_auto) end elseif (nil ~= _81_) then local v_11_auto = _81_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _80_ return string.gsub("Must pick up run of alternating suit, descending rank", "#{(.-)}", resolve_6_auto) end return nil, _87_() end end elseif ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "cell") and (nil ~= pick_up_from[2]) and (pick_up_from[3] == 1)) then local col_n = pick_up_from[2]


 local remaining, held = table.split(state.cell[col_n], 1)
 local _90_ = #held if (_90_ == 1) then
 return held elseif (_90_ == 0) then
 local function _98_() local data_5_auto = {} local resolve_6_auto local function _91_(name_7_auto) local _92_ = data_5_auto[name_7_auto] local and_93_ = (nil ~= _92_) if and_93_ then local t_8_auto = _92_ and_93_ = ("table" == type(t_8_auto)) end if and_93_ then local t_8_auto = _92_ local _95_ = getmetatable(t_8_auto) if ((_G.type(_95_) == "table") and (nil ~= _95_.__tostring)) then local f_9_auto = _95_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _95_ return vim.inspect(t_8_auto) end elseif (nil ~= _92_) then local v_11_auto = _92_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _91_ return string.gsub("No card to pick up from free cell", "#{(.-)}", resolve_6_auto) end return nil, _98_() elseif (nil ~= _90_) then local n = _90_
 local function _106_() local data_5_auto = {} local resolve_6_auto local function _99_(name_7_auto) local _100_ = data_5_auto[name_7_auto] local and_101_ = (nil ~= _100_) if and_101_ then local t_8_auto = _100_ and_101_ = ("table" == type(t_8_auto)) end if and_101_ then local t_8_auto = _100_ local _103_ = getmetatable(t_8_auto) if ((_G.type(_103_) == "table") and (nil ~= _103_.__tostring)) then local f_9_auto = _103_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _103_ return vim.inspect(t_8_auto) end elseif (nil ~= _100_) then local v_11_auto = _100_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _99_ return string.gsub("May only pick up one card at a time from free cell", "#{(.-)}", resolve_6_auto) end return nil, _106_() else return nil end elseif ((_G.type(pick_up_from) == "table") and (nil ~= pick_up_from[1])) then local field = pick_up_from[1]


 local function _115_() local data_5_auto = {field = field} local resolve_6_auto local function _108_(name_7_auto) local _109_ = data_5_auto[name_7_auto] local and_110_ = (nil ~= _109_) if and_110_ then local t_8_auto = _109_ and_110_ = ("table" == type(t_8_auto)) end if and_110_ then local t_8_auto = _109_ local _112_ = getmetatable(t_8_auto) if ((_G.type(_112_) == "table") and (nil ~= _112_.__tostring)) then local f_9_auto = _112_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _112_ return vim.inspect(t_8_auto) end elseif (nil ~= _109_) then local v_11_auto = _109_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _108_ return string.gsub("May not pick up from #{field}", "#{(.-)}", resolve_6_auto) end return nil, _115_() else return nil end end

 local function put_down(state, pick_up_from, dropped_on, held)
 local _117_, _118_, _119_ = pick_up_from, dropped_on, held local and_120_ = (((_G.type(_117_) == "table") and (nil ~= _117_[1]) and (nil ~= _117_[2]) and (nil ~= _117_[3])) and ((_G.type(_118_) == "table") and (_117_[1] == _118_[1]) and (_117_[2] == _118_[2]) and (nil ~= _118_[3])) and true) if and_120_ then local field = _117_[1] local col = _117_[2] local from_n = _117_[3] local on_n = _118_[3] local _ = _119_ and_120_ = (from_n == (1 + on_n)) end if and_120_ then local field = _117_[1] local col = _117_[2] local from_n = _117_[3] local on_n = _118_[3] local _ = _119_


 return nil else local and_122_ = (true and ((_G.type(_118_) == "table") and (nil ~= _118_[1]) and (nil ~= _118_[2]) and (nil ~= _118_[3])) and true) if and_122_ then local _ = _117_ local field = _118_[1] local col_n = _118_[2] local card_n = _118_[3] local _0 = _119_ and_122_ = not (card_n == #state[field][col_n]) end if and_122_ then local _ = _117_ local field = _118_[1] local col_n = _118_[2] local card_n = _118_[3] local _0 = _119_



 local function _131_() local data_5_auto = {} local resolve_6_auto local function _124_(name_7_auto) local _125_ = data_5_auto[name_7_auto] local and_126_ = (nil ~= _125_) if and_126_ then local t_8_auto = _125_ and_126_ = ("table" == type(t_8_auto)) end if and_126_ then local t_8_auto = _125_ local _128_ = getmetatable(t_8_auto) if ((_G.type(_128_) == "table") and (nil ~= _128_.__tostring)) then local f_9_auto = _128_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _128_ return vim.inspect(t_8_auto) end elseif (nil ~= _125_) then local v_11_auto = _125_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _124_ return string.gsub("Must place cards on the bottom of a cascade", "#{(.-)}", resolve_6_auto) end return nil, _131_() elseif (true and ((_G.type(_118_) == "table") and (_118_[1] == "foundation")) and ((_G.type(_119_) == "table") and (nil ~= _119_[1]) and (nil ~= _119_[2]))) then local _ = _117_ local multiple = _119_[1] local cards = _119_[2]




 local function _139_() local data_5_auto = {} local resolve_6_auto local function _132_(name_7_auto) local _133_ = data_5_auto[name_7_auto] local and_134_ = (nil ~= _133_) if and_134_ then local t_8_auto = _133_ and_134_ = ("table" == type(t_8_auto)) end if and_134_ then local t_8_auto = _133_ local _136_ = getmetatable(t_8_auto) if ((_G.type(_136_) == "table") and (nil ~= _136_.__tostring)) then local f_9_auto = _136_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _136_ return vim.inspect(t_8_auto) end elseif (nil ~= _133_) then local v_11_auto = _133_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _132_ return string.gsub("May only place cards on a foundation one at a time", "#{(.-)}", resolve_6_auto) end return nil, _139_() elseif (true and ((_G.type(_118_) == "table") and (_118_[1] == "foundation") and (nil ~= _118_[2]) and (_118_[3] == 0)) and ((_G.type(_119_) == "table") and (nil ~= _119_[1]) and (_119_[2] == nil))) then local _ = _117_ local f_col_n = _118_[2] local card = _119_[1]



 if ((_G.type(card) == "table") and true and (card[2] == 1)) then local _suit = card[1]
 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col_n, 1}}}) else local _0 = card


 local function _147_() local data_5_auto = {} local resolve_6_auto local function _140_(name_7_auto) local _141_ = data_5_auto[name_7_auto] local and_142_ = (nil ~= _141_) if and_142_ then local t_8_auto = _141_ and_142_ = ("table" == type(t_8_auto)) end if and_142_ then local t_8_auto = _141_ local _144_ = getmetatable(t_8_auto) if ((_G.type(_144_) == "table") and (nil ~= _144_.__tostring)) then local f_9_auto = _144_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _144_ return vim.inspect(t_8_auto) end elseif (nil ~= _141_) then local v_11_auto = _141_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _140_ return string.gsub("Must build foundations same suit, 1, 2, ... 10, J, Q, K", "#{(.-)}", resolve_6_auto) end return nil, _147_() end elseif (true and ((_G.type(_118_) == "table") and (_118_[1] == "foundation") and (nil ~= _118_[2]) and (nil ~= _118_[3])) and ((_G.type(_119_) == "table") and (nil ~= _119_[1]) and (_119_[2] == nil))) then local _ = _117_ local f_col_n = _118_[2] local f_card_n = _118_[3] local new_card = _119_[1]



 local onto_card = location_contents(state, dropped_on)
 local _149_, _150_ = onto_card, new_card local and_151_ = (((_G.type(_149_) == "table") and (nil ~= _149_[1])) and ((_G.type(_150_) == "table") and (_149_[1] == _150_[1]))) if and_151_ then local suit = _149_[1] and_151_ = (-1 == (card_value(onto_card) - card_value(new_card))) end if and_151_ then local suit = _149_[1]

 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col_n, (f_card_n + 1)}}}) else local _0 = _149_


 local function _160_() local data_5_auto = {} local resolve_6_auto local function _153_(name_7_auto) local _154_ = data_5_auto[name_7_auto] local and_155_ = (nil ~= _154_) if and_155_ then local t_8_auto = _154_ and_155_ = ("table" == type(t_8_auto)) end if and_155_ then local t_8_auto = _154_ local _157_ = getmetatable(t_8_auto) if ((_G.type(_157_) == "table") and (nil ~= _157_.__tostring)) then local f_9_auto = _157_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _157_ return vim.inspect(t_8_auto) end elseif (nil ~= _154_) then local v_11_auto = _154_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _153_ return string.gsub("Must build foundations in same-suit, ascending order", "#{(.-)}", resolve_6_auto) end return nil, _160_() end elseif (true and ((_G.type(_118_) == "table") and (_118_[1] == "cell")) and ((_G.type(_119_) == "table") and (nil ~= _119_[1]) and (nil ~= _119_[2]))) then local _ = _117_ local multiple = _119_[1] local cards = _119_[2]



 local function _169_() local data_5_auto = {} local resolve_6_auto local function _162_(name_7_auto) local _163_ = data_5_auto[name_7_auto] local and_164_ = (nil ~= _163_) if and_164_ then local t_8_auto = _163_ and_164_ = ("table" == type(t_8_auto)) end if and_164_ then local t_8_auto = _163_ local _166_ = getmetatable(t_8_auto) if ((_G.type(_166_) == "table") and (nil ~= _166_.__tostring)) then local f_9_auto = _166_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _166_ return vim.inspect(t_8_auto) end elseif (nil ~= _163_) then local v_11_auto = _163_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _162_ return string.gsub("May only place single cards on a cell", "#{(.-)}", resolve_6_auto) end return nil, _169_() else local and_170_ = (true and ((_G.type(_118_) == "table") and (_118_[1] == "cell") and (nil ~= _118_[2]) and (nil ~= _118_[3])) and true) if and_170_ then local _ = _117_ local col_n = _118_[2] local card_n = _118_[3] local _0 = _119_ and_170_ = not (0 == card_n) end if and_170_ then local _ = _117_ local col_n = _118_[2] local card_n = _118_[3] local _0 = _119_

 local function _179_() local data_5_auto = {} local resolve_6_auto local function _172_(name_7_auto) local _173_ = data_5_auto[name_7_auto] local and_174_ = (nil ~= _173_) if and_174_ then local t_8_auto = _173_ and_174_ = ("table" == type(t_8_auto)) end if and_174_ then local t_8_auto = _173_ local _176_ = getmetatable(t_8_auto) if ((_G.type(_176_) == "table") and (nil ~= _176_.__tostring)) then local f_9_auto = _176_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _176_ return vim.inspect(t_8_auto) end elseif (nil ~= _173_) then local v_11_auto = _173_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _172_ return string.gsub("May only place single cards on a cell", "#{(.-)}", resolve_6_auto) end return nil, _179_() elseif (true and ((_G.type(_118_) == "table") and (_118_[1] == "cell") and (nil ~= _118_[2]) and (_118_[3] == 0)) and ((_G.type(_119_) == "table") and (nil ~= _119_[1]) and (_119_[2] == nil))) then local _ = _117_ local col_n = _118_[2] local new_card = _119_[1]


 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"cell", col_n, 1}}}) else local and_180_ = (((_G.type(_117_) == "table") and (_117_[1] == "tableau") and (nil ~= _117_[2]) and (_117_[3] == 1)) and ((_G.type(_118_) == "table") and (_118_[1] == "tableau") and (nil ~= _118_[2]) and (_118_[3] == 0)) and true) if and_180_ then local a = _117_[2] local b = _118_[2] local _ = _119_ and_180_ = not (a == b) end if and_180_ then local a = _117_[2] local b = _118_[2] local _ = _119_






 local from_col = state.tableau[a] local moves
 do local tbl_21_auto = {} local i_22_auto = 0 for i, _card in ipairs(from_col) do
 local val_23_auto = {"move", {"tableau", a, i}, {"tableau", b, i}} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end moves = tbl_21_auto end
 return apply_events(clone(state), moves, {["unsafely?"] = true}) elseif (true and ((_G.type(_118_) == "table") and (_118_[1] == "tableau") and (nil ~= _118_[2]) and (nil ~= _118_[3])) and true) then local _ = _117_ local t_col = _118_[2] local t_card_n = _118_[3] local _0 = _119_



 local _183_ = build_move_plan(state, pick_up_from, {"tableau", t_col, (1 + t_card_n)}) if (nil ~= _183_) then local moves = _183_
 local next_state = apply_events(inc_moves(clone(state), #moves), moves)


 local _1, new_run = table.split(next_state.tableau[t_col], t_card_n)
 if valid_sequence_3f(state.rules, new_run) then
 return next_state, moves else

 local function _191_() local data_5_auto = {} local resolve_6_auto local function _184_(name_7_auto) local _185_ = data_5_auto[name_7_auto] local and_186_ = (nil ~= _185_) if and_186_ then local t_8_auto = _185_ and_186_ = ("table" == type(t_8_auto)) end if and_186_ then local t_8_auto = _185_ local _188_ = getmetatable(t_8_auto) if ((_G.type(_188_) == "table") and (nil ~= _188_.__tostring)) then local f_9_auto = _188_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _188_ return vim.inspect(t_8_auto) end elseif (nil ~= _185_) then local v_11_auto = _185_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _184_ return string.gsub("Must build piles in alternating color, descending rank", "#{(.-)}", resolve_6_auto) end return nil, _191_() end else local _1 = _183_
 local function _200_() local data_5_auto = {len = #held} local resolve_6_auto local function _193_(name_7_auto) local _194_ = data_5_auto[name_7_auto] local and_195_ = (nil ~= _194_) if and_195_ then local t_8_auto = _194_ and_195_ = ("table" == type(t_8_auto)) end if and_195_ then local t_8_auto = _194_ local _197_ = getmetatable(t_8_auto) if ((_G.type(_197_) == "table") and (nil ~= _197_.__tostring)) then local f_9_auto = _197_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _197_ return vim.inspect(t_8_auto) end elseif (nil ~= _194_) then local v_11_auto = _194_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _193_ return string.gsub("Not enough spaces to move #{len} cards", "#{(.-)}", resolve_6_auto) end return nil, _200_() end else local _ = _117_


 local function _209_() local data_5_auto = {["dropped-on"] = dropped_on} local resolve_6_auto local function _202_(name_7_auto) local _203_ = data_5_auto[name_7_auto] local and_204_ = (nil ~= _203_) if and_204_ then local t_8_auto = _203_ and_204_ = ("table" == type(t_8_auto)) end if and_204_ then local t_8_auto = _203_ local _206_ = getmetatable(t_8_auto) if ((_G.type(_206_) == "table") and (nil ~= _206_.__tostring)) then local f_9_auto = _206_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _206_ return vim.inspect(t_8_auto) end elseif (nil ~= _203_) then local v_11_auto = _203_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _202_ return string.gsub("No putdown for #{dropped-on}", "#{(.-)}", resolve_6_auto) end return nil, _209_() end end end end end

 M.Action.move = function(state, pick_up_from, put_down_on)
 local function _211_(...) local _212_ = ... if (nil ~= _212_) then local held = _212_ local function _213_(...) local _214_, _215_ = ... if ((nil ~= _214_) and (nil ~= _215_)) then local next_state = _214_ local moves = _215_


 return next_state, moves else local __85_auto = _214_ return ... end end return _213_(put_down(state, pick_up_from, put_down_on, held)) else local __85_auto = _212_ return ... end end return _211_(check_pick_up(state, pick_up_from)) end

 local function freecell_plan_next_move_to_foundation(state)






 local speculative_state = clone(state) local check_locations
 do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 4 do local val_23_auto = {"cell", i} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end check_locations = tbl_21_auto end local _
 do local tbl_19_auto = check_locations for i = 1, 8 do local val_20_auto = {"tableau", i} table.insert(tbl_19_auto, val_20_auto) end _ = tbl_19_auto end local min_values
 do local min_vals = {red = math.huge, black = math.huge} for _l, card in M["iter-cards"](speculative_state, {"cell", "tableau"}) do

 local color = card_color(card)
 local val = card_value(card)
 min_vals = table.set(min_vals, color, math.min(val, min_vals[color])) end min_values = min_vals end local source_locations
 do local tbl_21_auto = {} local i_22_auto = 0 for _0, _219_ in ipairs(check_locations) do local field = _219_[1] local col = _219_[2] local val_23_auto
 do local card_n = #speculative_state[field][col]
 local _220_ = speculative_state[field][col][card_n] if (nil ~= _220_) then local card = _220_
 local alt_color if ("red" == card_color(card)) then alt_color = "black" else alt_color = "red" end
 local val = card_value(card)
 if ((card_value(card) <= min_values[alt_color]) or (2 == val)) then

 val_23_auto = {field, col, card_n} else val_23_auto = nil end else val_23_auto = nil end end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end source_locations = tbl_21_auto end
 local moves = {} for _0, from in ipairs(source_locations) do
 local tbl_19_auto = moves for i = 1, 4 do local val_20_auto
 do local _225_ = speculative_state.foundation[i] if ((_G.type(_225_) == "table") and (_225_[1] == nil)) then
 val_20_auto = {from, {"foundation", i, 0}} elseif (nil ~= _225_) then local cards = _225_
 val_20_auto = {from, {"foundation", i, #cards}} else val_20_auto = nil end end table.insert(tbl_19_auto, val_20_auto) end moves = tbl_19_auto end return moves end

 local function bakers_plan_next_move_to_foundation(state)


 local speculative_state = clone(state) local check_locations
 do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 4 do local val_23_auto = {"cell", i} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end check_locations = tbl_21_auto end local _
 do local tbl_19_auto = check_locations for i = 1, 8 do local val_20_auto = {"tableau", i} table.insert(tbl_19_auto, val_20_auto) end _ = tbl_19_auto end local min_values
 do local min_vals = {spades = math.huge, hearts = math.huge, diamonds = math.huge, clubs = math.huge} for _l, card in M["iter-cards"](speculative_state, {"cell", "tableau"}) do


 local suit = card_suit(card)
 local val = card_value(card)
 min_vals = table.set(min_vals, suit, math.min(val, min_vals[suit])) end min_values = min_vals end local source_locations
 do local tbl_21_auto = {} local i_22_auto = 0 for _0, _228_ in ipairs(check_locations) do local field = _228_[1] local col = _228_[2] local val_23_auto
 do local card_n = #speculative_state[field][col]
 local _229_ = speculative_state[field][col][card_n] if (nil ~= _229_) then local card = _229_
 local suit = card_suit(card)
 if (card_value(card) == min_values[suit]) then
 val_23_auto = {field, col, card_n} else val_23_auto = nil end else val_23_auto = nil end end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end source_locations = tbl_21_auto end
 local moves = {} for _0, from in ipairs(source_locations) do
 local tbl_19_auto = moves for i = 1, 4 do local val_20_auto
 do local _233_ = speculative_state.foundation[i] if ((_G.type(_233_) == "table") and (_233_[1] == nil)) then
 val_20_auto = {from, {"foundation", i, 0}} elseif (nil ~= _233_) then local cards = _233_
 val_20_auto = {from, {"foundation", i, #cards}} else val_20_auto = nil end end table.insert(tbl_19_auto, val_20_auto) end moves = tbl_19_auto end return moves end

 M.Plan["next-move-to-foundation"] = function(state)
 local potential_moves do local _235_ = state.rules if (_235_ == "freecell") then
 potential_moves = freecell_plan_next_move_to_foundation(state) elseif (_235_ == "bakers") then
 potential_moves = bakers_plan_next_move_to_foundation(state) else potential_moves = nil end end
 local actions = nil for _, _237_ in ipairs(potential_moves) do local pick_up_from = _237_[1] local put_down_on = _237_[2] if actions then break end
 local function _238_(...) local _239_ = ... if (nil ~= _239_) then local speculative_state = _239_

 return {pick_up_from, put_down_on} else local __85_auto = _239_ return ... end end actions = _238_(M.Action.move(clone(state), pick_up_from, put_down_on)) end return actions end

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