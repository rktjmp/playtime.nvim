
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

 local _local_2_ = vim local api = _local_2_["api"]
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





 AppState.Default.OnEvent.input["<LeftMouse>"] = function(app, _3_, pos) local _arg_4_ = _3_ local click_location = _arg_4_[1] local rest = (function (t, k, e) local mt = getmetatable(t) if 'table' == type(mt) and mt.__fennelrest then return mt.__fennelrest(t, k) elseif e then local rest = {} for k, v in pairs(t) do if not e[k] then rest[k] = v end end return rest else return {(table.unpack or unpack)(t, k)} end end)(_arg_4_, 2)
 if ((_G.type(click_location) == "table") and (click_location[1] == "menu") and (nil ~= click_location[2]) and (click_location[3] == nil)) then local idx = click_location[2] local menu_item = click_location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end



 AppState.Default.OnEvent.app["new-game"] = function(app) app["setup-new-game"](app, app["game-config"], nil)

 local function _6_() return app["switch-state"](app, AppState.NewRound) end return vim.defer_fn(_6_, 300) end

 AppState.Default.OnEvent.app["restart-game"] = function(app) app["setup-new-game"](app, app["game-config"], app.seed)

 local function _7_() return app["switch-state"](app, AppState.NewRound) end return vim.defer_fn(_7_, 300) end

 AppState.Default.OnEvent.app.replay = function(app, _8_) local _arg_9_ = _8_ local replay = _arg_9_["replay"] local _3fverify = _arg_9_["verify"] local _3fstate = _arg_9_["state"]
 if ((_G.type(replay) == "table") and (replay[1] == nil)) then
 return app elseif ((_G.type(replay) == "table") and (nil ~= replay[1])) then local action = replay[1] local rest = {select(2, (table.unpack or _G.unpack)(replay))}
 if ((_G.type(action) == "table") and (action[1] == nil)) then return app["queue-event"](app, "app", "replay", {replay = rest, verify = _3fverify}) elseif (nil ~= action) then local action0 = action

 local function _10_(...) local _11_, _12_ = ... if ((_G.type(_11_) == "table") and (nil ~= _11_[1])) then local f_name = _11_[1] local args = {select(2, (table.unpack or _G.unpack)(_11_))} local function _13_(...) local _14_, _15_ = ... if (nil ~= _14_) then local f = _14_ local function _16_(...) local _17_, _18_ = ... if ((nil ~= _17_) and (nil ~= _18_)) then local next_game = _17_ local events = _18_



 local after local function _19_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "replay", {replay = rest, verify = _3fverify}) return app["update-game"](app, next_game, action0) end after = _19_ local timeline = app["build-event-animation"](app, events, after, {["duration-ms"] = 80}) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_17_ == nil) and (nil ~= _18_)) then local err = _18_









 return error(err) else return nil end end return _16_(f(app.game, table.unpack(args))) elseif ((_14_ == nil) and (nil ~= _15_)) then local err = _15_ return error(err) else return nil end end return _13_(Logic.Action[f_name]) elseif ((_11_ == nil) and (nil ~= _12_)) then local err = _12_ return error(err) else return nil end end return _10_(action0) else return nil end else return nil end end

 AppState.GameEnded.activated = function(app)
 app["ended-at"] = os.time()
 local other = {string.fmt("Time: %ds", (app["ended-at"] - app["started-at"]))}
 local result = Logic.Query["game-result"](app.game) return (app.components["game-report"]):update(result, other) end


 AppState.GameEnded.OnEvent.input["<LeftMouse>"] = function(app, _25_, pos) local _arg_26_ = _25_ local location = _arg_26_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu")) then
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end





 AppState.NewRound.activated = function(app)


 local next_game, events = Logic.Action["clear-round"](app.game) local after
 local function _28_() app["update-game"](app, next_game, {"clear-round"})

 local next_game0, events0 = Logic.Action["new-round"](app.game) local after0
 local function _29_() app["update-game"](app, next_game0, {"new-round"}) return app["switch-state"](app, AppState.PickTrump) end after0 = _29_ local timeline = app["build-event-animation"](app, events0, after0, {["duration-ms"] = 300}, #next_game0.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end after = _28_ local timeline = app["build-event-animation"](app, events, after, {["duration-ms"] = 180}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end











 AppState.PickTrump.activated = function(app) return (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["pick-trump-label"], "set-visible", true) end


 AppState.PickTrump.deactivated = function(app) return (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["pick-trump-label"], "set-visible", false) end


 AppState.PickTrump.OnEvent.input["<LeftMouse>"] = function(app, _30_, pos) local _arg_31_ = _30_ local location = _arg_31_[1]
 app.state.context.hover = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 app.state.context.hover = {"hand", n} return nil elseif ((_G.type(location) == "table") and (location[1] == "menu")) then
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end

 AppState.PickTrump.OnEvent.input["<LeftDrag>"] = function(app, _33_, pos) local _arg_34_ = _33_ local location = _arg_34_[1]
 app.state.context.hover = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 app.state.context.hover = {"hand", n} return nil else return nil end end

 AppState.PickTrump.OnEvent.input["<LeftRelease>"] = function(app, _36_, pos) local _arg_37_ = _36_ local location = _arg_37_[1]
 app.state.context.hover = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 local function _38_(...) local _39_, _40_ = ... if ((nil ~= _39_) and (nil ~= _40_)) then local next_game = _39_ local moves = _40_

 local after local function _41_() app["update-game"](app, next_game, {"pick-trump", n}) return app["switch-state"](app, AppState.PickCard) end after = _41_ local timeline = app["build-event-animation"](app, moves, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_39_ == nil) and (nil ~= _40_)) then local e = _40_ return app:notify(e) else return nil end end return _38_(Logic.Action["pick-trump"](app.game, n)) else return nil end end











 AppState.PickCard.activated = function(app)
 if Logic.Query["round-ended?"](app.game) then
 do local next_game = Logic.Action["score-round"](app.game) app["update-game"](app, next_game, {"score-round"}) end

 if Logic.Query["game-ended?"](app.game) then return app["switch-state"](app, AppState.GameEnded) else return app["switch-state"](app, AppState.NewRound) end else return nil end end



 AppState.PickCard.OnEvent.input["<LeftMouse>"] = function(app, _46_, pos) local _arg_47_ = _46_ local location = _arg_47_[1]
 local _48_, _49_ = location if ((_G.type(_48_) == "table") and (_48_[1] == "hand") and (nil ~= _48_[2])) then local n = _48_[2] return app["switch-state"](app, AppState.PlayTrick, {hand = {"hand", n}}) elseif (((_G.type(_48_) == "table") and (_48_[1] == "menu")) and true) then local _ = _49_

 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end




 AppState.PlayTrick.OnEvent.input["<LeftMouse>"] = function(app, _51_, pos) local _arg_52_ = _51_ local location = _arg_52_[1]
 local _53_, _54_ = location, app.state.context.hand if (((_G.type(_53_) == "table") and (_53_[1] == "hand") and (nil ~= _53_[2])) and ((_G.type(_54_) == "table") and (_54_[1] == "hand") and (_53_[2] == _54_[2]))) then local n = _53_[2]

 app.state.context["lifting-from"] = nil return nil elseif (((_G.type(_53_) == "table") and (_53_[1] == "menu")) and true) then local _ = _54_
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end

 AppState.PlayTrick.OnEvent.input["<LeftDrag>"] = function(app, _56_, position) local _arg_57_ = _56_ local location = _arg_57_[1]
 if not app.state.context["drag-start"] then
 local _58_, _59_ = location, app.state.context.hand if (((_G.type(_58_) == "table") and (_58_[1] == "hand") and (nil ~= _58_[2])) and ((_G.type(_59_) == "table") and (_59_[1] == "hand") and (_58_[2] == _59_[2]))) then local n = _58_[2]
 app.state.context["drag-start"] = location else end else end
 local _62_, _63_ = app.state.context.hand, app.state.context["drag-start"] if (((_G.type(_62_) == "table") and (_62_[1] == "hand") and (nil ~= _62_[2])) and ((_G.type(_63_) == "table") and (_63_[1] == "hand") and (_62_[2] == _63_[2]))) then local n = _62_[2]
 app.state.context["drag-position"] = position return nil else return nil end end

 AppState.PlayTrick.OnEvent.input["<LeftRelease>"] = function(app, _65_, pos) local _arg_66_ = _65_ local _holding = _arg_66_[1] local location = _arg_66_[2]
 local _let_67_ = app.state.context.hand local _hand = _let_67_[1] local hand_n = _let_67_[2]
 if ((_G.type(location) == "table") and (location[1] == "play")) then
 local function _68_(...) local _69_, _70_ = ... if ((nil ~= _69_) and (nil ~= _70_)) then local next_game = _69_ local events = _70_

 local events0 do local t, memo = {}, {"hand", hand_n} for _, e in ipairs(events) do
 if ((_G.type(e) == "table") and (e[1] == "face-up") and ((_G.type(e[2]) == "table") and (e[2][1] == "grid") and (nil ~= e[2][2]) and (nil ~= e[2][3]))) then local row = e[2][2] local col = e[2][3]

 t, memo = table.join(t, {{"move", memo, {"grid-comp", row, col}}, e, {"wait", 300}}), {"grid-comp", row, col} elseif ((_G.type(e) == "table") and (e[1] == "move") and true and ((_G.type(e[3]) == "table") and (e[3][1] == "trick"))) then local _0 = e[2]



 t, memo = table.join(t, {{"wait", 300}, e}), memo else local _0 = e
 t, memo = table.insert(t, e), memo end end events0 = t, memo end local after
 local function _72_() app["update-game"](app, next_game, {"play-trick", hand_n, location})

 local _73_ do local winner_3f = false for _, e in ipairs(events0) do if winner_3f then break end
 if ((_G.type(e) == "table") and (e[1] == "move") and true and ((_G.type(e[3]) == "table") and (e[3][1] == "trick"))) then local _0 = e[2] winner_3f = true else winner_3f = nil end end _73_ = winner_3f end if _73_ then return app["switch-state"](app, AppState.PickCard) else

 local choices if ((_G.type(location) == "table") and (location[1] == "play") and (location[2] == "top") and (nil ~= location[3])) then local col = location[3]
 local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 6 do local val_20_auto = {"grid", i, col} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end choices = tbl_18_auto elseif ((_G.type(location) == "table") and (location[1] == "play") and (location[2] == "bottom") and (nil ~= location[3])) then local col = location[3]
 local tbl_18_auto = {} local i_19_auto = 0 for i = 6, 1, -1 do local val_20_auto = {"grid", i, col} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end choices = tbl_18_auto elseif ((_G.type(location) == "table") and (location[1] == "play") and (location[2] == "left") and (nil ~= location[3])) then local row = location[3]
 local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 6 do local val_20_auto = {"grid", row, i} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end choices = tbl_18_auto elseif ((_G.type(location) == "table") and (location[1] == "play") and (location[2] == "right") and (nil ~= location[3])) then local row = location[3]
 local tbl_18_auto = {} local i_19_auto = 0 for i = 6, 1, -1 do local val_20_auto = {"grid", row, i} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end choices = tbl_18_auto else choices = nil end return app["switch-state"](app, AppState.ResolveTrick, {hand = hand_n, ["card-pos"] = pos, choices = choices}) end end after = _72_ local timeline = app["build-event-animation"](app, events0, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_69_ == nil) and (nil ~= _70_)) then local e = _70_ app:notify(e) return app["switch-state"](app, AppState.PickCard) else return nil end end return _68_(Logic.Action["play-trick"](app.game, hand_n, location)) else local _ = location return app["switch-state"](app, AppState.PickCard) end end











 AppState.PlayTrick.OnEvent.input["<RightMouse>"] = function(app, _83_, pos) local _arg_84_ = _83_ local location = _arg_84_[1] return app["switch-state"](app, AppState.PickCard) end


 AppState.PlayTrick.tick = function(app)
 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card)

 local _85_, _86_ = location, app.state.context if (((_G.type(_85_) == "table") and (_85_[1] == "hand") and (nil ~= _85_[2])) and ((_G.type(_86_) == "table") and ((_G.type(_86_.hand) == "table") and (_86_.hand[1] == "hand") and (_85_[2] == _86_.hand[2])) and ((_G.type(_86_["drag-position"]) == "table") and (nil ~= _86_["drag-position"].row) and (nil ~= _86_["drag-position"].col)))) then local n = _85_[2] local row = _86_["drag-position"].row local col = _86_["drag-position"].col comp["set-position"](comp, {row = (row - 2), col = (col - 2), z = app["z-index-for-layer"](app, "lift")}) else end end return nil end









 AppState.ResolveTrick.activated = function(app) return (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["pick-resolve-label"], "set-visible", true) end


 AppState.ResolveTrick.deactivated = function(app) return (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components["pick-resolve-label"], "set-visible", false) end


 AppState.ResolveTrick["valid-choice?"] = function(app, location) local b = false
 for _, _88_ in ipairs(app.state.context.choices) do local _each_89_ = _88_ local _grid = _each_89_[1] local row = _each_89_[2] local col = _each_89_[3] if b then break end
 if ((_G.type(location) == "table") and (location[1] == "grid") and (location[2] == row) and (location[3] == col)) then b = true else b = nil end end return b end


 AppState.ResolveTrick.tick = function(app)
 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card)

 local _91_, _92_ = location, app.state.context if (((_G.type(_91_) == "table") and (_91_[1] == "hand") and (nil ~= _91_[2])) and ((_G.type(_92_) == "table") and (_91_[2] == _92_.hand) and ((_G.type(_92_["card-pos"]) == "table") and (nil ~= _92_["card-pos"].row) and (nil ~= _92_["card-pos"].col)))) then local n = _91_[2] local row = _92_["card-pos"].row local col = _92_["card-pos"].col comp["set-position"](comp, {row = (row - 2), col = (col - 2), z = app["z-index-for-layer"](app, "lift")}) elseif (((_G.type(_91_) == "table") and (_91_[1] == "grid") and (nil ~= _91_[2]) and (nil ~= _91_[3])) and ((_G.type(_92_) == "table") and ((_G.type(_92_.hover) == "table") and (_92_.hover[1] == "grid") and (_91_[2] == _92_.hover[2]) and (_91_[3] == _92_.hover[3])))) then local row = _91_[2] local col = _91_[3]





 local _let_93_ = app["location->position"](app, {"grid", row, col}) local row0 = _let_93_["row"] local col0 = _let_93_["col"] comp["set-position"](comp, {row = (row0 - 1), col = col0, z = app["z-index-for-layer"](app, "lift")}) else end end return nil end




 AppState.ResolveTrick.OnEvent.input["<LeftMouse>"] = function(app, _95_, pos) local _arg_96_ = _95_ local location = _arg_96_[1]
 local function _97_() return AppState.ResolveTrick["valid-choice?"](app, location) end if (((_G.type(location) == "table") and (location[1] == "grid")) and _97_()) then

 app.state.context.hover = location return nil else local _ = location
 app.state.context.hover = nil return nil end end

 AppState.ResolveTrick.OnEvent.input["<LeftDrag>"] = function(app, _99_, pos) local _arg_100_ = _99_ local location = _arg_100_[1]
 local function _101_() return AppState.ResolveTrick["valid-choice?"](app, location) end if (((_G.type(location) == "table") and (location[1] == "grid")) and _101_()) then

 app.state.context.hover = location return nil else local _ = location
 app.state.context.hover = nil return nil end end

 AppState.ResolveTrick.OnEvent.input["<LeftRelease>"] = function(app, _103_, pos) local _arg_104_ = _103_ local location = _arg_104_[1]
 local function _105_() return AppState.ResolveTrick["valid-choice?"](app, location) end if (((_G.type(location) == "table") and (location[1] == "grid")) and _105_()) then

 local function _106_(...) local _107_, _108_ = ... if (nil ~= _107_) then local hand_n = _107_ local function _109_(...) local _110_, _111_ = ... if ((nil ~= _110_) and (nil ~= _111_)) then local next_game = _110_ local events = _111_


 local after local function _112_() app["update-game"](app, next_game, {"force-trick", hand_n, location}) return app["switch-state"](app, AppState.PickCard) end after = _112_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_110_ == nil) and (nil ~= _111_)) then local e = _111_ return app:notify(e) else return nil end end return _109_(Logic.Action["force-trick"](app.game, hand_n, location)) elseif ((_107_ == nil) and (nil ~= _108_)) then local e = _108_ return app:notify(e) else return nil end end return _106_(app.state.context.hand) elseif ((_G.type(location) == "table") and (location[1] == "menu")) then






 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end






 M["build-event-animation"] = function(app, events, after, _3fopts, _3fhand_length)
 local function location__3eposition(_proxy, location)
 if (AppState.PlayTrick == app.state.module) then
 local _let_116_ = app.state.context local _let_117_ = _let_116_["hand"] local _ = _let_117_[1] local hand_n = _let_117_[2] local _let_118_ = _let_116_["drag-position"] local row = _let_118_["row"] local col = _let_118_["col"]
 if ((_G.type(location) == "table") and (location[1] == "hand") and (location[2] == hand_n)) then
 return {row = (row - 2), col = (col - 2), z = app["z-index-for-layer"](app, "lift")} else local _0 = location return app["location->position"](app, location, _3fhand_length) end else return app["location->position"](app, location, _3fhand_length) end end



 if _3fhand_length then
 local proxy = setmetatable({["location->position"] = location__3eposition}, {__index = app})

 return CardUtils["build-event-animation"](proxy, events, after, _3fopts) else
 return CardUtils["build-event-animation"](app, events, after, _3fopts) end end

 M["location->position"] = function(app, location, _3fhand_length)
 local _let_122_ = app["card-style"] local card_height = _let_122_["height"] local card_width = _let_122_["width"]
 local grid = {row = card_height, col = (1 + (3 * card_width))}

 local draw = {row = (grid.row + 1 + (7 * (card_height - 1))), col = (grid.col - 3 - card_width)}


 local hand = {row = draw.row, col = (draw.col + 3 + (4 * card_width) + -3)}

 do local _123_ = (_3fhand_length or #app.game.hand) if (_123_ == 0) then elseif (_123_ == 1) then elseif (nil ~= _123_) then local n = _123_


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

 local function _127_() return app["switch-state"](app, AppState.NewRound) end vim.defer_fn(_127_, 300) return app:render() end


 M["setup-new-game"] = function(app, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/optrita-lines/app.fnl:362") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/optrita-lines/app.fnl:362") app["new-game"](app, Logic.build, game_config, _3fseed) app["build-components"](app) app["switch-state"](app, AppState.Default)



 return app end

 M["build-components"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/optrita-lines/app.fnl:368")
 local function build_label(text, position)
 local _let_128_ = position local row = _let_128_["row"] local col = _let_128_["col"] local z = _let_128_["z"]

 local function _129_(self, enabled)
 local hl if enabled then hl = "@playtime.ui.on" else hl = "@playtime.ui.on" end return self["set-content"](self, {{{text, hl}}}) end return Component["set-content"](Component["set-size"](Component["set-position"](Component.build(_129_), position), {width = #text, height = 1}), {{{text, "@playtime.ui.on"}}}) end





 local function build_score(text, limit, position)
 local _let_131_ = position local row = _let_131_["row"] local col = _let_131_["col"] local z = _let_131_["z"]

 local function _132_(self, score)
 local text0 = string.format("%s: %d/%d", text, score, limit) self["set-content"](self, {{{text0, "@playtime.ui.on"}}}) return self["set-size"](self, {width = #text0, height = 1}) end return Component["set-position"](Component.build(_132_), position):update(0) end





 local function play_drop(side, position, tag)
 local _let_133_ = position local row = _let_133_["row"] local col = _let_133_["col"] local z = _let_133_["z"] local color = "@playtime.ui.off" local content

 if (side == "left") then
 content = {{{"     ", color}}, {{"   \226\134\146 ", color}}, {{"     ", color}}, {{"     ", color}}} elseif (side == "right") then



 content = {{{"     ", color}}, {{"     ", color}}, {{"\226\134\144    ", color}}, {{"     ", color}}} elseif (side == "top") then



 content = {{{"      ", color}}, {{"      ", color}}, {{"      ", color}}, {{"  \226\134\147   ", color}}} elseif (side == "bottom") then



 content = {{{"  \226\134\145   ", color}}, {{"      ", color}}, {{"      ", color}}, {{"      ", color}}} else content = nil end



 local content0 = {{{"     ", color}}, {{"     ", color}}, {{"     ", color}}, {{"     ", color}}}




 local function _135_(self, enabled)
 local hl if enabled then hl = "@playtime.ui.on" else hl = "@playtime.ui.off" end return self["set-content"](self, content0) end return Component["set-content"](Component["set-size"](Component["set-position"](Component["set-tag"](Component.build(_135_), tag), position), {width = 5, height = 4}), content0) end






 local card_card_components do local tbl_14_auto = {} for location, card in Logic["iter-cards"](app.game) do local k_15_auto, v_16_auto = nil, nil
 do local comp local function _137_(...) return app["location->position"](app, ...) end comp = CardComponents.card(_137_, location, card, app["card-style"])



 k_15_auto, v_16_auto = card.id, comp end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end card_card_components = tbl_14_auto end
 local menubar = CommonComponents.menubar({{"Optrita: Lines", {"file"}, {{"", nil}, {"New Game", {"new-game"}}, {"Restart Game", {"restart-game"}}, {"", nil}, {"Undo", {"undo"}}, {"", nil}, {"Quit", {"quit"}}, {"", nil}, {string.format("Seed: %s", app.seed), nil}}}}, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar")})














 local pick_trump_label = (function(tgt, m, ...) return tgt[m](tgt, ...) end)(build_label("Pick trump suit", {row = 24, col = 29, z = 100}), "set-visible", false)

 local pick_resolve_label = (function(tgt, m, ...) return tgt[m](tgt, ...) end)(build_label("Pick card to remove", {row = 24, col = 27, z = 100}), "set-visible", false)

 local game_report = CommonComponents["game-report"](app.view.width, app.view.height, app["z-index-for-layer"](app, "report"), {{"player", "The GRID has been vanquished"}, {"grid", "The GRID's reign of terror continues"}}) local droppers




 do local t = {} for i = 1, 6 do
 local tbl_17_auto = t for _, side in ipairs({"top", "bottom", "left", "right"}) do table.insert(tbl_17_auto, (function(tgt, m, ...) return tgt[m](tgt, ...) end)(play_drop(side, app["location->position"](app, {"play", side, i}), {"play", side, i}), "set-visible", true)) end t = tbl_17_auto end droppers = t end local droppers_by_tag












 do local tbl_14_auto = {} for _, d in ipairs(droppers) do
 local k_15_auto, v_16_auto = d.tag, d if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end droppers_by_tag = tbl_14_auto end
 local grid_score = build_score("Grid", app.game.rules["score-limit"].grid, app["location->position"](app, {"label", "score", "grid"}))


 local player_score = build_score("Player", app.game.rules["score-limit"].player, app["location->position"](app, {"label", "score", "player"}))


 app["card-id->components"] = card_card_components
 app["droppers-by-tag"] = droppers_by_tag
 return table.merge(app.components, {droppers = droppers, menubar = menubar, ["game-report"] = game_report, ["pick-trump-label"] = pick_trump_label, ["pick-resolve-label"] = pick_resolve_label, ["grid-score"] = grid_score, ["player-score"] = player_score, cards = table.values(card_card_components)}) end








 M.render = function(app) do end (app.view):render({app.components.droppers, app.components.cards, {app.components["pick-trump-label"], app.components["pick-resolve-label"], app.components["grid-score"], app.components["player-score"]}, {app.components["game-report"], app.components.menubar}})








 return app end

 M.tick = function(app)
 local now = uv.now() app["process-next-event"](app)

 do local _140_ = app.state.module.tick if (nil ~= _140_) then local f = _140_
 f(app) else local _ = _140_
 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card)

 local _141_ = app.state.context if ((_G.type(_141_) == "table") and ((_G.type(_141_.hover) == "table") and (_141_.hover[1] == "hand") and (nil ~= _141_.hover[2]))) then local n = _141_.hover[2]
 if ((_G.type(location) == "table") and (location[1] == "hand") and (location[2] == n)) then comp["set-position"](comp, {row = (comp.row - 1)}) else end else end end end end do end (app.components["player-score"]):update(app.game.score.player) do end (app.components["grid-score"]):update(app.game.score.grid) return app["request-render"](app) end










 M.save = function(app, filename) _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/game/optrita-lines/app.fnl:516") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/optrita-lines/app.fnl:516")





 local _145_ do local tbl_18_auto = {} local i_19_auto = 0 for _, _146_ in ipairs(app["game-history"]) do local _each_147_ = _146_ local _state = _each_147_[1] local action = _each_147_[2]
 local val_20_auto = action if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end _145_ = tbl_18_auto end return App.save(app, filename, {version = 1, ["app-id"] = app["app-id"], seed = app.seed, config = app["game-config"], latest = app.game, replay = _145_}) end

 M.load = function(app, filename) _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/game/optrita-lines/app.fnl:525") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/optrita-lines/app.fnl:525")
 local function _149_(...) local _150_ = ... if (nil ~= _150_) then local data = _150_

 local _let_151_ = data local config = _let_151_["config"] local seed = _let_151_["seed"] local latest = _let_151_["latest"] local replay = _let_151_["replay"] app["setup-new-game"](app, config, seed) return app["queue-event"](app, "app", "replay", {replay = replay, verify = latest}) else local __84_auto = _150_ return ... end end return _149_(App.load(app, filename)) end



 return M