
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local PatienceApp = require("playtime.app.patience")
 local PatienceState = require("playtime.app.patience.state")
 local Component = require("playtime.component")
 local CardComponents = require("playtime.common.card.components")
 local M = setmetatable({}, {__index = PatienceApp})

 local Logic = require("playtime.game.calculation.logic")
 local AppState = PatienceState.build(Logic)
 local M0 = setmetatable({}, {__index = PatienceApp})

 M0["location->position"] = function(app, location)
 local config = {card = {margin = {row = 0, col = 2}, width = 7, height = 5}}

 local card_col_step = (config.card.width + config.card.margin.col)
 local foundation = {row = 2, col = 13}
 local tableau = {row = (foundation.row + 5), col = 13}
 local stock = {row = 2, col = 3}
 if ((_G.type(location) == "table") and (location[1] == "foundation") and (nil ~= location[2]) and (nil ~= location[3])) then local n = location[2] local card = location[3]
 return {row = foundation.row, col = (foundation.col + (card_col_step * (n - 1))), z = app["z-index-for-layer"](app, "cards", card)} elseif ((_G.type(location) == "table") and (location[1] == "tableau") and (nil ~= location[2]) and (nil ~= location[3])) then local n = location[2] local card = location[3]


 return {row = (tableau.row + (math.max(0, (card - 1)) * 2)), col = (tableau.col + (card_col_step * (n - 1))), z = app["z-index-for-layer"](app, "cards", card)} elseif ((_G.type(location) == "table") and (location[1] == "stock") and (location[2] == 1) and (nil ~= location[3])) then local card = location[3]


 return {row = stock.row, col = stock.col, z = app["z-index-for-layer"](app, "cards", card)} else local _ = location


 local function _8_() local data_5_auto = {location = location} local resolve_6_auto local function _2_(name_7_auto) local _3_ = data_5_auto[name_7_auto] local function _4_() local t_8_auto = _3_ return ("table" == type(t_8_auto)) end if ((nil ~= _3_) and _4_()) then local t_8_auto = _3_ local _5_ = getmetatable(t_8_auto) if ((_G.type(_5_) == "table") and (nil ~= _5_.__tostring)) then local f_9_auto = _5_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _5_ return vim.inspect(t_8_auto) end elseif (nil ~= _3_) then local v_11_auto = _3_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _2_ return string.gsub("Unable to convert location to position, unknown location #{location}", "#{(.-)}", resolve_6_auto) end return error(_8_()) end end

 local function update_widgets(app)
 app.components["stock-count"](#app.game.stock[1])
 local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 4 do local val_20_auto
 do local _10_ = table.last(app.game.foundation[i]) if (nil ~= _10_) then local onto_card = _10_
 local val if ((_G.type(onto_card) == "table") and true and (onto_card[2] == "king")) then local _ = onto_card[1] val = 13 elseif ((_G.type(onto_card) == "table") and true and (onto_card[2] == "queen")) then local _ = onto_card[1] val = 12 elseif ((_G.type(onto_card) == "table") and true and (onto_card[2] == "jack")) then local _ = onto_card[1] val = 11 elseif ((_G.type(onto_card) == "table") and true and (nil ~= onto_card[2])) then local _ = onto_card[1] local v = onto_card[2]



 val = v else val = nil end local want_value
 do local _12_ = ((i + val) % 13) if (_12_ == 0) then want_value = 1 elseif (nil ~= _12_) then local n = _12_

 want_value = n else want_value = nil end end local text
 if (want_value == 13) then text = "K" elseif (want_value == 12) then text = "Q" elseif (want_value == 11) then text = "J" elseif (nil ~= want_value) then local n = want_value



 text = n else text = nil end
 val_20_auto = app.components.guides[i](#app.game.foundation[i]) else val_20_auto = nil end end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto end

 M0["build-components"] = function(app)
 local function build_card_count(position, z)
 local _let_17_ = position local row = _let_17_["row"] local col = _let_17_["col"]

 local function _18_(self, count)
 local text = tostring(count) local col0
 do local _19_ = vim.str_utfindex(text) if (_19_ == 1) then
 col0 = (col + 5) elseif (_19_ == 2) then
 col0 = (col + 4) elseif (_19_ == 3) then
 col0 = (col + 3) elseif (_19_ == 4) then
 col0 = (col + 2) else local _ = _19_
 col0 = (col + 1) end end self["set-position"](self, {row = (row + 4), col = col0, z = z}) self["set-size"](self, {width = #text, height = 1}) return self["set-content"](self, {{{text, "@playtime.ui.off"}}}) end return Component.build(_18_):update(0) end





 local function build_guide_strip(n, guide)
 local content do local tbl_18_auto = {} local i_19_auto = 0 for _, b in ipairs(guide) do local val_20_auto
 local function _21_() if (b == 10) then return "X" elseif (nil ~= b) then local n0 = b return n0 else return nil end end val_20_auto = {{tostring(_21_()), "@playtime.ui.off"}} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end content = tbl_18_auto end
 local _let_23_ = app["location->position"](app, {"stock", 1, 0}) local row = _let_23_["row"] local col = _let_23_["col"]

 local function _24_(comp, up_to)
 local content0 do local tbl_18_auto = {} local i_19_auto = 0 for i, _25_ in ipairs(content) do local _each_26_ = _25_ local _each_27_ = _each_26_[1] local s = _each_27_[1] local h = _each_27_[2] local val_20_auto
 local function _28_() if ((1 + up_to) == i) then return "@playtime.ui.on" else return "@playtime.ui.off" end end val_20_auto = {{s, _28_()}} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end content0 = tbl_18_auto end return comp["set-content"](comp, content0) end return Component["set-size"](Component["set-position"](Component["set-content"](Component.build(_24_), content), {row = (row + 6), col = (col + 0 + (2 * (n - 1))), z = app["z-index-for-layer"](app, "base")}), {width = 2, height = #guide}):update(1) end










 PatienceApp["build-components"](app)
 local guides = {{"A", 2, 3, 4, 5, 6, 7, 8, 9, 10, "J", "Q", "K"}, {2, 4, 6, 8, 10, "Q", "A", 3, 5, 7, 8, "J", "K"}, {3, 6, 9, "Q", 2, 5, 8, "J", "A", 4, 7, 10, "K"}, {4, 8, "Q", 3, 7, "J", 2, 6, 10, "A", 5, 9, "K"}} local guides0



 do local tbl_18_auto = {} local i_19_auto = 0 for i, g in ipairs(guides) do
 local val_20_auto = build_guide_strip(i, g) if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end guides0 = tbl_18_auto end
 local stock_count = CardComponents.count(table.set(app["location->position"](app, {"stock", 1, 0}), "z", app["z-index-for-layer"](app, "cards", 52)), app["card-style"])


 table.merge(app.components, {["stock-count"] = stock_count, guides = guides0})
 update_widgets(app)
 return app end

 M0.tick = function(app)
 update_widgets(app)
 return PatienceApp.tick(app) end

 M0.render = function(app) do end (app.view):render({app.components["empty-fields"], app.components.cards, app.components.guides, {app.components["stock-count"]}, app["standard-patience-components"](app)})





 return app end

 M0.start = function(app_config, game_config, _3fseed)
 return PatienceApp.start({name = "Calculation", filetype = "calculation", view = {width = 50, height = 40}, ["empty-fields"] = {{"foundation", 4}, {"tableau", 4}, {"stock", 1}}, ["card-style"] = {colors = 2}}, {AppImpl = M0, LogicImpl = Logic, StateImpl = AppState}, app_config, game_config, _3fseed) end










 return M0