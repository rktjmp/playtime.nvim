
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}



 local apply_events = CardGameUtils["apply-events"]
 local _local_2_ = CardGameUtils["make-card-util-fns"]({value = {14, king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_2_["card-value"] local card_color = _local_2_["card-color"] local card_rank = _local_2_["card-rank"] local card_suit = _local_2_["card-suit"]
 local rank_value = _local_2_["rank-value"]
 local suit_color = _local_2_["suit-color"]
 local card_face_up_3f = _local_2_["card-face-up?"] local card_face_down_3f = _local_2_["card-face-down?"]
 local flip_face_up = _local_2_["flip-face-up"] local flip_face_down = _local_2_["flip-face-down"]




 local function build_path(play_loc)
 if ((_G.type(play_loc) == "table") and (play_loc[1] == "play") and (play_loc[2] == "top") and (nil ~= play_loc[3])) then local col = play_loc[3]
 local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 6 do local val_23_auto = {"grid", i, col} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto elseif ((_G.type(play_loc) == "table") and (play_loc[1] == "play") and (play_loc[2] == "bottom") and (nil ~= play_loc[3])) then local col = play_loc[3]
 local tbl_21_auto = {} local i_22_auto = 0 for i = 6, 1, -1 do local val_23_auto = {"grid", i, col} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto elseif ((_G.type(play_loc) == "table") and (play_loc[1] == "play") and (play_loc[2] == "left") and (nil ~= play_loc[3])) then local row = play_loc[3]
 local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 6 do local val_23_auto = {"grid", row, i} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto elseif ((_G.type(play_loc) == "table") and (play_loc[1] == "play") and (play_loc[2] == "right") and (nil ~= play_loc[3])) then local row = play_loc[3]
 local tbl_21_auto = {} local i_22_auto = 0 for i = 6, 1, -1 do local val_23_auto = {"grid", row, i} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto else return nil end end

 M.build = function(config, _3fseed) _G.assert((nil ~= config), "Missing argument config on fnl/playtime/game/optrita-lines/logic.fnl:30")
 math.randomseed((_3fseed or os.time()))
 local config0 = table.merge({["score-limit"] = {player = 31, grid = 11}}, config) local deck, _other = nil, nil

 local function _8_(c) return not (10 == card_value(c)) end deck, _other = Deck.shuffle(Deck.split(Deck.Standard52.build(), _8_))

 local state = {score = {player = 0, grid = 0}, rules = {["score-limit"] = {grid = config0["score-limit"].grid, player = config0["score-limit"].player}}, grid = {{}, {}, {}, {}, {}, {}}, trick = {player = {{}, {}, {}, {}, {}, {}}, grid = {{}, {}, {}, {}, {}, {}}}, draw = {}, trump = {}, hand = {}}








 state["draw"] = deck
 return state end

 M["iter-cards"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:48")
 local function iter()
 for row_n, row in ipairs(state.grid) do
 for i = 1, 6 do
 local _9_ = row[i] if (nil ~= _9_) then local card = _9_
 coroutine.yield({"grid", row_n, i}, card) else end end end
 for side, tricks in pairs(state.trick) do
 for trick_n, trick in ipairs(tricks) do
 for i = 1, 2 do
 local _11_ = trick[i] if (nil ~= _11_) then local card = _11_
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
 do local _14_ = state0.trump if ((_G.type(_14_) == "table") and (nil ~= _14_[1])) then local c = _14_[1]
 table.join(events, {{"face-down", {"trump", 1}}, {"move", {"trump", 1}, {"draw", "bottom"}}}) else end end

 for side, tricks in pairs(state0.trick) do
 for trick_n, trick in ipairs(tricks) do
 for i, _ in ipairs(trick) do
 table.join(events, {{"face-down", {"trick", side, trick_n, i}}, {"move", {"trick", side, trick_n, i}, {"draw", "bottom"}}}) end end end

 return apply_events(state0, events) end

 local function clear_rows_21(state0)
 local paths do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 6 do local val_23_auto = build_path({"play", "left", i}) if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end paths = tbl_21_auto end local all_ups
 do local tbl_21_auto = {} local i_22_auto = 0 for _, path in ipairs(paths) do local val_23_auto
 local _17_ do local up_3f = true for _0, p in ipairs(path) do if not up_3f then break end
 local _18_ = table["get-in"](state0, p) if (nil ~= _18_) then local card = _18_
 up_3f = card_face_up_3f(card) elseif (_18_ == nil) then up_3f = true else up_3f = nil end end _17_ = up_3f end if _17_ then

 val_23_auto = path else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end all_ups = tbl_21_auto end
 local locs = table.join({}, table.unpack(all_ups)) local events
 do local t = {} for _, loc in ipairs(locs) do
 local _22_ = table["get-in"](state0, loc) if (nil ~= _22_) then local card = _22_
 t = table.join(t, {{"face-down", loc}, {"move", loc, {"draw", "bottom"}}}) else local _0 = _22_

 t = t end end events = t end
 return apply_events(state0, events) end

 local function clear_cols_21(state0)
 local paths do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 6 do local val_23_auto = build_path({"play", "top", i}) if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end paths = tbl_21_auto end local all_ups
 do local tbl_21_auto = {} local i_22_auto = 0 for _, path in ipairs(paths) do local val_23_auto
 local _25_ do local up_3f = true for _0, p in ipairs(path) do if not up_3f then break end
 local _26_ = table["get-in"](state0, p) if (nil ~= _26_) then local card = _26_
 up_3f = card_face_up_3f(card) elseif (_26_ == nil) then up_3f = true else up_3f = nil end end _25_ = up_3f end if _25_ then

 val_23_auto = path else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end all_ups = tbl_21_auto end
 local locs = table.join({}, table.unpack(all_ups)) local events
 do local t = {} for _, loc in ipairs(locs) do
 local _30_ = table["get-in"](state0, loc) if (nil ~= _30_) then local card = _30_
 t = table.join(t, {{"face-down", loc}, {"move", loc, {"draw", "bottom"}}}) else local _0 = _30_

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
 local _32_ = state0.grid[row_n][col] if (_32_ == nil) then

 table.insert(t, {"move", {"draw", "top"}, {"grid", row_n, col}}) local _33_ = state0.score.player



 if (((0 == _33_) and (_33_ == state0.score.grid)) and ((7 - row_n) == col)) then

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







 local function _36_(a, b)
 return (card_value(a) < card_value(b)) end

 local function _37_(a, b)
 local t = {hearts = 1, spades = 2, diamonds = 3, clubs = 4}
 local a0 = t[card_suit(a)]
 local b0 = t[card_suit(b)]
 return (a0 < b0) end table.sort(table.sort(state1.hand, _36_), _37_)
 return state1, events end

 M.Action["pick-trump"] = function(state, hand_n) _G.assert((nil ~= hand_n), "Missing argument hand-n on fnl/playtime/game/optrita-lines/logic.fnl:172") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:172")
 local events = {{"move", {"hand", hand_n}, {"trump", "top"}}} local events0
 do local tbl_19_auto = events for i = (hand_n + 1), #state.hand do
 local val_20_auto = {"move", {"hand", i}, {"hand", (i - 1)}} table.insert(tbl_19_auto, val_20_auto) end events0 = tbl_19_auto end
 return apply_events(clone(state), events0) end

 M.Action["play-trick"] = function(state, hand_n, play_loc) _G.assert((nil ~= play_loc), "Missing argument play-loc on fnl/playtime/game/optrita-lines/logic.fnl:178") _G.assert((nil ~= hand_n), "Missing argument hand-n on fnl/playtime/game/optrita-lines/logic.fnl:178") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:178")
 local function no_nil_cards_3f(path) local ok_3f = true
 for _, p in ipairs(path) do if not ok_3f then break end
 ok_3f = not (nil == table["get-in"](state, p)) end return ok_3f end

 local function play_path(path)
 local trump_suit = card_suit(state.trump[1]) local trick_player_n
 local _38_ do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 6 do local val_23_auto = state.trick.player[i][1] if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end _38_ = tbl_21_auto end trick_player_n = (1 + #_38_) local trick_grid_n
 local _40_ do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 6 do local val_23_auto = state.trick.grid[i][1] if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end _40_ = tbl_21_auto end trick_grid_n = (1 + #_40_)
 local player_card = state.hand[hand_n]
 local player_suit = card_suit(player_card)
 local player_value = card_value(player_card) local events, won_3f = nil, nil
 do local events0, result = {}, nil for _, p in ipairs(path) do if not (nil == result) then break end


 local grid_card = table["get-in"](state, p)
 local grid_suit = card_suit(grid_card)
 local grid_value = card_value(grid_card)
 table.insert(events0, {"face-up", p})
 local _42_, _43_, _44_, _45_ = grid_suit, grid_value, player_suit, player_value local and_46_ = ((nil ~= _42_) and (nil ~= _43_) and (_42_ == _44_) and (nil ~= _45_)) if and_46_ then local suit = _42_ local against = _43_ local played = _45_ and_46_ = (against < played) end if and_46_ then local suit = _42_ local against = _43_ local played = _45_


 local moves = {{"move", {"hand", hand_n}, {"trick", "player", trick_player_n, "top"}}, {"move", p, {"trick", "player", trick_player_n, "top"}}}

 events0, result = table.join(events0, moves), true else local and_48_ = ((nil ~= _42_) and (nil ~= _43_) and (_42_ == _44_) and (nil ~= _45_)) if and_48_ then local suit = _42_ local against = _43_ local played = _45_ and_48_ = (played < against) end if and_48_ then local suit = _42_ local against = _43_ local played = _45_


 local moves = {{"move", {"hand", hand_n}, {"trick", "grid", trick_grid_n, "top"}}, {"move", p, {"trick", "grid", trick_grid_n, "top"}}}

 events0, result = table.join(events0, moves), false else local _0 = _42_

 events0, result = events0, nil end end end events, won_3f = events0, result end local events0, won_3f0 = nil, nil
 if (nil == won_3f) then


 local trumps local _51_ do local tbl_21_auto = {} local i_22_auto = 0 for i, p in ipairs(path) do local val_23_auto
 do local grid_card = table["get-in"](state, p)
 if (trump_suit == card_suit(grid_card)) then
 val_23_auto = {p, card_value(grid_card)} else val_23_auto = nil end end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end _51_ = tbl_21_auto end
 local function _56_(_54_, _55_) local _ = _54_[1] local a = _54_[2] local _0 = _55_[1] local b = _55_[2] return (a < b) end trumps = table.sort(_51_, _56_) local _3ftrump_moves
 if ((_G.type(trumps) == "table") and ((_G.type(trumps[1]) == "table") and (nil ~= trumps[1][1]) and true)) then local p = trumps[1][1] local _card = trumps[1][2]
 _3ftrump_moves = {{"move", {"hand", hand_n}, {"trick", "grid", trick_grid_n, "top"}}, {"move", p, {"trick", "grid", trick_grid_n, "top"}}} else _3ftrump_moves = nil end

 if _3ftrump_moves then
 events0, won_3f0 = table.join(events, _3ftrump_moves), false else

 events0, won_3f0 = events, nil end else
 events0, won_3f0 = events, won_3f end
 if (nil == won_3f0) then
 return events0, nil else


 do local tbl_19_auto = events0 for i = (hand_n + 1), #state.hand do
 local val_20_auto = {"move", {"hand", i}, {"hand", (i - 1)}} table.insert(tbl_19_auto, val_20_auto) end end
 return events0, won_3f0 end end

 local function do_play(path)
 if not no_nil_cards_3f(path) then
 local function _68_() local data_5_auto = {} local resolve_6_auto local function _61_(name_7_auto) local _62_ = data_5_auto[name_7_auto] local and_63_ = (nil ~= _62_) if and_63_ then local t_8_auto = _62_ and_63_ = ("table" == type(t_8_auto)) end if and_63_ then local t_8_auto = _62_ local _65_ = getmetatable(t_8_auto) if ((_G.type(_65_) == "table") and (nil ~= _65_.__tostring)) then local f_9_auto = _65_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _65_ return vim.inspect(t_8_auto) end elseif (nil ~= _62_) then local v_11_auto = _62_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _61_ return string.gsub("cant play a row or column with empty spaces", "#{(.-)}", resolve_6_auto) end return nil, _68_() else
 local _69_, _70_ = play_path(path) if ((nil ~= _69_) and (nil ~= _70_)) then local events = _69_ local player_won_3f = _70_
 local next_state, events0 = apply_events(clone(state), events)




 return next_state, events0 elseif ((nil ~= _69_) and (_70_ == nil)) then local events = _69_




 return apply_events(clone(state), events) else return nil end end end

 if (nil == state.hand[hand_n]) then
 local function _80_() local data_5_auto = {["hand-n"] = hand_n} local resolve_6_auto local function _73_(name_7_auto) local _74_ = data_5_auto[name_7_auto] local and_75_ = (nil ~= _74_) if and_75_ then local t_8_auto = _74_ and_75_ = ("table" == type(t_8_auto)) end if and_75_ then local t_8_auto = _74_ local _77_ = getmetatable(t_8_auto) if ((_G.type(_77_) == "table") and (nil ~= _77_.__tostring)) then local f_9_auto = _77_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _77_ return vim.inspect(t_8_auto) end elseif (nil ~= _74_) then local v_11_auto = _74_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _73_ return string.gsub("No card at hand #{hand-n} to play", "#{(.-)}", resolve_6_auto) end return nil, _80_() else
 if ((_G.type(play_loc) == "table") and (play_loc[1] == "play")) then
 return do_play(build_path(play_loc)) else local _ = play_loc
 local function _88_() local data_5_auto = {["play-loc"] = play_loc} local resolve_6_auto local function _81_(name_7_auto) local _82_ = data_5_auto[name_7_auto] local and_83_ = (nil ~= _82_) if and_83_ then local t_8_auto = _82_ and_83_ = ("table" == type(t_8_auto)) end if and_83_ then local t_8_auto = _82_ local _85_ = getmetatable(t_8_auto) if ((_G.type(_85_) == "table") and (nil ~= _85_.__tostring)) then local f_9_auto = _85_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _85_ return vim.inspect(t_8_auto) end elseif (nil ~= _82_) then local v_11_auto = _82_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _81_ return string.gsub("Cant play tricks to #{play-loc}", "#{(.-)}", resolve_6_auto) end return nil, _88_() end end end

 M.Action["force-trick"] = function(state, hand_n, play_loc) _G.assert((nil ~= play_loc), "Missing argument play-loc on fnl/playtime/game/optrita-lines/logic.fnl:256") _G.assert((nil ~= hand_n), "Missing argument hand-n on fnl/playtime/game/optrita-lines/logic.fnl:256") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:256")
 local trick_n do local n = nil for i, t in ipairs(state.trick.player) do if n then break end
 if table["empty?"](t) then n = i else n = nil end end trick_n = n end
 local events = {{"move", {"hand", hand_n}, {"trick", "player", trick_n, "top"}}, {"move", play_loc, {"trick", "player", trick_n, "top"}}} local _

 do local tbl_19_auto = events for i = (hand_n + 1), #state.hand do
 local val_20_auto = {"move", {"hand", i}, {"hand", (i - 1)}} table.insert(tbl_19_auto, val_20_auto) end _ = tbl_19_auto end
 return apply_events(clone(state), events) end

 M.Query["game-ended?"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:265")
 return ((state.rules["score-limit"].player <= state.score.player) or (state.rules["score-limit"].grid <= state.score.grid)) end


 M.Query["game-result"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:269")
 if (state.rules["score-limit"].grid <= state.score.grid) then return "grid" elseif (state.rules["score-limit"].player <= state.score.player) then return "player" else return "unfinished" end end





 M.Query["round-ended?"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/optrita-lines/logic.fnl:276")
 return (0 == #state.hand) end

 return M