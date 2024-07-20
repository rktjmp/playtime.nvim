
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Error = require("playtime.error")

 local Animate = require("playtime.animate")
 local Component = require("playtime.component")
 local CommonComponents = require("playtime.common.components")
 local CardComponents = require("playtime.common.card.components")
 local CardUtils = require("playtime.common.card.utils")
 local App = require("playtime.app")
 local Window = require("playtime.app.window")

 local api = vim["api"]
 local uv = (vim.loop or vim.uv)
 local M = setmetatable({}, {__index = App})
 local Logic = require("playtime.game.optrita-lines.logic")

 local AppState = {}

 AppState.Default = App.State.build("Default", {delegate = {app = App.State.DefaultAppState}})
 AppState.NewRound = App.State.build("NewRound", {delegate = {app = AppState.Default}})
 AppState.PickTrump = App.State.build("PickTrump", {delegate = {app = AppState.Default}})
 AppState.PickCard = App.State.build("PickCard", {delegate = {app = AppState.Default}})
 AppState.PlayTrick = App.State.build("PlayTrick", {delegate = {app = AppState.Default}})
 AppState.ResolveTrick = App.State.build("ResolveTrick", {delegate = {app = AppState.Default}})
 AppState.GameEnded = App.State.build("GameEnded", {delegate = {app = AppState.Default}})





 AppState.Default.OnEvent.input["<LeftMouse>"] = function(app, _2_, pos) local click_location = _2_[1] local rest = (function (t, k, e) local mt = getmetatable(t) if 'table' == type(mt) and mt.__fennelrest then return mt.__fennelrest(t, k) elseif e then local rest = {} for k, v in pairs(t) do if not e[k] then rest[k] = v end end return rest else return {(table.unpack or unpack)(t, k)} end end)(_2_, 2)
 if ((_G.type(click_location) == "table") and (click_location[1] == "menu") and (nil ~= click_location[2]) and (click_location[3] == nil)) then local idx = click_location[2] local menu_item = click_location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end



 AppState.Default.OnEvent.app["new-game"] = function(app) app["setup-new-game"](app, app["game-config"], nil)

 local function _4_() return app["switch-state"](app, AppState.NewRound) end return vim.defer_fn(_4_, 300) end

 AppState.Default.OnEvent.app["restart-game"] = function(app) app["setup-new-game"](app, app["game-config"], app.seed)

 local function _5_() return app["switch-state"](app, AppState.NewRound) end return vim.defer_fn(_5_, 300) end

 AppState.Default.OnEvent.app.replay = function(app, _6_) local replay = _6_["replay"] local _3fverify = _6_["verify"] local _3fstate = _6_["state"]
 if ((_G.type(replay) == "table") and (replay[1] == nil)) then
 return app elseif ((_G.type(replay) == "table") and (nil ~= replay[1])) then local action = replay[1] local rest = {select(2, (table.unpack or _G.unpack)(replay))}
 if ((_G.type(action) == "table") and (action[1] == nil)) then return app["queue-event"](app, "app", "replay", {replay = rest, verify = _3fverify}) elseif (nil ~= action) then local action0 = action

 local function _7_(...) local _8_, _9_ = ... if ((_G.type(_8_) == "table") and (nil ~= _8_[1])) then local f_name = _8_[1] local args = {select(2, (table.unpack or _G.unpack)(_8_))} local function _10_(...) local _11_, _12_ = ... if (nil ~= _11_) then local f = _11_ local function _13_(...) local _14_, _15_ = ... if ((nil ~= _14_) and (nil ~= _15_)) then local next_game = _14_ local events = _15_



 local after local function _16_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "replay", {replay = rest, verify = _3fverify}) return app["update-game"](app, next_game, action0) end after = _16_ local timeline = app["build-event-animation"](app, events, after, {["duration-ms"] = 80}) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_14_ == nil) and (nil ~= _15_)) then local err = _15_









 return error(err) else return nil end end return _13_(f(app.game, table.unpack(args))) elseif ((_11_ == nil) and (nil ~= _12_)) then local err = _12_ return error(err) else return nil end end return _10_(Logic.Action[f_name]) elseif ((_8_ == nil) and (nil ~= _9_)) then local err = _9_ return error(err) else return nil end end return _7_(action0) else return nil end else return nil end end

 AppState.GameEnded.activated = function(app)
 app["ended-at"] = os.time()
 local other = {string.fmt("Time: %ds", (app["ended-at"] - app["started-at"]))}
 local result = Logic.Query["game-result"](app.game) return app.components["game-report"]:update(result, other) end


 AppState.GameEnded.OnEvent.input["<LeftMouse>"] = function(app, _22_, pos) local location = _22_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu")) then
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end





 AppState.NewRound.activated = function(app)


 local next_game, events = Logic.Action["clear-round"](app.game) local after
 local function _24_() app["update-game"](app, next_game, {"clear-round"})

 local next_game0, events0 = Logic.Action["new-round"](app.game) local after0
 local function _25_() app["update-game"](app, next_game0, {"new-round"}) return app["switch-state"](app, AppState.PickTrump) end after0 = _25_ local timeline = app["build-event-animation"](app, events0, after0, {["duration-ms"] = 300}, #next_game0.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end after = _24_ local timeline = app["build-event-animation"](app, events, after, {["duration-ms"] = 180}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end











 AppState.PickTrump.activated = function(app) return app.components["pick-trump-label"]["set-visible"](app.components["pick-trump-label"], true) end


 AppState.PickTrump.deactivated = function(app) return app.components["pick-trump-label"]["set-visible"](app.components["pick-trump-label"], false) end


 AppState.PickTrump.OnEvent.input["<LeftMouse>"] = function(app, _26_, pos) local location = _26_[1]
 app.state.context.hover = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 app.state.context.hover = {"hand", n} return nil elseif ((_G.type(location) == "table") and (location[1] == "menu")) then
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end

 AppState.PickTrump.OnEvent.input["<LeftDrag>"] = function(app, _28_, pos) local location = _28_[1]
 app.state.context.hover = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 app.state.context.hover = {"hand", n} return nil else return nil end end

 AppState.PickTrump.OnEvent.input["<LeftRelease>"] = function(app, _30_, pos) local location = _30_[1]
 app.state.context.hover = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 local function _31_(...) local _32_, _33_ = ... if ((nil ~= _32_) and (nil ~= _33_)) then local next_game = _32_ local moves = _33_

 local after local function _34_() app["update-game"](app, next_game, {"pick-trump", n}) return app["switch-state"](app, AppState.PickCard) end after = _34_ local timeline = app["build-event-animation"](app, moves, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_32_ == nil) and (nil ~= _33_)) then local e = _33_ return app:notify(e) else return nil end end return _31_(Logic.Action["pick-trump"](app.game, n)) else return nil end end











 AppState.PickCard.activated = function(app)
 if Logic.Query["round-ended?"](app.game) then
 do local next_game = Logic.Action["score-round"](app.game) app["update-game"](app, next_game, {"score-round"}) end

 if Logic.Query["game-ended?"](app.game) then return app["switch-state"](app, AppState.GameEnded) else return app["switch-state"](app, AppState.NewRound) end else return nil end end



 AppState.PickCard.OnEvent.input["<LeftMouse>"] = function(app, _39_, pos) local location = _39_[1]
 local _40_, _41_ = location if ((_G.type(_40_) == "table") and (_40_[1] == "hand") and (nil ~= _40_[2])) then local n = _40_[2] return app["switch-state"](app, AppState.PlayTrick, {hand = {"hand", n}}) elseif (((_G.type(_40_) == "table") and (_40_[1] == "menu")) and true) then local _ = _41_

 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end




 AppState.PlayTrick.OnEvent.input["<LeftMouse>"] = function(app, _43_, pos) local location = _43_[1]
 local _44_, _45_ = location, app.state.context.hand if (((_G.type(_44_) == "table") and (_44_[1] == "hand") and (nil ~= _44_[2])) and ((_G.type(_45_) == "table") and (_45_[1] == "hand") and (_44_[2] == _45_[2]))) then local n = _44_[2]

 app.state.context["lifting-from"] = nil return nil elseif (((_G.type(_44_) == "table") and (_44_[1] == "menu")) and true) then local _ = _45_
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end

 AppState.PlayTrick.OnEvent.input["<LeftDrag>"] = function(app, _47_, position) local location = _47_[1]
 if not app.state.context["drag-start"] then
 local _48_, _49_ = location, app.state.context.hand if (((_G.type(_48_) == "table") and (_48_[1] == "hand") and (nil ~= _48_[2])) and ((_G.type(_49_) == "table") and (_49_[1] == "hand") and (_48_[2] == _49_[2]))) then local n = _48_[2]
 app.state.context["drag-start"] = location else end else end
 local _52_, _53_ = app.state.context.hand, app.state.context["drag-start"] if (((_G.type(_52_) == "table") and (_52_[1] == "hand") and (nil ~= _52_[2])) and ((_G.type(_53_) == "table") and (_53_[1] == "hand") and (_52_[2] == _53_[2]))) then local n = _52_[2]
 app.state.context["drag-position"] = position return nil else return nil end end

 AppState.PlayTrick.OnEvent.input["<LeftRelease>"] = function(app, _55_, pos) local _holding = _55_[1] local location = _55_[2]
 local _hand = app.state.context.hand[1] local hand_n = app.state.context.hand[2]
 if ((_G.type(location) == "table") and (location[1] == "play")) then
 local function _56_(...) local _57_, _58_ = ... if ((nil ~= _57_) and (nil ~= _58_)) then local next_game = _57_ local events = _58_

 local events0 do local t, memo = {}, {"hand", hand_n} for _, e in ipairs(events) do
 if ((_G.type(e) == "table") and (e[1] == "face-up") and ((_G.type(e[2]) == "table") and (e[2][1] == "grid") and (nil ~= e[2][2]) and (nil ~= e[2][3]))) then local row = e[2][2] local col = e[2][3]

 t, memo = table.join(t, {{"move", memo, {"grid-comp", row, col}}, e, {"wait", 300}}), {"grid-comp", row, col} elseif ((_G.type(e) == "table") and (e[1] == "move") and true and ((_G.type(e[3]) == "table") and (e[3][1] == "trick"))) then local _0 = e[2]



 t, memo = table.join(t, {{"wait", 300}, e}), memo else local _0 = e
 t, memo = table.insert(t, e), memo end end events0 = t, memo end local after
 local function _60_() app["update-game"](app, next_game, {"play-trick", hand_n, location})

 local _61_ do local winner_3f = false for _, e in ipairs(events0) do if winner_3f then break end
 if ((_G.type(e) == "table") and (e[1] == "move") and true and ((_G.type(e[3]) == "table") and (e[3][1] == "trick"))) then local _0 = e[2] winner_3f = true else winner_3f = nil end end _61_ = winner_3f end if _61_ then return app["switch-state"](app, AppState.PickCard) else

 local choices if ((_G.type(location) == "table") and (location[1] == "play") and (location[2] == "top") and (nil ~= location[3])) then local col = location[3]
 local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 6 do local val_23_auto = {"grid", i, col} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end choices = tbl_21_auto elseif ((_G.type(location) == "table") and (location[1] == "play") and (location[2] == "bottom") and (nil ~= location[3])) then local col = location[3]
 local tbl_21_auto = {} local i_22_auto = 0 for i = 6, 1, -1 do local val_23_auto = {"grid", i, col} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end choices = tbl_21_auto elseif ((_G.type(location) == "table") and (location[1] == "play") and (location[2] == "left") and (nil ~= location[3])) then local row = location[3]
 local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 6 do local val_23_auto = {"grid", row, i} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end choices = tbl_21_auto elseif ((_G.type(location) == "table") and (location[1] == "play") and (location[2] == "right") and (nil ~= location[3])) then local row = location[3]
 local tbl_21_auto = {} local i_22_auto = 0 for i = 6, 1, -1 do local val_23_auto = {"grid", row, i} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end choices = tbl_21_auto else choices = nil end return app["switch-state"](app, AppState.ResolveTrick, {hand = hand_n, ["card-pos"] = pos, choices = choices}) end end after = _60_ local timeline = app["build-event-animation"](app, events0, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_57_ == nil) and (nil ~= _58_)) then local e = _58_ app:notify(e) return app["switch-state"](app, AppState.PickCard) else return nil end end return _56_(Logic.Action["play-trick"](app.game, hand_n, location)) else local _ = location return app["switch-state"](app, AppState.PickCard) end end











 AppState.PlayTrick.OnEvent.input["<RightMouse>"] = function(app, _71_, pos) local location = _71_[1] return app["switch-state"](app, AppState.PickCard) end


 AppState.PlayTrick.tick = function(app)
 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card)

 local _72_, _73_ = location, app.state.context if (((_G.type(_72_) == "table") and (_72_[1] == "hand") and (nil ~= _72_[2])) and ((_G.type(_73_) == "table") and ((_G.type(_73_.hand) == "table") and (_73_.hand[1] == "hand") and (_72_[2] == _73_.hand[2])) and ((_G.type(_73_["drag-position"]) == "table") and (nil ~= _73_["drag-position"].row) and (nil ~= _73_["drag-position"].col)))) then local n = _72_[2] local row = _73_["drag-position"].row local col = _73_["drag-position"].col comp["set-position"](comp, {row = (row - 2), col = (col - 2), z = app["z-index-for-layer"](app, "lift")}) else end end return nil end









 AppState.ResolveTrick.activated = function(app) return app.components["pick-resolve-label"]["set-visible"](app.components["pick-resolve-label"], true) end


 AppState.ResolveTrick.deactivated = function(app) return app.components["pick-resolve-label"]["set-visible"](app.components["pick-resolve-label"], false) end


 AppState.ResolveTrick["valid-choice?"] = function(app, location) local b = false
 for _, _75_ in ipairs(app.state.context.choices) do local _grid = _75_[1] local row = _75_[2] local col = _75_[3] if b then break end
 if ((_G.type(location) == "table") and (location[1] == "grid") and (location[2] == row) and (location[3] == col)) then b = true else b = nil end end return b end


 AppState.ResolveTrick.tick = function(app)
 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card)

 local _77_, _78_ = location, app.state.context if (((_G.type(_77_) == "table") and (_77_[1] == "hand") and (nil ~= _77_[2])) and ((_G.type(_78_) == "table") and (_77_[2] == _78_.hand) and ((_G.type(_78_["card-pos"]) == "table") and (nil ~= _78_["card-pos"].row) and (nil ~= _78_["card-pos"].col)))) then local n = _77_[2] local row = _78_["card-pos"].row local col = _78_["card-pos"].col comp["set-position"](comp, {row = (row - 2), col = (col - 2), z = app["z-index-for-layer"](app, "lift")}) elseif (((_G.type(_77_) == "table") and (_77_[1] == "grid") and (nil ~= _77_[2]) and (nil ~= _77_[3])) and ((_G.type(_78_) == "table") and ((_G.type(_78_.hover) == "table") and (_78_.hover[1] == "grid") and (_77_[2] == _78_.hover[2]) and (_77_[3] == _78_.hover[3])))) then local row = _77_[2] local col = _77_[3]





 local _let_79_ = app["location->position"](app, {"grid", row, col}) local row0 = _let_79_["row"] local col0 = _let_79_["col"] comp["set-position"](comp, {row = (row0 - 1), col = col0, z = app["z-index-for-layer"](app, "lift")}) else end end return nil end




 AppState.ResolveTrick.OnEvent.input["<LeftMouse>"] = function(app, _81_, pos) local location = _81_[1]
 local and_82_ = ((_G.type(location) == "table") and (location[1] == "grid")) if and_82_ then and_82_ = AppState.ResolveTrick["valid-choice?"](app, location) end if and_82_ then

 app.state.context.hover = location return nil else local _ = location
 app.state.context.hover = nil return nil end end

 AppState.ResolveTrick.OnEvent.input["<LeftDrag>"] = function(app, _85_, pos) local location = _85_[1]
 local and_86_ = ((_G.type(location) == "table") and (location[1] == "grid")) if and_86_ then and_86_ = AppState.ResolveTrick["valid-choice?"](app, location) end if and_86_ then

 app.state.context.hover = location return nil else local _ = location
 app.state.context.hover = nil return nil end end

 AppState.ResolveTrick.OnEvent.input["<LeftRelease>"] = function(app, _89_, pos) local location = _89_[1]
 local and_90_ = ((_G.type(location) == "table") and (location[1] == "grid")) if and_90_ then and_90_ = AppState.ResolveTrick["valid-choice?"](app, location) end if and_90_ then

 local function _92_(...) local _93_, _94_ = ... if (nil ~= _93_) then local hand_n = _93_ local function _95_(...) local _96_, _97_ = ... if ((nil ~= _96_) and (nil ~= _97_)) then local next_game = _96_ local events = _97_


 local after local function _98_() app["update-game"](app, next_game, {"force-trick", hand_n, location}) return app["switch-state"](app, AppState.PickCard) end after = _98_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_96_ == nil) and (nil ~= _97_)) then local e = _97_ return app:notify(e) else return nil end end return _95_(Logic.Action["force-trick"](app.game, hand_n, location)) elseif ((_93_ == nil) and (nil ~= _94_)) then local e = _94_ return app:notify(e) else return nil end end return _92_(app.state.context.hand) elseif ((_G.type(location) == "table") and (location[1] == "menu")) then






 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end






 M["build-event-animation"] = function(app, events, after, _3fopts, _3fhand_length)
 local function location__3eposition(_proxy, location)
 if (AppState.PlayTrick == app.state.module) then
 local _let_102_ = app.state.context["hand"] local _ = _let_102_[1] local hand_n = _let_102_[2] local _let_103_ = app.state.context["drag-position"] local row = _let_103_["row"] local col = _let_103_["col"]
 if ((_G.type(location) == "table") and (location[1] == "hand") and (location[2] == hand_n)) then
 return {row = (row - 2), col = (col - 2), z = app["z-index-for-layer"](app, "lift")} else local _0 = location return app["location->position"](app, location, _3fhand_length) end else return app["location->position"](app, location, _3fhand_length) end end



 if _3fhand_length then
 local proxy = setmetatable({["location->position"] = location__3eposition}, {__index = app})

 return CardUtils["build-event-animation"](proxy, events, after, _3fopts) else
 return CardUtils["build-event-animation"](app, events, after, _3fopts) end end

 M["location->position"] = function(app, location, _3fhand_length)
 local card_height = app["card-style"]["height"] local card_width = app["card-style"]["width"]
 local grid = {row = card_height, col = (1 + (3 * card_width))}

 local draw = {row = (grid.row + 1 + (7 * (card_height - 1))), col = (grid.col - 3 - (1 * card_width))}


 local hand = {row = draw.row, col = (draw.col + 3 + (4 * card_width) + -3)}

 do local _107_ = (_3fhand_length or #app.game.hand) if (_107_ == 0) then elseif (_107_ == 1) then elseif (nil ~= _107_) then local n = _107_


 hand.col = (hand.col - (2 * (n - 1))) else end end
 if ((_G.type(location) == "table") and (location[1] == "label") and (location[2] == "score") and (location[3] == "grid")) then
 return {row = 2, col = (grid.col + (card_width * 7)), z = app["z-index-for-layer"](app, "base")} elseif ((_G.type(location) == "table") and (location[1] == "label") and (location[2] == "score") and (location[3] == "player")) then


 return {row = 2, col = 3, z = app["z-index-for-layer"](app, "base")} elseif ((_G.type(location) == "table") and (location[1] == "draw") and (nil ~= location[2])) then local card_n = location[2]


 return {row = draw.row, col = draw.col, z = app["z-index-for-layer"](app, "cards", card_n)} elseif ((_G.type(location) == "table") and (location[1] == "trick") and (nil ~= location[2]) and (nil ~= location[3]) and (nil ~= location[4])) then local who = location[2] local n = location[3] local card_n = location[4]


 local col if (who == "grid") then
 col = (grid.col + (7 * card_width) + (3 * (card_n - 1))) elseif (who == "player") then
 col = (grid.col + 3 + (-3 * card_width) + (3 * (card_n - 1))) else col = nil end
 return {row = (3 + ((card_height - 1) * (n - 1))), col = col, z = ((2 * n) + card_n)} elseif ((_G.type(location) == "table") and (location[1] == "trump") and true) then local _ = location[2]


 return {row = draw.row, col = (draw.col + 0), z = app["z-index-for-layer"](app, "cards", 54)} elseif ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]


 return {row = hand.row, col = (hand.col + (4 * (n - 1))), z = app["z-index-for-layer"](app, "hand", n)} elseif ((_G.type(location) == "table") and (location[1] == "grid") and (nil ~= location[2]) and (nil ~= location[3])) then local row = location[2] local col = location[3]


 return {row = (grid.row + ((card_height - 1) * (row - 1))), col = (grid.col + ((col - 1) * (card_width - 0))), z = app["z-index-for-layer"](app, "cards", (((row - 1) * 6) + col))} elseif ((_G.type(location) == "table") and (location[1] == "grid-comp") and (nil ~= location[2]) and (nil ~= location[3])) then local row = location[2] local col = location[3]


 return {row = (grid.row + 1 + ((card_height - 1) * (row - 1))), col = (grid.col + 3 + ((col - 1) * (card_width - 0))), z = app["z-index-for-layer"](app, "cards", (100 + (row * 6) + col))} elseif ((_G.type(location) == "table") and (location[1] == "play") and (location[2] == "left") and (nil ~= location[3])) then local row = location[3]


 return {row = (grid.row + ((card_height - 1) * (row - 1))), col = (grid.col - card_width), z = 1} elseif ((_G.type(location) == "table") and (location[1] == "play") and (location[2] == "right") and (nil ~= location[3])) then local row = location[3]


 return {row = (grid.row + ((card_height - 1) * (row - 1))), col = (grid.col + 1 + (6 * (card_width - 0))), z = 1} elseif ((_G.type(location) == "table") and (location[1] == "play") and (location[2] == "top") and (nil ~= location[3])) then local col = location[3]


 return {row = (grid.row - (card_height - 1)), col = (grid.col + ((col - 1) * card_width)), z = 1} elseif ((_G.type(location) == "table") and (location[1] == "play") and (location[2] == "bottom") and (nil ~= location[3])) then local col = location[3]


 return {row = (grid.row + 1 + ((card_height - 1) * 6)), col = (grid.col + ((col - 1) * card_width)), z = 1} else return nil end end



 M.start = function(app_config, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/optrita-lines/app.fnl:343") _G.assert((nil ~= app_config), "Missing argument app-config on fnl/playtime/game/optrita-lines/app.fnl:343")
 local app = setmetatable(App.build("Optrita Lines", "optrita-lines", app_config, game_config), {__index = M})




 local view = Window.open("optrita-lines", App["build-default-window-dispatch-options"](app), {width = 73, height = 31, ["window-position"] = app_config["window-position"], ["minimise-position"] = app_config["minimise-position"]})





 local _ = table.merge(app["z-layers"], {cards = 25, hand = 100, label = 100, lift = 200, animation = 200})
 app.view = view
 app["card-style"] = {width = 6, height = 4, colors = 4, stacking = "horizontal-left"} app["setup-new-game"](app, app["game-config"], _3fseed)

 local function _111_() return app["switch-state"](app, AppState.NewRound) end vim.defer_fn(_111_, 300) return app:render() end


 M["setup-new-game"] = function(app, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/optrita-lines/app.fnl:362") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/optrita-lines/app.fnl:362") app["new-game"](app, Logic.build, game_config, _3fseed) app["build-components"](app) app["switch-state"](app, AppState.Default)



 return app end

 M["build-components"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/optrita-lines/app.fnl:368")
 local function build_label(text, position)
 local row = position["row"] local col = position["col"] local z = position["z"]

 local function _112_(self, enabled)
 local hl if enabled then hl = "@playtime.ui.on" else hl = "@playtime.ui.on" end return self["set-content"](self, {{{text, hl}}}) end return Component["set-content"](Component["set-size"](Component["set-position"](Component.build(_112_), position), {width = #text, height = 1}), {{{text, "@playtime.ui.on"}}}) end





 local function build_score(text, limit, position)
 local row = position["row"] local col = position["col"] local z = position["z"]

 local function _114_(self, score)
 local text0 = string.format("%s: %d/%d", text, score, limit) self["set-content"](self, {{{text0, "@playtime.ui.on"}}}) return self["set-size"](self, {width = #text0, height = 1}) end return Component["set-position"](Component.build(_114_), position):update(0) end





 local function play_drop(side, position, tag)
 local row = position["row"] local col = position["col"] local z = position["z"] local color = "@playtime.ui.off" local content

 if (side == "left") then
 content = {{{"     ", color}}, {{"   \226\134\146 ", color}}, {{"     ", color}}, {{"     ", color}}} elseif (side == "right") then



 content = {{{"     ", color}}, {{"     ", color}}, {{"\226\134\144    ", color}}, {{"     ", color}}} elseif (side == "top") then



 content = {{{"      ", color}}, {{"      ", color}}, {{"      ", color}}, {{"  \226\134\147   ", color}}} elseif (side == "bottom") then



 content = {{{"  \226\134\145   ", color}}, {{"      ", color}}, {{"      ", color}}, {{"      ", color}}} else content = nil end



 local content0 = {{{"     ", color}}, {{"     ", color}}, {{"     ", color}}, {{"     ", color}}}




 local function _116_(self, enabled)
 local hl if enabled then hl = "@playtime.ui.on" else hl = "@playtime.ui.off" end return self["set-content"](self, content0) end return Component["set-content"](Component["set-size"](Component["set-position"](Component["set-tag"](Component.build(_116_), tag), position), {width = 5, height = 4}), content0) end






 local card_card_components do local tbl_16_auto = {} for location, card in Logic["iter-cards"](app.game) do local k_17_auto, v_18_auto = nil, nil
 do local comp local function _118_(...) return app["location->position"](app, ...) end comp = CardComponents.card(_118_, location, card, app["card-style"])



 k_17_auto, v_18_auto = card.id, comp end if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end card_card_components = tbl_16_auto end
 local menubar = CommonComponents.menubar({{"Optrita: Lines", {"file"}, {{"", nil}, {"New Game", {"new-game"}}, {"Restart Game", {"restart-game"}}, {"", nil}, {"Undo", {"undo"}}, {"", nil}, {"Quit", {"quit"}}, {"", nil}, {string.format("Seed: %s", app.seed), nil}}}}, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar")}) local pick_trump_label local tgt_120_ = build_label("Pick trump suit", {row = 24, col = 29, z = 100})














 pick_trump_label = (tgt_120_)["set-visible"](tgt_120_, false) local pick_resolve_label local tgt_121_ = build_label("Pick card to remove", {row = 24, col = 27, z = 100})

 pick_resolve_label = (tgt_121_)["set-visible"](tgt_121_, false)

 local game_report = CommonComponents["game-report"](app.view.width, app.view.height, app["z-index-for-layer"](app, "report"), {{"player", "The GRID has been vanquished"}, {"grid", "The GRID's reign of terror continues"}}) local droppers




 do local t = {} for i = 1, 6 do
 local tbl_19_auto = t for _, side in ipairs({"top", "bottom", "left", "right"}) do local val_20_auto local tgt_122_ = play_drop(side, app["location->position"](app, {"play", side, i}), {"play", side, i})
 val_20_auto = (tgt_122_)["set-visible"](tgt_122_, true) table.insert(tbl_19_auto, val_20_auto) end t = tbl_19_auto end droppers = t end local droppers_by_tag











 do local tbl_16_auto = {} for _, d in ipairs(droppers) do
 local k_17_auto, v_18_auto = d.tag, d if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end droppers_by_tag = tbl_16_auto end
 local grid_score = build_score("Grid", app.game.rules["score-limit"].grid, app["location->position"](app, {"label", "score", "grid"}))


 local player_score = build_score("Player", app.game.rules["score-limit"].player, app["location->position"](app, {"label", "score", "player"}))


 app["card-id->components"] = card_card_components
 app["droppers-by-tag"] = droppers_by_tag
 return table.merge(app.components, {droppers = droppers, menubar = menubar, ["game-report"] = game_report, ["pick-trump-label"] = pick_trump_label, ["pick-resolve-label"] = pick_resolve_label, ["grid-score"] = grid_score, ["player-score"] = player_score, cards = table.values(card_card_components)}) end








 M.render = function(app) app.view:render({app.components.droppers, app.components.cards, {app.components["pick-trump-label"], app.components["pick-resolve-label"], app.components["grid-score"], app.components["player-score"]}, {app.components["game-report"], app.components.menubar}})








 return app end

 M.tick = function(app)
 local now = uv.now() app["process-next-event"](app)

 do local _124_ = app.state.module.tick if (nil ~= _124_) then local f = _124_
 f(app) else local _ = _124_
 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card)

 local _125_ = app.state.context if ((_G.type(_125_) == "table") and ((_G.type(_125_.hover) == "table") and (_125_.hover[1] == "hand") and (nil ~= _125_.hover[2]))) then local n = _125_.hover[2]
 if ((_G.type(location) == "table") and (location[1] == "hand") and (location[2] == n)) then comp["set-position"](comp, {row = (comp.row - 1)}) else end else end end end end app.components["player-score"]:update(app.game.score.player) app.components["grid-score"]:update(app.game.score.grid) return app["request-render"](app) end










 M.save = function(app, filename) _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/game/optrita-lines/app.fnl:516") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/optrita-lines/app.fnl:516")





 local _129_ do local tbl_21_auto = {} local i_22_auto = 0 for _, _130_ in ipairs(app["game-history"]) do local _state = _130_[1] local action = _130_[2]
 local val_23_auto = action if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end _129_ = tbl_21_auto end return App.save(app, filename, {version = 1, ["app-id"] = app["app-id"], seed = app.seed, config = app["game-config"], latest = app.game, replay = _129_}) end

 M.load = function(app, filename) _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/game/optrita-lines/app.fnl:525") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/optrita-lines/app.fnl:525")
 local function _132_(...) local _133_ = ... if (nil ~= _133_) then local data = _133_

 local config = data["config"] local seed = data["seed"] local latest = data["latest"] local replay = data["replay"] app["setup-new-game"](app, config, seed) return app["queue-event"](app, "app", "replay", {replay = replay, verify = latest}) else local __85_auto = _133_ return ... end end return _132_(App.load(app, filename)) end



 return M