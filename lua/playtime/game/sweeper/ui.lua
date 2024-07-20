
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Error = require("playtime.error")
 local Component = require("playtime.component")

 local M = {}

 local function make_cell(cell, tag, _2_, _3fcorners) local row = _2_["row"] local col = _2_["col"] local z = _2_["z"]
 local corners = table.merge({ne = "\226\148\188", n = "\226\148\128", nw = "\226\148\188", e = "\226\148\130", w = "\226\148\130", se = "\226\148\188", s = "\226\148\128", sw = "\226\148\188"}, (_3fcorners or {}))



 local ne = corners["ne"] local n = corners["n"] local nw = corners["nw"] local e = corners["e"] local w = corners["w"] local se = corners["se"] local s = corners["s"] local sw = corners["sw"]
 local function gen_content(center)
 return {{{(ne .. n .. n .. n .. nw), "Comment"}}, {{(w .. " " .. center .. " " .. e), "Comment"}}, {{(se .. s .. s .. s .. sw), "Comment"}}} end



 local function _5_(_3_, cell0, ...) local _arg_4_ = _3_["children"] local c = _arg_4_[1] return c:update(cell0, ...) end



 local function _6_(comp, cell0, _3fother)
 local _let_7_ = table.merge({["pressed?"] = false}, (_3fother or {})) local pressed_3f = _let_7_["pressed?"]
 if ((_G.type(cell0) == "table") and (cell0["revealed?"] == true) and (cell0.mark == nil)) then

 local function _8_() if ((_G.type(cell0) == "table") and (cell0["mine?"] == true)) then
 return {" \226\185\139 ", "@playtime.color.red"} elseif ((_G.type(cell0) == "table") and (cell0.count == 0)) then
 return {"   ", "@playtime.ui.off"} elseif ((_G.type(cell0) == "table") and (nil ~= cell0.count)) then local count = cell0.count
 return {(" " .. count .. " "), "@playtime.ui.off"} else return nil end end local _let_9_ = _8_() local content = _let_9_[1] local hl = _let_9_[2] return comp["set-content"](comp, {{{content, hl}}}) elseif ((_G.type(cell0) == "table") and (cell0.mark == nil) and (cell0["revealed?"] == false)) then


 local _10_ if pressed_3f then _10_ = "\226\150\145\226\150\145\226\150\145" else _10_ = "\226\150\147\226\150\147\226\150\147" end return comp["set-content"](comp, {{{_10_, "@playtime.ui.off"}}}) elseif ((_G.type(cell0) == "table") and true and (cell0.mark == "flag")) then local _ = cell0["revealed?"]

 local _12_ if pressed_3f then _12_ = " \226\154\144 " else _12_ = " \226\154\145 " end return comp["set-content"](comp, {{{_12_, "@playtime.color.red"}}}) elseif ((_G.type(cell0) == "table") and true and (cell0.mark == "maybe")) then local _ = cell0["revealed?"]

 local _14_ if pressed_3f then _14_ = "   " else _14_ = " \226\154\144 " end return comp["set-content"](comp, {{{_14_, "@playtime.color.yellow"}}}) else return nil end end return Component["set-content"](Component["set-size"](Component["set-position"](Component["set-children"](Component.build(_5_), {Component["set-position"](Component["set-size"](Component["set-tag"](Component.build(_6_), {"grid", tag}), {width = 3, height = 1}), {row = (row + 1), col = (col + 1), z = z}):update(cell)}), {row = row, col = col, z = z}), {height = 3, width = 5}), {{{(ne .. n .. n .. n .. nw), "Comment"}}, {{(w .. "   " .. e), "Comment"}}, {{(se .. s .. s .. s .. sw), "Comment"}}}):update(cell) end











 M["mid-cell"] = function(cell, tag, position) return make_cell(cell, tag, position) end
 M["n-cell"] = function(cell, tag, position) return make_cell(cell, tag, position, {ne = "\226\148\172", nw = "\226\148\172"}) end
 M["s-cell"] = function(cell, tag, position) return make_cell(cell, tag, position, {se = "\226\148\180", sw = "\226\148\180"}) end
 M["e-cell"] = function(cell, tag, position) return make_cell(cell, tag, position, {nw = "\226\148\164", sw = "\226\148\164"}) end
 M["w-cell"] = function(cell, tag, position) return make_cell(cell, tag, position, {ne = "\226\148\156", se = "\226\148\156"}) end
 M["ne-cell"] = function(cell, tag, position) return make_cell(cell, tag, position, {ne = "\226\148\172", nw = "\226\149\174", sw = "\226\148\164"}) end
 M["nw-cell"] = function(cell, tag, position) return make_cell(cell, tag, position, {ne = "\226\149\173", nw = "\226\148\172", se = "\226\148\156"}) end
 M["se-cell"] = function(cell, tag, position) return make_cell(cell, tag, position, {se = "\226\148\180", sw = "\226\149\175", nw = "\226\148\164"}) end
 M["sw-cell"] = function(cell, tag, position) return make_cell(cell, tag, position, {se = "\226\149\176", sw = "\226\148\180", ne = "\226\148\156"}) end

 return M