
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local PatienceApp = require("playtime.app.patience")
 local PatienceState = require("playtime.app.patience.state")
 local Logic = require("playtime.game.freecell.logic")
 local _local_2_ = require("playtime.common.card.utils") local same_location_field_column_3f = _local_2_["same-location-field-column?"]

 local M = setmetatable({}, {__index = PatienceApp})
 local AppState = PatienceState.build(Logic)

 M["build-event-animation"] = function(app, events, after, _3fopts)







 local function simple_resort_3f(events0) local yes_3f = true
 for i, move in ipairs(events0) do if not yes_3f then break end
 if ((_G.type(move) == "table") and (move[1] == "move") and ((_G.type(move[2]) == "table") and (move[2][1] == "tableau") and (nil ~= move[2][2]) and (nil ~= move[2][3])) and ((_G.type(move[3]) == "table") and (move[3][1] == "tableau") and (nil ~= move[3][2]) and (move[2][3] == move[3][3]))) then local a = move[2][2] local n = move[2][3] local b = move[3][2] yes_3f = true else local _ = move yes_3f = false end end return yes_3f end


 local events0 if ((_G.type(events) == "table") and ((_G.type(events[1]) == "table") and true and ((_G.type(events[1][2]) == "table") and (events[1][2][1] == "draw") and (events[1][2][2] == 1) and (events[1][2][3] == 52)))) then local _ = events[1][1]

 events0 = events else local and_4_ = (nil ~= events) if and_4_ then local events1 = events and_4_ = simple_resort_3f(events1) end if and_4_ then local events1 = events

 events0 = events1 else local _ = events




 local _let_6_ = table.first(events) local _move = _let_6_[1] local first_from = _let_6_[2] local _first_to = _let_6_[3]
 local _let_7_ = table.last(events) local _move0 = _let_7_[1] local _last_from = _let_7_[2] local last_to = _let_7_[3] local froms









 do local t, stop_3f = {}, false for _0, _8_ in ipairs(events) do
 local _move1 = _8_[1] local from = _8_[2] local _1 = _8_[3] if stop_3f then break end

 local and_9_ = ((_G.type(from) == "table") and (from[1] == "tableau") and (nil ~= from[2]) and (from[3] == 1)) if and_9_ then local n = from[2] and_9_ = same_location_field_column_3f(first_from, from) end if and_9_ then local n = from[2]

 t, stop_3f = table.insert(t, from), true else local and_11_ = true if and_11_ then local _2 = from and_11_ = same_location_field_column_3f(first_from, from) end if and_11_ then local _2 = from

 t, stop_3f = table.insert(t, from), false else local _2 = from

 t, stop_3f = t, false end end end froms = t, stop_3f end local tos
 do local t = {} for i = #events, 1, -1 do if (#t == #froms) then break end
 local _let_14_ = events[i] local _move1 = _let_14_[1] local _from = _let_14_[2] local to = _let_14_[3]
 if same_location_field_column_3f(last_to, to) then
 t = table.insert(t, to) else
 t = t end end tos = t end local ff_moves
 do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, #froms do local val_23_auto
 do local from = froms[i]
 local f = from[1] local c = from[2] local n = from[3]
 local card = app.game[f][c][n]
 val_23_auto = {"move", froms[i], tos[i]} end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end ff_moves = tbl_21_auto end
 local tbl_21_auto = {} local i_22_auto = 0 for i = #ff_moves, 1, -1 do
 local val_23_auto = ff_moves[i] if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end events0 = tbl_21_auto end end
 return PatienceApp["build-event-animation"](app, events0, after, _3fopts) end

 M["location->position"] = function(app, location)
 local config = {card = {margin = {row = 0, col = 2}, width = app["card-style"].width, height = app["card-style"].height}}

 local card_col_step = (config.card.width + config.card.margin.col)
 local cell = {row = 2, col = 4}
 local foundation = {row = cell.row, col = (cell.col + (4 * card_col_step))}
 local tableau = {row = (cell.row + config.card.height + config.card.margin.row), col = cell.col}
 if ((_G.type(location) == "table") and (location[1] == "cell") and (nil ~= location[2]) and (nil ~= location[3])) then local n = location[2] local card = location[3]
 return {row = cell.row, col = (cell.col + ((n - 1) * card_col_step)), z = card} elseif ((_G.type(location) == "table") and (location[1] == "foundation") and (nil ~= location[2]) and (nil ~= location[3])) then local n = location[2] local card = location[3]


 return {row = foundation.row, col = (foundation.col + ((n - 1) * card_col_step)), z = card} elseif ((_G.type(location) == "table") and (location[1] == "tableau") and (nil ~= location[2]) and (nil ~= location[3])) then local col = location[2] local card = location[3]


 return {row = (tableau.row + (math.max(0, (card - 1)) * 2)), col = (tableau.col + ((col - 1) * card_col_step)), z = card} elseif ((_G.type(location) == "table") and (location[1] == "draw") and (location[2] == 1) and (nil ~= location[3])) then local card = location[3]


 return {row = (tableau.row + (math.max(0, (9 - 1)) * 2)), col = (tableau.col + (4 * card_col_step) + -4), z = card} else local _ = location


 local function _26_() local data_5_auto = {location = location} local resolve_6_auto local function _19_(name_7_auto) local _20_ = data_5_auto[name_7_auto] local and_21_ = (nil ~= _20_) if and_21_ then local t_8_auto = _20_ and_21_ = ("table" == type(t_8_auto)) end if and_21_ then local t_8_auto = _20_ local _23_ = getmetatable(t_8_auto) if ((_G.type(_23_) == "table") and (nil ~= _23_.__tostring)) then local f_9_auto = _23_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _23_ return vim.inspect(t_8_auto) end elseif (nil ~= _20_) then local v_11_auto = _20_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _19_ return string.gsub("Unable to convert location to position, unknown location #{location}", "#{(.-)}", resolve_6_auto) end return error(_26_()) end end

 AppState.Default.OnEvent.app["maybe-auto-move"] = function(app)
 local function _28_(...) local _29_ = ... if ((_G.type(_29_) == "table") and (nil ~= _29_[1]) and (nil ~= _29_[2])) then local from = _29_[1] local to = _29_[2] local function _30_(...) local _31_, _32_ = ... if ((nil ~= _31_) and (nil ~= _32_)) then local next_game = _31_ local events = _32_


 local after local function _33_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "maybe-auto-move") return app["update-game"](app, next_game, {"move", from, to}) end after = _33_ local timeline = app["build-event-animation"](app, events, after) return app["switch-state"](app, AppState.Animating, timeline) else local __85_auto = _31_ return ... end end return _30_(Logic.Action.move(app.game, from, to)) else local __85_auto = _29_ return ... end end return _28_(Logic.Plan["next-move-to-foundation"](app.game)) end






 M.start = function(app_config, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/freecell/app.fnl:103") _G.assert((nil ~= app_config), "Missing argument app-config on fnl/playtime/game/freecell/app.fnl:103")
 local game_config0 = table.merge({rules = "freecell"}, game_config) local name, filetype, colors = nil, nil, nil
 do local _36_ = game_config0.rules if (_36_ == "bakers") then
 name, filetype, colors = "Baker's Game", "bakers", 4 elseif (_36_ == "freecell") then
 name, filetype, colors = "FreeCell", "freecell", 2 elseif (nil ~= _36_) then local r = _36_
 local function _44_() local data_5_auto = {r = r} local resolve_6_auto local function _37_(name_7_auto) local _38_ = data_5_auto[name_7_auto] local and_39_ = (nil ~= _38_) if and_39_ then local t_8_auto = _38_ and_39_ = ("table" == type(t_8_auto)) end if and_39_ then local t_8_auto = _38_ local _41_ = getmetatable(t_8_auto) if ((_G.type(_41_) == "table") and (nil ~= _41_.__tostring)) then local f_9_auto = _41_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _41_ return vim.inspect(t_8_auto) end elseif (nil ~= _38_) then local v_11_auto = _38_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _37_ return string.gsub("Unknown ruleset #{r}", "#{(.-)}", resolve_6_auto) end name, filetype, colors = error(_44_()) else name, filetype, colors = nil end end
 return PatienceApp.start({name = name, filetype = filetype, view = {width = 78, height = 42}, ["card-style"] = {colors = colors}, ["empty-fields"] = {{"cell", 4}, {"foundation", 4}, {"tableau", 8}}}, {AppImpl = M, LogicImpl = Logic, StateImpl = AppState}, app_config, game_config0, _3fseed) end










 return M