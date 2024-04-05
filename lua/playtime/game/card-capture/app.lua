
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

 local function enabled_indexes(list)
 local tbl_19_auto = {} local i_20_auto = 0 for i, v in ipairs(list) do local val_21_auto
 if v then val_21_auto = i else val_21_auto = nil end if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end return tbl_19_auto end

 local Logic = require("playtime.game.card-capture.logic")
 local AppState = {}

 AppState.Default = App.State.build("Default", {delegate = {app = App.State.DefaultAppState}})
 AppState.DealPhase = App.State.build("DealPhase", {delegate = {app = AppState.Default}})
 AppState.EnemyPhase = App.State.build("EnemyPhase", {delegate = {app = AppState.Default}})
 AppState.DiscardPhase = App.State.build("DiscardPhase", {delegate = {app = AppState.Default}})
 AppState.DrawPhase = App.State.build("DrawPhase", {delegate = {app = AppState.Default}})
 AppState.CapturePhase = App.State.build("CapturePhase", {delegate = {app = AppState.Default}})
 AppState.GameEnded = App.State.build("GameEnded", {delegate = {app = AppState.Default}})

 local _local_5_ = CardUtils local build_event_animation = _local_5_["build-event-animation"]

 AppState.GameEnded.activated = function(app)
 local winner = Logic.Query["game-result"](app.game) local other
 if (winner == "player") then
 other = {"You captured all cards"} elseif (winner == "enemy") then
 other = {"The opposition captured a K,Q,J or A"} else other = nil end
 app["ended-at"] = os.time() do end (app.components["game-report"]):update(winner, other)

 if (winner == "player") then app:save((os.time() .. "-win")) return app["update-statistics"](app) else return nil end end




 AppState.GameEnded.OnEvent.input["<LeftMouse>"] = function(app, _8_, pos) local _arg_9_ = _8_ local location = _arg_9_[1]
 Logger.info(location)
 if ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end


 AppState.Default.OnEvent.app["new-game"] = function(app) return app["setup-new-game"](app, app["game-config"], nil) end


 AppState.Default.OnEvent.app["restart-game"] = function(app) return app["setup-new-game"](app, app["game-config"], app.seed) end


 AppState.Default.OnEvent.app.replay = function(app, _11_) local _arg_12_ = _11_ local replay = _arg_12_["replay"] local _3fverify = _arg_12_["verify"] local state = _arg_12_["state"]
 if ((_G.type(replay) == "table") and (replay[1] == nil)) then return app["switch-state"](app, state) elseif ((_G.type(replay) == "table") and (nil ~= replay[1])) then local action = replay[1] local rest = {select(2, (table.unpack or _G.unpack)(replay))}


 if ((_G.type(action) == "table") and (action[1] == nil)) then return app["queue-event"](app, "app", "replay", {replay = rest, verify = _3fverify, state = state}) elseif (nil ~= action) then local action0 = action

 local function _13_(...) local _14_ = ... if ((_G.type(_14_) == "table") and (nil ~= _14_[1])) then local f_name = _14_[1] local args = {select(2, (table.unpack or _G.unpack)(_14_))} local function _15_(...) local _16_ = ... if (nil ~= _16_) then local f = _16_ local function _17_(...) local _18_, _19_ = ... if ((nil ~= _18_) and (nil ~= _19_)) then local next_game = _18_ local moves = _19_



 if true then app["update-game"](app, next_game, action0)


 return AppState.Default.OnEvent.app.replay(app, {replay = rest, verify = _3fverify, state = state}) else



 local after local function _20_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "noop") app["queue-event"](app, "app", "replay", {replay = rest, verify = _3fverify, state = state}) return app["update-game"](app, next_game, action0) end after = _20_




 local timeline = build_event_animation(moves, after, {["duration-ms"] = 120}) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end else local __85_auto = _18_ return ... end end return _17_(f(app.game, table.unpack(args))) else local __85_auto = _16_ return ... end end return _15_(Logic.Action[f_name]) else local __85_auto = _14_ return ... end end return _13_(action0) else return nil end else return nil end end


 AppState.DealPhase.activated = function(app)
 local next_game, moves = Logic.Action["both-draw"](app.game) local after
 local function _27_() app["update-game"](app, next_game, {"both-draw"}) return app["switch-state"](app, AppState.DiscardPhase) end after = _27_


 local timeline = build_event_animation(app, moves, after) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end


 AppState.EnemyPhase.activated = function(app) do end (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["discard-label"], "set-visible", false) do end (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["capture-label"], "set-visible", false) do end (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["sacrifice-label"], "set-visible", false) do end (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["yield-label"], "set-visible", false)




 local next_game, moves = Logic.Action["enemy-draw"](app.game) local after
 local function _28_() app["update-game"](app, next_game, {"enemy-draw"}) return app["switch-state"](app, AppState.DiscardPhase) end after = _28_


 local timeline = build_event_animation(app, moves, after) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end


 AppState.DiscardPhase.activated = function(app)
 app.state.context.player = {false, false, false, false} do end (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["discard-label"], "set-visible", true) do end (app.components["discard-label"]):update(true, 0)


 local c do local s = 0 for i = 1, 4 do local function _29_() if app.game.player.hand[i] then return 1 else return 0 end end s = (s + _29_()) end c = s end
 if (0 == c) then return app["switch-state"](app, AppState.DrawPhase) else return nil end end


 AppState.DiscardPhase.deactivated = function(app) return (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["discard-label"], "set-visible", false) end


 AppState.DiscardPhase.OnEvent.input["<LeftMouse>"] = function(app, _31_, pos) local _arg_32_ = _31_ local location = _arg_32_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) elseif ((_G.type(location) == "table") and (location[1] == "player") and (location[2] == "hand") and (nil ~= location[3]) and (location[4] == nil)) then local n = location[3]



 app.state.context.player[n] = not app.state.context.player[n] return nil elseif ((_G.type(location) == "table") and (location[1] == "player") and (location[2] == "discard")) then
 local indexes = enabled_indexes(app.state.context.player)
 local next_game, moves = Logic.Action.discard(app.game, indexes) local after
 local function _33_() app["update-game"](app, next_game, {"discard", indexes}) return app["switch-state"](app, AppState.DrawPhase) end after = _33_


 local timeline = build_event_animation(app, moves, after) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) else return nil end end


 AppState.DrawPhase.activated = function(app)
 local next_game, moves = Logic.Action["player-draw"](app.game) local after
 local function _35_() app["update-game"](app, next_game, {"player-draw"}) return app["switch-state"](app, AppState.CapturePhase) end after = _35_


 local timeline = build_event_animation(app, moves, after) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end


 AppState.CapturePhase.activated = function(app)
 app.state.context = {player = {false, false, false, false}, enemy = {false, false, false, false}} do end (app.components["discard-label"]):update(false) do end (app.components["capture-label"]):update(false) do end (app.components["sacrifice-label"]):update(false) do end (app.components["yield-label"]):update(false) do end (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["capture-label"], "set-visible", true) do end (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["sacrifice-label"], "set-visible", true) return (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["yield-label"], "set-visible", true) end









 AppState.CapturePhase.deactivated = function(app) do end (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["capture-label"], "set-visible", false) do end (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["sacrifice-label"], "set-visible", false) return (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["yield-label"], "set-visible", false) end




 AppState.CapturePhase.OnEvent.input["<LeftMouse>"] = function(app, _36_, pos) local _arg_37_ = _36_ local location = _arg_37_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) elseif ((_G.type(location) == "table") and (location[1] == "player") and (location[2] == "hand") and (nil ~= location[3])) then local n = location[3]

 app.state.context.player[n] = not app.state.context.player[n] elseif ((_G.type(location) == "table") and (location[1] == "enemy") and (location[2] == "hand") and (nil ~= location[3])) then local n = location[3]
 for i, _ in ipairs(app.state.context.enemy) do
 app.state.context.enemy[i] = ((n == i) and not app.state.context.enemy[i]) end else end
 if (AppState.CapturePhase == app.state.module) then
 local player_indexes = enabled_indexes(app.state.context.player)
 local _let_39_ = enabled_indexes(app.state.context.enemy) local enemy_index = _let_39_[1] do end (app.components["yield-label"]):update(false) do end (app.components["sacrifice-label"]):update(false) do end (app.components["capture-label"]):update(false)



 if (enemy_index and (0 < #player_indexes)) then do end (app.components["yield-label"]):update(((1 == enemy_index) and not (nil == Logic.Action.yield(app.game, player_indexes)))) do end (app.components["sacrifice-label"]):update(not (nil == Logic.Action.sacrifice(app.game, player_indexes, enemy_index))) do end (app.components["capture-label"]):update(not (nil == Logic.Action.capture(app.game, player_indexes, enemy_index)))







 local op if ((_G.type(location) == "table") and (location[1] == "player") and (location[2] == "discard")) then
 op = {"capture", player_indexes, enemy_index} elseif ((_G.type(location) == "table") and (location[1] == "enemy") and (location[2] == "discard")) then
 op = {"yield", player_indexes} elseif ((_G.type(location) == "table") and (location[1] == "enemy") and (location[2] == "draw")) then
 op = {"sacrifice", player_indexes, enemy_index} else op = nil end
 if ((_G.type(op) == "table") and (nil ~= op[1])) then local f = op[1] local rest = {select(2, (table.unpack or _G.unpack)(op))}
 local function _41_(...) local _42_, _43_ = ... if ((nil ~= _42_) and (nil ~= _43_)) then local next_game = _42_ local moves = _43_

 local after local function _44_() app["update-game"](app, next_game, op) app["queue-event"](app, "app", "noop") return app["switch-state"](app, AppState.EnemyPhase) end after = _44_




 local timeline = build_event_animation(app, moves, after) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_42_ == nil) and (nil ~= _43_)) then local err = _43_ return app:notify(err) else return nil end end return _41_(Logic.Action[f](app.game, table.unpack(rest))) else return nil end else return nil end else return nil end end




 local function tick_with_picked_cards(app)
 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card)

 if ((_G.type(location) == "table") and (nil ~= location[1]) and (location[2] == "hand") and (nil ~= location[3])) then local actor = location[1] local n = location[3]
 local _let_49_ = app["location->position"](app, {actor, "hand", n}) local row = _let_49_["row"] local col = _let_49_["col"] local z = _let_49_["z"] local mod
 if (actor == "player") then mod = -1 elseif (actor == "enemy") then mod = 1 else mod = nil end
 local _52_ do local t_51_ = app.state.context if (nil ~= t_51_) then t_51_ = t_51_[actor] else end if (nil ~= t_51_) then t_51_ = t_51_[n] else end _52_ = t_51_ end if _52_ then comp["set-position"](comp, {row = (row + mod), col = col, z = z}) else end else end end return nil end


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

 local function _58_() return app["switch-state"](app, AppState.DealPhase) end vim.defer_fn(_58_, 300) return app:render() end


 M["setup-new-game"] = function(app, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/card-capture/app.fnl:268") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/card-capture/app.fnl:268") app["new-game"](app, Logic.build, game_config, _3fseed) app["build-components"](app) app["switch-state"](app, AppState.Default)



 return app end

 local function update_card_counts(app)
 app.components["card-counts"].player.draw(#app.game.player.draw)
 app.components["card-counts"].player.discard(#app.game.player.discard)
 app.components["card-counts"].enemy.draw(#app.game.enemy.draw)
 return app.components["card-counts"].enemy.discard(#app.game.enemy.discard) end

 M["build-components"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/card-capture/app.fnl:280")
 local function build_label(text, position)
 local _let_59_ = position local row = _let_59_["row"] local col = _let_59_["col"] local z = _let_59_["z"]

 local function _60_(self, enabled)
 local hl if enabled then hl = "@playtime.ui.on" else hl = "@playtime.ui.off" end return self["set-content"](self, {{{text, hl}}}) end return Component["set-content"](Component["set-size"](Component["set-position"](Component.build(_60_), position), {width = #text, height = 1}), {{{text, "@playtime.ui.off"}}}) end





 local function build_card_count(position, z)
 local _let_62_ = position local row = _let_62_["row"] local col = _let_62_["col"]

 local function _63_(self, count)
 local text = tostring(count) local col0
 do local _64_ = #text if (_64_ == 1) then
 col0 = (col + 5) elseif (_64_ == 2) then
 col0 = (col + 4) else col0 = nil end end self["set-position"](self, {row = (row + 4), col = col0, z = z}) self["set-size"](self, {width = #text, height = 1}) return self["set-content"](self, {{{text, "@playtime.ui.off"}}}) end return Component.build(_63_):update(0) end





 local card_card_components do local tbl_14_auto = {} for location, card in Logic["iter-cards"](app.game) do local k_15_auto, v_16_auto = nil, nil
 do local comp local function _66_(...) return app["location->position"](app, ...) end comp = CardComponents.card(_66_, location, card, app["card-style"])



 k_15_auto, v_16_auto = card.id, comp end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end card_card_components = tbl_14_auto end
 local card_counts = {player = {draw = build_card_count(app["location->position"](app, {"player", "draw", 0}), app["z-index-for-layer"](app, "label")), discard = build_card_count(app["location->position"](app, {"player", "discard", 0}), app["z-index-for-layer"](app, "label"))}, enemy = {draw = build_card_count(app["location->position"](app, {"enemy", "draw", 0}), app["z-index-for-layer"](app, "label")), discard = build_card_count(app["location->position"](app, {"enemy", "discard", 0}), app["z-index-for-layer"](app, "label"))}}







 local discard_label = build_label("discard", app["location->position"](app, {"label", "discard"}))
 local yield_label = build_label("yield", app["location->position"](app, {"label", "yield"}))
 local sacrifice_label = build_label("sacrifice", app["location->position"](app, {"label", "sacrifice"}))
 local capture_label = build_label("capture", app["location->position"](app, {"label", "capture"}))
 local menubar = CommonComponents.menubar({{"Card Capture", {"file"}, {{"", nil}, {"New Game", {"new-game"}}, {"Restart Game", {"restart-game"}}, {"", nil}, {"Undo", {"undo"}}, {"", nil}, {"Save current game", {"save"}}, {"Load last save", {"load"}}, {"", nil}, {"Quit", {"quit"}}, {"", nil}, {string.format("Seed: %s", app.seed), nil}}}}, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar")}) local empty_fields














 do local base = {} for _, _68_ in ipairs({{"hand", 4}, {"draw", 1}, {"discard", 1}}) do local _each_69_ = _68_ local field = _each_69_[1] local count = _each_69_[2]

 for _0, actor in ipairs({"player", "enemy"}) do
 local tbl_17_auto = base for i = 1, count do local val_18_auto
 local function _70_(...) return table.set(app["location->position"](app, ...), "z", app["z-index-for-layer"](app, "base")) end val_18_auto = CardComponents.slot(_70_, {actor, field, i, 0}, app["card-style"]) table.insert(tbl_17_auto, val_18_auto) end end



 base = base end empty_fields = base end
 local game_report = CommonComponents["game-report"](app.view.width, app.view.height, app["z-index-for-layer"](app, "report"), {{"player", "Won"}, {"enemy", "Lost"}})





 table.merge(app.components, {["empty-fields"] = empty_fields, menubar = menubar, ["game-report"] = game_report, ["card-counts"] = card_counts, ["yield-label"] = yield_label, ["discard-label"] = discard_label, ["sacrifice-label"] = sacrifice_label, ["capture-label"] = capture_label})




 app["card-id->components"] = card_card_components
 app.components.cards = table.values(card_card_components)
 update_card_counts(app)
 return app end

 M.render = function(app) do end (app.view):render({app.components["empty-fields"], app.components.cards, {app.components["card-counts"].player.discard, app.components["card-counts"].player.draw, app.components["card-counts"].enemy.discard, app.components["card-counts"].enemy.draw}, {app.components["yield-label"], app.components["discard-label"], app.components["sacrifice-label"], app.components["capture-label"]}, {app.components["game-report"]}, {app.components.menubar, app.components.cheating}})














 return app end

 M.tick = function(app)
 local now = uv.now() app["process-next-event"](app)

 do local _71_ = app.state.module.tick if (nil ~= _71_) then local f = _71_
 f(app) else local _ = _71_
 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card) end end end

 update_card_counts(app)


 if (not ((AppState.GameEnded == app.state.module) or (App.State.DefaultInMenuState == app.state.module)) and Logic.Query["game-ended?"](app.game)) then app["switch-state"](app, AppState.GameEnded) else end return app["request-render"](app) end





 M.save = function(app, filename) _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/game/card-capture/app.fnl:396") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/card-capture/app.fnl:396")





 local _76_ do local _74_, _75_ = app.state.module if (_74_ == AppState.DiscardPhase) then _76_ = "discard" elseif (_74_ == AppState.CapturePhase) then _76_ = "capture" elseif (_74_ == AppState.GameEnded) then _76_ = "ended" else local _3fmod = _74_



 _76_ = error(Error("unable to save turn for #{s}", {s = _3fmod})) end end
 local _82_ do local tbl_19_auto = {} local i_20_auto = 0 for _, _83_ in ipairs(app["game-history"]) do local _each_84_ = _83_ local _state = _each_84_[1] local action = _each_84_[2]
 local val_21_auto = action if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end _82_ = tbl_19_auto end return App.save(app, filename, {version = 1, ["app-id"] = app["app-id"], seed = app.seed, config = app["game-config"], latest = app.game, turn = _76_, replay = _82_}) end

 M.load = function(app, filename) _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/game/card-capture/app.fnl:410") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/card-capture/app.fnl:410")
 local function _86_(...) local _87_ = ... if (nil ~= _87_) then local data = _87_

 local _let_88_ = data local config = _let_88_["config"] local seed = _let_88_["seed"] local latest = _let_88_["latest"] local replay = _let_88_["replay"] local turn = _let_88_["turn"] local state
 if (turn == "discard") then
 state = AppState.DiscardPhase elseif (turn == "capture") then
 state = AppState.CapturePhase elseif (turn == "ended") then
 state = AppState.GameEnded else local _ = turn
 state = error(Error("unknown turn: #{turn}", {turn = turn})) end app["setup-new-game"](app, config, seed) return app["queue-event"](app, "app", "replay", {replay = replay, verify = latest, state = state}) else local __85_auto = _87_ return ... end end return _86_(App.load(app, filename)) end



 M["update-statistics"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/card-capture/app.fnl:422")
 local function update(d)
 local data = table.merge({version = 1, wins = 0, games = {}}, d)
 data.wins = (data.wins + 1)
 data.games = table.insert(data.games, {seed = app.seed, time = ((app["ended-at"] or app["started-at"]) - app["started-at"])})


 return data end
 return App["update-statistics"](app, update) end

 return M