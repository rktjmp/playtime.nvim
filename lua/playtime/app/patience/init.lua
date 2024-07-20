
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

 local api = vim["api"]
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
 local _4_ = impl_config.StateImpl if ((_G.type(_4_) == "table") and (nil ~= _4_.Default) and (nil ~= _4_.Animating) and (nil ~= _4_.GameEnded) and (nil ~= _4_.LiftingCards) and (nil ~= _4_.DraggingCards)) then local Default = _4_.Default local Animating = _4_.Animating local GameEnded = _4_.GameEnded local LiftingCards = _4_.LiftingCards local DraggingCards = _4_.DraggingCards do local _ = impl_config.StateImpl end else local __2_auto = _4_ error("impl-config.StateImpl must match {:Animating Animating\n :Default Default\n :DraggingCards DraggingCards\n :GameEnded GameEnded\n :LiftingCards LiftingCards}") end end
 do

 local _6_ = impl_config.LogicImpl if ((_G.type(_6_) == "table") and ((_G.type(_6_.Action) == "table") and (nil ~= _6_.Action.move)) and ((_G.type(_6_.Query) == "table") and (nil ~= _6_.Query["liftable?"]) and (nil ~= _6_.Query["droppable?"]) and (nil ~= _6_.Query["game-ended?"]) and (nil ~= _6_.Query["game-result"]))) then local move = _6_.Action.move local liftable_3f = _6_.Query["liftable?"] local droppable_3f = _6_.Query["droppable?"] local game_ended_3f = _6_.Query["game-ended?"] local game_result = _6_.Query["game-result"] do local _ = impl_config.LogicImpl end else local __2_auto = _6_ error("impl-config.LogicImpl must match {:Action {:move move}\n :Query {:droppable? droppable?\n         :game-ended? game-ended?\n         :game-result game-result\n         :liftable? liftable?}}") end end
 local function __index(_, key) return (impl_config.AppImpl[key] or M[key]) end
 local app = setmetatable(App.build(template_config.name, template_config.filetype, app_config, game_config), {__index = __index})




 local view = Window.open(template_config.filetype, App["build-default-window-dispatch-options"](app), {width = template_config.view.width, height = template_config.view.height, ["window-position"] = app_config["window-position"], ["minimise-position"] = app_config["minimise-position"]})





 local card_style = table.merge({width = 7, height = 5}, template_config["card-style"])
 app.Impl = impl_config
 app.Template = template_config
 app.view = view
 app["card-style"] = card_style
 table.merge(app["z-layers"], {button = 5, cards = 25, animation = 200, lift = 200}) app["setup-new-game"](app, app["game-config"], _3fseed)

 local function _8_() return app["queue-event"](app, "app", "deal") end vim.defer_fn(_8_, 300) return app:render() end


 M["setup-new-game"] = function(app, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/app/patience/init.fnl:57") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/patience/init.fnl:57") app["new-game"](app, app.Impl.LogicImpl.build, game_config, _3fseed) app["build-components"](app) app["switch-state"](app, app.Impl.StateImpl.Default)



 return app end

 M["build-components"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/patience/init.fnl:63")
 local card_card_components do local tbl_16_auto = {} for location, card in app.Impl.LogicImpl["iter-cards"](app.game) do local k_17_auto, v_18_auto = nil, nil
 do local comp local function _9_(...) return app["location->position"](app, ...) end comp = CardComponents.card(_9_, location, card, app["card-style"])



 k_17_auto, v_18_auto = card.id, comp end if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end card_card_components = tbl_16_auto end
 local menubar = CommonComponents.menubar({{app.name, {"file"}, {{"", nil}, {"New Deal", {"new-deal"}}, {"Repeat Deal", {"repeat-deal"}}, {"", nil}, {"Undo", {"undo"}}, {"", nil}, {"Save current game", {"save"}}, {"Load last save", {"load"}}, {"", nil}, {"Quit", {"quit"}}, {"", nil}, {string.format("Seed: %s", app.seed), nil}}}}, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar")}) local win_count














 do local _let_11_ = app["fetch-statistics"](app) local wins = _let_11_["wins"]
 win_count = CommonComponents["win-count"](wins, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar", 1)}) end


 local empty_fields = app.Template["empty-fields"] local empty_fields0
 do local base = {} for _, _12_ in ipairs(empty_fields) do local field = _12_[1] local count = _12_[2]
 local tbl_19_auto = base for i = 1, count do local val_20_auto
 local function _13_(location)
 return table.set(app["location->position"](app, location), "z", app["z-index-for-layer"](app, "base")) end val_20_auto = CardComponents.slot(_13_, {field, i, 0}, app["card-style"]) table.insert(tbl_19_auto, val_20_auto) end base = tbl_19_auto end empty_fields0 = base end



 local game_report = CommonComponents["game-report"](app.view.width, app.view.height, app["z-index-for-layer"](app, "report"), {{"won", "Solved"}, {"lost", "Not Solved"}})




 table.merge(app.components, {["empty-fields"] = empty_fields0, menubar = menubar, ["win-count"] = win_count, ["game-report"] = game_report})
 app["card-id->components"] = card_card_components
 app.components.cards = table.values(card_card_components)
 return app end

 M["standard-patience-components"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/patience/init.fnl:107")
 local tbl_21_auto = {} local i_22_auto = 0 for _, key in ipairs({"game-report", "win-count", "menubar", "cheating"}) do
 local val_23_auto = app.components[key] if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end

 M.save = function(app, filename) _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/app/patience/init.fnl:111") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/patience/init.fnl:111")





 local _15_ do local tbl_21_auto = {} local i_22_auto = 0 for _, _16_ in ipairs(app["game-history"]) do local _state = _16_[1] local action = _16_[2]
 local val_23_auto = action if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end _15_ = tbl_21_auto end return App.save(app, filename, {version = 1, ["app-id"] = app["app-id"], seed = app.seed, config = app["game-config"], latest = app.game, replay = _15_}) end

 M.load = function(app, filename) _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/app/patience/init.fnl:120") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/patience/init.fnl:120")
 local function _18_(...) local _19_ = ... if (nil ~= _19_) then local data = _19_

 local config = data["config"] local seed = data["seed"] local latest = data["latest"] local replay = data["replay"] app["setup-new-game"](app, config, seed) return app["queue-event"](app, "app", "replay", {replay = replay, verify = latest}) else local __85_auto = _19_ return ... end end return _18_(App.load(app, filename)) end



 M["update-statistics"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/patience/init.fnl:127")
 local function update(d)
 local data = table.merge({version = 1, wins = 0, games = {}}, d)
 data.wins = (data.wins + 1)
 data.games = table.insert(data.games, {seed = app.seed, moves = app.game.moves, time = ((app["ended-at"] or app["started-at"]) - app["started-at"])})



 return data end
 return App["update-statistics"](app, update) end

 M.render = function(app) app.view:render({app.components["empty-fields"], app.components.cards, app["standard-patience-components"](app)})



 return app end

 M["game-ended-data"] = function(app)
 local key do local _21_ = app.Impl.LogicImpl.Query["game-result"](app.game) if (_21_ == true) then key = "won" else local _ = _21_ key = "lost" end end


 local other = {string.fmt("Moves: %d", app.game.moves), string.fmt("Time:  %ds", (app["ended-at"] - app["started-at"]))}

 return {key, other} end

 M.tick = function(app)
 local now = uv.now() app["process-next-event"](app)

 do local _23_ = app.state.module.tick if (nil ~= _23_) then local f = _23_
 f(app) else local _ = _23_
 for location, card in app.Impl.LogicImpl["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card) end end end



 if (not ((app.Impl.StateImpl.GameEnded == app.state.module) or (App.State.DefaultInMenuState == app.state.module)) and app.Impl.LogicImpl.Query["game-ended?"](app.game)) then app["switch-state"](app, app.Impl.StateImpl.GameEnded) else end return app["request-render"](app) end





 return M