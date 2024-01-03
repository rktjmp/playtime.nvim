
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
 local priv = {}
 local Logic = require("playtime.game.the-emissary.logic")

 local AppState = {}

 AppState.Default = App.State.build("Default", {delegate = {app = App.State.DefaultAppState}})

 AppState.DealPhase = App.State.build("DealPhase", {delegate = {app = AppState.Default}})
 AppState.PickKingdomPhase = App.State.build("PickKingdomPhase", {delegate = {app = AppState.Default}})

 AppState.PreparePhase = App.State.build("PreparePhase", {delegate = {app = AppState.Default}})
 AppState.RulerPhase = App.State.build("RulerPhase", {delegate = {app = AppState.Default}})
 AppState.RespondPhase = App.State.build("RespondPhase", {delegate = {app = AppState.Default}})
 AppState.FinishKingdom = App.State.build("FinishKingdom", {delegate = {app = AppState.Default}})
 AppState.AbilityDiplomacy = App.State.build("AbilityDiplomacy", {delegate = {app = AppState.Default}})
 AppState.AbilityMilitary = App.State.build("AbilityMilitary", {delegate = {app = AppState.Default}})
 AppState.AbilityPolitics = App.State.build("AbilityPolitics", {delegate = {app = AppState.Default}})
 AppState.AbilityCommerce = App.State.build("AbilityCommerce", {delegate = {app = AppState.Default}})
 AppState.GameEnded = App.State.build("GameEnded", {delegate = {app = AppState.Default}})

 AppState.Default.OnEvent.app["new-game"] = function(app) app["setup-new-game"](app, app["game-config"], nil)

 local function _3_() return app["switch-state"](app, AppState.DealPhase) end return vim.defer_fn(_3_, 300) end

 AppState.Default.OnEvent.app["restart-game"] = function(app) app["setup-new-game"](app, app["game-config"], app.seed)

 local function _4_() return app["switch-state"](app, AppState.DealPhase) end return vim.defer_fn(_4_, 300) end

 AppState.Default.OnEvent.input["<LeftMouse>"] = function(app, _5_, pos) local _arg_6_ = _5_ local click_location = _arg_6_[1] local rest = (function (t, k, e) local mt = getmetatable(t) if 'table' == type(mt) and mt.__fennelrest then return mt.__fennelrest(t, k) elseif e then local rest = {} for k, v in pairs(t) do if not e[k] then rest[k] = v end end return rest else return {(table.unpack or unpack)(t, k)} end end)(_arg_6_, 2)
 if ((_G.type(click_location) == "table") and (click_location[1] == "menu") and (nil ~= click_location[2]) and (click_location[3] == nil)) then local idx = click_location[2] local menu_item = click_location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end



 AppState.GameEnded.activated = function(app)
 app["ended-at"] = os.time()
 local _let_8_ = Logic.Query["game-result"](app.game) local won_3f = _let_8_[1] local score = _let_8_[2]
 local other = {string.fmt("Time: %ds", (app["ended-at"] - app["started-at"])), string.fmt("Score: %d/16", score)}

 if won_3f then app["update-statistics"](app) else end return (app.components["game-report"]):update(won_3f, other) end


 AppState.GameEnded.OnEvent.input["<LeftMouse>"] = function(app, _10_, pos) local _arg_11_ = _10_ local location = _arg_11_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu")) then
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end




 AppState.AbilityDiplomacy.activated = function(app, which_advisor) do end (app.components["guide-text"]):update("Discarding cards in rulers suit...")

 local next_game, events = Logic.Action.diplomacy(app.game, which_advisor) local after
 local function _13_() app["update-game"](app, next_game, {"diplomacy", which_advisor}) return app["switch-state"](app, AppState.RulerPhase) end after = _13_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end









 AppState.AbilityMilitary.activated = function(app, which_advisor) do end (app.components["guide-text"]):update("Drawing cards for each club in hand...")

 local next_game, events = Logic.Action.military(app.game, which_advisor) local after
 local function _14_() app["update-game"](app, next_game, {"military", which_advisor}) return app["switch-state"](app, AppState.RulerPhase) end after = _14_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end









 AppState.AbilityPolitics.activated = function(app, which_advisor) do end (app.components["guide-text"]):update("Select kingdom ruler to swap with current ruler...")

 app.state.context = {["which-advisor"] = which_advisor} return nil end

 AppState.AbilityPolitics.OnEvent.input["<LeftMouse>"] = function(app, _15_) local _arg_16_ = _15_ local location = _arg_16_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and (location[3] == 1)) then local n = location[2]
 app.state.context.selecting = {"kingdom", n} return nil elseif ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end



 AppState.AbilityPolitics.OnEvent.input["<LeftDrag>"] = function(app, _18_) local _arg_19_ = _18_ local location = _arg_19_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and (location[3] == 1)) then local n = location[2]
 app.state.context.selecting = {"kingdom", n} return nil else return nil end end

 AppState.AbilityPolitics.OnEvent.input["<LeftRelease>"] = function(app, _21_) local _arg_22_ = _21_ local location = _arg_22_[1]
 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and (location[3] == 1)) then local n = location[2]
 local _let_23_ = app.state.context local which_advisor = _let_23_["which-advisor"]
 local next_game, events = Logic.Action.politics(app.game, which_advisor, n) local after
 local function _24_() app["update-game"](app, next_game, {"politics", which_advisor}) return app["switch-state"](app, AppState.RulerPhase) end after = _24_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) else local _ = location




 app.state.context.selecting = nil return nil end end





 AppState.AbilityCommerce.activated = function(app, which_advisor) do end (app.components["guide-text"]):update("Drawing two cards, select two cards to discard...")

 app.state.context = {["which-advisor"] = which_advisor, selected = {hand = {}}, selecting = nil}


 local next_game, events = Logic.Action.commerce(app.game, which_advisor) local after
 local function _26_() app["update-game"](app, next_game, {"commerce", which_advisor}) return app["pop-state"](app) end after = _26_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["push-state"](app, App.State.DefaultAnimatingState, timeline) end





 AppState.AbilityCommerce.OnEvent.input["<LeftMouse>"] = function(app, _27_) local _arg_28_ = _27_ local location = _arg_28_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 app.state.context.selecting = {"hand", n} return nil elseif ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end



 AppState.AbilityCommerce.OnEvent.input["<LeftDrag>"] = function(app, _30_) local _arg_31_ = _30_ local location = _arg_31_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 app.state.context.selecting = {"hand", n} return nil else return nil end end

 AppState.AbilityCommerce.OnEvent.input["<LeftRelease>"] = function(app, _33_) local _arg_34_ = _33_ local location = _arg_34_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 local _let_35_ = app.state.context local which_advisor = _let_35_["which-advisor"] local selected = _let_35_["selected"] local _
 local _36_ if (nil == selected.hand[n]) then _36_ = true else _36_ = nil end selected.hand[n] = _36_ _ = nil
 local ns = table.keys(selected.hand)
 if (2 == #ns) then
 local next_game, events = Logic.Action.commerce(app.game, which_advisor, ns) local after
 local function _38_() app["update-game"](app, next_game, {"commerce", which_advisor, ns}) return app["switch-state"](app, AppState.RulerPhase) end after = _38_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) else return nil end else return nil end end









 AppState.DealPhase.activated = function(app) do end (app.components["guide-text"]):update("Select a kingdom to visit...")

 local next_game, events = Logic.Action.deal(app.game) local after
 local function _41_() app["update-game"](app, next_game, {"deal"}) return app["switch-state"](app, AppState.PickKingdomPhase) end after = _41_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end









 local function try_ability(app, suit, n)

 local map = {hearts = {"diplomacy", AppState.AbilityDiplomacy}, clubs = {"military", AppState.AbilityMilitary}, spades = {"politics", AppState.AbilityPolitics}, diamonds = {"commerce", AppState.AbilityCommerce}}



 local _let_42_ = map[suit] local action = _let_42_[1] local state = _let_42_[2]
 local _43_, _44_ = Logic.Query[action](app.game, n) if (_43_ == true) then return app["switch-state"](app, state, n) elseif ((_43_ == nil) and (nil ~= _44_)) then local err = _44_ return app:notify(err) else return nil end end



 AppState.PickKingdomPhase.OnEvent.input["<LeftMouse>"] = function(app, _46_, pos) local _arg_47_ = _46_ local location = _arg_47_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and (location[3] == 1)) then local n = location[2]
 app.state.context.selecting = {"kingdom", n} return nil else return nil end end

 AppState.PickKingdomPhase.OnEvent.input["<LeftDrag>"] = function(app, _49_, pos) local _arg_50_ = _49_ local location = _arg_50_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and (location[3] == 1)) then local n = location[2]
 app.state.context.selecting = {"kingdom", n} return nil else return nil end end

 AppState.PickKingdomPhase.OnEvent.input["<LeftRelease>"] = function(app, _52_, pos) local _arg_53_ = _52_ local location = _arg_53_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and true) then local n = location[2] local _ = location[3]

 local function _54_(...) local _55_, _56_ = ... if (nil ~= _55_) then local next_game = _55_

 local _let_57_ = app["location->position"](app, {"kingdom", n}) local row = _let_57_["row"] local col = _let_57_["col"] local z = _let_57_["z"] do end (function(tgt, m, ...) return tgt[m](tgt, ...) end)(app.components.emissary, "set-position", {row = (row + 1), col = (col - 1), z = (z + 1)}) return app["update-game"](app, next_game, {"pick-kingdom", n}) elseif ((_55_ == nil) and (nil ~= _56_)) then local e = _56_ return app:notify(e) else return nil end end return _54_(Logic.Action["pick-kingdom"](app.game, n)) elseif ((_G.type(location) == "table") and (location[1] == "draw")) then





 if app.game["at-kingdom"] then return app["switch-state"](app, AppState.RulerPhase) else return nil end elseif ((_G.type(location) == "table") and (location[1] == "hand")) then
 if app.game["at-kingdom"] then return app["switch-state"](app, AppState.RulerPhase) else return nil end elseif ((_G.type(location) == "table") and (location[1] == "advisor") and (nil ~= location[2]) and (nil ~= location[3])) then local suit = location[2] local n = location[3]
 if app.game["at-kingdom"] then return try_ability(app, suit, n) else return nil end elseif ((_G.type(location) == "table") and (location[1] == "menu")) then
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end





 AppState.PreparePhase.activated = function(app) return (app.components["guide-text"]):update("Activate an ability or click deck/hand for ruler turn") end


 AppState.PreparePhase.OnEvent.input["<LeftMouse>"] = function(app, _63_, pos) local _arg_64_ = _63_ local location = _arg_64_[1]
 if ((_G.type(location) == "table") and (location[1] == "draw")) then return app["switch-state"](app, AppState.RulerPhase) elseif ((_G.type(location) == "table") and (location[1] == "hand")) then return app["switch-state"](app, AppState.RulerPhase) elseif ((_G.type(location) == "table") and (location[1] == "advisor") and (nil ~= location[2]) and (nil ~= location[3])) then local suit = location[2] local n = location[3]


 return try_ability(app, suit, n) elseif ((_G.type(location) == "table") and (location[1] == "menu")) then
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end





 AppState.RulerPhase.activated = function(app)
 if Logic.Query["hand-exhausted?"](app.game) then return app["switch-state"](app, AppState.FinishKingdom) else

 local function _66_(...) local _67_, _68_ = ... if ((nil ~= _67_) and (nil ~= _68_)) then local next_game = _67_ local moves = _68_

 local after local function _69_() app["update-game"](app, next_game, {"draw"}) return app["switch-state"](app, AppState.RespondPhase) end after = _69_ local timeline = app["build-event-animation"](app, moves, after) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_67_ == nil) and (nil ~= _68_)) then local e = _68_ return app:notify(e) else return nil end end return _66_(Logic.Action.draw(app.game)) end end











 AppState.RespondPhase.activated = function(app) return (app.components["guide-text"]):update("Select card to respond") end


 AppState.RespondPhase.OnEvent.input["<LeftMouse>"] = function(app, _72_, pos) local _arg_73_ = _72_ local location = _arg_73_[1] app.state.context.safe = true



 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 app.state.context.selecting = {"hand", n} return nil elseif ((_G.type(location) == "table") and (location[1] == "menu")) then
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end

 AppState.RespondPhase.OnEvent.input["<LeftDrag>"] = function(app, _75_, pos) local _arg_76_ = _75_ local location = _arg_76_[1]
 if app.state.context.safe then
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 app.state.context.selecting = {"hand", n} return nil else return nil end else return nil end end

 AppState.RespondPhase.OnEvent.input["<LeftRelease>"] = function(app, _79_, pos) local _arg_80_ = _79_ local location = _arg_80_[1]
 if app.state.context.safe then
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 local function _81_(...) local _82_, _83_ = ... if ((nil ~= _82_) and (nil ~= _83_)) then local next_game = _82_ local moves = _83_

 local _ = table.insert(moves, 2, {"wait", 300}) local after
 local function _84_() app["update-game"](app, next_game, {"play-hand", n})

 if Logic.Query["hand-exhausted?"](app.game) then return app["switch-state"](app, AppState.FinishKingdom) else return app["switch-state"](app, AppState.PreparePhase) end end after = _84_ local timeline = app["build-event-animation"](app, moves, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_82_ == nil) and (nil ~= _83_)) then local e = _83_ return app:notify(e) else return nil end end return _81_(Logic.Action["play-hand"](app.game, n)) elseif ((_G.type(location) == "table") and (location[1] == "advisor")) then return app:notify("You may only activate a advisor before a ruler statement") else return nil end else return nil end end








 AppState.FinishKingdom.activated = function(app)
 local next_game, events = Logic.Action["finish-kingdom"](app.game) local after
 local function _89_() app["update-game"](app, next_game, {"finish-kingdom"})

 if Logic.Query["game-ended?"](app.game) then return app["switch-state"](app, AppState.GameEnded) else return app["switch-state"](app, AppState.DealPhase) end end after = _89_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end









 local function update_card_counts(app) do end (app.components["card-counts"].draw):update(#app.game.draw) do end (app.components["card-counts"].discard):update(#app.game.discard) return (app.components["card-counts"].score):update(#app.game.score) end




 M["build-event-animation"] = function(app, events, after, _3fopts, _3fhand_length)
 if _3fhand_length then
 local proxy local function _91_(_241, _242) return app["location->position"](app, _242, _3fhand_length) end proxy = setmetatable({["location->position"] = _91_}, {__index = app})

 return CardUtils["build-event-animation"](proxy, events, after, _3fopts) else
 return CardUtils["build-event-animation"](app, events, after, _3fopts) end end

 M["location->position"] = function(app, location, _3fhand_length)
 local config = {card = {margin = {row = 1, col = 1}, width = 7, height = 5}}

 local card_col_step = (config.card.width + config.card.margin.col + 2)
 local kingdom = {row = 2, col = 3}
 local draw = {row = 8, col = 38}
 local discard = {row = 8, col = (draw.col - card_col_step)}
 local debate = {row = 8, col = draw.col}
 local score = {row = 8, col = (draw.col + card_col_step)}
 local hand = {row = 14, col = 28}
 local advisor = {row = 20, col = 23} local hand_offset
 do local _93_ = (_3fhand_length or #app.game.hand) if (_93_ == 0) then
 hand.col = draw.col hand_offset = nil elseif (_93_ == 1) then
 hand.col = draw.col hand_offset = nil elseif (nil ~= _93_) then local n = _93_
 hand.col = (draw.col - (2 * (n - 1))) hand_offset = nil else hand_offset = nil end end

 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and true) then local n = location[2] local _ = location[3]
 return {row = kingdom.row, col = (kingdom.col + (card_col_step * (n - 1))), z = app["z-index-for-layer"](app, "cards")} elseif ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]


 return {row = hand.row, col = (hand.col + (4 * (n - 1))), z = app["z-index-for-layer"](app, "hand", n)} elseif ((_G.type(location) == "table") and (location[1] == "debate") and (nil ~= location[2])) then local c = location[2]



 local _95_ if (c == 1) then
 _95_ = (debate.col - 2) elseif (c == 2) then
 _95_ = (debate.col + 2) else local _ = c _95_ = 0 end return {row = debate.row, col = _95_, z = app["z-index-for-layer"](app, "debate", ((1 * 10) + c))} elseif ((_G.type(location) == "table") and (location[1] == "discard") and (nil ~= location[2])) then local c = location[2]


 return {row = discard.row, col = discard.col, z = app["z-index-for-layer"](app, "cards", c)} elseif ((_G.type(location) == "table") and (location[1] == "draw") and (nil ~= location[2])) then local c = location[2]


 return {row = draw.row, col = draw.col, z = app["z-index-for-layer"](app, "cards", c)} elseif ((_G.type(location) == "table") and (location[1] == "score") and (nil ~= location[2])) then local c = location[2]



 return {row = score.row, col = score.col, z = app["z-index-for-layer"](app, "cards", c)} elseif ((_G.type(location) == "table") and (location[1] == "advisor") and (location[2] == "hearts") and (location[3] == "label")) then



 return {row = (advisor.row - 0), col = (advisor.col + 1), z = app["z-index-for-layer"](app, "label")} elseif ((_G.type(location) == "table") and (location[1] == "advisor") and (location[2] == "hearts") and (nil ~= location[3])) then local n = location[3]


 return {row = (advisor.row + ((n - 1) * 2)), col = advisor.col, z = n} elseif ((_G.type(location) == "table") and (location[1] == "advisor") and (location[2] == "clubs") and (location[3] == "label")) then



 return {row = (advisor.row - 0), col = (advisor.col + (1 * card_col_step) + 1), z = app["z-index-for-layer"](app, "label")} elseif ((_G.type(location) == "table") and (location[1] == "advisor") and (location[2] == "clubs") and (nil ~= location[3])) then local n = location[3]


 return {row = (advisor.row + ((n - 1) * 2)), col = (advisor.col + (1 * card_col_step)), z = n} elseif ((_G.type(location) == "table") and (location[1] == "advisor") and (location[2] == "spades") and (location[3] == "label")) then



 return {row = (advisor.row - 0), col = (advisor.col + 1 + (2 * card_col_step)), z = app["z-index-for-layer"](app, "label")} elseif ((_G.type(location) == "table") and (location[1] == "advisor") and (location[2] == "spades") and (nil ~= location[3])) then local n = location[3]


 return {row = (advisor.row + ((n - 1) * 2)), col = (advisor.col + (2 * card_col_step)), z = n} elseif ((_G.type(location) == "table") and (location[1] == "advisor") and (location[2] == "diamonds") and (location[3] == "label")) then



 return {row = (advisor.row - 0), col = (advisor.col + 1 + (3 * card_col_step)), z = app["z-index-for-layer"](app, "label")} elseif ((_G.type(location) == "table") and (location[1] == "advisor") and (location[2] == "diamonds") and (nil ~= location[3])) then local n = location[3]


 return {row = (advisor.row + ((n - 1) * 2)), col = (advisor.col + (3 * card_col_step)), z = n} else local _ = location



 return error(Error("Unable to convert location to position, unknown location #{location}", {location = location})) end end


 M.start = function(app_config, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/the-emissary/app.fnl:384") _G.assert((nil ~= app_config), "Missing argument app-config on fnl/playtime/game/the-emissary/app.fnl:384")
 local app = setmetatable(App.build("The Emissary", "the-emissary", app_config, game_config), {__index = M})




 local view = Window.open("the-emissary", App["build-default-window-dispatch-options"](app), {width = 83, height = 32, ["window-position"] = app_config["window-position"], ["minimise-position"] = app_config["minimise-position"]})





 local _ = table.merge(app["z-layers"], {cards = 25, kingdom = 25, debate = 90, label = 100, hand = 100, animation = 200})
 app.view = view
 app["card-style"] = {width = 7, height = 5, colors = 4, stacking = "horizontal-left"} app["setup-new-game"](app, app["game-config"], _3fseed) return app:render() end



 M["setup-new-game"] = function(app, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/the-emissary/app.fnl:402") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/the-emissary/app.fnl:402") app["new-game"](app, Logic.build, game_config, _3fseed) app["build-components"](app) app["switch-state"](app, AppState.Default)



 local function _101_() return app["switch-state"](app, AppState.DealPhase) end vim.defer_fn(_101_, 300)
 return app end

 M["build-components"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/the-emissary/app.fnl:409")
 local function build_emissary(position)
 return Component["set-position"](Component["set-size"](Component["set-content"](Component.build(), {{{"\240\159\174\178\240\159\174\179", "@playtime.ui.on"}}}), {width = 2, height = 1}), {row = 13, col = 41}) end



 local function build_label(text, position)
 local _let_102_ = position local row = _let_102_["row"] local col = _let_102_["col"] local z = _let_102_["z"]

 local function _103_(self, enabled)
 local hl if enabled then hl = "@playtime.ui.on" else hl = "@playtime.ui.off" end return self["set-content"](self, {{{text, hl}}}) end return Component["set-content"](Component["set-size"](Component["set-position"](Component.build(_103_), position), {width = #text, height = 1}), {{{text, "@playtime.ui.off"}}}) end




 local card_card_components do local tbl_14_auto = {} for location, card in Logic["iter-cards"](app.game) do local k_15_auto, v_16_auto = nil, nil
 do local card_style if (8 < Logic["card-value"](card)) then
 card_style = table.set(clone(app["card-style"]), "stacking", "vertical-down") else

 card_style = app["card-style"] end local comp
 local function _106_(...) return app["location->position"](app, ...) end comp = CardComponents.card(_106_, location, card, card_style)



 k_15_auto, v_16_auto = card.id, comp end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end card_card_components = tbl_14_auto end
 local menubar = CommonComponents.menubar({{"The Emissary", {"file"}, {{"", nil}, {"New Game", {"new-game"}}, {"Restart Game", {"restart-game"}}, {"", nil}, {"Quit", {"quit"}}, {"", nil}, {string.format("Seed: %s", app.seed), nil}}}}, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar")}) local card_counts














 do local tbl_14_auto = {} for _, key in ipairs({"draw", "discard", "score"}) do local k_15_auto, v_16_auto = nil, nil


 local function _108_() return app["z-index-for-layer"](app, "label") end k_15_auto, v_16_auto = key, CardComponents.count(table["update-in"](app["location->position"](app, {key, 0}), {"z"}, _108_), app["card-style"]) if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end card_counts = tbl_14_auto end local win_needed_labels

 do local pos local function _110_(n) local _111_ = app["location->position"](app, {"kingdom", n})

 local function _112_(_241) return (_241 + 4) end table["update-in"](_111_, {"row"}, _112_)
 local function _113_(_241) return (_241 + 2) end table["update-in"](_111_, {"col"}, _113_)
 local function _114_(_241) return (_241 + 5) end table["update-in"](_111_, {"z"}, _114_) return _111_ end pos = _110_
 local tbl_18_auto = {} local i_19_auto = 0 for n = 1, 8 do
 local val_20_auto = build_label((" " .. tostring(n) .. " "), pos(n)) if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end win_needed_labels = tbl_18_auto end
 local advisors = {hearts = "dip.", clubs = "mil.", spades = "pol.", diamonds = "com."} local advisor_titles
 do local tbl_18_auto = {} local i_19_auto = 0 for suit, short_name in pairs(advisors) do
 local val_20_auto = build_label(short_name, app["location->position"](app, {"advisor", suit, "label"})) if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end advisor_titles = tbl_18_auto end local empty_fields
 do local base = {} for _, _117_ in ipairs({{"kingdom", 8}, {"draw", 1}, {"discard", 1}, {"score", 1}}) do local _each_118_ = _117_ local field = _each_118_[1] local count = _each_118_[2]



 local tbl_17_auto = base for i = 1, count do
 local function _119_(...) return table.set(app["location->position"](app, ...), "z", app["z-index-for-layer"](app, "base")) end table.insert(tbl_17_auto, CardComponents.slot(_119_, {field, i, 0}, app["card-style"])) end base = tbl_17_auto end empty_fields = base end local empty_fields0



 do local tbl_17_auto = empty_fields for _, t in ipairs(advisors) do
 local function _120_(...) return table.set(app["location->position"](app, ...), "z", app["z-index-for-layer"](app, "base")) end table.insert(tbl_17_auto, CardComponents.slot(_120_, {"advisor", t, 0}, app["card-style"])) end empty_fields0 = tbl_17_auto end



 local game_report = CommonComponents["game-report"](app.view.width, app.view.height, app["z-index-for-layer"](app, "report"), {{true, "The land is in concord."}, {false, "The land remains fractured."}}) local guide_text





 local function _121_(self, text) self["set-content"](self, {{{text, "@playtime.ui.off"}}}) self["set-position"](self, {row = 30, col = math.floor(((app.view.width / 2) - (#text / 2))), z = app["z-index-for-layer"](app, "label")}) return self["set-size"](self, {width = #text, height = 1}) end guide_text = Component.build(_121_):update("Select a kingdom") local win_count







 do local _let_122_ = app["fetch-statistics"](app) local wins = _let_122_["wins"]
 win_count = CommonComponents["win-count"](wins, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar", 1)}) end


 local emissary = build_emissary()
 app["card-id->components"] = card_card_components
 table.merge(app.components, {["empty-fields"] = empty_fields0, menubar = menubar, emissary = emissary, ["guide-text"] = guide_text, ["game-report"] = game_report, ["card-counts"] = card_counts, ["win-count"] = win_count, ["win-needed-labels"] = win_needed_labels, cards = table.values(card_card_components), ["advisor-titles"] = advisor_titles})










 return update_card_counts(app) end

 M.render = function(app) do end (app.view):render({app.components["empty-fields"], app.components["advisor-titles"], app.components.cards, app.components["win-needed-labels"], {app.components.emissary, app.components["guide-text"], app.components["card-counts"].discard, app.components["card-counts"].draw, app.components["card-counts"].score, app.components["game-report"], app.components["win-count"], app.components.menubar}})












 return app end

 M.tick = function(app)
 local now = uv.now() app["process-next-event"](app)

 do local _123_ = app.state.module.tick if (nil ~= _123_) then local f = _123_
 f(app) else local _ = _123_
 local adjustment do local t = {}
 for key, vals in pairs((app.state.context.selected or {})) do
 for i, _0 in pairs(vals) do
 table.set(t, string.fmt("%s.%s", key, i), {key, i}) end end
 do local _124_ = app.state.context.selecting if ((_G.type(_124_) == "table") and (nil ~= _124_[1]) and (nil ~= _124_[2])) then local key = _124_[1] local v = _124_[2]
 table.set(t, string.fmt("%s.%s", key, v), {key, v}) else end end

 adjustment = table.values(t) end
 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card)

 for _0, marked in ipairs(adjustment) do
 local _126_, _127_ = location, marked if (((_G.type(_126_) == "table") and (nil ~= _126_[1]) and (nil ~= _126_[2])) and ((_G.type(_127_) == "table") and (_126_[1] == _127_[1]) and (_126_[2] == _127_[2]))) then local f = _126_[1] local n = _126_[2] comp["set-position"](comp, {row = (comp.row - 1)}) else end end end end end

 update_card_counts(app) return app["request-render"](app) end


 M["update-statistics"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/the-emissary/app.fnl:548")
 local function update(d)
 local data = table.merge({version = 1, wins = 0, games = {}}, d)
 data.wins = (data.wins + 1)
 data.games = table.insert(data.games, {seed = app.seed, time = ((app["ended-at"] or app["started-at"]) - app["started-at"])})


 return data end
 return App["update-statistics"](app, update) end

 return M