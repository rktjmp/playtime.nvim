
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Error = require("playtime.error")

 local CommonComponents = require("playtime.common.components")
 local CardComponents = require("playtime.common.card.components")
 local SetComponents = require("playtime.game.set.components")
 local CardUtils = require("playtime.common.card.utils")
 local App = require("playtime.app")
 local Window = require("playtime.app.window")

 local M = setmetatable({}, {__index = App})
 local Logic = require("playtime.game.set.logic")





 local RegularAppState = {}

 RegularAppState.Default = App.State.build("Default", {delegate = {app = App.State.DefaultAppState}})
 RegularAppState.SubmitSet = App.State.build("SubmitSet", {delegate = {app = RegularAppState.Default}})
 RegularAppState.GameEnded = App.State.build("GameEnded", {delegate = {app = RegularAppState.Default}})
 RegularAppState.Animating = clone(App.State.DefaultAnimatingState)

 RegularAppState.Default.activated = function(app, _3fcontext)
 if ((_G.type(_3fcontext) == "table") and (_3fcontext.selected == nil)) then
 app.state.context.selected = {} return nil else return nil end end

 RegularAppState.Default.OnEvent.app["new-game"] = function(app) app["setup-new-game"](app, app["game-config"], nil)

 local function _3_() return app["queue-event"](app, "app", "deal") end return vim.defer_fn(_3_, 300) end

 RegularAppState.Default.OnEvent.app["restart-game"] = function(app) app["setup-new-game"](app, app["game-config"], app.seed)

 local function _4_() return app["queue-event"](app, "app", "deal") end return vim.defer_fn(_4_, 300) end

 RegularAppState.Default.OnEvent.app["hint-random-set"] = function(app)
 local _5_ = Logic.Query["find-sets"](app.game) if ((_G.type(_5_) == "table") and (_5_[1] == nil)) then return app:notify("No sets to hint!") elseif (nil ~= _5_) then local sets = _5_

 local _let_6_ = table.shuffle(sets) local a_set = _let_6_[1]
 local logic_hint = Logic.Query["hint-for-set"](app.game, a_set)
 local function _7_() local h = {same = {}, diff = {}} for k, v in pairs(logic_hint) do

 h = table.set(h, v, table.insert(h[v], k)) end return h end local _let_8_ = _7_() local same = _let_8_["same"] local diff = _let_8_["diff"] local single_hint
 do local _9_, _10_ = same, diff if (((_G.type(_9_) == "table") and (_9_[1] == nil)) and true) then local _ = _10_ single_hint = "everything different" elseif (true and ((_G.type(_10_) == "table") and (_10_[1] == nil))) then local _ = _9_ single_hint = "everything identical" elseif ((nil ~= _9_) and (nil ~= _10_)) then local sames = _9_ local diffs = _10_


 single_hint = string.fmt("identical %s and different %s", table.concat(sames, ", "), table.concat(diffs, ", ")) else single_hint = nil end end


 local function _13_() local _12_ = #sets if (_12_ == 1) then
 return {"is", "it", 1, "set"} elseif (nil ~= _12_) then local n = _12_
 return {"are", "One", n, "sets"} else return nil end end local _let_15_ = _13_() local verb_1 = _let_15_[1] local verb_2 = _let_15_[2] local count = _let_15_[3] local noun = _let_15_[4] local msg
 do local data_5_auto = {count = count, noun = noun, ["single-hint"] = single_hint, ["verb-1"] = verb_1, ["verb-2"] = verb_2} local resolve_6_auto local function _16_(name_7_auto) local _17_ = data_5_auto[name_7_auto] local and_18_ = (nil ~= _17_) if and_18_ then local t_8_auto = _17_ and_18_ = ("table" == type(t_8_auto)) end if and_18_ then local t_8_auto = _17_ local _20_ = getmetatable(t_8_auto) if ((_G.type(_20_) == "table") and (nil ~= _20_.__tostring)) then local f_9_auto = _20_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _20_ return vim.inspect(t_8_auto) end elseif (nil ~= _17_) then local v_11_auto = _17_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _16_ msg = string.gsub("There #{verb-1} #{count} possible #{noun}. #{verb-2} has #{single-hint}.", "#{(.-)}", resolve_6_auto) end return app:notify(msg) else return nil end end


 RegularAppState.Default.OnEvent.app["deal-more"] = function(app)
 local function _24_(...) local _25_, _26_ = ... if ((nil ~= _25_) and (nil ~= _26_)) then local next_game = _25_ local moves = _26_

 local after local function _27_() app["update-game"](app, next_game, {"deal-more"})

 if Logic.Query["game-ended?"](app.game) then return app["switch-state"](app, RegularAppState.GameEnded) else app["switch-state"](app, RegularAppState.Default) app["queue-event"](app, "app", "noop")




 if table["empty?"](Logic.Query["find-sets"](app.game)) then return app["queue-event"](app, "app", "deal-more") else return nil end end end after = _27_ local timeline = app["build-event-animation"](app, moves, after, {["stagger-ms"] = 50, ["duration-ms"] = 120}) return app["switch-state"](app, RegularAppState.Animating, timeline) elseif ((_25_ == nil) and (nil ~= _26_)) then local e = _26_ return app:notify(e) else return nil end end return _24_(Logic.Action["deal-more"](app.game)) end






 RegularAppState.Default.OnEvent.input["<LeftMouse>"] = function(app, _31_, _pos) local location = _31_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu") and true and (location[3] == nil)) then local _idx = location[2] local menu_item = location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) elseif ((_G.type(location) == "table") and (location[1] == "draw") and true) then local _ = location[2] return app["queue-event"](app, "app", "deal-more") elseif ((_G.type(location) == "table") and (location[1] == "deal") and (nil ~= location[2])) then local n = location[2]



 local selected = app.state.context["selected"] local _3findex
 do local found = nil for i, deal_n in ipairs(selected) do if found then break end
 if (n == deal_n) then found = i else found = nil end end _3findex = found end
 if (_3findex == nil) then
 table.insert(selected, n) elseif (nil ~= _3findex) then local i = _3findex
 table.remove(selected, i) else end
 if (3 == #selected) then return app["switch-state"](app, RegularAppState.SubmitSet, {selected = selected}) else return nil end else return nil end end


 RegularAppState.Default.OnEvent.input["<RightMouse>"] = function(app, _location, _pos)
 app.state.context.selected = {} return nil end

 RegularAppState.Default.OnEvent.app.deal = function(app)
 local next_game, moves = Logic.Action.deal(app.game) local after
 local function _36_() app["switch-state"](app, RegularAppState.Default, {selected = {}}) app["update-game"](app, next_game, {"deal"}) app["queue-event"](app, "app", "noop")








 if table["empty?"](Logic.Query["find-sets"](app.game)) then return app["queue-event"](app, "app", "deal-more") else return nil end end after = _36_ local timeline = app["build-event-animation"](app, moves, after, {["stagger-ms"] = 50, ["duration-ms"] = 120}) return app["switch-state"](app, RegularAppState.Animating, timeline) end




 RegularAppState.Default.tick = function(app)
 local selected = app.state.context["selected"] app.components["set-count"]:update((#app.game.discard / 3)) app.components["draw-count"]:update(#app.game.draw)


 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] local selected_3f
 if ((_G.type(location) == "table") and (location[1] == "deal") and (nil ~= location[2])) then local n = location[2] local found = false
 for i, deal_n in ipairs(selected) do if found then break end
 found = (n == deal_n) end selected_3f = found else local _ = location selected_3f = false end comp:update(location, card, selected_3f) end return nil end



 RegularAppState.SubmitSet.activated = function(app, _context)

 local function _39_() return app["queue-event"](app, "app", "submit") end return vim.defer_fn(_39_, 180) end

 RegularAppState.SubmitSet.tick = function(...)

 return RegularAppState.Default.tick(...) end

 RegularAppState.SubmitSet.OnEvent.app.submit = function(app)
 local selected = app.state.context["selected"]
 local function _40_(...) local _41_, _42_ = ... if ((nil ~= _41_) and (nil ~= _42_)) then local next_game = _41_ local moves = _42_

 local after local function _43_() app["update-game"](app, next_game, {"submit-set", selected})

 if Logic.Query["game-ended?"](app.game) then return app["switch-state"](app, RegularAppState.GameEnded) else app["switch-state"](app, RegularAppState.Default)



 if table["empty?"](Logic.Query["find-sets"](app.game)) then return app["queue-event"](app, "app", "deal-more") else return nil end end end after = _43_ local timeline = app["build-event-animation"](app, moves, after, {["stagger-ms"] = 50, ["duration-ms"] = 120}) return app["switch-state"](app, RegularAppState.Animating, timeline) elseif ((_41_ == nil) and (nil ~= _42_)) then local e = _42_ app:notify(e) return app["switch-state"](app, RegularAppState.Default, {selected = {}}) else return nil end end return _40_(Logic.Action["submit-set"](app.game, selected)) end








 RegularAppState.GameEnded.activated = function(app)
 app["ended-at"] = os.time()
 local _let_47_ = Logic.Query["game-result"](app.game) local sets = _let_47_["sets"] local remaining = _let_47_["remaining"]
 local other = {string.fmt("Sets found: %d", sets), string.fmt("Remaining cards: %d", remaining), string.fmt("Time: %ds", (app["ended-at"] - app["started-at"]))} return app.components["game-report"]:update("won", other) end




 RegularAppState.GameEnded.OnEvent.input["<LeftMouse>"] = function(app, _48_, pos) local location = _48_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end



 M["build-event-animation"] = function(app, moves, after, _3fopts) _G.assert((nil ~= after), "Missing argument after on fnl/playtime/game/set/app.fnl:162") _G.assert((nil ~= moves), "Missing argument moves on fnl/playtime/game/set/app.fnl:162") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/set/app.fnl:162")
 return CardUtils["build-event-animation"](app, moves, after, _3fopts) end

 M["location->position"] = function(app, location)
 local card_width = app["card-style"]["width"]
 local deal_start_col = (4 + card_width) local deal_start_row = 2

 if ((_G.type(location) == "table") and (location[1] == "draw") and (nil ~= location[2])) then local n = location[2]
 return {row = deal_start_row, col = (deal_start_col - (card_width + 2)), z = n} elseif ((_G.type(location) == "table") and (location[1] == "discard") and (nil ~= location[2])) then local n = location[2]


 return {row = deal_start_row, col = (((card_width + 1) * 5) + 4), z = n} elseif ((_G.type(location) == "table") and (location[1] == "deal") and (nil ~= location[2])) then local n = location[2]


 local row = (1 + math.modf(((n - 1) / 4)))
 local col = (1 + ((n - 1) % 4))
 return {row = (2 + ((row - 1) * 5)), col = (deal_start_col + ((col - 1) * (card_width + 1))), z = 1} else local _ = location


 local function _57_() local data_5_auto = {location = location} local resolve_6_auto local function _50_(name_7_auto) local _51_ = data_5_auto[name_7_auto] local and_52_ = (nil ~= _51_) if and_52_ then local t_8_auto = _51_ and_52_ = ("table" == type(t_8_auto)) end if and_52_ then local t_8_auto = _51_ local _54_ = getmetatable(t_8_auto) if ((_G.type(_54_) == "table") and (nil ~= _54_.__tostring)) then local f_9_auto = _54_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _54_ return vim.inspect(t_8_auto) end elseif (nil ~= _51_) then local v_11_auto = _51_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _50_ return string.gsub("Unable to convert location to position, unknown location #{location}", "#{(.-)}", resolve_6_auto) end return error(Error(_57_())) end end

 M.start = function(app_config, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/set/app.fnl:183") _G.assert((nil ~= app_config), "Missing argument app-config on fnl/playtime/game/set/app.fnl:183")
 local app = setmetatable(App.build("SET", "set", app_config, game_config), {__index = M})

 local game_set_glyph_width = app_config["__beta-game-set-font-glyph-width"] local card_style


 local _59_ if ("wide" == game_set_glyph_width) then _59_ = 10 else _59_ = 9 end card_style = {height = 5, ["glyph-width"] = game_set_glyph_width, width = _59_} local view


 local _61_ if (game_set_glyph_width == "wide") then _61_ = 71 else _61_ = 65 end view = Window.open("set", App["build-default-window-dispatch-options"](app), {width = _61_, height = 25, ["window-position"] = app_config["window-position"], ["minimise-position"] = app_config["minimise-position"]})



 local _ = table.merge(app["z-layers"], {cards = 25, report = 120, animation = 200})
 app.view = view
 app["card-style"] = card_style app["setup-new-game"](app, app["game-config"], _3fseed)

 local function _63_() return app["queue-event"](app, "app", "deal") end vim.defer_fn(_63_, 300) return app:render() end


 M["setup-new-game"] = function(app, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/set/app.fnl:203") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/set/app.fnl:203") app["new-game"](app, Logic.build, game_config, _3fseed) app["build-components"](app) app["switch-state"](app, RegularAppState.Default, {selected = {}})



 return app end

 M["build-components"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/set/app.fnl:209")
 local card_style = app["card-style"] local card_card_components
 do local tbl_16_auto = {} for location, card in Logic["iter-cards"](app.game) do local k_17_auto, v_18_auto = nil, nil
 do local comp
 local function _64_(_241) return app["location->position"](app, _241) end comp = SetComponents.card(_64_, location, card, card_style)



 k_17_auto, v_18_auto = card.id, comp end if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end card_card_components = tbl_16_auto end
 local game_report = CommonComponents["game-report"](app.view.width, app.view.height, app["z-index-for-layer"](app, "report"), {{"won", "You did it!"}}) local slots



 local function _66_(_241) return app["location->position"](app, _241) end


 local function _67_(_241) return app["location->position"](app, _241) end slots = {SetComponents.slot(_66_, {"draw", 0}, card_style), SetComponents.slot(_67_, {"discard", 0}, card_style)}


 local draw_count = CardComponents.count(app["location->position"](app, {"draw", 100}), card_style):update(81)

 local set_count = CardComponents.count(app["location->position"](app, {"discard", 100}), card_style)
 local menubar = CommonComponents.menubar({{"SET", {"file"}, {{"", nil}, {"New Game", {"new-game"}}, {"Restart Game", {"restart-game"}}, {"", nil}, {"Undo", {"undo"}}, {"", nil}, {"Hint", {"hint-random-set"}}, {"", nil}, {"Quit", {"quit"}}, {"", nil}, {string.format("Seed: %s", app.seed), nil}}}}, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar")})
















 app["card-id->components"] = card_card_components
 return table.merge(app.components, {menubar = menubar, slots = slots, ["draw-count"] = draw_count, ["set-count"] = set_count, ["game-report"] = game_report, cards = table.values(card_card_components)}) end






 M.render = function(app) app.view:render({{app.components.menubar}, app.components.slots, {app.components["draw-count"], app.components["set-count"]}, app.components.cards, {app.components["game-report"]}})





 return app end

 M.tick = function(app) app["process-next-event"](app)

 do local _68_ = app.state.module.tick if (nil ~= _68_) then local f = _68_
 f(app) else local _ = _68_
 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card) end end end return app["request-render"](app) end



 return M