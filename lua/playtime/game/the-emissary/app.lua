
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

 local function _2_() return app["switch-state"](app, AppState.DealPhase) end return vim.defer_fn(_2_, 300) end

 AppState.Default.OnEvent.app["restart-game"] = function(app) app["setup-new-game"](app, app["game-config"], app.seed)

 local function _3_() return app["switch-state"](app, AppState.DealPhase) end return vim.defer_fn(_3_, 300) end

 AppState.Default.OnEvent.input["<LeftMouse>"] = function(app, _4_, pos) local click_location = _4_[1] local rest = (function (t, k, e) local mt = getmetatable(t) if 'table' == type(mt) and mt.__fennelrest then return mt.__fennelrest(t, k) elseif e then local rest = {} for k, v in pairs(t) do if not e[k] then rest[k] = v end end return rest else return {(table.unpack or unpack)(t, k)} end end)(_4_, 2)
 if ((_G.type(click_location) == "table") and (click_location[1] == "menu") and (nil ~= click_location[2]) and (click_location[3] == nil)) then local idx = click_location[2] local menu_item = click_location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end



 AppState.GameEnded.activated = function(app)
 app["ended-at"] = os.time()
 local _let_6_ = Logic.Query["game-result"](app.game) local won_3f = _let_6_[1] local score = _let_6_[2]
 local other = {string.fmt("Time: %ds", (app["ended-at"] - app["started-at"])), string.fmt("Score: %d/16", score)}

 if won_3f then app["update-statistics"](app) else end return app.components["game-report"]:update(won_3f, other) end


 AppState.GameEnded.OnEvent.input["<LeftMouse>"] = function(app, _8_, pos) local location = _8_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu")) then
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end




 AppState.AbilityDiplomacy.activated = function(app, which_advisor) app.components["guide-text"]:update("Discarding cards in rulers suit...")

 local next_game, events = Logic.Action.diplomacy(app.game, which_advisor) local after
 local function _10_() app["update-game"](app, next_game, {"diplomacy", which_advisor}) return app["switch-state"](app, AppState.RulerPhase) end after = _10_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end









 AppState.AbilityMilitary.activated = function(app, which_advisor) app.components["guide-text"]:update("Drawing cards for each club in hand...")

 local next_game, events = Logic.Action.military(app.game, which_advisor) local after
 local function _11_() app["update-game"](app, next_game, {"military", which_advisor}) return app["switch-state"](app, AppState.RulerPhase) end after = _11_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end









 AppState.AbilityPolitics.activated = function(app, which_advisor) app.components["guide-text"]:update("Select kingdom ruler to swap with current ruler...")

 app.state.context = {["which-advisor"] = which_advisor} return nil end

 AppState.AbilityPolitics.OnEvent.input["<LeftMouse>"] = function(app, _12_) local location = _12_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and (location[3] == 1)) then local n = location[2]
 app.state.context.selecting = {"kingdom", n} return nil elseif ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end



 AppState.AbilityPolitics.OnEvent.input["<LeftDrag>"] = function(app, _14_) local location = _14_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and (location[3] == 1)) then local n = location[2]
 app.state.context.selecting = {"kingdom", n} return nil else return nil end end

 AppState.AbilityPolitics.OnEvent.input["<LeftRelease>"] = function(app, _16_) local location = _16_[1]
 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and (location[3] == 1)) then local n = location[2]
 local which_advisor = app.state.context["which-advisor"]
 local next_game, events = Logic.Action.politics(app.game, which_advisor, n) local after
 local function _17_() app["update-game"](app, next_game, {"politics", which_advisor}) return app["switch-state"](app, AppState.RulerPhase) end after = _17_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) else local _ = location




 app.state.context.selecting = nil return nil end end





 AppState.AbilityCommerce.activated = function(app, which_advisor) app.components["guide-text"]:update("Drawing two cards, select two cards to discard...")

 app.state.context = {["which-advisor"] = which_advisor, selected = {hand = {}}, selecting = nil}


 local next_game, events = Logic.Action.commerce(app.game, which_advisor) local after
 local function _19_() app["update-game"](app, next_game, {"commerce", which_advisor}) return app["pop-state"](app) end after = _19_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["push-state"](app, App.State.DefaultAnimatingState, timeline) end





 AppState.AbilityCommerce.OnEvent.input["<LeftMouse>"] = function(app, _20_) local location = _20_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 app.state.context.selecting = {"hand", n} return nil elseif ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local idx = location[2] local menu_item = location return app["push-state"](app, App.State.DefaultInMenuState, {["menu-item"] = menu_item}) else return nil end end



 AppState.AbilityCommerce.OnEvent.input["<LeftDrag>"] = function(app, _22_) local location = _22_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 app.state.context.selecting = {"hand", n} return nil else return nil end end

 AppState.AbilityCommerce.OnEvent.input["<LeftRelease>"] = function(app, _24_) local location = _24_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 local which_advisor = app.state.context["which-advisor"] local selected = app.state.context["selected"] local _
 local _25_ if (nil == selected.hand[n]) then _25_ = true else _25_ = nil end selected.hand[n] = _25_ _ = nil
 local ns = table.keys(selected.hand)
 if (2 == #ns) then
 local next_game, events = Logic.Action.commerce(app.game, which_advisor, ns) local after
 local function _27_() app["update-game"](app, next_game, {"commerce", which_advisor, ns}) return app["switch-state"](app, AppState.RulerPhase) end after = _27_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) else return nil end else return nil end end









 AppState.DealPhase.activated = function(app) app.components["guide-text"]:update("Select a kingdom to visit...")

 local next_game, events = Logic.Action.deal(app.game) local after
 local function _30_() app["update-game"](app, next_game, {"deal"}) return app["switch-state"](app, AppState.PickKingdomPhase) end after = _30_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end









 local function try_ability(app, suit, n)

 local map = {hearts = {"diplomacy", AppState.AbilityDiplomacy}, clubs = {"military", AppState.AbilityMilitary}, spades = {"politics", AppState.AbilityPolitics}, diamonds = {"commerce", AppState.AbilityCommerce}}



 local _let_31_ = map[suit] local action = _let_31_[1] local state = _let_31_[2]
 local _32_, _33_ = Logic.Query[action](app.game, n) if (_32_ == true) then return app["switch-state"](app, state, n) elseif ((_32_ == nil) and (nil ~= _33_)) then local err = _33_ return app:notify(err) else return nil end end



 AppState.PickKingdomPhase.OnEvent.input["<LeftMouse>"] = function(app, _35_, pos) local location = _35_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and (location[3] == 1)) then local n = location[2]
 app.state.context.selecting = {"kingdom", n} return nil else return nil end end

 AppState.PickKingdomPhase.OnEvent.input["<LeftDrag>"] = function(app, _37_, pos) local location = _37_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and (location[3] == 1)) then local n = location[2]
 app.state.context.selecting = {"kingdom", n} return nil else return nil end end

 AppState.PickKingdomPhase.OnEvent.input["<LeftRelease>"] = function(app, _39_, pos) local location = _39_[1]
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and true) then local n = location[2] local _ = location[3]

 local function _40_(...) local _41_, _42_ = ... if (nil ~= _41_) then local next_game = _41_

 local _let_43_ = app["location->position"](app, {"kingdom", n}) local row = _let_43_["row"] local col = _let_43_["col"] local z = _let_43_["z"] app.components.emissary["set-position"](app.components.emissary, {row = (row + 1), col = (col - 1), z = (z + 1)}) return app["update-game"](app, next_game, {"pick-kingdom", n}) elseif ((_41_ == nil) and (nil ~= _42_)) then local e = _42_ return app:notify(e) else return nil end end return _40_(Logic.Action["pick-kingdom"](app.game, n)) elseif ((_G.type(location) == "table") and (location[1] == "draw")) then





 if app.game["at-kingdom"] then return app["switch-state"](app, AppState.RulerPhase) else return nil end elseif ((_G.type(location) == "table") and (location[1] == "hand")) then
 if app.game["at-kingdom"] then return app["switch-state"](app, AppState.RulerPhase) else return nil end elseif ((_G.type(location) == "table") and (location[1] == "advisor") and (nil ~= location[2]) and (nil ~= location[3])) then local suit = location[2] local n = location[3]
 if app.game["at-kingdom"] then return try_ability(app, suit, n) else return nil end elseif ((_G.type(location) == "table") and (location[1] == "menu")) then
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end





 AppState.PreparePhase.activated = function(app) return app.components["guide-text"]:update("Activate an ability or click deck/hand for ruler turn") end


 AppState.PreparePhase.OnEvent.input["<LeftMouse>"] = function(app, _49_, pos) local location = _49_[1]
 if ((_G.type(location) == "table") and (location[1] == "draw")) then return app["switch-state"](app, AppState.RulerPhase) elseif ((_G.type(location) == "table") and (location[1] == "hand")) then return app["switch-state"](app, AppState.RulerPhase) elseif ((_G.type(location) == "table") and (location[1] == "advisor") and (nil ~= location[2]) and (nil ~= location[3])) then local suit = location[2] local n = location[3]


 return try_ability(app, suit, n) elseif ((_G.type(location) == "table") and (location[1] == "menu")) then
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end





 AppState.RulerPhase.activated = function(app)
 if Logic.Query["hand-exhausted?"](app.game) then return app["switch-state"](app, AppState.FinishKingdom) else

 local function _51_(...) local _52_, _53_ = ... if ((nil ~= _52_) and (nil ~= _53_)) then local next_game = _52_ local moves = _53_

 local after local function _54_() app["update-game"](app, next_game, {"draw"}) return app["switch-state"](app, AppState.RespondPhase) end after = _54_ local timeline = app["build-event-animation"](app, moves, after) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_52_ == nil) and (nil ~= _53_)) then local e = _53_ return app:notify(e) else return nil end end return _51_(Logic.Action.draw(app.game)) end end











 AppState.RespondPhase.activated = function(app) return app.components["guide-text"]:update("Select card to respond") end


 AppState.RespondPhase.OnEvent.input["<LeftMouse>"] = function(app, _57_, pos) local location = _57_[1] app.state.context.safe = true



 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 app.state.context.selecting = {"hand", n} return nil elseif ((_G.type(location) == "table") and (location[1] == "menu")) then
 return AppState.Default.OnEvent.input["<LeftMouse>"](app, {location}, pos) else return nil end end

 AppState.RespondPhase.OnEvent.input["<LeftDrag>"] = function(app, _59_, pos) local location = _59_[1]
 if app.state.context.safe then
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 app.state.context.selecting = {"hand", n} return nil else return nil end else return nil end end

 AppState.RespondPhase.OnEvent.input["<LeftRelease>"] = function(app, _62_, pos) local location = _62_[1]
 if app.state.context.safe then
 app.state.context.selecting = nil
 if ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]
 local function _63_(...) local _64_, _65_ = ... if ((nil ~= _64_) and (nil ~= _65_)) then local next_game = _64_ local moves = _65_

 local _ = table.insert(moves, 2, {"wait", 300}) local after
 local function _66_() app["update-game"](app, next_game, {"play-hand", n})

 if Logic.Query["hand-exhausted?"](app.game) then return app["switch-state"](app, AppState.FinishKingdom) else return app["switch-state"](app, AppState.PreparePhase) end end after = _66_ local timeline = app["build-event-animation"](app, moves, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) elseif ((_64_ == nil) and (nil ~= _65_)) then local e = _65_ return app:notify(e) else return nil end end return _63_(Logic.Action["play-hand"](app.game, n)) elseif ((_G.type(location) == "table") and (location[1] == "advisor")) then return app:notify("You may only activate a advisor before a ruler statement") else return nil end else return nil end end








 AppState.FinishKingdom.activated = function(app)
 local next_game, events = Logic.Action["finish-kingdom"](app.game) local after
 local function _71_() app["update-game"](app, next_game, {"finish-kingdom"})

 if Logic.Query["game-ended?"](app.game) then return app["switch-state"](app, AppState.GameEnded) else return app["switch-state"](app, AppState.DealPhase) end end after = _71_ local timeline = app["build-event-animation"](app, events, after, {}, #next_game.hand) return app["switch-state"](app, App.State.DefaultAnimatingState, timeline) end









 local function update_card_counts(app) app.components["card-counts"].draw:update(#app.game.draw) app.components["card-counts"].discard:update(#app.game.discard) return app.components["card-counts"].score:update(#app.game.score) end




 M["build-event-animation"] = function(app, events, after, _3fopts, _3fhand_length)
 if _3fhand_length then
 local proxy local function _73_(_241, _242) return app["location->position"](app, _242, _3fhand_length) end proxy = setmetatable({["location->position"] = _73_}, {__index = app})

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
 do local _75_ = (_3fhand_length or #app.game.hand) if (_75_ == 0) then
 hand.col = draw.col hand_offset = nil elseif (_75_ == 1) then
 hand.col = draw.col hand_offset = nil elseif (nil ~= _75_) then local n = _75_
 hand.col = (draw.col - (2 * (n - 1))) hand_offset = nil else hand_offset = nil end end

 if ((_G.type(location) == "table") and (location[1] == "kingdom") and (nil ~= location[2]) and true) then local n = location[2] local _ = location[3]
 return {row = kingdom.row, col = (kingdom.col + (card_col_step * (n - 1))), z = app["z-index-for-layer"](app, "cards")} elseif ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2])) then local n = location[2]


 return {row = hand.row, col = (hand.col + (4 * (n - 1))), z = app["z-index-for-layer"](app, "hand", n)} elseif ((_G.type(location) == "table") and (location[1] == "debate") and (nil ~= location[2])) then local c = location[2]



 local _77_ if (c == 1) then
 _77_ = (debate.col - 2) elseif (c == 2) then
 _77_ = (debate.col + 2) else local _ = c _77_ = 0 end return {row = debate.row, col = _77_, z = app["z-index-for-layer"](app, "debate", ((1 * 10) + c))} elseif ((_G.type(location) == "table") and (location[1] == "discard") and (nil ~= location[2])) then local c = location[2]


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


 M.start = function(app_config, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/the-emissary/app.fnl:383") _G.assert((nil ~= app_config), "Missing argument app-config on fnl/playtime/game/the-emissary/app.fnl:383")
 local app = setmetatable(App.build("The Emissary", "the-emissary", app_config, game_config), {__index = M})




 local view = Window.open("the-emissary", App["build-default-window-dispatch-options"](app), {width = 83, height = 32, ["window-position"] = app_config["window-position"], ["minimise-position"] = app_config["minimise-position"]})





 local _ = table.merge(app["z-layers"], {cards = 25, kingdom = 25, debate = 90, label = 100, hand = 100, animation = 200})
 app.view = view
 app["card-style"] = {width = 7, height = 5, colors = 4, stacking = "horizontal-left"} app["setup-new-game"](app, app["game-config"], _3fseed) return app:render() end



 M["setup-new-game"] = function(app, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/the-emissary/app.fnl:401") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/the-emissary/app.fnl:401") app["new-game"](app, Logic.build, game_config, _3fseed) app["build-components"](app) app["switch-state"](app, AppState.Default)



 local function _83_() return app["switch-state"](app, AppState.DealPhase) end vim.defer_fn(_83_, 300)
 return app end

 M["build-components"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/the-emissary/app.fnl:408")
 local function build_emissary(position)
 return Component["set-position"](Component["set-size"](Component["set-content"](Component.build(), {{{"\240\159\174\178\240\159\174\179", "@playtime.ui.on"}}}), {width = 2, height = 1}), {row = 13, col = 41}) end



 local function build_label(text, position)
 local row = position["row"] local col = position["col"] local z = position["z"]

 local function _84_(self, enabled)
 local hl if enabled then hl = "@playtime.ui.on" else hl = "@playtime.ui.off" end return self["set-content"](self, {{{text, hl}}}) end return Component["set-content"](Component["set-size"](Component["set-position"](Component.build(_84_), position), {width = #text, height = 1}), {{{text, "@playtime.ui.off"}}}) end




 local card_card_components do local tbl_16_auto = {} for location, card in Logic["iter-cards"](app.game) do local k_17_auto, v_18_auto = nil, nil
 do local card_style if (8 < Logic["card-value"](card)) then
 card_style = table.set(clone(app["card-style"]), "stacking", "vertical-down") else

 card_style = app["card-style"] end local comp
 local function _87_(...) return app["location->position"](app, ...) end comp = CardComponents.card(_87_, location, card, card_style)



 k_17_auto, v_18_auto = card.id, comp end if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end card_card_components = tbl_16_auto end
 local menubar = CommonComponents.menubar({{"The Emissary", {"file"}, {{"", nil}, {"New Game", {"new-game"}}, {"Restart Game", {"restart-game"}}, {"", nil}, {"Quit", {"quit"}}, {"", nil}, {string.format("Seed: %s", app.seed), nil}}}}, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar")}) local card_counts














 do local tbl_16_auto = {} for _, key in ipairs({"draw", "discard", "score"}) do local k_17_auto, v_18_auto = nil, nil


 local function _89_() return app["z-index-for-layer"](app, "label") end k_17_auto, v_18_auto = key, CardComponents.count(table["update-in"](app["location->position"](app, {key, 0}), {"z"}, _89_), app["card-style"]) if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end card_counts = tbl_16_auto end local win_needed_labels

 do local pos local function _91_(n) local tmp_9_auto = app["location->position"](app, {"kingdom", n})

 local function _92_(_241) return (_241 + 4) end table["update-in"](tmp_9_auto, {"row"}, _92_)
 local function _93_(_241) return (_241 + 2) end table["update-in"](tmp_9_auto, {"col"}, _93_)
 local function _94_(_241) return (_241 + 5) end table["update-in"](tmp_9_auto, {"z"}, _94_) return tmp_9_auto end pos = _91_
 local tbl_21_auto = {} local i_22_auto = 0 for n = 1, 8 do
 local val_23_auto = build_label((" " .. tostring(n) .. " "), pos(n)) if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end win_needed_labels = tbl_21_auto end
 local advisors = {hearts = "dip.", clubs = "mil.", spades = "pol.", diamonds = "com."} local advisor_titles
 do local tbl_21_auto = {} local i_22_auto = 0 for suit, short_name in pairs(advisors) do
 local val_23_auto = build_label(short_name, app["location->position"](app, {"advisor", suit, "label"})) if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end advisor_titles = tbl_21_auto end local empty_fields
 do local base = {} for _, _97_ in ipairs({{"kingdom", 8}, {"draw", 1}, {"discard", 1}, {"score", 1}}) do local field = _97_[1] local count = _97_[2]



 local tbl_19_auto = base for i = 1, count do local val_20_auto
 local function _98_(...) return table.set(app["location->position"](app, ...), "z", app["z-index-for-layer"](app, "base")) end val_20_auto = CardComponents.slot(_98_, {field, i, 0}, app["card-style"]) table.insert(tbl_19_auto, val_20_auto) end base = tbl_19_auto end empty_fields = base end local empty_fields0



 do local tbl_19_auto = empty_fields for _, t in ipairs(advisors) do local val_20_auto
 local function _99_(...) return table.set(app["location->position"](app, ...), "z", app["z-index-for-layer"](app, "base")) end val_20_auto = CardComponents.slot(_99_, {"advisor", t, 0}, app["card-style"]) table.insert(tbl_19_auto, val_20_auto) end empty_fields0 = tbl_19_auto end



 local game_report = CommonComponents["game-report"](app.view.width, app.view.height, app["z-index-for-layer"](app, "report"), {{true, "The land is in concord."}, {false, "The land remains fractured."}}) local guide_text





 local function _100_(self, text) self["set-content"](self, {{{text, "@playtime.ui.off"}}}) self["set-position"](self, {row = 30, col = math.floor(((app.view.width / 2) - (#text / 2))), z = app["z-index-for-layer"](app, "label")}) return self["set-size"](self, {width = #text, height = 1}) end guide_text = Component.build(_100_):update("Select a kingdom") local win_count







 do local _let_101_ = app["fetch-statistics"](app) local wins = _let_101_["wins"]
 win_count = CommonComponents["win-count"](wins, {width = app.view.width, z = app["z-index-for-layer"](app, "menubar", 1)}) end


 local emissary = build_emissary()
 app["card-id->components"] = card_card_components
 table.merge(app.components, {["empty-fields"] = empty_fields0, menubar = menubar, emissary = emissary, ["guide-text"] = guide_text, ["game-report"] = game_report, ["card-counts"] = card_counts, ["win-count"] = win_count, ["win-needed-labels"] = win_needed_labels, cards = table.values(card_card_components), ["advisor-titles"] = advisor_titles})










 return update_card_counts(app) end

 M.render = function(app) app.view:render({app.components["empty-fields"], app.components["advisor-titles"], app.components.cards, app.components["win-needed-labels"], {app.components.emissary, app.components["guide-text"], app.components["card-counts"].discard, app.components["card-counts"].draw, app.components["card-counts"].score, app.components["game-report"], app.components["win-count"], app.components.menubar}})












 return app end

 M.tick = function(app)
 local now = uv.now() app["process-next-event"](app)

 do local _102_ = app.state.module.tick if (nil ~= _102_) then local f = _102_
 f(app) else local _ = _102_
 local adjustment do local t = {}
 for key, vals in pairs((app.state.context.selected or {})) do
 for i, _0 in pairs(vals) do
 table.set(t, string.fmt("%s.%s", key, i), {key, i}) end end
 do local _103_ = app.state.context.selecting if ((_G.type(_103_) == "table") and (nil ~= _103_[1]) and (nil ~= _103_[2])) then local key = _103_[1] local v = _103_[2]
 table.set(t, string.fmt("%s.%s", key, v), {key, v}) else end end

 adjustment = table.values(t) end
 for location, card in Logic["iter-cards"](app.game) do
 local comp = app["card-id->components"][card.id] comp:update(location, card)

 for _0, marked in ipairs(adjustment) do
 local _105_, _106_ = location, marked if (((_G.type(_105_) == "table") and (nil ~= _105_[1]) and (nil ~= _105_[2])) and ((_G.type(_106_) == "table") and (_105_[1] == _106_[1]) and (_105_[2] == _106_[2]))) then local f = _105_[1] local n = _105_[2] comp["set-position"](comp, {row = (comp.row - 1)}) else end end end end end

 update_card_counts(app) return app["request-render"](app) end


 M["update-statistics"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/game/the-emissary/app.fnl:547")
 local function update(d)
 local data = table.merge({version = 1, wins = 0, games = {}}, d)
 data.wins = (data.wins + 1)
 data.games = table.insert(data.games, {seed = app.seed, time = ((app["ended-at"] or app["started-at"]) - app["started-at"])})


 return data end
 return App["update-statistics"](app, update) end

 return M