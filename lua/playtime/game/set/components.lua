
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Component = require("playtime.component")
 local M = {}


 local icons = {circle = {solid = "\226\151\143", split = "\226\151\144", outline = "\226\151\139"}, square = {solid = "\226\150\160", split = "\226\151\167", outline = "\226\150\161"}, triangle = {solid = "\226\150\178", split = "\226\151\173", outline = "\226\150\179"}}









 local function make_line(width, left, mid, right)
 return (left .. string.rep(mid, (width - 2)) .. right) end

 M.slot = function(location__3eposition, location, _2_) local width = _2_["width"] local height = _2_["height"] local card_style = _2_

 local _let_3_ = location__3eposition(location) local row = _let_3_["row"] local col = _let_3_["col"] local z = _let_3_["z"] local fill
 local function _4_(_241, _242, _243) return make_line(width, _241, _242, _243) end fill = _4_ local color = "@playtime.game.card.back"

 local content = {{{fill("\226\149\173", "\226\148\128", "\226\149\174"), color}}, {{fill("\226\148\130", " ", "\226\148\130"), color}}, {{fill("\226\148\130", " ", "\226\148\130"), color}}, {{fill("\226\148\130", " ", "\226\148\130"), color}}, {{fill("\226\149\176", "\226\148\128", "\226\149\175"), color}}}




 return Component["set-content"](Component["set-size"](Component["set-position"](Component["set-tag"](Component.build(), location), {row = row, col = col, z = z}), {width = width, height = height}), content) end





 M.card = function(location__3eposition, initial_location, card, _5_) local glyph_width = _5_["glyph-width"] local width = _5_["width"] local height = _5_["height"] local card_style = _5_

 local shape = card["shape"] local style = card["style"] local color = card["color"] local count = card["count"] local fill
 local function _6_(_241, _242, _243) return make_line(width, _241, _242, _243) end fill = _6_
 local icon = icons[shape][style]
 local icon_hl = ("@playtime.game.set." .. color) local selected_hl = "@playtime.game.set.selected" local muted_hl = "@playtime.game.card.empty" local the_line


 do local right_pad if ("wide" == glyph_width) then right_pad = " " else right_pad = "" end
 if (count == 1) then
 the_line = string.fmt("   %s   %s", icon, right_pad) elseif (count == 2) then
 the_line = string.fmt("  %s %s  %s", icon, icon, right_pad) elseif (count == 3) then
 the_line = string.fmt(" %s %s %s %s", icon, icon, icon, right_pad) else the_line = nil end end
 local face_down_content = {{{fill("\226\149\173", "\226\148\128", "\226\149\174"), muted_hl}}, {{fill("\226\148\130", "\\", "\226\148\130"), muted_hl}}, {{fill("\226\148\130", "/", "\226\148\130"), muted_hl}}, {{fill("\226\148\130", "\\", "\226\148\130"), muted_hl}}, {{fill("\226\149\176", "\226\148\128", "\226\149\175"), muted_hl}}}




 local face_up_content = {{{fill("\226\149\173", "\226\148\128", "\226\149\174"), muted_hl}}, {{fill("\226\148\130", " ", "\226\148\130"), muted_hl}}, {{"\226\148\130", muted_hl}, {the_line, icon_hl}, {"\226\148\130", muted_hl}}, {{fill("\226\148\130", " ", "\226\148\130"), muted_hl}}, {{fill("\226\149\176", "\226\148\128", "\226\149\175"), muted_hl}}}




 local selected_content = {{{fill("\226\149\173", "\226\148\128", "\226\149\174"), selected_hl}}, {{fill("\226\148\130", " ", "\226\148\130"), selected_hl}}, {{"\226\148\130", selected_hl}, {the_line, icon_hl}, {"\226\148\130", selected_hl}}, {{fill("\226\148\130", " ", "\226\148\130"), selected_hl}}, {{fill("\226\149\176", "\226\148\128", "\226\149\175"), selected_hl}}} local comp





 local function _9_(self, location, card0, selected_3f) self["set-tag"](self, location) self["set-position"](self, location__3eposition(location))



 local function _11_() local _10_ = card0.face if (_10_ == "up") then
 if selected_3f then return selected_content else return face_up_content end elseif (_10_ == "down") then
 return face_down_content else return nil end end return self["set-content"](self, _11_()) end comp = Component["set-size"](Component.build(_9_), {width = width, height = height}):update(initial_location, card)


 comp["force-flip"] = function(self, dir) _G.assert((nil ~= dir), "Missing argument dir on fnl/playtime/game/set/components.fnl:76") _G.assert((nil ~= self), "Missing argument self on fnl/playtime/game/set/components.fnl:76")


 if (dir == "face-down") then return self["set-content"](self, face_down_content) elseif (dir == "face-up") then return self["set-content"](self, face_up_content) else return nil end end


 return comp end

 return M