
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

 local function enabled_indexes(list)
 local tbl_21_auto = {} local i_22_auto = 0 for i, v in ipairs(list) do local val_23_auto
 if v then val_23_auto = i else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end

 local Logic = require("playtime.game.card-capture.logic")
 local AppState = {}

 AppState.Default = App.State.build("Default", {delegate = {app = App.State.DefaultAppState}})
 AppState.DealPhase = App.State.build("DealPhase", {delegate = {app = AppState.Default}})
 AppState.EnemyPhase = App.State.build("EnemyPhase", {delegate = {app = AppState.Default}})
 AppState.DiscardPhase = App.State.build("DiscardPhase", {delegate = {app = AppState.Default}})
 AppState.DrawPhase = App.State.build("DrawPhase", {delegate = {app = AppState.Default}})
 AppState.CapturePhase = App.State.build("CapturePhase", {delegate = {app = AppState.Default}})
 AppState.GameEnded = App.State.build("GameEnded", {delegate = {app = AppState.Default}})

 local build_event_animation = CardUtils["build-event-animation"]

 AppState.GameEnded.activated = function(app)
 local winner = Logic.Query["game-result"](app.game) local other
 if (winner == "player") then
 other = {"You captured all cards"} elseif (winner == "enemy") then
 other = {"The opposition captured a K,Q,J or A"} else other = nil end
 app["ended-at"] = os.time() app.components["game-report"]:update(winner, other)

 if (winner == "player") then app:save((os.time() .. "-win")) return app["update-statistics"](app) else return nil end end




 AppState.GameEnded.OnEvent.input["<LeftMouse>"] = function(app, _6_, pos) local location = _6_[1]
 Logger.info(location)
 if ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end


 AppState.Default.OnEvent.app["new-game"] = function(app) return app["setup-new-game"](app, app["game-config"], nil) end


 AppState.Default.OnEvent.app["restart-game"] = function(app) return app["setup-new-game"](app, app["game-config"], app.seed) end


 AppState.Default.OnEvent.app.replay = function(app, _8_) local replay = _8_["replay"] local _3fverify = _8_["verify"] local state = _8_["state"]
 if ((_G.type(replay) == "table") and (replay[1] == nil)) then return app["switch-state"](app, state) elseif ((_G.type(replay) == "table") and (nil ~= replay[1])) then local action = replay[1] local rest = {select(2, (table.unpack or _G.unpack)(replay))}


 if ((_G.type(action) == "table") and (action[1] == nil)) then return app["queue-event"](app, "app", "replay", {replay = rest, verify = _3fverify, state = state}) elseif (nil ~= action) then local action0 = action

 local function _9_(...) local _10_ = ... if ((_G.type(_10_) == "table") and (nil ~= _10_[1])) then local f_name = _10_[1] local args = {select(2, (table.unpack or _G.unpack)(_10_))} local function _11_(...) local _12_ = ... if (nil ~= _12_) then local f = _12_ local function _13_(...) local _14_, _15_ = ... if ((nil ~= _14_) and (nil ~= _15_)) then local next_game = _14_ local moves = _15_



 if true then app["update-game"](app, next_game, action0)


 return AppState.Default.OnEvent.app.replay(app, {replay = rest, verify = _3fverify, state = state}) else



 local after local function _16_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "noop") app["queue-event"](app, "app", "replay", {replay = rest, verify = _3fverify, state = state}) return app["update-game"](app, next_game, action0) end after = _16_




 local timeline = build_event_animation(moves, after, {["duration-ms"] = 120}) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end else local __85_auto = _14_ return ... end end return _13_(f(app.game, table.unpack(args))) else local __85_auto = _12_ return ... end end return _11_(Logic.Action[f_name]) else local __85_auto = _10_ return ... end end return _9_(action0) else return nil end else return nil end end


 AppState.DealPhase.activated = function(app)
 local next_game, moves = Logic.Action["both-draw"](app.game) local after
 local function _23_() app["update-game"](app, next_game, {"both-draw"}) return app["switch-state"](app, AppState.DiscardPhase) end after = _23_


 local timeline = build_event_animation(app, moves, after) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end


 AppState.EnemyPhase.activated = function(app) app.components["discard-label"]["set-visible"](app.components["discard-label"], false) app.components["capture-label"]["set-visible"](app.components["capture-label"], false) app.components["sacrifice-label"]["set-visible"](app.components["sacrifice-label"], false) app.components["yield-label"]["set-visible"](app.components["yield-label"], false)




 local next_game, moves = Logic.Action["enemy-draw"](app.game) local after
 local function _24_() app["update-game"](app, next_game, {"enemy-draw"}) return app["switch-state"](app, AppState.DiscardPhase) end after = _24_


 local timeline = build_event_animation(app, moves, after) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end


 AppState.DiscardPhase.activated = function(app)
 app.state.context.player = {false, false, false, false} app.components["discard-label"]["set-visible"](app.components["discard-label"], true) app.components["discard-label"]:update(true, 0)


 local c do local s = 0 for i = 1, 4 do local _25_ if app.game.player.hand[i] then _25_ = 1 else _25_ = 0 end s = (s + _25_) end c = s end
 if (0 == c) then return app["switch-state"](app, AppState.DrawPhase) else return nil end end


 AppState.DiscardPhase.deactivated = function(app) return app.components["discard-label"]["set-visible"](app.components["discard-label"], false) end


 AppState.DiscardPhase.OnEvent.input["<LeftMouse>"] = function(app, _28_, pos) local location = _28_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) elseif ((_G.type(location) == "table") and (location[1] == "player") and (location[2] == "hand") and (nil ~= location[3]) and (location[4] == nil)) then local n = location[3]



 app.state.context.player[n] = not app.state.context.player[n] return nil elseif ((_G.type(location) == "table") and (location[1] == "player") and (location[2] == "discard")) then
 local indexes = enabled_indexes(app.state.context.player)
 local next_game, moves = Logic.Action.discard(app.game, indexes) local after
 local function _29_() app["update-game"](app, next_game, {"discard", indexes}) return app["switch-state"](app, AppState.DrawPhase) end after = _29_


 local timeline = build_event_animation(app, moves, after) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) else return nil end end


 AppState.DrawPhase.activated = function(app)
 local next_game, moves = Logic.Action["player-draw"](app.game) local after
 local function _31_() app["update-game"](app, next_game, {"player-draw"}) return app["switch-state"](app, AppState.CapturePhase) end after = _31_


 local timeline = build_event_animation(app, moves, after) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end


 AppState.CapturePhase.activated = function(app)
 app.state.context = {player = {false, false, false, false}, enemy = {false, false, false, false}} app.components["discard-label"]:update(false) app.components["capture-label"]:update(false) app.components["sacrifice-label"]:update(false) app.components["yield-label"]:update(false) app.components["capture-label"]["set-visible"](app.components["capture-label"], true) app.components["sacrifice-label"]["set-visible"](app.components["sacrifice-label"], true) return app.components["yield-label"]["set-visible"](app.components["yield-label"], true) end









 AppState.CapturePhase.deactivated = function(app) app.components["capture-label"]["set-visible"](app.components["capture-label"], false) app.components["sacrifice-label"]["set-visible"](app.components["sacrifice-label"], false) return app.components["yield-label"]["set-visible"](app.components["yield-label"], false) end




 AppState.CapturePhase.OnEvent.input["<LeftMouse>"] = function(app, _32_, pos) local location = _32_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) elseif ((_G.type(location) == "table") and (location[1] == "player") and (location[2] == "hand") and (nil ~= location[3])) then local n = location[3]

 app.state.context.player[n] = not app.state.context.player[n] elseif ((_G.type(location) == "table") and (location[1] == "enemy") and (location[2] == "hand") and (nil ~= location[3])) then local n = location[3]
 for i, _ in ipairs(app.state.context.enemy) do
 app.state.context.enemy[i] = ((n == i) and not app.state.context.enemy[i]) end else end
 if (AppState.CapturePhase == app.state.module) then
 local player_indexes = enabled_indexes(app.state.context.player)
 local _let_34_ = enabled_indexes(app.state.context.enemy) local enemy_index = _let_34_[1] app.components["yield-label"]:update(false) app.components["sacrifice-label"]:update(false) app.components["capture-label"]:update(false)



 if (enemy_index and (0 < #player_indexes)) then

 local and_35_ = (1 == enemy_index)
 if and_35_ then and_35_ = not (nil == Logic.Action.yield(app.game, player_indexes)) end app.components["yield-label"]:update(and_35_) app.components["sacrifice-label"]:update(not (nil == Logic.Action.sacrifice(app.game, player_indexes, enemy_index))) app.components["capture-label"]:update(not (nil == Logic.Action.capture(app.game, player_indexes, enemy_index)))




 local op if ((_G.type(location) == "table") and (location[1] == "player") and (location[2] == "discard")) then
 op = {"capture", player_indexes, enemy_index} elseif ((_G.type(location) == "table") and (location[1] == "enemy") and (location[2] == "discard")) then
 op = {"yield", player_indexes} elseif ((_G.type(location) == "table") and (location[1] == "enemy") and (location[2] == "draw")) then
 op = {"sacrifice", player_indexes, enemy_index} else op = nil end
 if ((_G.type(op) == "table") and (nil ~= op[1])) then local f = op[1] local rest = {select(2, (table.unpack or _G.unpack)(op))}
 local function _37_(...) local _38_, _39_ = ... if ((nil ~= _38_) and (nil ~= _39_)) then local next_game = _38_ local moves = _39_

 local after local function _40_() app["update-game"](app, next_game, op) app["queue-event"](app, "app", "noop") return app["switch-state"](app, AppState.EnemyPhase) end after = _40_




 local timeline = build_event_animation(app, moves, after) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_38_ == nil) and (nil ~= _39_)) then local err = _39_ return app:notify(err) else return nil end end return _37_(Logic.Action[f](app.game, table.unpack(rest))) else return nil end else return nil end else return nil end end




 local function tick_with_picked_cards(app)
 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card)

 if ((_G.type(location) == "table") and (nil ~= location[1]) and (location[2] == "hand") and (nil ~= location[3])) then local actor = location[1] local n = location[3]
 local _let_45_ = app["location->position"](app, {actor, "hand", n}) local row = _let_45_["row"] local col = _let_45_["col"] local z = _let_45_["z"] local mod
 if (actor == "player") then mod = -1 elseif (actor == "enemy") then mod = 1 else mod = nil end
 local _48_ do local t_47_ = app.state.context if (nil ~= t_47_) then t_47_ = t_47_[actor] else end if (nil ~= t_47_) then t_47_ = t_47_[n] else end _48_ = t_47_ end if _48_ then comp["set-position"](comp, {row = (row + mod), col = col, z = z}) else end else end end return nil end


 AppState.DiscardPhase.tick = function(app)
 return tick_with_picked_cards(app) end

 AppState.CapturePhase.tick = function(app)
 return tick_with_picked_cards(app) end

 M["location->position"] = function(app, location)
 local config = {card = {margin = {row = 0, col = 1}, width = 7, height = 5}}

 local card_col_step = (config.card.width + config.card.margin.col)
 local enemy = {row = 4}
 local player = {row = 12}
 local draw = {col = 4}
 local hand = {col = (2 * card_col_step)}
 local discard = {col = (draw.col + (6 * card_col_step))}
 if ((_G.type(location) == "table") and (location[1] == "label") and (location[2] == "discard")) then
 return {row = (player.row + config.card.height + -3), col = discard.col, z = app["z-index-for-layer"](app, "label")} elseif ((_G.type(location) == "table") and (location[1] == "label") and (location[2] == "yield")) then


 return {row = (enemy.row + config.card.height + -3), col = (1 + discard.col), z = app["z-index-for-layer"](app, "label")} elseif ((_G.type(location) == "table") and (location[1] == "label") and (location[2] == "sacrifice")) then


 return {row = (enemy.row + config.card.height + -3), col = (draw.col + -1), z = app["z-index-for-layer"](app, "label")} elseif ((_G.type(location) == "table") and (location[1] == "label") and (location[2] == "capture")) then


 return {row = (player.row + config.card.height + -3), col = (1 + -1 + discard.col), z = app["z-index-for-layer"](app, "label")} elseif ((_G.type(location) == "table") and (location[1] == "enemy") and (location[2] == "draw") and (nil ~= location[3])) then local n = location[3]


 return {row = enemy.row, col = draw.col, z = n} elseif ((_G.type(location) == "table") and (location[1] == "enemy") and (location[2] == "hand") and (nil ~= location[3])) then local n = location[3]


 return {row = enemy.row, col = (hand.col + ((4 - n) * card_col_step)), z = n} elseif ((_G.type(location) == "table") and (location[1] == "enemy") and (location[2] == "discard") and (nil ~= location[3])) then local n = location[3]


 return {row = enemy.row, col = discard.col, z = n} elseif ((_G.type(location) == "table") and (location[1] == "player") and (location[2] == "draw") and (nil ~= location[3])) then local n = location[3]


 return {row = player.row, col = draw.col, z = n} elseif ((_G.type(location) == "table") and (location[1] == "player") and (location[2] == "hand") and (nil ~= location[3])) then local n = location[3]


 return {row = player.row, col = (hand.col + ((4 - n) * card_col_step)), z = n} elseif ((_G.type(location) == "table") and (location[1] == "player") and (location[2] == "discard") and (nil ~= location[3])) then local n = location[3]


 return {row = player.row, col = discard.col, z = n} else local _ = location


 return error(Error("Unable to convert location to position, unknown location #{location}", {location = location})) end end


 M.start = function(app_config, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/card-capture/app.fnl:249") _G.assert((nil ~= app_config), "Missing argument app-config on fnl/playtime/game/card-capture/app.fnl:249")
 local app = setmetatable(App.build("Card Capture", "card-capture", app_config, game_config), {__index = M})




 local view = Window.open("card-capture", App["build-default-window-dispatch-options"](app), {width = 63, height = 22, ["window-position"] = app_config["window-position"], ["minimise-position"] = app_config["minimise-position"]})





 local _ = table.merge(app["z-layers"], {cards = 25, label = 100, animation = 200})
 app.view = view
 app["card-style"] = {width = 7, height = 5, colors = 2} app["setup-new-game"](app, app["game-config"], _3fseed)

 local function _54_() return app["switch-state"](app, AppState.DealPhase) end vim.defer_fn(_54_, 300) return app:render() end


 M["setup-new-game"] = function(app, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/card-capture/app.fnl:268") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/card-capture/app.fnl:268") app["new-game"](app, Logic.build, game_config, _3fseed) app["build-components"](app) app["switch-state"](app, AppState.Default)



 return app end

 local function update_card_counts(app)
 app.components["card-counts"].player.draw(#app.game.player.draw)
 app.components["card-counts"].player.discard(#app.game.player.discard)
 app.components["card-counts"].enemy.draw(#app.game.enemy.draw)
 return app.components["card-counts"].enemy.discard(#app.game.enemy.discard) end

 M["build-components"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/card-capture/app.fnl:280")
 local function build_label(text, position)
 local row = position["row"] local col = position["col"] local z = position["z"]

 local function _55_(self, enabled)
 local hl if enabled then hl = "@playtime.ui.on" else hl = "@playtime.ui.off" end return self["set-content"](self, {{{text, hl}}}) end return Component["set-content"](Component["set-size"](Component["set-position"](Component.build(_55_), position), {width = #text, height = 1}), {{{text, "@playtime.ui.off"}}}) end





 local function build_card_count(position, z)
 local row = position["row"] local col = position["col"]

 local function _57_(self, count)
 local text = tostring(count) local col0
 do local _58_ = #text if (_58_ == 1) then
 col0 = (col + 5) elseif (_58_ == 2) then
 col0 = (col + 4) else col0 = nil end end self["set-position"](self, {row = (row + 4), col = col0, z = z}) self["set-size"](self, {width = #text, height = 1}) return self["set-content"](self, {{{text, "@playtime.ui.off"}}}) end return Component.build(_57_):update(0) end





 local card_card_components do local tbl_16_auto = {} for location, card in Logic["iter-cards"](app.game) do local k_17_auto, v_18_auto = nil, nil
 do local comp local function _60_(...) return app["location->position"](app, ...) end comp = CardComponents.card(_60_, location, card, app["card-style"])



 k_17_auto, v_18_auto = card.id, comp end if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end card_card_components = tbl_16_auto end
 local card_counts = {player = {draw = build_card_count(app["location->position"](app, {"player", "draw", 0}), app["z-index-for-layer"](app, "label")), discard = build_card_count(app["location->position"](app, {"player", "discard", 0}), app["z-index-for-layer"](app, "label"))}, enemy = {draw = build_card_count(app["location->position"](app, {"enemy", "draw", 0}), app["z-index-for-layer"](app, "label")), discard = build_card_count(app["location->position"](app, {"enemy", "discard", 0}), app["z-index-for-layer"](app, "label"))}}







 local discard_label = build_label("discard", app["location->position"](app, {"label", "discard"}))
 local yield_label = build_label("yield", app["location->position"](app, {"label", "yield"}))
 local sacrifice_label = build_label("sacrifice", app["location->position"](app, {"label", "sacrifice"}))
 local capture_label = build_label("capture", app["location->position"](app, {"label", "capture"}))
 local menubar = CommonComponents.menubar({{"Card Capture", {"file"}, {{"", nil}, {"New Game", {"new-game"}}, {"Restart Game", {"restart-game"}}, {"", nil}, {"Undo", {"undo"}}, {"", nil}, {"Save current game", {"save"}}, {"Load last save", {"load"}}, {"", nil}, {"Quit", {"quit"}}, {"", nil}, {string.format("Seed: %s", app.seed), nil}}}}, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar")}) local empty_fields














 do local base = {} for _, _62_ in ipairs({{"hand", 4}, {"draw", 1}, {"discard", 1}}) do local field = _62_[1] local count = _62_[2]

 for _0, actor in ipairs({"player", "enemy"}) do
 local tbl_19_auto = base for i = 1, count do local val_20_auto
 local function _63_(...) return table.set(app["location->position"](app, ...), "z", app["z-index-for-layer"](app, "base")) end val_20_auto = CardComponents.slot(_63_, {actor, field, i, 0}, app["card-style"]) table.insert(tbl_19_auto, val_20_auto) end end



 base = base end empty_fields = base end
 local game_report = CommonComponents["game-report"](app.view.width, app.view.height, app["z-index-for-layer"](app, "report"), {{"player", "Won"}, {"enemy", "Lost"}})





 table.merge(app.components, {["empty-fields"] = empty_fields, menubar = menubar, ["game-report"] = game_report, ["card-counts"] = card_counts, ["yield-label"] = yield_label, ["discard-label"] = discard_label, ["sacrifice-label"] = sacrifice_label, ["capture-label"] = capture_label})




 app["card-id->components"] = card_card_components
 app.components.cards = table.values(card_card_components)
 update_card_counts(app)
 return app end

 M.render = function(app) app.view:render({app.components["empty-fields"], app.components.cards, {app.components["card-counts"].player.discard, app.components["card-counts"].player.draw, app.components["card-counts"].enemy.discard, app.components["card-counts"].enemy.draw}, {app.components["yield-label"], app.components["discard-label"], app.components["sacrifice-label"], app.components["capture-label"]}, {app.components["game-report"]}, {app.components.menubar, app.components.cheating}})














 return app end

 M.tick = function(app)
 local now = uv.now() app["process-next-event"](app)

 do local _64_ = app.state.module.tick if (nil ~= _64_) then local f = _64_
 f(app) else local _ = _64_
 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card) end end end

 update_card_counts(app)


 if (not ((AppState.GameEnded == app.state.module) or (App.State.DefaultInMenuState == app.state.module)) and Logic.Query["game-ended?"](app.game)) then app["switch-state"](app, AppState.GameEnded) else end return app["request-render"](app) end





 M.save = function(app, filename) _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/game/card-capture/app.fnl:396") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/card-capture/app.fnl:396")





 local _69_ do local _67_, _68_ = app.state.module if (_67_ == AppState.DiscardPhase) then _69_ = "discard" elseif (_67_ == AppState.CapturePhase) then _69_ = "capture" elseif (_67_ == AppState.GameEnded) then _69_ = "ended" else local _3fmod = _67_



 _69_ = error(Error("unable to save turn for #{s}", {s = _3fmod})) end end
 local _75_ do local tbl_21_auto = {} local i_22_auto = 0 for _, _76_ in ipairs(app["game-history"]) do local _state = _76_[1] local action = _76_[2]
 local val_23_auto = action if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end _75_ = tbl_21_auto end return App.save(app, filename, {version = 1, ["app-id"] = app["app-id"], seed = app.seed, config = app["game-config"], latest = app.game, turn = _69_, replay = _75_}) end

 M.load = function(app, filename) _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/game/card-capture/app.fnl:410") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/card-capture/app.fnl:410")
 local function _78_(...) local _79_ = ... if (nil ~= _79_) then local data = _79_

 local config = data["config"] local seed = data["seed"] local latest = data["latest"] local replay = data["replay"] local turn = data["turn"] local state
 if (turn == "discard") then
 state = AppState.DiscardPhase elseif (turn == "capture") then
 state = AppState.CapturePhase elseif (turn == "ended") then
 state = AppState.GameEnded else local _ = turn
 state = error(Error("unknown turn: #{turn}", {turn = turn})) end app["setup-new-game"](app, config, seed) return app["queue-event"](app, "app", "replay", {replay = replay, verify = latest, state = state}) else local __85_auto = _79_ return ... end end return _78_(App.load(app, filename)) end



 M["update-statistics"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/card-capture/app.fnl:422")
 local function update(d)
 local data = table.merge({version = 1, wins = 0, games = {}}, d)
 data.wins = (data.wins + 1)
 data.games = table.insert(data.games, {seed = app.seed, time = ((app["ended-at"] or app["started-at"]) - app["started-at"])})


 return data end
 return App["update-statistics"](app, update) end

 return M