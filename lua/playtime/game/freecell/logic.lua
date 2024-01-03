
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
 do end (state)["draw"][1] = deck
 state["rules"] = config.rules

 return state end

 M["iter-cards"] = CardGameUtils["make-iter-cards-fn"]({"draw", "cell", "tableau", "foundation"})
 local _local_3_ = CardGameUtils local location_contents = _local_3_["location-contents"]
 local same_location_field_column_3f = _local_3_["same-location-field-column?"]
 local inc_moves = _local_3_["inc-moves"]
 local apply_events = _local_3_["apply-events"]
 local _local_4_ = CardGameUtils["make-card-util-fns"]({value = {king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_4_["card-value"] local card_color = _local_4_["card-color"] local card_rank = _local_4_["card-rank"] local card_suit = _local_4_["card-suit"] local rank_value = _local_4_["rank-value"] local suit_color = _local_4_["suit-color"]




 local valid_freecell_sequence_3f

 local function _7_(next_card, _5_) local _arg_6_ = _5_ local last_card = _arg_6_[1]
 local last_color = card_color(last_card)
 local last_value = card_value(last_card)
 local next_color = card_color(next_card)
 local next_value = card_value(next_card)
 return (not (last_color == next_color) and (last_value == (next_value + 1))) end valid_freecell_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_7_)


 local valid_bakers_sequence_3f

 local function _10_(next_card, _8_) local _arg_9_ = _8_ local last_card = _arg_9_[1]
 local last_suit = card_suit(last_card)
 local last_value = card_value(last_card)
 local next_suit = card_suit(next_card)
 local next_value = card_value(next_card)
 return ((last_suit == next_suit) and (last_value == (next_value + 1))) end valid_bakers_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_10_)


 local winning_foundation_sequence_3f
 do
 local valid_sequence_3f

 local function _13_(next_card, _11_) local _arg_12_ = _11_ local last_card = _arg_12_[1]
 return ((card_suit(next_card) == card_suit(last_card)) and (card_value(next_card) == (1 + card_value(last_card)))) end valid_sequence_3f = CardGameUtils["make-valid-sequence?-fn"](_13_)


 local function _14_(sequence)
 return ((rank_value("king") == #sequence) and valid_sequence_3f(sequence)) end winning_foundation_sequence_3f = _14_ end


 local function valid_sequence_3f(rules, sequence)
 if (rules == "freecell") then
 return valid_freecell_sequence_3f(sequence) elseif (rules == "bakers") then
 return valid_bakers_sequence_3f(sequence) else return nil end end

 local function build_move_plan(cur_state, from, to) _G.assert((nil ~= to), "Missing argument to on fnl/playtime/game/freecell/logic.fnl:78") _G.assert((nil ~= from), "Missing argument from on fnl/playtime/game/freecell/logic.fnl:78") _G.assert((nil ~= cur_state), "Missing argument cur-state on fnl/playtime/game/freecell/logic.fnl:78")
 local function find_empty_cells(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/freecell/logic.fnl:79")
 local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 4 do local val_20_auto
 if table["empty?"](location_contents(state, {"cell", i})) then
 val_20_auto = {"cell", i, 1} else val_20_auto = nil end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto end

 local function find_empty_columns(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/freecell/logic.fnl:84")
 local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 8 do local val_20_auto
 if table["empty?"](location_contents(state, {"tableau", i})) then
 val_20_auto = {"tableau", i, 1} else val_20_auto = nil end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto end

 local function stack_unstack_move(cur_state0, _20_, _22_) local _arg_21_ = _20_ local from_f = _arg_21_[1] local from_c = _arg_21_[2] local from_n = _arg_21_[3] local from0 = _arg_21_ local _arg_23_ = _22_ local to_f = _arg_23_[1] local to_c = _arg_23_[2] local to_n = _arg_23_[3] local to0 = _arg_23_ _G.assert((nil ~= to0), "Missing argument to on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= to_n), "Missing argument to-n on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= to_c), "Missing argument to-c on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= to_f), "Missing argument to-f on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= from0), "Missing argument from on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= from_n), "Missing argument from-n on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= from_c), "Missing argument from-c on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= from_f), "Missing argument from-f on fnl/playtime/game/freecell/logic.fnl:89") _G.assert((nil ~= cur_state0), "Missing argument cur-state on fnl/playtime/game/freecell/logic.fnl:89")


 local next_state = clone(cur_state0)
 local from_t = next_state[from_f][from_c]
 local to_t = next_state[to_f][to_c]
 local total_cards_to_move = (#from_t - (from_n - 1))

 local num_cards_to_hold = (total_cards_to_move - 1) local holding_locs
 do local t = {}
 do local tbl_17_auto = t for _, l in ipairs(find_empty_cells(next_state)) do table.insert(tbl_17_auto, l) end end
 do local tbl_17_auto = t for _, l in ipairs(find_empty_columns(next_state)) do table.insert(tbl_17_auto, l) end end
 local tbl_18_auto = {} local i_19_auto = 0 for _, l in ipairs(t) do local val_20_auto
 if not same_location_field_column_3f(to0, l) then val_20_auto = l else val_20_auto = nil end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end holding_locs = tbl_18_auto end
 if (num_cards_to_hold <= #holding_locs) then
 local unstack, restack = nil, nil do local unstack0, restack0 = {}, {} for i = 1, num_cards_to_hold do

 local _let_26_ = holding_locs[i] local hold_f = _let_26_[1] local hold_c = _let_26_[2] local hold_n = _let_26_[3]


 local from_loc = {from_f, from_c, (#from_t - (i - 1))}

 local to_loc = {to_f, to_c, (#to_t + 1 + (num_cards_to_hold - i) + 1)}
 local unstack_move = {"move", from_loc, {hold_f, hold_c, hold_n}}
 local restack_move = {"move", {hold_f, hold_c, hold_n}, to_loc}


 table.insert(unstack0, unstack_move)
 table.insert(restack0, 1, restack_move)
 unstack0, restack0 = unstack0, restack0 end unstack, restack = unstack0, restack0 end
 table.insert(unstack, {"move", from0, to0})
 local tbl_17_auto = unstack for _, re in ipairs(restack) do table.insert(tbl_17_auto, re) end return tbl_17_auto else
 local function _33_() local data_5_auto = {["total-cards-to-move"] = total_cards_to_move} local resolve_6_auto local function _27_(name_7_auto) local _28_ = data_5_auto[name_7_auto] local function _29_() local t_8_auto = _28_ return ("table" == type(t_8_auto)) end if ((nil ~= _28_) and _29_()) then local t_8_auto = _28_ local _30_ = getmetatable(t_8_auto) if ((_G.type(_30_) == "table") and (nil ~= _30_.__tostring)) then local f_9_auto = _30_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _30_ return vim.inspect(t_8_auto) end elseif (nil ~= _28_) then local v_11_auto = _28_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _27_ return string.gsub("Unable to plan move for #{total-cards-to-move} cards, not enough holding spaces", "#{(.-)}", resolve_6_auto) end return nil, _33_() end end

 local next_state = clone(cur_state)
 local _35_, _36_ = stack_unstack_move(next_state, from, to) if (nil ~= _35_) then local moves = _35_

 return moves elseif ((_35_ == nil) and (nil ~= _36_)) then local err = _36_


 local _let_37_ = from local from_f = _let_37_[1] local from_c = _let_37_[2] local from_n = _let_37_[3]
 local _let_38_ = to local to_f = _let_38_[1] local to_c = _let_38_[2] local to_n = _let_38_[3] local sub_stack_to
 local function _39_() local tbl_18_auto = {} local i_19_auto = 0 for _, l in ipairs(find_empty_columns(next_state)) do local val_20_auto
 if not same_location_field_column_3f(to, l) then val_20_auto = l else val_20_auto = nil end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto end sub_stack_to = table.first(_39_())

 if sub_stack_to then
 local holding_locs do local t = {}
 do local tbl_17_auto = t for _, l in ipairs(find_empty_cells(next_state)) do table.insert(tbl_17_auto, l) end end
 do local tbl_17_auto = t for _, l in ipairs(find_empty_columns(next_state)) do table.insert(tbl_17_auto, l) end end
 local tbl_18_auto = {} local i_19_auto = 0 for _, _42_ in ipairs(t) do local _each_43_ = _42_ local f = _each_43_[1] local c = _each_43_[2] local l = _each_43_ local val_20_auto
 if (not same_location_field_column_3f(to, l) and not same_location_field_column_3f(sub_stack_to, l)) then

 val_20_auto = l else val_20_auto = nil end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end holding_locs = tbl_18_auto end
 local from_t = next_state[from_f][from_c]
 local sub_stack_from = {from_f, from_c, (#from_t - #holding_locs)}
 local _46_, _47_ = build_move_plan(next_state, sub_stack_from, sub_stack_to) if (nil ~= _46_) then local moves = _46_



 local next_state0 = apply_events(next_state, moves)
 local _48_ = build_move_plan(next_state0, from, to) if (nil ~= _48_) then local next_moves = _48_
 local next_state1 = apply_events(next_state0, next_moves)
 local sub_stack_from0 = sub_stack_to
 local sub_stack_to0 = {to_f, to_c, (1 + #next_state1[to_f][to_c])}
 local unwind_moves = stack_unstack_move(next_state1, sub_stack_from0, sub_stack_to0)
 do local tbl_17_auto = moves for _, move in ipairs(next_moves) do table.insert(tbl_17_auto, move) end end
 local tbl_17_auto = moves for _, move in ipairs(unwind_moves) do table.insert(tbl_17_auto, move) end return tbl_17_auto elseif (_48_ == nil) then
 local function _55_() local data_5_auto = {from = from, to = to} local resolve_6_auto local function _49_(name_7_auto) local _50_ = data_5_auto[name_7_auto] local function _51_() local t_8_auto = _50_ return ("table" == type(t_8_auto)) end if ((nil ~= _50_) and _51_()) then local t_8_auto = _50_ local _52_ = getmetatable(t_8_auto) if ((_G.type(_52_) == "table") and (nil ~= _52_.__tostring)) then local f_9_auto = _52_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _52_ return vim.inspect(t_8_auto) end elseif (nil ~= _50_) then local v_11_auto = _50_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _49_ return string.gsub("Cannot plan #{from} -> #{to}, not enough spaces", "#{(.-)}", resolve_6_auto) end return nil, _55_() else return nil end elseif ((_46_ == nil) and (nil ~= _47_)) then local err0 = _47_

 local function _63_() local data_5_auto = {from = from, to = to} local resolve_6_auto local function _57_(name_7_auto) local _58_ = data_5_auto[name_7_auto] local function _59_() local t_8_auto = _58_ return ("table" == type(t_8_auto)) end if ((nil ~= _58_) and _59_()) then local t_8_auto = _58_ local _60_ = getmetatable(t_8_auto) if ((_G.type(_60_) == "table") and (nil ~= _60_.__tostring)) then local f_9_auto = _60_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _60_ return vim.inspect(t_8_auto) end elseif (nil ~= _58_) then local v_11_auto = _58_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _57_ return string.gsub("Cannot plan #{from} -> #{to}, not enough spaces", "#{(.-)}", resolve_6_auto) end return nil, _63_() else return nil end else
 local function _71_() local data_5_auto = {from = from, to = to} local resolve_6_auto local function _65_(name_7_auto) local _66_ = data_5_auto[name_7_auto] local function _67_() local t_8_auto = _66_ return ("table" == type(t_8_auto)) end if ((nil ~= _66_) and _67_()) then local t_8_auto = _66_ local _68_ = getmetatable(t_8_auto) if ((_G.type(_68_) == "table") and (nil ~= _68_.__tostring)) then local f_9_auto = _68_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _68_ return vim.inspect(t_8_auto) end elseif (nil ~= _66_) then local v_11_auto = _66_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _65_ return string.gsub("Cannot plan #{from} -> #{to}, no free columns", "#{(.-)}", resolve_6_auto) end return nil, _71_() end else return nil end end

 M.Action.deal = function(state)
 local moves do local moves0, t_col, row = {}, 1, 1 for i = #state.draw[1], 1, -1 do

 local from = {"draw", 1, i}
 local to = {"tableau", t_col, row}



 local _74_ if (t_col == 8) then _74_ = 1 else _74_ = (t_col + 1) end
 local function _76_() if (t_col == 8) then return (row + 1) else return row end end moves0, t_col, row = table.insert(table.insert(moves0, {"move", from, to}), {"face-up", to}), _74_, _76_() end moves = moves0, t_col, row end
 local next_state, moves0 = apply_events(clone(state), moves)
 return next_state, moves0 end

 local function check_pick_up(state, pick_up_from)
 if ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "tableau") and (nil ~= pick_up_from[2]) and (nil ~= pick_up_from[3])) then local col_n = pick_up_from[2] local card_n = pick_up_from[3]

 local remaining, held = table.split(state.tableau[col_n], card_n)
 if valid_sequence_3f(state.rules, held) then
 return held else
 if ((_G.type(held) == "table") and (held[1] == nil)) then
 local function _83_() local data_5_auto = {["col-n"] = col_n} local resolve_6_auto local function _77_(name_7_auto) local _78_ = data_5_auto[name_7_auto] local function _79_() local t_8_auto = _78_ return ("table" == type(t_8_auto)) end if ((nil ~= _78_) and _79_()) then local t_8_auto = _78_ local _80_ = getmetatable(t_8_auto) if ((_G.type(_80_) == "table") and (nil ~= _80_.__tostring)) then local f_9_auto = _80_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _80_ return vim.inspect(t_8_auto) end elseif (nil ~= _78_) then local v_11_auto = _78_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _77_ return string.gsub("No cards to pick up from tableau column #{col-n}", "#{(.-)}", resolve_6_auto) end return nil, _83_() else local _ = held
 local function _90_() local data_5_auto = {} local resolve_6_auto local function _84_(name_7_auto) local _85_ = data_5_auto[name_7_auto] local function _86_() local t_8_auto = _85_ return ("table" == type(t_8_auto)) end if ((nil ~= _85_) and _86_()) then local t_8_auto = _85_ local _87_ = getmetatable(t_8_auto) if ((_G.type(_87_) == "table") and (nil ~= _87_.__tostring)) then local f_9_auto = _87_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _87_ return vim.inspect(t_8_auto) end elseif (nil ~= _85_) then local v_11_auto = _85_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _84_ return string.gsub("Must pick up run of alternating suit, descending rank", "#{(.-)}", resolve_6_auto) end return nil, _90_() end end elseif ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "cell") and (nil ~= pick_up_from[2]) and (pick_up_from[3] == 1)) then local col_n = pick_up_from[2]


 local remaining, held = table.split(state.cell[col_n], 1)
 local _93_ = #held if (_93_ == 1) then
 return held elseif (_93_ == 0) then
 local function _100_() local data_5_auto = {} local resolve_6_auto local function _94_(name_7_auto) local _95_ = data_5_auto[name_7_auto] local function _96_() local t_8_auto = _95_ return ("table" == type(t_8_auto)) end if ((nil ~= _95_) and _96_()) then local t_8_auto = _95_ local _97_ = getmetatable(t_8_auto) if ((_G.type(_97_) == "table") and (nil ~= _97_.__tostring)) then local f_9_auto = _97_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _97_ return vim.inspect(t_8_auto) end elseif (nil ~= _95_) then local v_11_auto = _95_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _94_ return string.gsub("No card to pick up from free cell", "#{(.-)}", resolve_6_auto) end return nil, _100_() elseif (nil ~= _93_) then local n = _93_
 local function _107_() local data_5_auto = {} local resolve_6_auto local function _101_(name_7_auto) local _102_ = data_5_auto[name_7_auto] local function _103_() local t_8_auto = _102_ return ("table" == type(t_8_auto)) end if ((nil ~= _102_) and _103_()) then local t_8_auto = _102_ local _104_ = getmetatable(t_8_auto) if ((_G.type(_104_) == "table") and (nil ~= _104_.__tostring)) then local f_9_auto = _104_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _104_ return vim.inspect(t_8_auto) end elseif (nil ~= _102_) then local v_11_auto = _102_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _101_ return string.gsub("May only pick up one card at a time from free cell", "#{(.-)}", resolve_6_auto) end return nil, _107_() else return nil end elseif ((_G.type(pick_up_from) == "table") and (nil ~= pick_up_from[1])) then local field = pick_up_from[1]


 local function _115_() local data_5_auto = {field = field} local resolve_6_auto local function _109_(name_7_auto) local _110_ = data_5_auto[name_7_auto] local function _111_() local t_8_auto = _110_ return ("table" == type(t_8_auto)) end if ((nil ~= _110_) and _111_()) then local t_8_auto = _110_ local _112_ = getmetatable(t_8_auto) if ((_G.type(_112_) == "table") and (nil ~= _112_.__tostring)) then local f_9_auto = _112_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _112_ return vim.inspect(t_8_auto) end elseif (nil ~= _110_) then local v_11_auto = _110_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _109_ return string.gsub("May not pick up from #{field}", "#{(.-)}", resolve_6_auto) end return nil, _115_() else return nil end end

 local function put_down(state, pick_up_from, dropped_on, held)
 local _117_, _118_, _119_ = pick_up_from, dropped_on, held local function _120_() local field = _117_[1] local col = _117_[2] local from_n = _117_[3] local on_n = _118_[3] local _ = _119_ return (from_n == (1 + on_n)) end if ((((_G.type(_117_) == "table") and (nil ~= _117_[1]) and (nil ~= _117_[2]) and (nil ~= _117_[3])) and ((_G.type(_118_) == "table") and (_117_[1] == _118_[1]) and (_117_[2] == _118_[2]) and (nil ~= _118_[3])) and true) and _120_()) then local field = _117_[1] local col = _117_[2] local from_n = _117_[3] local on_n = _118_[3] local _ = _119_


 return nil else local function _121_() local _ = _117_ local field = _118_[1] local col_n = _118_[2] local card_n = _118_[3] local _0 = _119_ return not (card_n == #state[field][col_n]) end if ((true and ((_G.type(_118_) == "table") and (nil ~= _118_[1]) and (nil ~= _118_[2]) and (nil ~= _118_[3])) and true) and _121_()) then local _ = _117_ local field = _118_[1] local col_n = _118_[2] local card_n = _118_[3] local _0 = _119_



 local function _128_() local data_5_auto = {} local resolve_6_auto local function _122_(name_7_auto) local _123_ = data_5_auto[name_7_auto] local function _124_() local t_8_auto = _123_ return ("table" == type(t_8_auto)) end if ((nil ~= _123_) and _124_()) then local t_8_auto = _123_ local _125_ = getmetatable(t_8_auto) if ((_G.type(_125_) == "table") and (nil ~= _125_.__tostring)) then local f_9_auto = _125_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _125_ return vim.inspect(t_8_auto) end elseif (nil ~= _123_) then local v_11_auto = _123_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _122_ return string.gsub("Must place cards on the bottom of a cascade", "#{(.-)}", resolve_6_auto) end return nil, _128_() elseif (true and ((_G.type(_118_) == "table") and (_118_[1] == "foundation")) and ((_G.type(_119_) == "table") and (nil ~= _119_[1]) and (nil ~= _119_[2]))) then local _ = _117_ local multiple = _119_[1] local cards = _119_[2]




 local function _135_() local data_5_auto = {} local resolve_6_auto local function _129_(name_7_auto) local _130_ = data_5_auto[name_7_auto] local function _131_() local t_8_auto = _130_ return ("table" == type(t_8_auto)) end if ((nil ~= _130_) and _131_()) then local t_8_auto = _130_ local _132_ = getmetatable(t_8_auto) if ((_G.type(_132_) == "table") and (nil ~= _132_.__tostring)) then local f_9_auto = _132_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _132_ return vim.inspect(t_8_auto) end elseif (nil ~= _130_) then local v_11_auto = _130_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _129_ return string.gsub("May only place cards on a foundation one at a time", "#{(.-)}", resolve_6_auto) end return nil, _135_() elseif (true and ((_G.type(_118_) == "table") and (_118_[1] == "foundation") and (nil ~= _118_[2]) and (_118_[3] == 0)) and ((_G.type(_119_) == "table") and (nil ~= _119_[1]) and (_119_[2] == nil))) then local _ = _117_ local f_col_n = _118_[2] local card = _119_[1]



 if ((_G.type(card) == "table") and true and (card[2] == 1)) then local _suit = card[1]
 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col_n, 1}}}) else local _0 = card


 local function _142_() local data_5_auto = {} local resolve_6_auto local function _136_(name_7_auto) local _137_ = data_5_auto[name_7_auto] local function _138_() local t_8_auto = _137_ return ("table" == type(t_8_auto)) end if ((nil ~= _137_) and _138_()) then local t_8_auto = _137_ local _139_ = getmetatable(t_8_auto) if ((_G.type(_139_) == "table") and (nil ~= _139_.__tostring)) then local f_9_auto = _139_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _139_ return vim.inspect(t_8_auto) end elseif (nil ~= _137_) then local v_11_auto = _137_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _136_ return string.gsub("Must build foundations same suit, 1, 2, ... 10, J, Q, K", "#{(.-)}", resolve_6_auto) end return nil, _142_() end elseif (true and ((_G.type(_118_) == "table") and (_118_[1] == "foundation") and (nil ~= _118_[2]) and (nil ~= _118_[3])) and ((_G.type(_119_) == "table") and (nil ~= _119_[1]) and (_119_[2] == nil))) then local _ = _117_ local f_col_n = _118_[2] local f_card_n = _118_[3] local new_card = _119_[1]



 local onto_card = location_contents(state, dropped_on)
 local _144_, _145_ = onto_card, new_card local function _146_() local suit = _144_[1] return (-1 == (card_value(onto_card) - card_value(new_card))) end if ((((_G.type(_144_) == "table") and (nil ~= _144_[1])) and ((_G.type(_145_) == "table") and (_144_[1] == _145_[1]))) and _146_()) then local suit = _144_[1]

 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col_n, (f_card_n + 1)}}}) else local _0 = _144_


 local function _153_() local data_5_auto = {} local resolve_6_auto local function _147_(name_7_auto) local _148_ = data_5_auto[name_7_auto] local function _149_() local t_8_auto = _148_ return ("table" == type(t_8_auto)) end if ((nil ~= _148_) and _149_()) then local t_8_auto = _148_ local _150_ = getmetatable(t_8_auto) if ((_G.type(_150_) == "table") and (nil ~= _150_.__tostring)) then local f_9_auto = _150_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _150_ return vim.inspect(t_8_auto) end elseif (nil ~= _148_) then local v_11_auto = _148_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _147_ return string.gsub("Must build foundations in same-suit, ascending order", "#{(.-)}", resolve_6_auto) end return nil, _153_() end elseif (true and ((_G.type(_118_) == "table") and (_118_[1] == "cell")) and ((_G.type(_119_) == "table") and (nil ~= _119_[1]) and (nil ~= _119_[2]))) then local _ = _117_ local multiple = _119_[1] local cards = _119_[2]



 local function _161_() local data_5_auto = {} local resolve_6_auto local function _155_(name_7_auto) local _156_ = data_5_auto[name_7_auto] local function _157_() local t_8_auto = _156_ return ("table" == type(t_8_auto)) end if ((nil ~= _156_) and _157_()) then local t_8_auto = _156_ local _158_ = getmetatable(t_8_auto) if ((_G.type(_158_) == "table") and (nil ~= _158_.__tostring)) then local f_9_auto = _158_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _158_ return vim.inspect(t_8_auto) end elseif (nil ~= _156_) then local v_11_auto = _156_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _155_ return string.gsub("May only place single cards on a cell", "#{(.-)}", resolve_6_auto) end return nil, _161_() else local function _162_() local _ = _117_ local col_n = _118_[2] local card_n = _118_[3] local _0 = _119_ return not (0 == card_n) end if ((true and ((_G.type(_118_) == "table") and (_118_[1] == "cell") and (nil ~= _118_[2]) and (nil ~= _118_[3])) and true) and _162_()) then local _ = _117_ local col_n = _118_[2] local card_n = _118_[3] local _0 = _119_

 local function _169_() local data_5_auto = {} local resolve_6_auto local function _163_(name_7_auto) local _164_ = data_5_auto[name_7_auto] local function _165_() local t_8_auto = _164_ return ("table" == type(t_8_auto)) end if ((nil ~= _164_) and _165_()) then local t_8_auto = _164_ local _166_ = getmetatable(t_8_auto) if ((_G.type(_166_) == "table") and (nil ~= _166_.__tostring)) then local f_9_auto = _166_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _166_ return vim.inspect(t_8_auto) end elseif (nil ~= _164_) then local v_11_auto = _164_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _163_ return string.gsub("May only place single cards on a cell", "#{(.-)}", resolve_6_auto) end return nil, _169_() elseif (true and ((_G.type(_118_) == "table") and (_118_[1] == "cell") and (nil ~= _118_[2]) and (_118_[3] == 0)) and ((_G.type(_119_) == "table") and (nil ~= _119_[1]) and (_119_[2] == nil))) then local _ = _117_ local col_n = _118_[2] local new_card = _119_[1]


 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"cell", col_n, 1}}}) else local function _170_() local a = _117_[2] local b = _118_[2] local _ = _119_ return not (a == b) end if ((((_G.type(_117_) == "table") and (_117_[1] == "tableau") and (nil ~= _117_[2]) and (_117_[3] == 1)) and ((_G.type(_118_) == "table") and (_118_[1] == "tableau") and (nil ~= _118_[2]) and (_118_[3] == 0)) and true) and _170_()) then local a = _117_[2] local b = _118_[2] local _ = _119_






 local from_col = state.tableau[a] local moves
 do local tbl_18_auto = {} local i_19_auto = 0 for i, _card in ipairs(from_col) do
 local val_20_auto = {"move", {"tableau", a, i}, {"tableau", b, i}} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end moves = tbl_18_auto end
 return apply_events(clone(state), moves, {["unsafely?"] = true}) elseif (true and ((_G.type(_118_) == "table") and (_118_[1] == "tableau") and (nil ~= _118_[2]) and (nil ~= _118_[3])) and true) then local _ = _117_ local t_col = _118_[2] local t_card_n = _118_[3] local _0 = _119_



 local _172_ = build_move_plan(state, pick_up_from, {"tableau", t_col, (1 + t_card_n)}) if (nil ~= _172_) then local moves = _172_
 local next_state = apply_events(inc_moves(clone(state), #moves), moves)


 local _1, new_run = table.split(next_state.tableau[t_col], t_card_n)
 if valid_sequence_3f(state.rules, new_run) then
 return next_state, moves else

 local function _179_() local data_5_auto = {} local resolve_6_auto local function _173_(name_7_auto) local _174_ = data_5_auto[name_7_auto] local function _175_() local t_8_auto = _174_ return ("table" == type(t_8_auto)) end if ((nil ~= _174_) and _175_()) then local t_8_auto = _174_ local _176_ = getmetatable(t_8_auto) if ((_G.type(_176_) == "table") and (nil ~= _176_.__tostring)) then local f_9_auto = _176_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _176_ return vim.inspect(t_8_auto) end elseif (nil ~= _174_) then local v_11_auto = _174_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _173_ return string.gsub("Must build piles in alternating color, descending rank", "#{(.-)}", resolve_6_auto) end return nil, _179_() end else local _1 = _172_
 local function _187_() local data_5_auto = {len = #held} local resolve_6_auto local function _181_(name_7_auto) local _182_ = data_5_auto[name_7_auto] local function _183_() local t_8_auto = _182_ return ("table" == type(t_8_auto)) end if ((nil ~= _182_) and _183_()) then local t_8_auto = _182_ local _184_ = getmetatable(t_8_auto) if ((_G.type(_184_) == "table") and (nil ~= _184_.__tostring)) then local f_9_auto = _184_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _184_ return vim.inspect(t_8_auto) end elseif (nil ~= _182_) then local v_11_auto = _182_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _181_ return string.gsub("Not enough spaces to move #{len} cards", "#{(.-)}", resolve_6_auto) end return nil, _187_() end else local _ = _117_


 local function _195_() local data_5_auto = {["dropped-on"] = dropped_on} local resolve_6_auto local function _189_(name_7_auto) local _190_ = data_5_auto[name_7_auto] local function _191_() local t_8_auto = _190_ return ("table" == type(t_8_auto)) end if ((nil ~= _190_) and _191_()) then local t_8_auto = _190_ local _192_ = getmetatable(t_8_auto) if ((_G.type(_192_) == "table") and (nil ~= _192_.__tostring)) then local f_9_auto = _192_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _192_ return vim.inspect(t_8_auto) end elseif (nil ~= _190_) then local v_11_auto = _190_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _189_ return string.gsub("No putdown for #{dropped-on}", "#{(.-)}", resolve_6_auto) end return nil, _195_() end end end end end

 M.Action.move = function(state, pick_up_from, put_down_on)
 local function _197_(...) local _198_ = ... if (nil ~= _198_) then local held = _198_ local function _199_(...) local _200_, _201_ = ... if ((nil ~= _200_) and (nil ~= _201_)) then local next_state = _200_ local moves = _201_


 return next_state, moves else local __84_auto = _200_ return ... end end return _199_(put_down(state, pick_up_from, put_down_on, held)) else local __84_auto = _198_ return ... end end return _197_(check_pick_up(state, pick_up_from)) end

 local function freecell_plan_next_move_to_foundation(state)






 local speculative_state = clone(state) local check_locations
 do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 4 do local val_20_auto = {"cell", i} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end check_locations = tbl_18_auto end local _
 do local tbl_17_auto = check_locations for i = 1, 8 do table.insert(tbl_17_auto, {"tableau", i}) end _ = tbl_17_auto end local min_values
 do local min_vals = {red = math.huge, black = math.huge} for _l, card in M["iter-cards"](speculative_state, {"cell", "tableau"}) do

 local color = card_color(card)
 local val = card_value(card)
 min_vals = table.set(min_vals, color, math.min(val, min_vals[color])) end min_values = min_vals end local source_locations
 do local tbl_18_auto = {} local i_19_auto = 0 for _0, _205_ in ipairs(check_locations) do local _each_206_ = _205_ local field = _each_206_[1] local col = _each_206_[2] local val_20_auto
 do local card_n = #speculative_state[field][col]
 local _207_ = speculative_state[field][col][card_n] if (nil ~= _207_) then local card = _207_
 local alt_color if ("red" == card_color(card)) then alt_color = "black" else alt_color = "red" end
 local val = card_value(card)
 if ((card_value(card) <= min_values[alt_color]) or (2 == val)) then

 val_20_auto = {field, col, card_n} else val_20_auto = nil end else val_20_auto = nil end end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end source_locations = tbl_18_auto end
 local moves = {} for _0, from in ipairs(source_locations) do
 local tbl_17_auto = moves for i = 1, 4 do
 local function _213_() local _212_ = speculative_state.foundation[i] if ((_G.type(_212_) == "table") and (_212_[1] == nil)) then
 return {from, {"foundation", i, 0}} elseif (nil ~= _212_) then local cards = _212_
 return {from, {"foundation", i, #cards}} else return nil end end table.insert(tbl_17_auto, _213_()) end moves = tbl_17_auto end return moves end

 local function bakers_plan_next_move_to_foundation(state)


 local speculative_state = clone(state) local check_locations
 do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 4 do local val_20_auto = {"cell", i} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end check_locations = tbl_18_auto end local _
 do local tbl_17_auto = check_locations for i = 1, 8 do table.insert(tbl_17_auto, {"tableau", i}) end _ = tbl_17_auto end local min_values
 do local min_vals = {spades = math.huge, hearts = math.huge, diamonds = math.huge, clubs = math.huge} for _l, card in M["iter-cards"](speculative_state, {"cell", "tableau"}) do


 local suit = card_suit(card)
 local val = card_value(card)
 min_vals = table.set(min_vals, suit, math.min(val, min_vals[suit])) end min_values = min_vals end local source_locations
 do local tbl_18_auto = {} local i_19_auto = 0 for _0, _216_ in ipairs(check_locations) do local _each_217_ = _216_ local field = _each_217_[1] local col = _each_217_[2] local val_20_auto
 do local card_n = #speculative_state[field][col]
 local _218_ = speculative_state[field][col][card_n] if (nil ~= _218_) then local card = _218_
 local suit = card_suit(card)
 if (card_value(card) == min_values[suit]) then
 val_20_auto = {field, col, card_n} else val_20_auto = nil end else val_20_auto = nil end end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end source_locations = tbl_18_auto end
 local moves = {} for _0, from in ipairs(source_locations) do
 local tbl_17_auto = moves for i = 1, 4 do
 local function _223_() local _222_ = speculative_state.foundation[i] if ((_G.type(_222_) == "table") and (_222_[1] == nil)) then
 return {from, {"foundation", i, 0}} elseif (nil ~= _222_) then local cards = _222_
 return {from, {"foundation", i, #cards}} else return nil end end table.insert(tbl_17_auto, _223_()) end moves = tbl_17_auto end return moves end

 M.Plan["next-move-to-foundation"] = function(state)
 local potential_moves do local _225_ = state.rules if (_225_ == "freecell") then
 potential_moves = freecell_plan_next_move_to_foundation(state) elseif (_225_ == "bakers") then
 potential_moves = bakers_plan_next_move_to_foundation(state) else potential_moves = nil end end
 local actions = nil for _, _227_ in ipairs(potential_moves) do local _each_228_ = _227_ local pick_up_from = _each_228_[1] local put_down_on = _each_228_[2] if actions then break end
 local function _229_(...) local _230_ = ... if (nil ~= _230_) then local speculative_state = _230_

 return {pick_up_from, put_down_on} else local __84_auto = _230_ return ... end end actions = _229_(M.Action.move(clone(state), pick_up_from, put_down_on)) end return actions end

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