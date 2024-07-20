
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Error = require("playtime.error")
 local PatienceApp = require("playtime.app.patience")
 local PatienceState = require("playtime.app.patience.state")

 local Logic = require("playtime.game.forty-fortunes.logic")
 local AppState = PatienceState.build(Logic)
 local M = setmetatable({}, {__index = PatienceApp})

 M["location->position"] = function(app, location)
 local config = {card = {margin = {row = 0, col = 2}, width = app["card-style"].width, height = app["card-style"].height}}

 local card_col_step = (config.card.width + config.card.margin.col)
 local cell = {row = 2, col = 4}
 local foundation = {row = cell.row, col = (2 + cell.col + (7 * card_col_step))}
 local tableau = {row = (cell.row + config.card.height + config.card.margin.row), col = cell.col}
 if ((_G.type(location) == "table") and (location[1] == "cell") and (nil ~= location[2]) and (nil ~= location[3])) then local n = location[2] local card = location[3]
 return {row = cell.row, col = (tableau.col + ((7 - 1) * card_col_step)), z = card} elseif ((_G.type(location) == "table") and (location[1] == "foundation") and (nil ~= location[2]) and (nil ~= location[3])) then local n = location[2] local card = location[3]






 local _2_ local and_3_ = (nil ~= n) if and_3_ then local n0 = n and_3_ = (n0 < 5) end if and_3_ then local n0 = n _2_ = 0 else local and_6_ = (nil ~= n) if and_6_ then local n0 = n and_6_ = (5 <= n0) end if and_6_ then local n0 = n

 _2_ = (3 * card_col_step) else _2_ = nil end end return {row = (0 + foundation.row), col = (tableau.col + card_col_step + ((n - 1) * card_col_step) + _2_), z = card} elseif ((_G.type(location) == "table") and (location[1] == "tableau") and (nil ~= location[2]) and (nil ~= location[3])) then local col = location[2] local card = location[3]

 return {row = (tableau.row + (math.max(0, (card - 1)) * 2)), col = (tableau.col + ((col - 1) * card_col_step)), z = card} elseif ((_G.type(location) == "table") and (location[1] == "draw") and (location[2] == 1) and (nil ~= location[3])) then local card = location[3]


 return {row = tableau.row, col = (tableau.col + ((7 - 1) * card_col_step)), z = card} else local _ = location


 return error(Error("Unable to convert location to position, unknown location #{location}", {location = location})) end end


 AppState.Default.OnEvent.app["maybe-auto-move"] = function(app)
 local function _11_(...) local _12_ = ... if ((_G.type(_12_) == "table") and (nil ~= _12_[1]) and (nil ~= _12_[2])) then local from = _12_[1] local to = _12_[2] local function _13_(...) local _14_, _15_ = ... if ((nil ~= _14_) and (nil ~= _15_)) then local next_game = _14_ local events = _15_


 local after local function _16_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "maybe-auto-move") return app["update-game"](app, next_game, {"move", from, to}) end after = _16_ local timeline = app["build-event-animation"](app, events, after, {["stagger-ms"] = 200}) return app["switch-state"](app, AppState.Animating, timeline) else local __85_auto = _14_ return ... end end return _13_(Logic.Action.move(app.game, from, to)) else local __85_auto = _12_ return ... end end return _11_(Logic.Plan["next-move-to-foundation"](app.game)) end






 AppState.DraggingCards.OnEvent.input["<LeftRelease>"] = function(app, _19_, pos) local _ = _19_[1] local location = _19_[2]
 if Logic.Query["droppable?"](app.game, location) then
 local function _20_(...) local _21_, _22_ = ... if ((nil ~= _21_) and (nil ~= _22_)) then local from = _21_ local to = _22_ local function _23_(...) local _24_, _25_ = ... if ((nil ~= _24_) and (nil ~= _25_)) then local next_game = _24_ local events = _25_


 local after local function _26_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "maybe-auto-move") return app["update-game"](app, next_game, {"move", from, to}) end after = _26_ local timeline = app["build-event-animation"](app, events, after, {["stagger-ms"] = 120})






 timeline[1]:tick(timeline[1]["finish-at"])
 table.remove(timeline, 1) return app["switch-state"](app, AppState.Animating, timeline) elseif ((_24_ == nil) and (nil ~= _25_)) then local err = _25_ app:notify(err) return app["switch-state"](app, AppState.Default) else local _0 = _24_ return app["switch-state"](app, AppState.Default) end end return _23_(Logic.Action.move(app.game, from, to)) elseif ((_21_ == nil) and (nil ~= _22_)) then local err = _22_ app:notify(err) return app["switch-state"](app, AppState.Default) else local _0 = _21_ return app["switch-state"](app, AppState.Default) end end return _20_(app.state.context["lifted-from"], location) else return app["switch-state"](app, AppState.Default) end end








 M.start = function(app_config, game_config, _3fseed)
 return PatienceApp.start({name = "Forty Fortunes", filetype = "forty-fortunes", view = {width = 123, height = 42}, ["empty-fields"] = {{"cell", 1}, {"tableau", 13}, {"foundation", 8}}, ["card-style"] = {colors = 4}}, {AppImpl = M, LogicImpl = Logic, StateImpl = AppState}, app_config, game_config, _3fseed) end










 return M