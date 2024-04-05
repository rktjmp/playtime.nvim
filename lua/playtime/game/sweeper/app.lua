
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Error = require("playtime.error")
 local Animate = require("playtime.animate")
 local CommonComponents = require("playtime.common.components")
 local Component = require("playtime.component")
 local App = require("playtime.app")
 local Window = require("playtime.app.window")

 local _local_2_ = vim local api = _local_2_["api"]
 local uv = (vim.loop or vim.uv)

 local Logic = require("playtime.game.sweeper.logic")
 local UI = require("playtime.game.sweeper.ui")
 local M = setmetatable({}, {__index = App})

 local AppState = {}
 AppState.Default = App.State.build("Default", {delegate = {app = App.State.DefaultAppState}})
 AppState.PickingCell = App.State.build("PickingCell", {delegate = {app = AppState.Default}})
 AppState.MarkingCell = App.State.build("MarkingCell", {delegate = {app = AppState.Default}})
 AppState.GameEnded = App.State.build("GameEnded", {delegate = {app = AppState.Default}})





 AppState.Default.activated = function(app) return (app.components.smile):update("smile") end


 AppState.GameEnded.activated = function(app)
 app["ended-at"] = os.time()
 local other = {string.fmt("Time: %ds", (app["ended-at"] - app["started-at"]))}
 local result = Logic.Query["game-result"](app.game) local face
 if (result == "won") then face = "bruh" elseif (result == "lost") then face = "sad" else face = nil end do end (app.components["game-report"]):update(result, other) return (app.components.smile):update(face) end





 AppState.PickingCell.activated = function(app) return (app.components.smile):update("scare") end


 AppState.Default.OnEvent.input["<LeftMouse>"] = function(app, _4_, pos) local _arg_5_ = _4_ local location = _arg_5_[1]
 if ((_G.type(location) == "table") and (location[1] == "face")) then return app["queue-event"](app, "app", "restart-game") elseif ((_G.type(location) == "table") and (location[1] == "grid")) then return app["push-state"](app, AppState.PickingCell, {picking = location}) elseif ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end









 AppState.Default.OnEvent.input["<RightMouse>"] = function(app, _7_, pos) local _arg_8_ = _7_ local location = _arg_8_[1]
 if ((_G.type(location) == "table") and (location[1] == "grid")) then return app["push-state"](app, AppState.MarkingCell, {picking = location}) else return nil end end



 AppState.GameEnded.OnEvent.input["<LeftMouse>"] = function(app, _10_) local _arg_11_ = _10_ local location = _arg_11_[1]
 if ((_G.type(location) == "table") and (location[1] == "face")) then return app["queue-event"](app, "app", "restart-game") elseif ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end




 AppState.PickingCell.OnEvent.input["<LeftDrag>"] = function(app, _13_, pos) local _arg_14_ = _13_ local location = _arg_14_[1]
 if ((_G.type(location) == "table") and (location[1] == "grid")) then
 app.state.context.picking = location return nil else local _ = location
 app.state.context.picking = nil return nil end end

 AppState.PickingCell.OnEvent.input["<LeftRelease>"] = function(app, _16_, pos) local _arg_17_ = _16_ local location = _arg_17_[1]
 if ((_G.type(location) == "table") and (location[1] == "face")) then return app["queue-event"](app, "app", "restart-game") elseif ((_G.type(location) == "table") and (location[1] == "grid") and ((_G.type(location[2]) == "table") and (nil ~= location[2].x) and (nil ~= location[2].y))) then local x = location[2].x local y = location[2].y


 local function _18_(...) local _19_ = ... if (nil ~= _19_) then local next_game = _19_ app["update-game"](app, next_game, {"reveal-location", {x = x, y = y}})



 if Logic.Query["game-ended?"](app.game) then return app["switch-state"](app, AppState.GameEnded) else return app["switch-state"](app, AppState.Default) end else local __85_auto = _19_ return ... end end return _18_(Logic.Action["reveal-location"](app.game, {x = x, y = y})) else local _ = location return app["switch-state"](app, AppState.Default) end end




 AppState.MarkingCell.OnEvent.input["<RightDrag>"] = function(app, _23_, pos) local _arg_24_ = _23_ local location = _arg_24_[1]
 if ((_G.type(location) == "table") and (location[1] == "grid")) then
 app.state.context.picking = location return nil else local _ = location
 app.state.context.picking = nil return nil end end

 AppState.MarkingCell.OnEvent.input["<RightRelease>"] = function(app, _26_, pos) local _arg_27_ = _26_ local location = _arg_27_[1]
 if ((_G.type(location) == "table") and (location[1] == "grid") and ((_G.type(location[2]) == "table") and (nil ~= location[2].x) and (nil ~= location[2].y))) then local x = location[2].x local y = location[2].y

 local function _28_(...) local _29_ = ... if (nil ~= _29_) then local next_game = _29_ app["update-game"](app, next_game, {"mark-location", {x = x, y = y}})



 if Logic.Query["game-ended?"](app.game) then return app["switch-state"](app, AppState.GameEnded) else return app["switch-state"](app, AppState.Default) end else local __85_auto = _29_ return ... end end return _28_(Logic.Action["mark-location"](app.game, {x = x, y = y})) else local _ = location return app["switch-state"](app, AppState.Default) end end




 AppState.Default.OnEvent.app["restart-game"] = function(app)
 return AppState.Default.OnEvent.app["new-game"](app, {app["game-config"].width, app["game-config"].height, app["game-config"]["n-mines"]}) end



 AppState.Default.OnEvent.app["new-game"] = function(app, _33_) local _arg_34_ = _33_ local width = _arg_34_[1] local height = _arg_34_[2] local n_mines = _arg_34_[3] app["queue-event"](app, "app", "quit")

 local function _35_() return M.start(app["app-config"], {width = width, height = height, ["n-mines"] = n_mines}, nil) end return vim.schedule(_35_) end

 local function dim_hover(app)
 for loc, cell in Logic["iter-cells"](app.game) do
 local comp = app["cell-id->cell-component"][cell.id]
 local _36_, _37_ = loc, app.state.context.picking if (((_G.type(_36_) == "table") and (nil ~= _36_.x) and (nil ~= _36_.y)) and ((_G.type(_37_) == "table") and (_37_[1] == "grid") and ((_G.type(_37_[2]) == "table") and (_36_.x == _37_[2].x) and (_36_.y == _37_[2].y)))) then local x = _36_.x local y = _36_.y

 local pressed_3f do local _38_, _39_ = cell, app.state.module if (((_G.type(_38_) == "table") and (_38_.mark == nil)) and (_39_ == AppState.PickingCell)) then pressed_3f = true elseif (((_G.type(_38_) == "table") and (nil ~= _38_.mark)) and (_39_ == AppState.MarkingCell)) then local mark = _38_.mark pressed_3f = true else local _ = _38_ pressed_3f = false end end comp:update(cell, {["pressed?"] = pressed_3f}) else local _ = _36_ comp:update(cell) end end return nil end






 AppState.PickingCell.tick = function(app)
 return dim_hover(app) end

 AppState.MarkingCell.tick = function(app)
 return dim_hover(app) end

 AppState.Default.tick = function(app)
 for loc, cell in Logic["iter-cells"](app.game) do
 local comp = app["cell-id->cell-component"][cell.id] comp:update(cell) end return nil end


 M["setup-new-game"] = function(app, game_config, _3fseed) app["new-game"](app, Logic.build, game_config, _3fseed) app["build-components"](app) app["switch-state"](app, AppState.Default)



 return app end

 M["build-components"] = function(app)
 local function build_grid_component(game, offset)
 local _let_42_ = game local _let_43_ = _let_42_["size"] local width = _let_43_["width"] local height = _let_43_["height"]
 local _let_44_ = offset local row = _let_44_["row"] local col = _let_44_["col"] local cell_height = 3 local cell_width = 5 local t


 do local tbl_14_auto = {} for _45_, cell in Logic["iter-cells"](game) do local _each_46_ = _45_ local x = _each_46_["x"] local y = _each_46_["y"] local k_15_auto, v_16_auto = nil, nil
 do local tag = {x = x, y = y} local f
 do local _47_, _48_ = x, y if ((_47_ == 1) and (_48_ == 1)) then
 f = UI["nw-cell"] elseif ((_47_ == width) and (_48_ == 1)) then
 f = UI["ne-cell"] elseif ((_47_ == 1) and (_48_ == height)) then
 f = UI["sw-cell"] elseif ((_47_ == width) and (_48_ == height)) then
 f = UI["se-cell"] elseif ((_47_ == 1) and true) then local _ = _48_
 f = UI["w-cell"] elseif ((_47_ == width) and true) then local _ = _48_
 f = UI["e-cell"] elseif (true and (_48_ == 1)) then local _ = _47_
 f = UI["n-cell"] elseif (true and (_48_ == height)) then local _ = _47_
 f = UI["s-cell"] else local _ = _47_
 f = UI["mid-cell"] end end
 k_15_auto, v_16_auto = cell.id, f(cell, tag, {row = (row + ((cell_height - 1) * (y - 1))), col = (col + ((cell_width - 1) * (x - 1))), z = app["z-index-for-layer"](app, "grid")}) end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end t = tbl_14_auto end local components





 do local tbl_19_auto = {} local i_20_auto = 0 for _, _51_ in Logic["iter-cells"](game) do local _each_52_ = _51_ local id = _each_52_["id"] local val_21_auto = t[id] if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end components = tbl_19_auto end
 return components, t end

 local grid, cell_id__3ecell_component = build_grid_component(app.game, {row = 5, col = 3})
 local menubar = CommonComponents.menubar({{"Sweeper", {"file"}, {{"", nil}, {"New Classic 8x8, 10", {"new-game", {8, 8, 10}}}, {"New Easy 9x9, 10", {"new-game", {9, 9, 10}}}, {"New Medium 16x16, 40", {"new-game", {16, 16, 40}}}, {"New Expert 30x16, 99", {"new-game", {30, 16, 99}}}, {"", nil}, {"Undo", {"undo"}}, {"", nil}, {"Quit", {"quit"}}, {"", nil}}}}, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar")}) local remaining













 local function _54_(self, count)
 local s = string.format("%03d", count) self["set-content"](self, {{{s, "@playtime.color.red"}}}) return self["set-size"](self, {width = #s, height = 1}) end remaining = Component["set-position"](Component.build(_54_), {row = 3, col = 4, z = 10}):update(app.game["n-mines"]) local timer





 local function _55_(self, count)
 local s = string.format("%03d", count) self["set-content"](self, {{{s, "@playtime.color.red"}}}) return self["set-size"](self, {width = #s, height = 1}) end timer = Component["set-position"](Component.build(_55_), {row = 3, col = (app.view.width - 8), z = 10}):update(0) local smile





 local function _56_(self, what)
 local lines if (what == "smile") then
 lines = {" \226\160\182 \226\160\182 ", "\226\160\160\226\163\128\226\163\128\226\163\128\226\160\132"} elseif (what == "scare") then

 lines = {" \226\160\182 \226\160\182 ", "  \226\163\164  "} elseif (what == "sad") then

 lines = {" \226\160\182 \226\160\182 ", "\226\162\128\226\160\164\226\160\164\226\160\164\226\161\128"} elseif (what == "bruh") then

 lines = {" \226\160\182\226\160\146\226\160\182 ", "\226\160\160\226\163\164\226\163\164\226\163\164\226\160\132"} else lines = nil end local content

 do local tbl_19_auto = {} local i_20_auto = 0 for _, l in ipairs(lines) do
 local val_21_auto = {{l, "@playtime.color.yellow"}} if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end content = tbl_19_auto end return self["set-content"](self, content) end smile = Component["set-position"](Component["set-tag"](Component["set-size"](Component.build(_56_), {width = 5, height = 2}), {"face"}), {row = 2, col = (math.floor((app.view.width / 2)) - 3), z = 100}):update("smile")





 local game_report = CommonComponents["game-report"](app.view.width, app.view.height, app["z-index-for-layer"](app, "report"), {{"won", "Won"}, {"lost", "Lost"}})



 for _59_, cell in Logic["iter-cells"](app.game) do local _each_60_ = _59_ local i = _each_60_["i"]
 local comp = grid[i] comp:update(cell) end

 app["cell-id->cell-component"] = cell_id__3ecell_component
 table.merge(app.components, {smile = smile, remaining = remaining, timer = timer, grid = grid, menubar = menubar, ["game-report"] = game_report})

 return app end

 M.start = function(app_config, game_config, _3fseed)
 local app = setmetatable(App.build("Sweeper", "sweeper", app_config, game_config, _3fseed), {__index = M})

 local view_width = (8 + (4 * game_config.width))
 local view_height = (8 + (2 * game_config.height))
 local view = Window.open("sweeper", App["build-default-window-dispatch-options"](app), {width = view_width, height = view_height, ["window-position"] = app_config["window-position"], ["minimise-position"] = app_config["minimise-position"]})





 local _ = table.merge(app["z-layers"], {grid = 25})
 app.view = view app["setup-new-game"](app, app["game-config"], _3fseed) return app:render() end



 M.render = function(app) do end (app.view):render({app.components.grid, {app.components.smile, app.components.remaining, app.components.timer}, {app.components["game-report"], app.components.menubar, app.components.cheating}})





 return app end

 M.tick = function(app)
 local now = uv.now() app["process-next-event"](app) do end (app.components.remaining):update(app.game.remaining) do end (app.components.timer):update(((app["ended-at"] or os.time()) - app["started-at"]))



 do local _61_ = app.state.module.tick if (nil ~= _61_) then local f = _61_
 f(app) else local _ = _61_
 for loc, cell in Logic["iter-cells"](app.game) do
 local comp = app["cell-id->cell-component"][cell.id] comp:update(cell) end end end return app["request-render"](app) end



 return M