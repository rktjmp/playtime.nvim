
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}



 local _local_2_ = CardGameUtils local apply_events = _local_2_["apply-events"]
 local _local_3_ = CardGameUtils["make-card-util-fns"]({value = {14, king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_3_["card-value"] local card_color = _local_3_["card-color"] local card_rank = _local_3_["card-rank"] local card_suit = _local_3_["card-suit"]
 local rank_value = _local_3_["rank-value"]
 local suit_color = _local_3_["suit-color"]
 local card_face_up_3f = _local_3_["card-face-up?"] local card_face_down_3f = _local_3_["card-face-down?"]
 local flip_face_up = _local_3_["flip-face-up"] local flip_face_down = _local_3_["flip-face-down"]




 local function build_path(play_loc)
 if ((_G.type(play_loc) == "table") and (play_loc[1] == "play") and (play_loc[2] == "top") and (nil ~= play_loc[3])) then local col = play_loc[3]
 local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 6 do local val_20_auto = {"grid", i, col} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto elseif ((_G.type(play_loc) == "table") and (play_loc[1] == "play") and (play_loc[2] == "bottom") and (nil ~= play_loc[3])) then local col = play_loc[3]
 local tbl_18_auto = {} local i_19_auto = 0 for i = 6, 1, -1 do local val_20_auto = {"grid", i, col} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto elseif ((_G.type(play_loc) == "table") and (play_loc[1] == "play") and (play_loc[2] == "left") and (nil ~= play_loc[3])) then local row = play_loc[3]
 local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 6 do local val_20_auto = {"grid", row, i} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto elseif ((_G.type(play_loc) == "table") and (play_loc[1] == "play") and (play_loc[2] == "right") and (nil ~= play_loc[3])) then local row = play_loc[3]
 local tbl_18_auto = {} local i_19_auto = 0 for i = 6, 1, -1 do local val_20_auto = {"grid", row, i} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto else return nil end end

 M.build = function(config, _3fseed) _G.assert((nil ~= config), "Missing argument config on fnl/playtime/game/optrita-lines/logic.fnl:30")
 math.randomseed((_3fseed or os.time()))
 local config0 = table.merge({["score-limit"] = {player = 31, grid = 11}}, config) local deck, _other = nil, nil

 local function _9_(c) return not (10 == card_value(c)) end deck, _other = Deck.shuffle(Deck.split(Deck.Standard52.build(), _9_))

 local state = {score = {player = 0, grid = 0}, rules = {["score-limit"] = {grid = config0["score-limit"].grid, player = config0["score-limit"].player}}, grid = {{}, {}, {}, {}, {}, {}}, trick = {player = {{}, {}, {}, {}, {}, {}}, grid = {{}, {}, {}, {}, {}, {}}}, draw = {}, trump = {}, hand = {}}








 state["draw"] = deck
 return state end

 M["iter-cards"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:48")
 local function iter()
 for row_n, row in ipairs(state.grid) do
 for i = 1, 6 do
 local _10_ = row[i] if (nil ~= _10_) then local card = _10_
 coroutine.yield({"grid", row_n, i}, card) else end end end
 for side, tricks in pairs(state.trick) do
 for trick_n, trick in ipairs(tricks) do
 for i = 1, 2 do
 local _12_ = trick[i] if (nil ~= _12_) then local card = _12_
 coroutine.yield({"trick", side, trick_n, i}, card) else end end end end
 for _, field in ipairs({"draw", "hand", "trump"}) do
 for card_n, card in ipairs(state[field]) do
 coroutine.yield({field, card_n}, card) end end return nil end
 return coroutine.wrap(iter) end

 M.Action["score-round"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:64")
 local function sum_tricks(key) local sum = 0
 for _, trick in ipairs(state.trick[key]) do
 if ((_G.type(trick) == "table") and (trick[1] == nil)) then
 sum = sum else local _0 = trick
 sum = (1 + sum) end end return sum end
 local player = sum_tricks("player")
 local grid = sum_tricks("grid")
 local state0 = clone(state)
 state0.score.player = (state0.score.player + player)
 state0.score.grid = (state0.score.grid + grid)
 return state0 end

 M.Action["clear-round"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:77")
 local function clear_tricks_21(state0)
 local events = {}
 do local _15_ = state0.trump if ((_G.type(_15_) == "table") and (nil ~= _15_[1])) then local c = _15_[1]
 table.join(events, {{"face-down", {"trump", 1}}, {"move", {"trump", 1}, {"draw", "bottom"}}}) else end end

 for side, tricks in pairs(state0.trick) do
 for trick_n, trick in ipairs(tricks) do
 for i, _ in ipairs(trick) do
 table.join(events, {{"face-down", {"trick", side, trick_n, i}}, {"move", {"trick", side, trick_n, i}, {"draw", "bottom"}}}) end end end

 return apply_events(state0, events) end

 local function clear_rows_21(state0)
 local paths do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 6 do local val_20_auto = build_path({"play", "left", i}) if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end paths = tbl_18_auto end local all_ups
 do local tbl_18_auto = {} local i_19_auto = 0 for _, path in ipairs(paths) do local val_20_auto
 local _18_ do local up_3f = true for _0, p in ipairs(path) do if not up_3f then break end
 local _19_ = table["get-in"](state0, p) if (nil ~= _19_) then local card = _19_
 up_3f = card_face_up_3f(card) elseif (_19_ == nil) then up_3f = true else up_3f = nil end end _18_ = up_3f end if _18_ then

 val_20_auto = path else val_20_auto = nil end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end all_ups = tbl_18_auto end
 local locs = table.join({}, table.unpack(all_ups)) local events
 do local t = {} for _, loc in ipairs(locs) do
 local _23_ = table["get-in"](state0, loc) if (nil ~= _23_) then local card = _23_
 t = table.join(t, {{"face-down", loc}, {"move", loc, {"draw", "bottom"}}}) else local _0 = _23_

 t = t end end events = t end
 return apply_events(state0, events) end

 local function clear_cols_21(state0)
 local paths do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 6 do local val_20_auto = build_path({"play", "top", i}) if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end paths = tbl_18_auto end local all_ups
 do local tbl_18_auto = {} local i_19_auto = 0 for _, path in ipairs(paths) do local val_20_auto
 local _26_ do local up_3f = true for _0, p in ipairs(path) do if not up_3f then break end
 local _27_ = table["get-in"](state0, p) if (nil ~= _27_) then local card = _27_
 up_3f = card_face_up_3f(card) elseif (_27_ == nil) then up_3f = true else up_3f = nil end end _26_ = up_3f end if _26_ then

 val_20_auto = path else val_20_auto = nil end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end all_ups = tbl_18_auto end
 local locs = table.join({}, table.unpack(all_ups)) local events
 do local t = {} for _, loc in ipairs(locs) do
 local _31_ = table["get-in"](state0, loc) if (nil ~= _31_) then local card = _31_
 t = table.join(t, {{"face-down", loc}, {"move", loc, {"draw", "bottom"}}}) else local _0 = _31_

 t = t end end events = t end
 return apply_events(state0, events) end

 local state0, trick_events = clear_tricks_21(clone(state))
 local state1, row_events = clear_rows_21(state0)
 local state2, col_events = clear_cols_21(state1)
 local events = table.join(trick_events, row_events, col_events)
 Deck.shuffle(state2.draw)
 return state2, events end

 M.Action["new-round"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:129")
 local function fill_grid_21(state0)
 local events do local t = {} for row_n, _ in ipairs(state0.grid) do

 for col = 1, 6 do
 local _33_ = state0.grid[row_n][col] if (_33_ == nil) then

 table.insert(t, {"move", {"draw", "top"}, {"grid", row_n, col}})



 if ((function(_34_,_35_,_36_) return (_34_ == _35_) and (_35_ == _36_) end)(0,state0.score.player,state0.score.grid) and ((7 - row_n) == col)) then

 table.insert(t, {"face-up", {"grid", row_n, col}}) else end else end end
 t = t end events = t end
 return apply_events(state0, events) end

 local function draw_hand_21(state0)
 local events do local t = {} for i = 1, 7 do
 t = table.join(t, {{"move", {"draw", "top"}, {"hand", i}}, {"face-up", {"hand", i}}}) end events = t end

 return apply_events(state0, events) end

 local state0, fill_events = fill_grid_21(clone(state))
 local state1, draw_events = draw_hand_21(state0)
 local events = table.join(fill_events, draw_events)







 local function _39_(a, b)
 return (card_value(a) < card_value(b)) end

 local function _40_(a, b)
 local t = {hearts = 1, spades = 2, diamonds = 3, clubs = 4}
 local a0 = t[card_suit(a)]
 local b0 = t[card_suit(b)]
 return (a0 < b0) end table.sort(table.sort(state1.hand, _39_), _40_)
 return state1, events end

 M.Action["pick-trump"] = function(state, hand_n) _G.assert((nil ~= hand_n), "Missing argument hand-n on fnl/playtime/game/optrita-lines/logic.fnl:172") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:172")
 local events = {{"move", {"hand", hand_n}, {"trump", "top"}}} local events0
 do local tbl_17_auto = events for i = (hand_n + 1), #state.hand do table.insert(tbl_17_auto, {"move", {"hand", i}, {"hand", (i - 1)}}) end events0 = tbl_17_auto end

 return apply_events(clone(state), events0) end

 M.Action["play-trick"] = function(state, hand_n, play_loc) _G.assert((nil ~= play_loc), "Missing argument play-loc on fnl/playtime/game/optrita-lines/logic.fnl:178") _G.assert((nil ~= hand_n), "Missing argument hand-n on fnl/playtime/game/optrita-lines/logic.fnl:178") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:178")
 local function no_nil_cards_3f(path) local ok_3f = true
 for _, p in ipairs(path) do if not ok_3f then break end
 ok_3f = not (nil == table["get-in"](state, p)) end return ok_3f end

 local function play_path(path)
 local trump_suit = card_suit(state.trump[1]) local trick_player_n
 local _41_ do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 6 do local val_20_auto = state.trick.player[i][1] if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end _41_ = tbl_18_auto end trick_player_n = (1 + #_41_) local trick_grid_n
 local _43_ do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 6 do local val_20_auto = state.trick.grid[i][1] if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end _43_ = tbl_18_auto end trick_grid_n = (1 + #_43_)
 local player_card = state.hand[hand_n]
 local player_suit = card_suit(player_card)
 local player_value = card_value(player_card) local events, won_3f = nil, nil
 do local events0, result = {}, nil for _, p in ipairs(path) do if not (nil == result) then break end


 local grid_card = table["get-in"](state, p)
 local grid_suit = card_suit(grid_card)
 local grid_value = card_value(grid_card)
 table.insert(events0, {"face-up", p})
 local _45_, _46_, _47_, _48_ = grid_suit, grid_value, player_suit, player_value local function _49_() local suit = _45_ local against = _46_ local played = _48_ return (against < played) end if (((nil ~= _45_) and (nil ~= _46_) and (_45_ == _47_) and (nil ~= _48_)) and _49_()) then local suit = _45_ local against = _46_ local played = _48_


 local moves = {{"move", {"hand", hand_n}, {"trick", "player", trick_player_n, "top"}}, {"move", p, {"trick", "player", trick_player_n, "top"}}}

 events0, result = table.join(events0, moves), true else local function _50_() local suit = _45_ local against = _46_ local played = _48_ return (played < against) end if (((nil ~= _45_) and (nil ~= _46_) and (_45_ == _47_) and (nil ~= _48_)) and _50_()) then local suit = _45_ local against = _46_ local played = _48_


 local moves = {{"move", {"hand", hand_n}, {"trick", "grid", trick_grid_n, "top"}}, {"move", p, {"trick", "grid", trick_grid_n, "top"}}}

 events0, result = table.join(events0, moves), false else local _0 = _45_

 events0, result = events0, nil end end end events, won_3f = events0, result end local events0, won_3f0 = nil, nil
 if (nil == won_3f) then


 local trumps local _52_ do local tbl_18_auto = {} local i_19_auto = 0 for i, p in ipairs(path) do local val_20_auto
 do local grid_card = table["get-in"](state, p)
 if (trump_suit == card_suit(grid_card)) then
 val_20_auto = {p, card_value(grid_card)} else val_20_auto = nil end end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end _52_ = tbl_18_auto end
 local function _59_(_55_, _57_) local _arg_56_ = _55_ local _ = _arg_56_[1] local a = _arg_56_[2] local _arg_58_ = _57_ local _0 = _arg_58_[1] local b = _arg_58_[2] return (a < b) end trumps = table.sort(_52_, _59_) local _3ftrump_moves
 if ((_G.type(trumps) == "table") and ((_G.type(trumps[1]) == "table") and (nil ~= trumps[1][1]) and true)) then local p = trumps[1][1] local _card = trumps[1][2]
 _3ftrump_moves = {{"move", {"hand", hand_n}, {"trick", "grid", trick_grid_n, "top"}}, {"move", p, {"trick", "grid", trick_grid_n, "top"}}} else _3ftrump_moves = nil end

 if _3ftrump_moves then
 events0, won_3f0 = table.join(events, _3ftrump_moves), false else

 events0, won_3f0 = events, nil end else
 events0, won_3f0 = events, won_3f end
 if (nil == won_3f0) then
 return events0, nil else


 do local tbl_17_auto = events0 for i = (hand_n + 1), #state.hand do table.insert(tbl_17_auto, {"move", {"hand", i}, {"hand", (i - 1)}}) end end

 return events0, won_3f0 end end

 local function do_play(path)
 if not no_nil_cards_3f(path) then
 local function _70_() local data_5_auto = {} local resolve_6_auto local function _64_(name_7_auto) local _65_ = data_5_auto[name_7_auto] local function _66_() local t_8_auto = _65_ return ("table" == type(t_8_auto)) end if ((nil ~= _65_) and _66_()) then local t_8_auto = _65_ local _67_ = getmetatable(t_8_auto) if ((_G.type(_67_) == "table") and (nil ~= _67_.__tostring)) then local f_9_auto = _67_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _67_ return vim.inspect(t_8_auto) end elseif (nil ~= _65_) then local v_11_auto = _65_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _64_ return string.gsub("cant play a row or column with empty spaces", "#{(.-)}", resolve_6_auto) end return nil, _70_() else
 local _71_, _72_ = play_path(path) if ((nil ~= _71_) and (nil ~= _72_)) then local events = _71_ local player_won_3f = _72_
 local next_state, events0 = apply_events(clone(state), events)




 return next_state, events0 elseif ((nil ~= _71_) and (_72_ == nil)) then local events = _71_




 return apply_events(clone(state), events) else return nil end end end

 if (nil == state.hand[hand_n]) then
 local function _81_() local data_5_auto = {["hand-n"] = hand_n} local resolve_6_auto local function _75_(name_7_auto) local _76_ = data_5_auto[name_7_auto] local function _77_() local t_8_auto = _76_ return ("table" == type(t_8_auto)) end if ((nil ~= _76_) and _77_()) then local t_8_auto = _76_ local _78_ = getmetatable(t_8_auto) if ((_G.type(_78_) == "table") and (nil ~= _78_.__tostring)) then local f_9_auto = _78_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _78_ return vim.inspect(t_8_auto) end elseif (nil ~= _76_) then local v_11_auto = _76_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _75_ return string.gsub("No card at hand #{hand-n} to play", "#{(.-)}", resolve_6_auto) end return nil, _81_() else
 if ((_G.type(play_loc) == "table") and (play_loc[1] == "play")) then
 return do_play(build_path(play_loc)) else local _ = play_loc
 local function _88_() local data_5_auto = {["play-loc"] = play_loc} local resolve_6_auto local function _82_(name_7_auto) local _83_ = data_5_auto[name_7_auto] local function _84_() local t_8_auto = _83_ return ("table" == type(t_8_auto)) end if ((nil ~= _83_) and _84_()) then local t_8_auto = _83_ local _85_ = getmetatable(t_8_auto) if ((_G.type(_85_) == "table") and (nil ~= _85_.__tostring)) then local f_9_auto = _85_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _85_ return vim.inspect(t_8_auto) end elseif (nil ~= _83_) then local v_11_auto = _83_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _82_ return string.gsub("Cant play tricks to #{play-loc}", "#{(.-)}", resolve_6_auto) end return nil, _88_() end end end

 M.Action["force-trick"] = function(state, hand_n, play_loc) _G.assert((nil ~= play_loc), "Missing argument play-loc on fnl/playtime/game/optrita-lines/logic.fnl:256") _G.assert((nil ~= hand_n), "Missing argument hand-n on fnl/playtime/game/optrita-lines/logic.fnl:256") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:256")
 local trick_n do local n = nil for i, t in ipairs(state.trick.player) do if n then break end
 if table["empty?"](t) then n = i else n = nil end end trick_n = n end
 local events = {{"move", {"hand", hand_n}, {"trick", "player", trick_n, "top"}}, {"move", play_loc, {"trick", "player", trick_n, "top"}}} local _

 do local tbl_17_auto = events for i = (hand_n + 1), #state.hand do table.insert(tbl_17_auto, {"move", {"hand", i}, {"hand", (i - 1)}}) end _ = tbl_17_auto end

 return apply_events(clone(state), events) end

 M.Query["game-ended?"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:265")
 return ((state.rules["score-limit"].player <= state.score.player) or (state.rules["score-limit"].grid <= state.score.grid)) end


 M.Query["game-result"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:269")
 if (state.rules["score-limit"].grid <= state.score.grid) then return "grid" elseif (state.rules["score-limit"].player <= state.score.player) then return "player" else return "unfinished" end end





 M.Query["round-ended?"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:276")
 return (0 == #state.hand) end

 return M