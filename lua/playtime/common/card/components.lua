
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Component = require("playtime.component")
 local M = {}

 local function fill_width(width, left_edge, left, fill, right, right_edge) _G.assert((nil ~= right_edge), "Missing argument right-edge on fnl/playtime/common/card/components.fnl:8") _G.assert((nil ~= right), "Missing argument right on fnl/playtime/common/card/components.fnl:8") _G.assert((nil ~= fill), "Missing argument fill on fnl/playtime/common/card/components.fnl:8") _G.assert((nil ~= left), "Missing argument left on fnl/playtime/common/card/components.fnl:8") _G.assert((nil ~= left_edge), "Missing argument left-edge on fnl/playtime/common/card/components.fnl:8") _G.assert((nil ~= width), "Missing argument width on fnl/playtime/common/card/components.fnl:8")
 return (left_edge .. left .. string.rep(fill, math.floor(((width - string["col-width"](left_edge) - string["col-width"](left) - string["col-width"](right) - string["col-width"](right_edge)) / string["col-width"](fill)))) .. right .. right_edge) end











 M.slot = function(location__3eposition, location, _2_) local _arg_3_ = _2_ local width = _arg_3_["width"] local height = _arg_3_["height"] local card_style = _arg_3_ _G.assert((nil ~= card_style), "Missing argument card-style on fnl/playtime/common/card/components.fnl:21") _G.assert((nil ~= height), "Missing argument height on fnl/playtime/common/card/components.fnl:21") _G.assert((nil ~= width), "Missing argument width on fnl/playtime/common/card/components.fnl:21") _G.assert((nil ~= location), "Missing argument location on fnl/playtime/common/card/components.fnl:21") _G.assert((nil ~= location__3eposition), "Missing argument location->position on fnl/playtime/common/card/components.fnl:21")
 local _let_4_ = location__3eposition(location) local row = _let_4_["row"] local col = _let_4_["col"] local z = _let_4_["z"] local wide
 local function _5_(...) return fill_width(width, ...) end wide = _5_





 local function _7_() local middle do local tbl_19_auto = {} local i_20_auto = 0 for _ = 1, (height - 2) do
 local val_21_auto = {{wide("\226\148\130", "", " ", "", "\226\148\130"), "@playtime.game.card.empty"}} if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end middle = tbl_19_auto end
 return table.join({{{wide("\226\149\173", "", "\226\148\128", "", "\226\149\174"), "@playtime.game.card.empty"}}}, middle, {{{wide("\226\149\176", "", "\226\148\128", "", "\226\149\175"), "@playtime.game.card.empty"}}}) end return Component["set-content"](Component["set-size"](Component["set-position"](Component["set-tag"](Component.build(), location), {row = row, col = col, z = z}), {width = width, height = height}), _7_()) end





 local function default_french_graphics(suit, rank, color_count)

 local suit_text if (suit == "hearts") then suit_text = "\226\153\165" elseif (suit == "diamonds") then suit_text = "\226\153\166" elseif (suit == "clubs") then suit_text = "\226\153\163" elseif (suit == "spades") then suit_text = "\226\153\160" elseif (suit == "joker") then suit_text = "\240\159\174\178\240\159\174\179" else suit_text = nil end local rank_text





 if (rank == "king") then rank_text = "K" elseif (rank == "queen") then rank_text = "Q" elseif (rank == "jack") then rank_text = "J" elseif (rank == 1) then rank_text = "A" elseif (nil ~= rank) then local n = rank




 rank_text = tostring(n) else rank_text = nil end local suit_text0, rank_text0 = nil, nil
 if (suit == "joker") then
 suit_text0, rank_text0 = "", suit_text else local _ = suit
 suit_text0, rank_text0 = suit_text, rank_text end local highlight
 if (color_count == 2) then local data_5_auto = {suit = suit}
 local resolve_6_auto local function _11_(name_7_auto) local _12_ = data_5_auto[name_7_auto] local function _13_() local t_8_auto = _12_ return ("table" == type(t_8_auto)) end if ((nil ~= _12_) and _13_()) then local t_8_auto = _12_ local _14_ = getmetatable(t_8_auto) if ((_G.type(_14_) == "table") and (nil ~= _14_.__tostring)) then local f_9_auto = _14_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _14_ return vim.inspect(t_8_auto) end elseif (nil ~= _12_) then local v_11_auto = _12_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _11_ highlight = string.gsub("@playtime.game.card.#{suit}.two_colors", "#{(.-)}", resolve_6_auto) elseif (color_count == 4) then local data_5_auto = {suit = suit}
 local resolve_6_auto local function _17_(name_7_auto) local _18_ = data_5_auto[name_7_auto] local function _19_() local t_8_auto = _18_ return ("table" == type(t_8_auto)) end if ((nil ~= _18_) and _19_()) then local t_8_auto = _18_ local _20_ = getmetatable(t_8_auto) if ((_G.type(_20_) == "table") and (nil ~= _20_.__tostring)) then local f_9_auto = _20_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _20_ return vim.inspect(t_8_auto) end elseif (nil ~= _18_) then local v_11_auto = _18_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _17_ highlight = string.gsub("@playtime.game.card.#{suit}.four_colors", "#{(.-)}", resolve_6_auto) else highlight = nil end
 return {suit_text0, rank_text0, highlight} end

 M.card = function(location__3eposition, initial_location, card, card_style) _G.assert((nil ~= card_style), "Missing argument card-style on fnl/playtime/common/card/components.fnl:59") _G.assert((nil ~= card), "Missing argument card on fnl/playtime/common/card/components.fnl:59") _G.assert((nil ~= initial_location), "Missing argument initial-location on fnl/playtime/common/card/components.fnl:59") _G.assert((nil ~= location__3eposition), "Missing argument location->position on fnl/playtime/common/card/components.fnl:59")
 local _let_24_ = card_style local width = _let_24_["width"] local height = _let_24_["height"]
 local graphics = (card_style.graphics or default_french_graphics)
 local _let_25_ = card local suit = _let_25_[1] local rank = _let_25_[2]
 local _let_26_ = graphics(suit, rank, card_style.colors) local suit_text = _let_26_[1] local rank_text = _let_26_[2] local color = _let_26_[3] local wide
 local function _27_(...) return fill_width(width, ...) end wide = _27_
 local top = {{wide("\226\149\173", "", "\226\148\128", "", "\226\149\174"), color}}
 local bottom = {{wide("\226\149\176", "", "\226\148\128", "", "\226\149\175"), color}} local body
 do local _28_ = (card_style.stacking or "vertical-down") if (_28_ == "horizontal-left") then
 body = {{{wide("\226\148\130", rank_text, " ", "", "\226\148\130"), color}}, {{wide("\226\148\130", suit_text, " ", "", "\226\148\130"), color}}} elseif (_28_ == "horizontal-right") then

 body = {{{wide("\226\148\130", "", " ", rank_text, "\226\148\130"), color}}, {{wide("\226\148\130", "", " ", suit_text, "\226\148\130"), color}}} else local _ = _28_

 body = {{{wide("\226\148\130", rank_text, " ", suit_text, "\226\148\130"), color}}, {{wide("\226\148\130", "", " ", "", "\226\148\130"), color}}} end end local _

 for i = 1, (height - 4) do
 table.insert(body, {{"\226\148\130     \226\148\130", color}}) end _ = nil
 local face_up_content = table.join({top}, body, {bottom}) local face_down_color = "@playtime.game.card.back"

 local top0 = {{wide("\226\149\173", "", "\226\148\128", "", "\226\149\174"), face_down_color}}
 local bottom0 = {{wide("\226\149\176", "", "\226\148\128", "", "\226\149\175"), face_down_color}} local face_down_content
 if (height == 5) then
 face_down_content = {top0, {{wide("\226\148\130", "+", " + ", "+", "\226\148\130"), face_down_color}}, {{wide("\226\148\130", "", " +", " ", "\226\148\130"), face_down_color}}, {{wide("\226\148\130", "+", " + ", "+", "\226\148\130"), face_down_color}}, bottom0} elseif (nil ~= height) then local n = height




 local _30_ do local tbl_19_auto = {} local i_20_auto = 0 for i = 1, (n - 2) do
 local val_21_auto = {{wide("\226\148\130", "+", " ", "+", "\226\148\130"), face_down_color}} if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end _30_ = tbl_19_auto end face_down_content = table.insert(table.insert(_30_, 1, top0), bottom0) else face_down_content = nil end local comp



 local function _33_(self, location, card0) self["set-tag"](self, location) self["set-position"](self, location__3eposition(location))



 local function _35_() local _34_ = card0.face if (_34_ == "up") then
 return face_up_content elseif (_34_ == "down") then
 return face_down_content else return nil end end return self["set-content"](self, _35_()) end comp = Component["set-size"](Component.build(_33_), {width = width, height = height}):update(initial_location, card)


 comp["force-flip"] = function(self, dir) _G.assert((nil ~= dir), "Missing argument dir on fnl/playtime/common/card/components.fnl:100") _G.assert((nil ~= self), "Missing argument self on fnl/playtime/common/card/components.fnl:100")


 if (dir == "face-down") then return self["set-content"](self, face_down_content) elseif (dir == "face-up") then return self["set-content"](self, face_up_content) else return nil end end


 return comp end

 M.count = function(position, card_style) _G.assert((nil ~= card_style), "Missing argument card-style on fnl/playtime/common/card/components.fnl:108") _G.assert((nil ~= position), "Missing argument position on fnl/playtime/common/card/components.fnl:108")
 local _let_38_ = position local row = _let_38_["row"] local col = _let_38_["col"] local z = _let_38_["z"]
 local _let_39_ = card_style local height = _let_39_["height"] local width = _let_39_["width"]

 local function _40_(self, count)
 local text = tostring(count) local col0
 do local _41_ = string["col-width"](text) local function _42_() local n = _41_ return ((1 <= n) and (n <= 5)) end if ((nil ~= _41_) and _42_()) then local n = _41_

 col0 = (col + (width - n - 1)) else local _ = _41_
 col0 = (col + 1) end end self["set-position"](self, {row = (row + (height - 1)), col = col0, z = z}) self["set-size"](self, {width = #text, height = 1}) return self["set-content"](self, {{{text, "@playtime.ui.off"}}}) end return Component.build(_40_):update(0) end





 return M