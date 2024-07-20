
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

 AppState.Default.OnEvent.app.replay = function(app, _3_) local replay = _3_["replay"] local _3fverify = _3_["verify"]
 if ((_G.type(replay) == "table") and (replay[1] == nil)) then
 return app elseif ((_G.type(replay) == "table") and (nil ~= replay[1])) then local action = replay[1] local rest = {select(2, (table.unpack or _G.unpack)(replay))}
 if ((_G.type(action) == "table") and (action[1] == nil)) then return app["queue-event"](app, "app", "replay", {replay = rest, verify = _3fverify}) elseif (nil ~= action) then local action0 = action

 local function _4_(...) local _5_, _6_ = ... if ((_G.type(_5_) == "table") and (nil ~= _5_[1])) then local f_name = _5_[1] local args = {select(2, (table.unpack or _G.unpack)(_5_))} local function _7_(...) local _8_, _9_ = ... if (nil ~= _8_) then local f = _8_ local function _10_(...) local _11_, _12_ = ... if ((nil ~= _11_) and (nil ~= _12_)) then local next_game = _11_ local moves = _12_



 local after local function _13_() app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "replay", {replay = rest, verify = _3fverify}) return app["update-game"](app, next_game, action0) end after = _13_ local timeline = app["build-event-animation"](app, moves, after, {["duration-ms"] = 80}) return app["switch-state"](app, AppState.Animating, timeline) elseif ((_11_ == nil) and (nil ~= _12_)) then local err = _12_








 return error(err) else return nil end end return _10_(f(app.game, table.unpack(args))) elseif ((_8_ == nil) and (nil ~= _9_)) then local err = _9_ return error(err) else return nil end end return _7_(LogicImpl.Action[f_name]) elseif ((_5_ == nil) and (nil ~= _6_)) then local err = _6_ return error(err) else return nil end end return _4_(action0) else return nil end else return nil end end

 AppState.Default.OnEvent.app.menu = function(app, menu_item)
 local _ = menu_item
 return error(Error("unhandled menu item #{menu-item}", {["menu-item"] = menu_item})) end

 AppState.Default.OnEvent.app["new-deal"] = function(app) app["setup-new-game"](app, app["game-config"], nil)

 local function _19_() return app["queue-event"](app, "app", "deal") end return vim.defer_fn(_19_, 300) end

 AppState.Default.OnEvent.app["repeat-deal"] = function(app) app["setup-new-game"](app, app["game-config"], app.seed)

 local function _20_() return app["queue-event"](app, "app", "deal") end return vim.defer_fn(_20_, 300) end

 AppState.Default.OnEvent.app.deal = function(app)
 local next_game, moves = LogicImpl.Action.deal(app.game) local after
 local function _21_() app["switch-state"](app, AppState.Default) app["update-game"](app, next_game, {"deal"}) app["queue-event"](app, "app", "noop") return app["queue-event"](app, "app", "maybe-auto-move") end after = _21_ local timeline = app["build-event-animation"](app, moves, after, {["stagger-ms"] = 50, ["duration-ms"] = 120}) return app["switch-state"](app, AppState.Animating, timeline) end











 AppState.Default.OnEvent.app.draw = function(app, _3fcontext)
 local function _22_(...) local _23_, _24_ = ... if ((nil ~= _23_) and (nil ~= _24_)) then local next_game = _23_ local moves = _24_

 local after local function _25_() app["switch-state"](app, AppState.Default) app["update-game"](app, next_game, {"draw", _3fcontext}) app["queue-event"](app, "app", "noop") return app["queue-event"](app, "app", "maybe-auto-move") end after = _25_ local timeline = app["build-event-animation"](app, moves, after, {["stagger-ms"] = 50, ["duration-ms"] = 120}) return app["switch-state"](app, AppState.Animating, timeline) elseif ((_23_ == nil) and (nil ~= _24_)) then local err = _24_ return app:notify(err) else return nil end end return _22_(LogicImpl.Action.draw(app.game, _3fcontext)) end













 AppState.Default.OnEvent.app["maybe-auto-move"] = function(app)




 return app end

 AppState.Default.OnEvent.input["<LeftMouse>"] = function(app, _27_, pos) local click_location = _27_[1] local rest = (function (t, k, e) local mt = getmetatable(t) if 'table' == type(mt) and mt.__fennelrest then return mt.__fennelrest(t, k) elseif e then local rest = {} for k, v in pairs(t) do if not e[k] then rest[k] = v end end return rest else return {(table.unpack or unpack)(t, k)} end end)(_27_, 2)
 local and_28_ = ((_G.type(click_location) == "table") and (nil ~= click_location[1])) if and_28_ then local field = click_location[1] and_28_ = eq_any_3f(field, {"tableau", "cell", "hand", "discard", "stock"}) end if and_28_ then local field = click_location[1]

 if LogicImpl.Query["liftable?"](app.game, click_location) then return app["switch-state"](app, AppState.LiftingCards, {["lifted-from"] = click_location}) else return nil end elseif ((_G.type(click_location) == "table") and (click_location[1] == "draw")) then return app["queue-event"](app, "app", "draw", click_location) elseif ((_G.type(click_location) == "table") and (click_location[1] == "menu") and (nil ~= click_location[2]) and (click_location[3] == nil)) then local idx = click_location[2] local menu_item = click_location return app["push-state"](app, State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end








 AppState.LiftingCards.OnEvent.input["<LeftMouse>"] = function(app, _32_, pos) local location = _32_[1]
 app.state.context["drag-start"] = nil
 local _33_, _34_ = location, app.state.context["lifted-from"] if (((_G.type(_33_) == "table") and (nil ~= _33_[1]) and (nil ~= _33_[2]) and (nil ~= _33_[3])) and ((_G.type(_34_) == "table") and (_33_[1] == _34_[1]) and (_33_[2] == _34_[2]) and (_33_[3] == _34_[3]))) then local f = _33_[1] local c = _33_[2] local n = _33_[3] app.state.context["return-on-left-release"] = true




 return nil elseif (((_G.type(_33_) == "table") and (nil ~= _33_[1]) and (nil ~= _33_[2])) and ((_G.type(_34_) == "table") and (_33_[1] == _34_[1]) and (_33_[2] == _34_[2]))) then local f = _33_[1] local c = _33_[2]


 if LogicImpl.Query["liftable?"](app.game, location) then return app["switch-state"](app, AppState.LiftingCards, {["lifted-from"] = location}) else return nil end elseif ((nil ~= _33_) and (nil ~= _34_)) then local to = _33_ local from = _34_




 if LogicImpl.Query["droppable?"](app.game, location) then
 local function _36_(...) local _37_, _38_ = ... if ((nil ~= _37_) and (nil ~= _38_)) then local next_game = _37_ local moves = _38_

 local after local function _39_() app["update-game"](app, next_game, {"move", from, to}) app["switch-state"](app, AppState.Default) app["queue-event"](app, "app", "noop") return app["queue-event"](app, "app", "maybe-auto-move") end after = _39_ local timeline = app["build-event-animation"](app, moves, after) return app["switch-state"](app, AppState.Animating, timeline) else local __85_auto = _37_ return ... end end return _36_(LogicImpl.Action.move(app.game, from, to)) else return nil end else return nil end end







 AppState.LiftingCards.OnEvent.input["<LeftRelease>"] = function(app, _43_, pos) local location = _43_[1]
 local _44_, _45_ = location, app.state.context["lifted-from"] if (((_G.type(_44_) == "table") and (nil ~= _44_[1]) and (nil ~= _44_[2]) and (nil ~= _44_[3])) and ((_G.type(_45_) == "table") and (_44_[1] == _45_[1]) and (_44_[2] == _45_[2]) and (_44_[3] == _45_[3]))) then local f = _44_[1] local c = _44_[2] local n = _44_[3]

 if app.state.context["return-on-left-release"] then return app["switch-state"](app, AppState.Default) else return nil end else return nil end end


 AppState.LiftingCards.OnEvent.input["<RightMouse>"] = function(app, _, _0) return app["switch-state"](app, AppState.Default) end


 AppState.LiftingCards.OnEvent.input["<LeftDrag>"] = function(app, _48_, pos) local location = _48_[1]
 if not app.state.context["drag-start"] then
 table.merge(app.state.context, {["drag-start"] = {location = location, position = pos}}) else end
 local context = app.state.context
 local _50_, _51_ = pos, app.state.context["drag-start"].position if (((_G.type(_50_) == "table") and (nil ~= _50_.row) and (nil ~= _50_.col)) and ((_G.type(_51_) == "table") and (_50_.row == _51_.row) and (_50_.col == _51_.col))) then local row = _50_.row local col = _50_.col
 return nil else local _ = _50_
 local _52_, _53_, _54_ = location, context["lifted-from"], context["drag-start"].location if (true and ((_G.type(_53_) == "table") and (nil ~= _53_[1]) and (nil ~= _53_[2]) and (nil ~= _53_[3])) and ((_G.type(_54_) == "table") and (_53_[1] == _54_[1]) and (_53_[2] == _54_[2]) and (_53_[3] == _54_[3]))) then local _0 = _52_ local f = _53_[1] local c = _53_[2] local n = _53_[3] return app["switch-state"](app, AppState.DraggingCards, table.merge(context, {drag = {location = location, position = pos}})) else return nil end end end






 AppState.DraggingCards.OnEvent.input["<LeftDrag>"] = function(app, _57_, pos) local location = _57_[1]
 app.state.context.drag.position = pos
 app.state.context.drag.location = location return nil end





 AppState.DraggingCards.OnEvent.input["<LeftRelease>"] = function(app, _58_, pos) local _ = _58_[1] local location = _58_[2]
 if LogicImpl.Query["droppable?"](app.game, location) then
 local function _59_(...) local _60_, _61_ = ... if ((nil ~= _60_) and (nil ~= _61_)) then local from = _60_ local to = _61_ local function _62_(...) local _63_, _64_ = ... if ((nil ~= _63_) and true) then local next_game = _63_ local _moves = _64_ app["update-game"](app, next_game, {"move", from, to}) app["queue-event"](app, "app", "noop") return app["queue-event"](app, "app", "maybe-auto-move") elseif ((_63_ == nil) and (nil ~= _64_)) then local err = _64_ return app:notify(err) else return nil end end return _62_(LogicImpl.Action.move(app.game, from, to)) elseif ((_60_ == nil) and (nil ~= _61_)) then local err = _61_ return app:notify(err) else return nil end end _59_(app.state.context["lifted-from"], location) else end return app["switch-state"](app, AppState.Default) end










 AppState.Default.tick = function(app)
 for location, card in LogicImpl["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card) end return nil end


 AppState.LiftingCards.tick = function(app)
 for location, card in LogicImpl["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id]
 local _68_, _69_ = location, app.state.context["lifted-from"] local and_70_ = (((_G.type(_68_) == "table") and (nil ~= _68_[1]) and (nil ~= _68_[2]) and (nil ~= _68_[3])) and ((_G.type(_69_) == "table") and (_68_[1] == _69_[1]) and (_68_[2] == _69_[2]) and (nil ~= _69_[3]))) if and_70_ then local f = _68_[1] local c = _68_[2] local card_n = _68_[3] local lift_n = _69_[3] and_70_ = (lift_n <= card_n) end if and_70_ then local f = _68_[1] local c = _68_[2] local card_n = _68_[3] local lift_n = _69_[3]

 local _let_72_ = app["location->position"](app, {f, c, card_n}) local row = _let_72_["row"] local col = _let_72_["col"] local z = _let_72_["z"] comp:update(location, card) comp["set-position"](comp, {row = row, col = (col + 1), z = app["z-index-for-layer"](app, "lift", z)}) else local _ = _68_ comp:update(location, card) end end return nil end






 AppState.DraggingCards.tick = function(app)
 for location, card in LogicImpl["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id]
 local _74_, _75_ = location, app.state.context["lifted-from"] local and_76_ = (((_G.type(_74_) == "table") and (nil ~= _74_[1]) and (nil ~= _74_[2]) and (nil ~= _74_[3])) and ((_G.type(_75_) == "table") and (_74_[1] == _75_[1]) and (_74_[2] == _75_[2]) and (nil ~= _75_[3]))) if and_76_ then local f = _74_[1] local c = _74_[2] local card_n = _74_[3] local lift_n = _75_[3] and_76_ = (lift_n <= card_n) end if and_76_ then local f = _74_[1] local c = _74_[2] local card_n = _74_[3] local lift_n = _75_[3]

 local _let_78_ = app["location->position"](app, {f, c, card_n}) local z = _let_78_["z"]
 local row = app.state.context.drag.position["row"] local col = app.state.context.drag.position["col"] comp:update(location, card) comp["set-position"](comp, {row = (row + 0 + ((card_n - lift_n) * 2)), col = (col - 3), z = app["z-index-for-layer"](app, "lift", comp.z)}) else local _ = _74_ comp:update(location, card) end end return nil end






 AppState.GameEnded.OnEvent.input["<LeftMouse>"] = function(app, _80_, pos) local location = _80_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end



 AppState.GameEnded.activated = function(app)
 app["ended-at"] = os.time() app:save((os.time() .. "-win")) app["update-statistics"](app)


 do local _let_82_ = app["game-ended-data"](app) local key = _let_82_[1] local other = _let_82_[2] app.components["game-report"]:update(key, other) end

 return app end

 return AppState end

 return M