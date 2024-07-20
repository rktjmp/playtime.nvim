
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Error = require("playtime.error")
 local Component = require("playtime.component")
 local PatienceApp = require("playtime.app.patience")
 local PatienceState = require("playtime.app.patience.state")
 local State = require("playtime.app.state")
 local Logic = require("playtime.game.shenzhen-solitaire.logic")
 local M = setmetatable({}, {__index = PatienceApp})
 local AppState = PatienceState.build(Logic)

 AppState.Default = State.build("Default", {delegate = {app = AppState.Default, input = AppState.Default}})


 local function card_graphics(suit, rank, _color_count)
 local rank_text do local _2_, _3_ = suit, rank if (_2_ == "red") then rank_text = "\197\160" elseif (_2_ == "green") then rank_text = "\195\145" elseif (_2_ == "white") then rank_text = "\195\149" elseif (_2_ == "flower") then rank_text = "\198\146" elseif (true and (nil ~= _3_)) then local _ = _2_ local pip = _3_




 rank_text = tostring(pip) else rank_text = nil end end local highlight

 local _5_ if (suit == "green") then _5_ = "dragon.green" elseif (suit == "red") then _5_ = "dragon.red" elseif (suit == "white") then _5_ = "dragon.white" elseif (nil ~= suit) then local suit0 = suit



 _5_ = suit0 else _5_ = nil end highlight = ("@playtime.game.shenzhen." .. _5_)
 return {"", rank_text, highlight} end

 M["location->position"] = function(app, location)
 local config = {card = {margin = {row = 0, col = 2}, width = 7, height = 5}}

 local card_col_step = (config.card.width + config.card.margin.col)
 local cell = {row = 2, col = 3}
 local button = {row = 3, col = (cell.col + 1 + (3 * card_col_step))}
 local lock = {row = cell.row, col = (cell.col + (3 * card_col_step))}
 local flower = {row = cell.row, col = (lock.col + (1 * card_col_step))}
 local foundation = {row = cell.row, col = (flower.col + (1 * card_col_step))}
 local tableau = {row = (cell.row + config.card.height + config.card.margin.row), col = cell.col}
 if ((_G.type(location) == "table") and (location[1] == "cell") and (nil ~= location[2]) and (nil ~= location[3])) then local n = location[2] local card = location[3]
 return {row = cell.row, col = (cell.col + ((n - 1) * card_col_step)), z = card} elseif ((_G.type(location) == "table") and (location[1] == "flower") and (location[2] == 1) and (nil ~= location[3])) then local card = location[3]


 return {row = flower.row, col = flower.col, z = card} elseif ((_G.type(location) == "table") and (location[1] == "foundation") and (nil ~= location[2]) and (nil ~= location[3])) then local n = location[2] local card = location[3]


 return {row = foundation.row, col = (foundation.col + ((n - 1) * card_col_step)), z = card} elseif ((_G.type(location) == "table") and (location[1] == "tableau") and (nil ~= location[2]) and (nil ~= location[3])) then local col = location[2] local card = location[3]


 return {row = (tableau.row + (math.max(0, (card - 1)) * 2)), col = (tableau.col + ((col - 1) * card_col_step)), z = card} elseif ((_G.type(location) == "table") and (location[1] == "button") and (location[2] == "lock") and (nil ~= location[3])) then local color = location[3]


 local n if (color == "red") then n = 1 elseif (color == "green") then n = 2 elseif (color == "white") then n = 3 else n = nil end



 return {row = (button.row + (n - 1)), col = button.col, z = app["z-index-for-layer"](app, "button")} else local _ = location


 return error(Error("Unable to convert location to position, unknown location #{location}", {location = location})) end end


 local function make_lock_button_component(tag, text, position, enabled_highlight, disabled_highlight) _G.assert((nil ~= disabled_highlight), "Missing argument disabled-highlight on fnl/playtime/game/shenzhen-solitaire/app.fnl:65") _G.assert((nil ~= enabled_highlight), "Missing argument enabled-highlight on fnl/playtime/game/shenzhen-solitaire/app.fnl:65") _G.assert((nil ~= position), "Missing argument position on fnl/playtime/game/shenzhen-solitaire/app.fnl:65") _G.assert((nil ~= text), "Missing argument text on fnl/playtime/game/shenzhen-solitaire/app.fnl:65") _G.assert((nil ~= tag), "Missing argument tag on fnl/playtime/game/shenzhen-solitaire/app.fnl:65")

 local function _13_(self, enabled_3f)
 local hi if enabled_3f then hi = enabled_highlight else hi = disabled_highlight end self["set-content"](self, {{{text, hi}}})

 if enabled_3f then return self["set-tag"](self, tag) else return self["set-tag"](self, nil) end end return Component["set-size"](Component["set-position"](Component.build(_13_), position), {width = 3, height = 1}):update(false) end






 AppState.Default.tick = function(app)
 for i, color in ipairs({"red", "green", "white"}) do
 local button = app.components.buttons[i] button:update(not (nil == Logic.Action["lock-dragon"](app.game, color))) end

 return AppState.Default.Delegate.app.tick(app) end

 AppState.Default.OnEvent.app["maybe-auto-move"] = function(app)
 local function _16_(...) local _17_ = ... if ((_G.type(_17_) == "table") and (nil ~= _17_[1]) and (nil ~= _17_[2])) then local from = _17_[1] local to = _17_[2] local function _18_(...) local _19_, _20_ = ... if ((nil ~= _19_) and (nil ~= _20_)) then local next_game = _19_ local events = _20_



 local after local function _21_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "maybe-auto-move") return app["update-game"](app, next_game, {"move", from, to}) end after = _21_ local timeline = app["build-event-animation"](app, events, after, {["stagger-ms"] = 200}) return app["switch-state"](app, AppState.Animating, timeline) else local __85_auto = _19_ return ... end end return _18_(Logic.Action.move(app.game, from, to)) else local __85_auto = _17_ return ... end end return _16_((Logic.Plan["next-move-to-flower"](app.game) or Logic.Plan["next-move-to-foundation"](app.game))) end






 AppState.Default.OnEvent.input["<LeftMouse>"] = function(app, locations, pos)
 if ((_G.type(locations) == "table") and ((_G.type(locations[1]) == "table") and (locations[1][1] == "button") and (locations[1][2] == "lock") and (nil ~= locations[1][3]))) then local color = locations[1][3]

 local function _24_(...) local _25_, _26_ = ... if ((nil ~= _25_) and (nil ~= _26_)) then local next_game = _25_ local events = _26_

 local timeline

 local function _27_() app["queue-event"](app, "app", "noop") app["queue-event"](app, "app", "maybe-auto-move") app["switch-state"](app, AppState.Default) return app["update-game"](app, next_game, {"lock-dragon", color}) end timeline = app["build-event-animation"](app, events, _27_, {["stagger-ms"] = 120}) return app["switch-state"](app, AppState.Animating, timeline) elseif ((_25_ == nil) and (nil ~= _26_)) then local err = _26_ return app:notify(err) else return nil end end return _24_(Logic.Action["lock-dragon"](app.game, color)) else local _ = locations








 return AppState.Default.Delegate.input.OnEvent.input["<LeftMouse>"](app, locations, pos) end end

 M.start = function(app_config, game_config, _3fseed)
 local app = PatienceApp.start({name = "Shenzhen Solitaire", filetype = "shenzhen-solitaire", view = {width = 80, height = 42}, ["empty-fields"] = {{"cell", 3}, {"tableau", 8}, {"foundation", 3}, {"flower", 1}}, ["card-style"] = {colors = "custom", graphics = card_graphics}}, {AppImpl = M, LogicImpl = Logic, StateImpl = AppState}, app_config, game_config, _3fseed) local buttons










 do local tbl_21_auto = {} local i_22_auto = 0 for _, a in ipairs({{{"button", "lock", "red"}, "\226\138\178 \197\160", app["location->position"](app, {"button", "lock", "red"}), "@playtime.game.shenzhen.dragon.red", "@playtime.ui.off"}, {{"button", "lock", "green"}, "\226\138\178 \195\145", app["location->position"](app, {"button", "lock", "green"}), "@playtime.game.shenzhen.dragon.green", "@playtime.ui.off"}, {{"button", "lock", "white"}, "\226\138\178 \195\149", app["location->position"](app, {"button", "lock", "white"}), "@playtime.game.shenzhen.dragon.white", "@playtime.ui.off"}}) do














 local val_23_auto = make_lock_button_component(table.unpack(a)) if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end buttons = tbl_21_auto end
 table.merge(app.components, {buttons = buttons}) app:render()








 return app end

 M.render = function(app) app.view:render({app.components["empty-fields"], app.components.buttons, app.components.cards, app["standard-patience-components"](app)})




 return app end

 return M