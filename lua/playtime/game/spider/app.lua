
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Error = require("playtime.error")
 local PatienceApp = require("playtime.app.patience")
 local PatienceState = require("playtime.app.patience.state")

 local M = setmetatable({}, {__index = PatienceApp})
 local Logic = require("playtime.game.spider.logic")
 local AppState = PatienceState.build(Logic)

 M["location->position"] = function(app, location)
 local config = {card = {margin = {row = 0, col = 2}, width = 7, height = 5}}

 local draw = {row = 2, col = 4}
 local card_col_step = (config.card.width + config.card.margin.col)
 local tableau = {row = (draw.row + config.card.height + config.card.margin.row), col = draw.col} local max_draws = 7

 if ((_G.type(location) == "table") and (location[1] == "tableau") and (nil ~= location[2]) and (nil ~= location[3])) then local col = location[2] local card = location[3]
 return {row = (tableau.row + (math.max(0, (card - 1)) * 2)), col = (tableau.col + ((col - 1) * card_col_step)), z = card} elseif ((_G.type(location) == "table") and (location[1] == "draw") and (nil ~= location[2]) and (nil ~= location[3])) then local n = location[2] local card = location[3]


 return {row = draw.row, col = (draw.col + ((max_draws - n - 1) * 2)), z = (((max_draws - n) * 10) + card)} elseif ((_G.type(location) == "table") and (location[1] == "complete") and (nil ~= location[2]) and (nil ~= location[3])) then local n = location[2] local card = location[3]


 return {row = draw.row, col = (tableau.col + (card_col_step * 9) + (-2 * (n - 1))), z = ((n * 10) + card)} else local _ = location


 return error(Error("Unable to convert location to position, unknown location #{location}", {location = location})) end end


 AppState.Default.OnEvent.app["maybe-auto-move"] = function(app)
 local function _3_(...) local _4_ = ... if (nil ~= _4_) then local from = _4_ local function _5_(...) local _6_, _7_ = ... if ((nil ~= _6_) and (nil ~= _7_)) then local next_game = _6_ local events = _7_


 local after local function _8_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "maybe-auto-move") return app["update-game"](app, next_game, {"remove-complete-sequence", from}) end after = _8_ local timeline = app["build-event-animation"](app, events, after, {["stagger-ms"] = 120}) return app["switch-state"](app, AppState.Animating, timeline) else local __85_auto = _6_ return ... end end return _5_(Logic.Action["remove-complete-sequence"](app.game, from)) else local __85_auto = _4_ return ... end end _3_(Logic.Plan["next-complete-sequence"](app.game))





 return app end

 M.start = function(app_config, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/spider/app.fnl:45") _G.assert((nil ~= app_config), "Missing argument app-config on fnl/playtime/game/spider/app.fnl:45")
 local game_config0 = table.merge({suits = 4}, game_config)
 return PatienceApp.start({name = string.format("Spider (%s Suits)", game_config0.suits), filetype = string.format("spider-%s", game_config0.suits), view = {width = 96, height = 42}, ["empty-fields"] = {{"tableau", 10}}, ["card-style"] = {colors = 4}}, {AppImpl = M, LogicImpl = Logic, StateImpl = AppState}, app_config, game_config0, _3fseed) end










 return M