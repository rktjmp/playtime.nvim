
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local State = require("playtime.app.state")
 local uv = (vim.loop or vim.uv)
 local Serializer = require("playtime.serializer")

 local M = {}










































 M.build = function(LogicImpl) _G.assert((nil ~= LogicImpl), "Missing argument LogicImpl on fnl/playtime/app/patience/state.fnl:53")
 if ((_G.type(LogicImpl) == "table") and ((_G.type(LogicImpl.Action) == "table") and (nil ~= LogicImpl.Action.move)) and ((_G.type(LogicImpl.Query) == "table") and (nil ~= LogicImpl.Query["liftable?"]) and (nil ~= LogicImpl.Query["droppable?"]) and (nil ~= LogicImpl.Query["game-ended?"]) and (nil ~= LogicImpl.Query["game-result"]))) then local move = LogicImpl.Action.move local liftable_3f = LogicImpl.Query["liftable?"] local droppable_3f = LogicImpl.Query["droppable?"] local game_ended_3f = LogicImpl.Query["game-ended?"] local game_result = LogicImpl.Query["game-result"] else

 local __2_auto = LogicImpl error("LogicImpl must match {:Action {:move move}\n :Query {:droppable? droppable?\n         :game-ended? game-ended?\n         :game-result game-result\n         :liftable? liftable?}}") end

 local AppState = {}

 AppState.Default = State.build("Default", {delegate = {app = State.DefaultAppState}})
 AppState.DraggingCards = State.build("DraggingCards", {delegate = {app = AppState.Default}})
 AppState.LiftingCards = State.build("LiftingCards", {delegate = {app = AppState.Default}})
 AppState.Animating = clone(State.DefaultAnimatingState)
 AppState.GameEnded = State.build("GameEnded", {delegate = {app = AppState.Default}})

 AppState.Default.OnEvent.app.replay = function(app, _3_) local _arg_4_ = _3_ local replay = _arg_4_["replay"] local _3fverify = _arg_4_["verify"]
 if ((_G.type(replay) == "table") and (replay[1] == nil)) then
 return app elseif ((_G.type(replay) == "table") and (nil ~= replay[1])) then local action = replay[1] local rest = {select(2, (table.unpack or _G.unpack)(replay))}
 if ((_G.type(action) == "table") and (action[1] == nil)) then return app["queue-event"](app, "app", "replay", {replay = rest, verify = _3fverify}) elseif (nil ~= action) then local action0 = action

 local function _5_(...) local _6_, _7_ = ... if ((_G.type(_6_) == "table") and (nil ~= _6_[1])) then local f_name = _6_[1] local args = {select(2, (table.unpack or _G.unpack)(_6_))} local function _8_(...) local _9_, _10_ = ... if (nil ~= _9_) then local f = _9_ local function _11_(...) local _12_, _13_ = ... if ((nil ~= _12_) and (nil ~= _13_)) then local next_game = _12_ local moves = _13_



 local after local function _14_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "replay", {replay = rest, verify = _3fverify}) return app["update-game"](app, next_game, action0) end after = _14_ local timeline = app["build-event-animation"](app, moves, after, {["duration-ms"] = 80}) return app["switch-state"](app, AppState.Animating, timeline) elseif ((_12_ == nil) and (nil ~= _13_)) then local err = _13_








 return error(err) else return nil end end return _11_(f(app.game, table.unpack(args))) elseif ((_9_ == nil) and (nil ~= _10_)) then local err = _10_ return error(err) else return nil end end return _8_(LogicImpl.Action[f_name]) elseif ((_6_ == nil) and (nil ~= _7_)) then local err = _7_ return error(err) else return nil end end return _5_(action0) else return nil end else return nil end end

 AppState.Default.OnEvent.app.menu = function(app, menu_item)
 local _ = menu_item
 return error(Error("unhandled menu item #{menu-item}", {["menu-item"] = menu_item})) end

 AppState.Default.OnEvent.app["new-deal"] = function(app) app["setup-new-game"](app, app["game-config"], nil)

 local function _20_() return app["queue-event"](app, "app", "deal") end return vim.defer_fn(_20_, 300) end

 AppState.Default.OnEvent.app["repeat-deal"] = function(app) app["setup-new-game"](app, app["game-config"], app.seed)

 local function _21_() return app["queue-event"](app, "app", "deal") end return vim.defer_fn(_21_, 300) end

 AppState.Default.OnEvent.app.deal = function(app)
 local next_game, moves = LogicImpl.Action.deal(app.game) local after
 local function _22_() app["switch-state"](app, AppState.Default) app["update-game"](app, next_game, {"deal"}) app["queue-event"](app, "app", "noop") return app["queue-event"](app, "app", "maybe-auto-move") end after = _22_ local timeline = app["build-event-animation"](app, moves, after, {["stagger-ms"] = 50, ["duration-ms"] = 120}) return app["switch-state"](app, AppState.Animating, timeline) end











 AppState.Default.OnEvent.app.draw = function(app, _3fcontext)
 local function _23_(...) local _24_, _25_ = ... if ((nil ~= _24_) and (nil ~= _25_)) then local next_game = _24_ local moves = _25_

 local after local function _26_() app["switch-state"](app, AppState.Default) app["update-game"](app, next_game, {"draw", _3fcontext}) app["queue-event"](app, "app", "noop") return app["queue-event"](app, "app", "maybe-auto-move") end after = _26_ local timeline = app["build-event-animation"](app, moves, after, {["stagger-ms"] = 50, ["duration-ms"] = 120}) return app["switch-state"](app, AppState.Animating, timeline) elseif ((_24_ == nil) and (nil ~= _25_)) then local err = _25_ return app:notify(err) else return nil end end return _23_(LogicImpl.Action.draw(app.game, _3fcontext)) end













 AppState.Default.OnEvent.app["maybe-auto-move"] = function(app)




 return app end

 AppState.Default.OnEvent.input["<LeftMouse>"] = function(app, _28_, pos) local _arg_29_ = _28_ local click_location = _arg_29_[1] local rest = (function (t, k, e) local mt = getmetatable(t) if 'table' == type(mt) and mt.__fennelrest then return mt.__fennelrest(t, k) elseif e then local rest = {} for k, v in pairs(t) do if not e[k] then rest[k] = v end end return rest else return {(table.unpack or unpack)(t, k)} end end)(_arg_29_, 2)
 local function _30_() local field = click_location[1] return eq_any_3f(field, {"tableau", "cell", "hand", "discard", "stock"}) end if (((_G.type(click_location) == "table") and (nil ~= click_location[1])) and _30_()) then local field = click_location[1]

 if LogicImpl.Query["liftable?"](app.game, click_location) then return app["switch-state"](app, AppState.LiftingCards, {["lifted-from"] = click_location}) else return nil end elseif ((_G.type(click_location) == "table") and (click_location[1] == "draw")) then return app["queue-event"](app, "app", "draw", click_location) elseif ((_G.type(click_location) == "table") and (click_location[1] == "menu") and (nil ~= click_location[2]) and (click_location[3] == nil)) then local idx = click_location[2] local menu_item = click_location return app["push-state"](app, State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end








 AppState.LiftingCards.OnEvent.input["<LeftMouse>"] = function(app, _33_, pos) local _arg_34_ = _33_ local location = _arg_34_[1]
 app.state.context["drag-start"] = nil
 local _35_, _36_ = location, app.state.context["lifted-from"] if (((_G.type(_35_) == "table") and (nil ~= _35_[1]) and (nil ~= _35_[2]) and (nil ~= _35_[3])) and ((_G.type(_36_) == "table") and (_35_[1] == _36_[1]) and (_35_[2] == _36_[2]) and (_35_[3] == _36_[3]))) then local f = _35_[1] local c = _35_[2] local n = _35_[3] app.state.context["return-on-left-release"] = true




 return nil elseif (((_G.type(_35_) == "table") and (nil ~= _35_[1]) and (nil ~= _35_[2])) and ((_G.type(_36_) == "table") and (_35_[1] == _36_[1]) and (_35_[2] == _36_[2]))) then local f = _35_[1] local c = _35_[2]


 if LogicImpl.Query["liftable?"](app.game, location) then return app["switch-state"](app, AppState.LiftingCards, {["lifted-from"] = location}) else return nil end elseif ((nil ~= _35_) and (nil ~= _36_)) then local to = _35_ local from = _36_




 if LogicImpl.Query["droppable?"](app.game, location) then
 local function _38_(...) local _39_, _40_ = ... if ((nil ~= _39_) and (nil ~= _40_)) then local next_game = _39_ local moves = _40_

 local after local function _41_() app["update-game"](app, next_game, {"move", from, to}) app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "noop") return app["queue-event"](app, "app", "maybe-auto-move") end after = _41_ local timeline = app["build-event-animation"](app, moves, after) return app["switch-state"](app, AppState.Animating, timeline) else local __85_auto = _39_ return ... end end return _38_(LogicImpl.Action.move(app.game, from, to)) else return nil end else return nil end end







 AppState.LiftingCards.OnEvent.input["<LeftRelease>"] = function(app, _45_, pos) local _arg_46_ = _45_ local location = _arg_46_[1]
 local _47_, _48_ = location, app.state.context["lifted-from"] if (((_G.type(_47_) == "table") and (nil ~= _47_[1]) and (nil ~= _47_[2]) and (nil ~= _47_[3])) and ((_G.type(_48_) == "table") and (_47_[1] == _48_[1]) and (_47_[2] == _48_[2]) and (_47_[3] == _48_[3]))) then local f = _47_[1] local c = _47_[2] local n = _47_[3]

 if app.state.context["return-on-left-release"] then return app["switch-state"](app, AppState.Default) else return nil end else return nil end end


 AppState.LiftingCards.OnEvent.input["<RightMouse>"] = function(app, _, _0) return app["switch-state"](app, AppState.Default) end


 AppState.LiftingCards.OnEvent.input["<LeftDrag>"] = function(app, _51_, pos) local _arg_52_ = _51_ local location = _arg_52_[1]
 if not app.state.context["drag-start"] then
 table.merge(app.state.context, {["drag-start"] = {location = location, position = pos}}) else end
 local context = app.state.context
 local _54_, _55_ = pos, app.state.context["drag-start"].position if (((_G.type(_54_) == "table") and (nil ~= _54_.row) and (nil ~= _54_.col)) and ((_G.type(_55_) == "table") and (_54_.row == _55_.row) and (_54_.col == _55_.col))) then local row = _54_.row local col = _54_.col
 return nil else local _ = _54_
 local _56_, _57_, _58_ = location, context["lifted-from"], context["drag-start"].location if (true and ((_G.type(_57_) == "table") and (nil ~= _57_[1]) and (nil ~= _57_[2]) and (nil ~= _57_[3])) and ((_G.type(_58_) == "table") and (_57_[1] == _58_[1]) and (_57_[2] == _58_[2]) and (_57_[3] == _58_[3]))) then local _0 = _56_ local f = _57_[1] local c = _57_[2] local n = _57_[3] return app["switch-state"](app, AppState.DraggingCards, table.merge(context, {drag = {location = location, position = pos}})) else return nil end end end






 AppState.DraggingCards.OnEvent.input["<LeftDrag>"] = function(app, _61_, pos) local _arg_62_ = _61_ local location = _arg_62_[1]
 app.state.context.drag.position = pos
 app.state.context.drag.location = location return nil end





 AppState.DraggingCards.OnEvent.input["<LeftRelease>"] = function(app, _63_, pos) local _arg_64_ = _63_ local _ = _arg_64_[1] local location = _arg_64_[2]
 if LogicImpl.Query["droppable?"](app.game, location) then
 local function _65_(...) local _66_, _67_ = ... if ((nil ~= _66_) and (nil ~= _67_)) then local from = _66_ local to = _67_ local function _68_(...) local _69_, _70_ = ... if ((nil ~= _69_) and true) then local next_game = _69_ local _moves = _70_ app["update-game"](app, next_game, {"move", from, to}) app["queue-event"](app, "app", "noop") return app["queue-event"](app, "app", "maybe-auto-move") elseif ((_69_ == nil) and (nil ~= _70_)) then local err = _70_ return app:notify(err) else return nil end end return _68_(LogicImpl.Action.move(app.game, from, to)) elseif ((_66_ == nil) and (nil ~= _67_)) then local err = _67_ return app:notify(err) else return nil end end _65_(app.state.context["lifted-from"], location) else end return app["switch-state"](app, AppState.Default) end










 AppState.Default.tick = function(app)
 for location, card in LogicImpl["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card) end return nil end


 AppState.LiftingCards.tick = function(app)
 for location, card in LogicImpl["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id]
 local _74_, _75_ = location, app.state.context["lifted-from"] local function _76_() local f = _74_[1] local c = _74_[2] local card_n = _74_[3] local lift_n = _75_[3] return (lift_n <= card_n) end if ((((_G.type(_74_) == "table") and (nil ~= _74_[1]) and (nil ~= _74_[2]) and (nil ~= _74_[3])) and ((_G.type(_75_) == "table") and (_74_[1] == _75_[1]) and (_74_[2] == _75_[2]) and (nil ~= _75_[3]))) and _76_()) then local f = _74_[1] local c = _74_[2] local card_n = _74_[3] local lift_n = _75_[3]

 local _let_77_ = app["location->position"](app, {f, c, card_n}) local row = _let_77_["row"] local col = _let_77_["col"] local z = _let_77_["z"] comp:update(location, card) comp["set-position"](comp, {row = row, col = (col + 1), z = app["z-index-for-layer"](app, "lift", z)}) else local _ = _74_ comp:update(location, card) end end return nil end






 AppState.DraggingCards.tick = function(app)
 for location, card in LogicImpl["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id]
 local _79_, _80_ = location, app.state.context["lifted-from"] local function _81_() local f = _79_[1] local c = _79_[2] local card_n = _79_[3] local lift_n = _80_[3] return (lift_n <= card_n) end if ((((_G.type(_79_) == "table") and (nil ~= _79_[1]) and (nil ~= _79_[2]) and (nil ~= _79_[3])) and ((_G.type(_80_) == "table") and (_79_[1] == _80_[1]) and (_79_[2] == _80_[2]) and (nil ~= _80_[3]))) and _81_()) then local f = _79_[1] local c = _79_[2] local card_n = _79_[3] local lift_n = _80_[3]

 local _let_82_ = app["location->position"](app, {f, c, card_n}) local z = _let_82_["z"]
 local _let_83_ = app.state.context.drag.position local row = _let_83_["row"] local col = _let_83_["col"] comp:update(location, card) comp["set-position"](comp, {row = (row + 0 + ((card_n - lift_n) * 2)), col = (col - 3), z = app["z-index-for-layer"](app, "lift", comp.z)}) else local _ = _79_ comp:update(location, card) end end return nil end






 AppState.GameEnded.OnEvent.input["<LeftMouse>"] = function(app, _85_, pos) local _arg_86_ = _85_ local location = _arg_86_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end



 AppState.GameEnded.activated = function(app)
 app["ended-at"] = os.time() app:save((os.time() .. "-win")) app["update-statistics"](app)


 do local _let_88_ = app["game-ended-data"](app) local key = _let_88_[1] local other = _let_88_[2] do end (app.components["game-report"]):update(key, other) end

 return app end

 return AppState end

 return M