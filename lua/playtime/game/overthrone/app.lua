
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local PatienceApp = require("playtime.app.patience")
 local PatienceState = require("playtime.app.patience.state")
 local Component = require("playtime.component")
 local CardComponents = require("playtime.common.card.components")
 local CommonComponents = require("playtime.common.components")
 local M = setmetatable({}, {__index = PatienceApp})

 local Logic = require("playtime.game.overthrone.logic")
 local AppState = PatienceState.build(Logic)
 local M0 = setmetatable({}, {__index = PatienceApp})

 AppState.GameEnded.activated = function(app)
 app["ended-at"] = os.time()
 do local _let_2_ = app["game-ended-data"](app) local key = _let_2_[1] local other = _let_2_[2]
 if (("0" == key) or ("1-3" == key)) then app:save((os.time() .. "-win")) app["update-statistics"](app) else end do end (app.components["game-report"]):update(key, other) end




 return app end

 M0["location->position"] = function(app, location)
 local config = {card = {margin = {row = 0, col = 2}, width = 7, height = 5}}

 local hand_size = app["game-config"]["hand-size"]
 local card_col_step = (config.card.width + config.card.margin.col) local throne
 local _4_ if (hand_size == 5) then _4_ = 25 elseif (hand_size == 6) then _4_ = 28 else _4_ = nil end throne = {row = 8, col = _4_}


 local draw = {row = 20, col = 2}
 local hand = {row = draw.row, col = (draw.col + card_col_step)}
 local foundation = {row = 14, col = 14}

 if ((_G.type(location) == "table") and (location[1] == "foundation") and (location[2] == 1) and (nil ~= location[3])) then local card = location[3]
 return {row = (throne.row - 6), col = throne.col, z = card} elseif ((_G.type(location) == "table") and (location[1] == "foundation") and (location[2] == 2) and (nil ~= location[3])) then local card = location[3]
 return {row = throne.row, col = (throne.col + 2 + card_col_step), z = card} elseif ((_G.type(location) == "table") and (location[1] == "foundation") and (location[2] == 3) and (nil ~= location[3])) then local card = location[3]
 return {row = (throne.row + 6), col = throne.col, z = card} elseif ((_G.type(location) == "table") and (location[1] == "foundation") and (location[2] == 4) and (nil ~= location[3])) then local card = location[3]
 return {row = throne.row, col = (throne.col - 2 - card_col_step), z = card} elseif ((_G.type(location) == "table") and (location[1] == "throne") and (location[2] == 1) and (nil ~= location[3])) then local card = location[3]
 return {row = throne.row, col = throne.col, z = card} elseif ((_G.type(location) == "table") and (location[1] == "draw") and (location[2] == 1) and (nil ~= location[3])) then local card = location[3]
 return {row = draw.row, col = draw.col, z = card} elseif ((_G.type(location) == "table") and (location[1] == "hand") and (nil ~= location[2]) and (nil ~= location[3])) then local n = location[2] local c = location[3]
 return {row = hand.row, col = (hand.col + ((n - 1) * 7)), z = c} elseif ((_G.type(location) == "table") and (location[1] == "discard") and (location[2] == 1) and (nil ~= location[3])) then local card = location[3]
 return {row = hand.row, col = (hand.col + card_col_step + ((hand_size - 1) * 7)), z = card} else local _ = location
 local function _14_() local data_5_auto = {location = location} local resolve_6_auto local function _8_(name_7_auto) local _9_ = data_5_auto[name_7_auto] local function _10_() local t_8_auto = _9_ return ("table" == type(t_8_auto)) end if ((nil ~= _9_) and _10_()) then local t_8_auto = _9_ local _11_ = getmetatable(t_8_auto) if ((_G.type(_11_) == "table") and (nil ~= _11_.__tostring)) then local f_9_auto = _11_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _11_ return vim.inspect(t_8_auto) end elseif (nil ~= _9_) then local v_11_auto = _9_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _8_ return string.gsub("Unable to convert location to position, unknown location #{location}", "#{(.-)}", resolve_6_auto) end return error(_14_()) end end

 AppState.Default.OnEvent.app["maybe-auto-move"] = function(app) end

 local function update_card_counts(app) do end (app.components.counters.draw):update(#app.game.draw[1]) return (app.components.counters.discard):update(#app.game.discard[1]) end



 M0["build-components"] = function(app)
 PatienceApp["build-components"](app)
 local throne_pos = M0["location->position"](app, {"throne", 1, 0})
 local throne = Component["set-content"](Component["set-position"](Component["set-size"](Component.build(), {width = 11, height = 7}), {row = (throne_pos.row - 1), col = (throne_pos.col - 2), z = 0}), {{{"\240\159\158\160 \226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\240\159\158\160 ", "@playtime.color.magenta"}}, {{" \226\150\143       \226\150\149", "@playtime.color.magenta"}}, {{" \226\150\143       \226\150\149", "@playtime.color.magenta"}}, {{" \226\150\143       \226\150\149", "@playtime.color.magenta"}}, {{" \226\150\143       \226\150\149", "@playtime.color.magenta"}}, {{" \226\150\143       \226\150\149", "@playtime.color.magenta"}}, {{"\240\159\158\160 \226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\226\149\144\240\159\158\160 ", "@playtime.color.magenta"}}})











 local counters = {draw = CardComponents.count(table.set(app["location->position"](app, {"draw", 1, 0}), "z", app["z-index-for-layer"](app, "cards", 52)), app["card-style"]), discard = CardComponents.count(table.set(app["location->position"](app, {"discard", 1, 0}), "z", app["z-index-for-layer"](app, "cards", 52)), app["card-style"])}





 local game_report = CommonComponents["game-report"](app.view.width, app.view.height, app["z-index-for-layer"](app, "report"), {{"0", "Perfect (0)"}, {"1-3", "Good (1-3)"}, {"4-7", "Not so good (4-7)"}, {"8+", "Uh-oh... (8+)"}})






 table.merge(app.components, {["game-report"] = game_report, throne = throne, counters = counters})
 update_card_counts(app)
 return app end

 M0.render = function(app) do end (app.view):render({{app.components.throne}, app.components["empty-fields"], app.components.cards, {app.components.counters.draw, app.components.counters.discard}, app["standard-patience-components"](app)})






 return app end

 M0["game-ended-data"] = function(app)
 local score = Logic.Query["game-result"](app.game) local score0
 if (0 == score) then score0 = "0" elseif ((0 < score) and (score < 4)) then score0 = "1-3" elseif ((3 < score) and (score < 8)) then score0 = "4-7" elseif (8 < score) then score0 = "8+" else score0 = nil end



 local other = {string.fmt("Moves: %d", app.game.moves), string.fmt("Time:  %ds", (app["ended-at"] - app["started-at"]))}

 return {score0, other} end

 M0.tick = function(app)
 update_card_counts(app)
 return PatienceApp.tick(app) end

 M0.start = function(app_config, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/game/overthrone/app.fnl:110") _G.assert((nil ~= app_config), "Missing argument app-config on fnl/playtime/game/overthrone/app.fnl:110")
 local game_config0 = table.merge({["hand-size"] = 5}, game_config) local width
 do local _17_ = game_config0["hand-size"] if (_17_ == 5) then width = 57 elseif (_17_ == 6) then width = 64 else width = nil end end


 return PatienceApp.start({name = "Overthrone", filetype = "overthrone", view = {width = width, height = 27}, ["empty-fields"] = {{"foundation", 4}, {"throne", 1}, {"draw", 1}, {"discard", 1}, {"hand", game_config0["hand-size"]}}, ["card-style"] = {colors = 4}}, {AppImpl = M0, LogicImpl = Logic, StateImpl = AppState}, app_config, game_config0, _3fseed) end














 return M0