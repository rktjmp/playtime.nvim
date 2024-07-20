
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local _local_2_ = vim["api"] local nvim_set_hl = _local_2_["nvim_set_hl"] local nvim_get_hl = _local_2_["nvim_get_hl"]

 local M = {}

 local function to_hex(c)
 local _let_3_ = require("bit") local tohex = _let_3_["tohex"]
 return string.format("#%s", tohex(c, 6)) end

 M["define-highlights"] = function()
 local function fetch_fg(hl_name, ...) local rest = {...}


 local function _4_(...) local _5_ = ... if ((_G.type(_5_) == "table") and (_5_.fg == nil)) then local function _6_(...) local _7_ = ... if ((_G.type(_7_) == "table") and (_7_.fg == nil)) then




 if ((_G.type(rest) == "table") and (nil ~= rest[1])) then local next = rest[1] local rest0 = {select(2, (table.unpack or _G.unpack)(rest))}

 return fetch_fg(next, table.unpack(rest0)) elseif ((_G.type(rest) == "table") and (rest[1] == nil)) then

 return {fg = "#FF00DD"} else return nil end elseif ((_G.type(_7_) == "table") and (nil ~= _7_.fg)) then local fg = _7_.fg

 return {fg = to_hex(fg)} else return nil end end return _6_(nvim_get_hl(0, {name = hl_name, link = true})) elseif ((_G.type(_5_) == "table") and (nil ~= _5_.fg)) then local fg = _5_.fg return {fg = to_hex(fg)} else return nil end end return _4_(nvim_get_hl(0, {name = hl_name, link = false})) end
 local function define_hl_if_missing(ns, hl_name, hl_data)



 if table["empty?"](nvim_get_hl(0, {name = hl_name, link = true})) then
 return nvim_set_hl(ns, hl_name, hl_data) else return nil end end
 local function hl(name, data) return define_hl_if_missing(0, name, data) end
 local function link(name, to) return define_hl_if_missing(0, name, {link = to}) end

 local core_hls = {{"PlaytimeHiddenCursor", {blend = 100, reverse = true}}, {"PlaytimeNormal", fetch_fg("NormalFloat", "Normal")}, {"PlaytimeMuted", fetch_fg("Comment")}, {"PlaytimeWhite", fetch_fg("NormalFloat", "Normal")}, {"PlaytimeRed", fetch_fg("DiagnosticError")}, {"PlaytimeGreen", fetch_fg("DiagnosticOk")}, {"PlaytimeYellow", {fg = "#fcd34d"}}, {"PlaytimeOrange", fetch_fg("DiagnosticWarn")}, {"PlaytimeBlue", fetch_fg("DiagnosticInfo")}, {"PlaytimeMagenta", {fg = "#e879f9"}}, {"PlaytimeCyan", {fg = "#22d3ee"}}, {"PlaytimeBlack", fetch_fg("Comment")}}












 for _, _12_ in ipairs(core_hls) do local name = _12_[1] local data = _12_[2] hl(name, data) end

 link("@playtime.ui.on", "PlaytimeNormal")
 link("@playtime.ui.off", "PlaytimeMuted")
 link("@playtime.ui.menu", "PmenuSBar")

 link("@playtime.color.white", "PlaytimeWhite")
 link("@playtime.color.red", "PlaytimeRed")
 link("@playtime.color.green", "PlaytimeGreen")
 link("@playtime.color.yellow", "PlaytimeYellow")
 link("@playtime.color.orange", "PlaytimeOrange")
 link("@playtime.color.blue", "PlaytimeBlue")
 link("@playtime.color.magenta", "PlaytimeMagenta")
 link("@playtime.color.cyan", "PlaytimeCyan")
 link("@playtime.color.black", "PlaytimeBlack")

 link("@playtime.game.card.empty", "PlaytimeMuted")
 link("@playtime.game.card.back", "PlaytimeMuted")

 link("@playtime.game.card.hearts", "PlaytimeRed")
 link("@playtime.game.card.diamonds", "PlaytimeRed")
 link("@playtime.game.card.clubs", "PlaytimeBlue")
 link("@playtime.game.card.spades", "PlaytimeBlue")

 link("@playtime.game.card.hearts.four_colors", "PlaytimeRed")
 link("@playtime.game.card.diamonds.four_colors", "PlaytimeYellow")

 link("@playtime.game.card.clubs.four_colors", "PlaytimeGreen")
 link("@playtime.game.card.spades.four_colors", "PlaytimeBlue")



 link("@playtime.game.set.selected", "PlaytimeYellow")
 link("@playtime.game.set.red", "PlaytimeRed")
 link("@playtime.game.set.green", "PlaytimeGreen")
 link("@playtime.game.set.blue", "PlaytimeBlue")

 link("@playtime.game.for_northwood.flowers", "PlaytimeMagenta")
 link("@playtime.game.for_northwood.claws", "PlaytimeCyan")
 link("@playtime.game.for_northwood.leaves", "PlaytimeYellow")
 link("@playtime.game.for_northwood.eyes", "PlaytimeBlue")

 link("@playtime.game.shenzhen.coins", "PlaytimeYellow")
 link("@playtime.game.shenzhen.myriads", "PlaytimeCyan")
 link("@playtime.game.shenzhen.strings", "PlaytimeBlue")
 link("@playtime.game.shenzhen.flower", "PlaytimeMagenta")
 link("@playtime.game.shenzhen.dragon.green", "PlaytimeGreen")
 link("@playtime.game.shenzhen.dragon.red", "PlaytimeRed")
 return link("@playtime.game.shenzhen.dragon.white", "PlaytimeWhite") end
















 return M