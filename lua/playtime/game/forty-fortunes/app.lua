
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






 local function _4_() local function _2_() local n0 = n return (n0 < 5) end if ((nil ~= n) and _2_()) then local n0 = n return 0 else local function _3_() local n0 = n return (5 <= n0) end if ((nil ~= n) and _3_()) then local n0 = n

 return (3 * card_col_step) else return nil end end end return {row = (0 + foundation.row), col = (tableau.col + card_col_step + ((n - 1) * card_col_step) + _4_()), z = card} elseif ((_G.type(location) == "table") and (location[1] == "tableau") and (nil ~= location[2]) and (nil ~= location[3])) then local col = location[2] local card = location[3]

 return {row = (tableau.row + (math.max(0, (card - 1)) * 2)), col = (tableau.col + ((col - 1) * card_col_step)), z = card} elseif ((_G.type(location) == "table") and (location[1] == "draw") and (location[2] == 1) and (nil ~= location[3])) then local card = location[3]


 return {row = tableau.row, col = (tableau.col + ((7 - 1) * card_col_step)), z = card} else local _ = location


 return error(Error("Unable to convert location to position, unknown location #{location}", {location = location})) end end


 AppState.Default.OnEvent.app["maybe-auto-move"] = function(app)
 local function _6_(...) local _7_ = ... if ((_G.type(_7_) == "table") and (nil ~= _7_[1]) and (nil ~= _7_[2])) then local from = _7_[1] local to = _7_[2] local function _8_(...) local _9_, _10_ = ... if ((nil ~= _9_) and (nil ~= _10_)) then local next_game = _9_ local events = _10_


 local after local function _11_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "maybe-auto-move") return app["update-game"](app, next_game, {"move", from, to}) end after = _11_ local timeline = app["build-event-animation"](app, events, after, {["stagger-ms"] = 200}) return app["switch-state"](app, AppState.Animating, timeline) else local __85_auto = _9_ return ... end end return _8_(Logic.Action.move(app.game, from, to)) else local __85_auto = _7_ return ... end end return _6_(Logic.Plan["next-move-to-foundation"](app.game)) end






 AppState.DraggingCards.OnEvent.input["<LeftRelease>"] = function(app, _14_, pos) local _arg_15_ = _14_ local _ = _arg_15_[1] local location = _arg_15_[2]
 if Logic.Query["droppable?"](app.game, location) then
 local function _16_(...) local _17_, _18_ = ... if ((nil ~= _17_) and (nil ~= _18_)) then local from = _17_ local to = _18_ local function _19_(...) local _20_, _21_ = ... if ((nil ~= _20_) and (nil ~= _21_)) then local next_game = _20_ local events = _21_


 local after local function _22_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "maybe-auto-move") return app["update-game"](app, next_game, {"move", from, to}) end after = _22_ local timeline = app["build-event-animation"](app, events, after, {["stagger-ms"] = 120})






 do end (timeline[1]):tick(timeline[1]["finish-at"])
 table.remove(timeline, 1) return app["switch-state"](app, AppState.Animating, timeline) elseif ((_20_ == nil) and (nil ~= _21_)) then local err = _21_ app:notify(err) return app["switch-state"](app, AppState.Default) else local _0 = _20_ return app["switch-state"](app, AppState.Default) end end return _19_(Logic.Action.move(app.game, from, to)) elseif ((_17_ == nil) and (nil ~= _18_)) then local err = _18_ app:notify(err) return app["switch-state"](app, AppState.Default) else local _0 = _17_ return app["switch-state"](app, AppState.Default) end end return _16_(app.state.context["lifted-from"], location) else return app["switch-state"](app, AppState.Default) end end








 M.start = function(app_config, game_config, _3fseed)
 return PatienceApp.start({name = "Forty Fortunes", filetype = "forty-fortunes", view = {width = 123, height = 42}, ["empty-fields"] = {{"cell", 1}, {"tableau", 13}, {"foundation", 8}}, ["card-style"] = {colors = 4}}, {AppImpl = M, LogicImpl = Logic, StateImpl = AppState}, app_config, game_config, _3fseed) end










 return M