
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local PatienceApp = require("playtime.app.patience")
 local PatienceState = require("playtime.app.patience.state")
 local M = setmetatable({}, {__index = PatienceApp})

 local Logic = require("playtime.game.penguin.logic")
 local AppState = PatienceState.build(Logic)
 local M0 = setmetatable({}, {__index = PatienceApp})

 M0["location->position"] = function(app, location)
 local config = {card = {margin = {row = 0, col = 2}, width = 7, height = 5}}

 local card_col_step = (config.card.width + config.card.margin.col)
 local cell = {row = 2, col = 4}
 local foundation = {row = cell.row, col = (2 + cell.col + (7 * card_col_step))}
 local tableau = {row = (cell.row + config.card.height + config.card.margin.row), col = cell.col}
 if ((_G.type(location) == "table") and (location[1] == "cell") and (nil ~= location[2]) and (nil ~= location[3])) then local n = location[2] local card = location[3]
 return {row = cell.row, col = (cell.col + ((n - 1) * card_col_step)), z = card} elseif ((_G.type(location) == "table") and (location[1] == "foundation") and (nil ~= location[2]) and (nil ~= location[3])) then local n = location[2] local card = location[3]


 return {row = (foundation.row + ((n - 1) * config.card.height)), col = foundation.col, z = card} elseif ((_G.type(location) == "table") and (location[1] == "tableau") and (nil ~= location[2]) and (nil ~= location[3])) then local col = location[2] local card = location[3]


 return {row = (tableau.row + (math.max(0, (card - 1)) * 2)), col = (tableau.col + ((col - 1) * card_col_step)), z = card} elseif ((_G.type(location) == "table") and (location[1] == "draw") and (location[2] == 1) and (nil ~= location[3])) then local card = location[3]


 return {row = (tableau.row + (math.max(0, (9 - 1)) * 2)), col = (tableau.col + (4 * card_col_step) + -4), z = card} else local _ = location


 local function _9_() local data_5_auto = {location = location} local resolve_6_auto local function _2_(name_7_auto) local _3_ = data_5_auto[name_7_auto] local and_4_ = (nil ~= _3_) if and_4_ then local t_8_auto = _3_ and_4_ = ("table" == type(t_8_auto)) end if and_4_ then local t_8_auto = _3_ local _6_ = getmetatable(t_8_auto) if ((_G.type(_6_) == "table") and (nil ~= _6_.__tostring)) then local f_9_auto = _6_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _6_ return vim.inspect(t_8_auto) end elseif (nil ~= _3_) then local v_11_auto = _3_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _2_ return string.gsub("Unable to convert location to position, unknown location #{location}", "#{(.-)}", resolve_6_auto) end return error(_9_()) end end

 AppState.Default.OnEvent.app["maybe-auto-move"] = function(app)
 local function _11_(...) local _12_ = ... if ((_G.type(_12_) == "table") and (nil ~= _12_[1]) and (nil ~= _12_[2])) then local from = _12_[1] local to = _12_[2] local function _13_(...) local _14_, _15_ = ... if ((nil ~= _14_) and (nil ~= _15_)) then local next_game = _14_ local events = _15_


 local after local function _16_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "maybe-auto-move") return app["update-game"](app, next_game, {"move", from, to}) end after = _16_ local timeline = app["build-event-animation"](app, events, after, {["stagger-ms"] = 200}) return app["switch-state"](app, AppState.Animating, timeline) else local __85_auto = _14_ return ... end end return _13_(Logic.Action.move(app.game, from, to)) else local __85_auto = _12_ return ... end end return _11_(Logic.Plan["next-move-to-foundation"](app.game)) end






 M0.start = function(app_config, game_config, _3fseed)
 return PatienceApp.start({name = "Penguin", filetype = "penguin", view = {width = 80, height = 42}, ["empty-fields"] = {{"cell", 7}, {"tableau", 7}, {"foundation", 4}}, ["card-style"] = {colors = 4}}, {AppImpl = M0, LogicImpl = Logic, StateImpl = AppState}, app_config, game_config, _3fseed) end










 return M0