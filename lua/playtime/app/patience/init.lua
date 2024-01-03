
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Error = require("playtime.error")
 local Animate = require("playtime.animate")
 local CommonComponents = require("playtime.common.components")
 local CardComponents = require("playtime.common.card.components")
 local CardUtils = require("playtime.common.card.utils")
 local Component = require("playtime.component")
 local App = require("playtime.app")
 local Window = require("playtime.app.window")

 local _local_2_ = vim local api = _local_2_["api"]
 local uv = (vim.loop or vim.uv)
 local M = setmetatable({}, {__index = App})

 M["build-event-animation"] = function(app, moves, after, _3fopts) _G.assert((nil ~= after), "Missing argument after on fnl/playtime/app/patience/init.fnl:18") _G.assert((nil ~= moves), "Missing argument moves on fnl/playtime/app/patience/init.fnl:18") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/patience/init.fnl:18")
 return CardUtils["build-event-animation"](app, moves, after, _3fopts) end

 M.start = function(template_config, impl_config, app_config, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/app/patience/init.fnl:21") _G.assert((nil ~= app_config), "Missing argument app-config on fnl/playtime/app/patience/init.fnl:21") _G.assert((nil ~= impl_config), "Missing argument impl-config on fnl/playtime/app/patience/init.fnl:21") _G.assert((nil ~= template_config), "Missing argument template-config on fnl/playtime/app/patience/init.fnl:21")
 if ((_G.type(template_config) == "table") and (nil ~= template_config.name) and (nil ~= template_config.filetype) and ((_G.type(template_config["card-style"]) == "table") and (nil ~= template_config["card-style"].colors)) and ((_G.type(template_config.view) == "table") and (nil ~= template_config.view.width) and (nil ~= template_config.view.height)) and (nil ~= template_config["empty-fields"])) then local name = template_config.name local filetype = template_config.filetype local colors = template_config["card-style"].colors local width = template_config.view.width local height = template_config.view.height local empty_fields = template_config["empty-fields"] else




 local __2_auto = template_config error("template-config must match {:card-style {:colors colors}\n :empty-fields empty-fields\n :filetype filetype\n :name name\n :view {:height height :width width}}") end
 if ((_G.type(impl_config) == "table") and (nil ~= impl_config.AppImpl) and (nil ~= impl_config.LogicImpl) and (nil ~= impl_config.StateImpl)) then local AppImpl = impl_config.AppImpl local LogicImpl = impl_config.LogicImpl local StateImpl = impl_config.StateImpl else
 local __2_auto = impl_config error("impl-config must match {:AppImpl AppImpl :LogicImpl LogicImpl :StateImpl StateImpl}") end
 do
 local _5_ = impl_config.StateImpl if ((_G.type(_5_) == "table") and (nil ~= _5_.Default) and (nil ~= _5_.Animating) and (nil ~= _5_.GameEnded) and (nil ~= _5_.LiftingCards) and (nil ~= _5_.DraggingCards)) then local Default = _5_.Default local Animating = _5_.Animating local GameEnded = _5_.GameEnded local LiftingCards = _5_.LiftingCards local DraggingCards = _5_.DraggingCards do local _ = impl_config.StateImpl end else local __2_auto = _5_ error("impl-config.StateImpl must match {:Animating Animating\n :Default Default\n :DraggingCards DraggingCards\n :GameEnded GameEnded\n :LiftingCards LiftingCards}") end end
 do

 local _7_ = impl_config.LogicImpl if ((_G.type(_7_) == "table") and ((_G.type(_7_.Action) == "table") and (nil ~= _7_.Action.move)) and ((_G.type(_7_.Query) == "table") and (nil ~= _7_.Query["liftable?"]) and (nil ~= _7_.Query["droppable?"]) and (nil ~= _7_.Query["game-ended?"]) and (nil ~= _7_.Query["game-result"]))) then local move = _7_.Action.move local liftable_3f = _7_.Query["liftable?"] local droppable_3f = _7_.Query["droppable?"] local game_ended_3f = _7_.Query["game-ended?"] local game_result = _7_.Query["game-result"] do local _ = impl_config.LogicImpl end else local __2_auto = _7_ error("impl-config.LogicImpl must match {:Action {:move move}\n :Query {:droppable? droppable?\n         :game-ended? game-ended?\n         :game-result game-result\n         :liftable? liftable?}}") end end
 local function __index(_, key) return (impl_config.AppImpl[key] or M[key]) end
 local app = setmetatable(App.build(template_config.name, template_config.filetype, app_config, game_config), {__index = __index})




 local view = Window.open(template_config.filetype, App["build-default-window-dispatch-options"](app), {width = template_config.view.width, height = template_config.view.height, ["window-position"] = app_config["window-position"], ["minimise-position"] = app_config["minimise-position"]})





 local card_style = table.merge({width = 7, height = 5}, template_config["card-style"])
 app.Impl = impl_config
 app.Template = template_config
 app.view = view
 app["card-style"] = card_style
 table.merge(app["z-layers"], {button = 5, cards = 25, animation = 200, lift = 200}) app["setup-new-game"](app, app["game-config"], _3fseed)

 local function _9_() return app["queue-event"](app, "app", "deal") end vim.defer_fn(_9_, 300) return app:render() end


 M["setup-new-game"] = function(app, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/app/patience/init.fnl:57") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/patience/init.fnl:57") app["new-game"](app, app.Impl.LogicImpl.build, game_config, _3fseed) app["build-components"](app) app["switch-state"](app, app.Impl.StateImpl.Default)



 return app end

 M["build-components"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/patience/init.fnl:63")
 local card_card_components do local tbl_14_auto = {} for location, card in app.Impl.LogicImpl["iter-cards"](app.game) do local k_15_auto, v_16_auto = nil, nil
 do local comp local function _10_(...) return app["location->position"](app, ...) end comp = CardComponents.card(_10_, location, card, app["card-style"])



 k_15_auto, v_16_auto = card.id, comp end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end card_card_components = tbl_14_auto end
 local menubar = CommonComponents.menubar({{app.name, {"file"}, {{"", nil}, {"New Deal", {"new-deal"}}, {"Repeat Deal", {"repeat-deal"}}, {"", nil}, {"Undo", {"undo"}}, {"", nil}, {"Save current game", {"save"}}, {"Load last save", {"load"}}, {"", nil}, {"Quit", {"quit"}}, {"", nil}, {string.format("Seed: %s", app.seed), nil}}}}, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar")}) local win_count














 do local _let_12_ = app["fetch-statistics"](app) local wins = _let_12_["wins"]
 win_count = CommonComponents["win-count"](wins, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar", 1)}) end


 local empty_fields = app.Template["empty-fields"] local empty_fields0
 do local base = {} for _, _13_ in ipairs(empty_fields) do local _each_14_ = _13_ local field = _each_14_[1] local count = _each_14_[2]
 local tbl_17_auto = base for i = 1, count do
 local function _15_(location)
 return table.set(app["location->position"](app, location), "z", app["z-index-for-layer"](app, "base")) end table.insert(tbl_17_auto, CardComponents.slot(_15_, {field, i, 0}, app["card-style"])) end base = tbl_17_auto end empty_fields0 = base end



 local game_report = CommonComponents["game-report"](app.view.width, app.view.height, app["z-index-for-layer"](app, "report"), {{"won", "Solved"}, {"lost", "Not Solved"}})




 table.merge(app.components, {["empty-fields"] = empty_fields0, menubar = menubar, ["win-count"] = win_count, ["game-report"] = game_report})
 app["card-id->components"] = card_card_components
 app.components.cards = table.values(card_card_components)
 return app end

 M["standard-patience-components"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/patience/init.fnl:107")
 local tbl_18_auto = {} local i_19_auto = 0 for _, key in ipairs({"game-report", "win-count", "menubar", "cheating"}) do
 local val_20_auto = app.components[key] if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto end

 M.save = function(app, filename) _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/app/patience/init.fnl:111") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/patience/init.fnl:111")





 local _17_ do local tbl_18_auto = {} local i_19_auto = 0 for _, _18_ in ipairs(app["game-history"]) do local _each_19_ = _18_ local _state = _each_19_[1] local action = _each_19_[2]
 local val_20_auto = action if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end _17_ = tbl_18_auto end return App.save(app, filename, {version = 1, ["app-id"] = app["app-id"], seed = app.seed, config = app["game-config"], latest = app.game, replay = _17_}) end

 M.load = function(app, filename) _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/app/patience/init.fnl:120") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/patience/init.fnl:120")
 local function _21_(...) local _22_ = ... if (nil ~= _22_) then local data = _22_

 local _let_23_ = data local config = _let_23_["config"] local seed = _let_23_["seed"] local latest = _let_23_["latest"] local replay = _let_23_["replay"] app["setup-new-game"](app, config, seed) return app["queue-event"](app, "app", "replay", {replay = replay, verify = latest}) else local __84_auto = _22_ return ... end end return _21_(App.load(app, filename)) end



 M["update-statistics"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/patience/init.fnl:127")
 local function update(d)
 local data = table.merge({version = 1, wins = 0, games = {}}, d)
 data.wins = (data.wins + 1)
 data.games = table.insert(data.games, {seed = app.seed, moves = app.game.moves, time = ((app["ended-at"] or app["started-at"]) - app["started-at"])})



 return data end
 return App["update-statistics"](app, update) end

 M.render = function(app) do end (app.view):render({app.components["empty-fields"], app.components.cards, app["standard-patience-components"](app)})



 return app end

 M["game-ended-data"] = function(app)
 local key do local _25_ = app.Impl.LogicImpl.Query["game-result"](app.game) if (_25_ == true) then key = "won" else local _ = _25_ key = "lost" end end


 local other = {string.fmt("Moves: %d", app.game.moves), string.fmt("Time:  %ds", (app["ended-at"] - app["started-at"]))}

 return {key, other} end

 M.tick = function(app)
 local now = uv.now() app["process-next-event"](app)

 do local _27_ = app.state.module.tick if (nil ~= _27_) then local f = _27_
 f(app) else local _ = _27_
 for location, card in app.Impl.LogicImpl["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card) end end end



 if (not ((app.Impl.StateImpl.GameEnded == app.state.module) or (App.State.DefaultInMenuState == app.state.module)) and app.Impl.LogicImpl.Query["game-ended?"](app.game)) then app["switch-state"](app, app.Impl.StateImpl.GameEnded) else end return app["request-render"](app) end





 return M