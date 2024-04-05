
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Error = require("playtime.error")
 local Animate = require("playtime.animate")
 local CommonComponents = require("playtime.common.components")
 local Component = require("playtime.component")
 local App = require("playtime.app")
 local Window = require("playtime.app.window")
 local Meta = require("playtime.meta")

 local _local_2_ = vim local api = _local_2_["api"]
 local uv = (vim.loop or vim.uv)
 local M = setmetatable({}, {__index = App})

 local AppState = {}
 AppState.Default = App.State.build("Default", {delegate = {app = App.State.DefaultAppState}})

 AppState.Default.OnEvent.input["<LeftMouse>"] = function(app, _3_, _pos) local _arg_4_ = _3_ local location = _arg_4_[1]
 if ((_G.type(location) == "table") and (location[1] == "game") and (nil ~= location[2]) and true) then local mod = location[2] local _3fconfig = location[3]

 local function _5_() local Playtime = require("playtime")
 return Playtime.play(mod, nil, _3fconfig) end vim.schedule(_5_) return app["queue-event"](app, "app", "quit") elseif ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end




 M["location->position"] = function(app, location)

 if ((_G.type(location) == "table") and (location[1] == "list") and (nil ~= location[2])) then local n = location[2]
 return {row = (2 + ((n - 1) * 1)), col = 2, z = 1} else local _ = location
 return error(Error("Unable to convert location to position, unknown location #{location}", {location = location})) end end


 local function build_game_title(view_width, position, meta) _G.assert((nil ~= meta), "Missing argument meta on fnl/playtime/game/playtime/app.fnl:36") _G.assert((nil ~= position), "Missing argument position on fnl/playtime/game/playtime/app.fnl:36") _G.assert((nil ~= view_width), "Missing argument view-width on fnl/playtime/game/playtime/app.fnl:36")
 local function justify(a, b, c, _3fcolors)
 local max_mid = (view_width - 4 - #a - #c - 2)
 local colors = (_3fcolors or {"@playtime.color.yellow", "@playtime.ui.off", "@playtime.ui.off"})
 local mid = string.sub(b, 1, max_mid)
 local fill = string.rep(" ", math.max(0, (max_mid - #mid)))
 return {{a, colors[1]}, {(" " .. mid .. fill .. " "), colors[2]}, {c, colors[3]}} end
 local lines = {justify(meta.name, ("by " .. table.concat(meta.authors, ", ")), table.concat(table.sort(meta.categories), ", "), {"@playtime.color.yellow", "@playtime.ui.off", "@playtime.ui.off"}), justify(meta.desc, "", "", {"@playtime.color.blue", "@playtime.ui.off", "@playtime.ui.off"})}






 return Component["set-content"](Component["set-position"](Component["set-size"](Component.build(), {width = view_width, height = 2}), position), lines) end




 local function build_game_button(view_width, position, meta, _3fmenu_name, config) _G.assert((nil ~= config), "Missing argument config on fnl/playtime/game/playtime/app.fnl:55") _G.assert((nil ~= meta), "Missing argument meta on fnl/playtime/game/playtime/app.fnl:55") _G.assert((nil ~= position), "Missing argument position on fnl/playtime/game/playtime/app.fnl:55") _G.assert((nil ~= view_width), "Missing argument view-width on fnl/playtime/game/playtime/app.fnl:55")
 local menu_name if (_3fmenu_name == nil) then menu_name = "Play" elseif (nil ~= _3fmenu_name) then local x = _3fmenu_name

 menu_name = ("Play " .. x) else menu_name = nil end
 local lines = {{{("" .. menu_name), "@playtime.ui.menu"}}}
 return Component["set-content"](Component["set-position"](Component["set-tag"](Component["set-size"](Component.build(), {width = view_width, height = 1}), {"game", meta.mod, config}), position), lines) end





 M.start = function(app_config, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/playtime/app.fnl:66") _G.assert((nil ~= app_config), "Missing argument app-config on fnl/playtime/game/playtime/app.fnl:66")
 local app = setmetatable(App.build("Playtime", "playtime-menu", app_config, game_config), {__index = M})

 local view = Window.open("playtime-menu", App["build-default-window-dispatch-options"](app), {width = 80, height = 40, ["window-position"] = app_config["window-position"], ["minimise-position"] = app_config["minimise-position"]}) local _





 app.view = view _ = nil
 local metas = Meta.find() local list
 do local t, n = {}, 1 for _0, meta in ipairs(metas) do

 local title = build_game_title(app.view.width, M["location->position"](nil, {"list", n}), meta)
 local n0 = (n + 1)
 local rulesets = (meta.rulesets or {{menu = nil, config = {}}}) local variants
 do local tbl_19_auto = {} local i_20_auto = 0 for i, _9_ in ipairs(rulesets) do local _each_10_ = _9_ local _menu = _each_10_["menu"] local config = _each_10_["config"]
 local val_21_auto = build_game_button(app.view.width, M["location->position"](nil, {"list", (n0 + i)}), meta, _menu, config) if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end variants = tbl_19_auto end


 t, n = table.join(t, {title}, variants), (n0 + 2 + #variants) end list = t, n end



 local menubar = CommonComponents.menubar({{"Playtime", {"file"}, {{"", nil}, {"Quit", {"quit"}}, {"", nil}}}}, {width = view.width, z = app["z-index-for-layer"](app, "menubar")})





 table.merge(app.components, {menubar = menubar, list = list}) app["switch-state"](app, AppState.Default) return app:render() end



 M.render = function(app) do end (app.view):render({app.components.list, {app.components.menubar}})

 return app end


 M.tick = function(app)
 local now = uv.now() app["process-next-event"](app) return app["request-render"](app) end



 return M