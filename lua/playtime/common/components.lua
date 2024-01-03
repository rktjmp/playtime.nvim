
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Component = require("playtime.component")
 local M = {}

 M.cursor = function(LayoutImpl, location) _G.assert((nil ~= location), "Missing argument location on fnl/playtime/common/components.fnl:8") _G.assert((nil ~= LayoutImpl), "Missing argument LayoutImpl on fnl/playtime/common/components.fnl:8")

 local function _2_(comp, location0)
 local _let_3_ = LayoutImpl["location->position"](location0) local row = _let_3_["row"] local col = _let_3_["col"]
 local z = LayoutImpl["z-index-for-layer"]("cursor")
 local row0 = (row + 1)
 local col0 = (col - 2) return comp["set-position"](comp, {row = row0, col = col0, z = z}) end return Component["set-content"](Component["set-size"](Component.build(_2_), {width = 3, height = 1}), {{{"\240\159\175\129\240\159\175\130\240\159\175\131", "Comment"}}}):update(location) end





 M.cheating = function()
 return Component["set-content"](Component["set-size"](Component["set-position"](Component.build(), {row = 0, col = 0, z = 150}), {width = 1, height = 1}), {{{"\240\159\145\187", "@playtime.ui.on"}}}) end




 M["win-count"] = function(_3fwins, _4_) local _arg_5_ = _4_ local width = _arg_5_["width"] local z = _arg_5_["z"] _G.assert((nil ~= z), "Missing argument z on fnl/playtime/common/components.fnl:26") _G.assert((nil ~= width), "Missing argument width on fnl/playtime/common/components.fnl:26")
 local text = ("Wins: " .. (_3fwins or 0))
 return Component["set-content"](Component["set-size"](Component["set-position"](Component.build(), {row = 0, col = (width - #text - 1), z = z}), {width = #text, height = 1}), {{{text, "@playtime.ui.menu"}}}) end




 M["game-report"] = function(view_width, view_height, z, options) _G.assert((nil ~= options), "Missing argument options on fnl/playtime/common/components.fnl:33") _G.assert((nil ~= z), "Missing argument z on fnl/playtime/common/components.fnl:33") _G.assert((nil ~= view_height), "Missing argument view-height on fnl/playtime/common/components.fnl:33") _G.assert((nil ~= view_width), "Missing argument view-width on fnl/playtime/common/components.fnl:33")


 local function _6_(comp, result, _3fother_lines)
 local other_lines = (_3fother_lines or {}) local max_len
 do local m = 0 for _, _7_ in ipairs(options) do local _each_8_ = _7_ local _id = _each_8_[1] local text = _each_8_[2]
 m = math.max(m, vim.str_utfindex(text)) end max_len = m end local max_len0
 do local m = max_len for _, text in ipairs(other_lines) do
 m = math.max(m, vim.str_utfindex(text)) end max_len0 = m end
 local max_len1 = (max_len0 + vim.str_utfindex(" \226\152\145   ")) local border_color = "@playtime.ui.on" local edge = "\226\149\145"


 local top = {{("\226\149\147" .. string.rep("\226\148\128", max_len1) .. "\226\149\150"), border_color}}
 local empty = {{(edge .. string.rep(" ", max_len1) .. edge), border_color}}
 local bottom = {{("\226\149\153" .. string.rep("\226\148\128", max_len1) .. "\226\149\156"), border_color}}
 local width = vim.str_utfindex(top[1][1]) local height




 local function _9_() if (0 < #other_lines) then
 return (#other_lines + 1) else return 0 end end height = (1 + 1 + #options + 1 + _9_() + 1) local row = 5




 local col = (math.floor((view_width / 2)) - math.floor((width / 2))) local lines
 do local tbl_18_auto = {} local i_19_auto = 0 for _, _10_ in ipairs(options) do local _each_11_ = _10_ local id = _each_11_[1] local text = _each_11_[2] local val_20_auto
 do local text0 local function _12_() if (id == result) then return "\226\152\145 " else return "\226\152\144 " end end text0 = (_12_() .. " " .. text)

 local function _13_() if (id == result) then return "@playtime.color.yellow" else return "@playtime.ui.off" end end val_20_auto = {{(edge .. " "), border_color}, {text0, _13_()}, {string.rep(" ", (max_len1 - vim.str_utfindex(text0) - 1))}, {(edge .. " "), border_color}} end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end lines = tbl_18_auto end


 table.insert(lines, 1, empty)
 table.insert(lines, 1, top)
 table.insert(lines, empty)
 for _, line in ipairs(other_lines) do
 table.insert(lines, {{(edge .. " "), border_color}, {line, "@playtime.ui.on"}, {string.rep(" ", (max_len1 - vim.str_utfindex(line) - 1))}, {(edge .. " "), border_color}}) end



 table.insert(lines, empty)
 table.insert(lines, bottom) comp["set-size"](comp, {width = width, height = height}) comp["set-position"](comp, {row = row, col = col, z = z}) comp["set-visible"](comp, true) return comp["set-content"](comp, lines) end return Component["set-visible"](Component.build(_6_), false) end






 M["you-died"] = function()

 local raw_lines = {"db    db  .d88b.  db    db      d8888b. d888888b d88888b d8888b.", "`8b  d8' .8P  Y8. 88    88      88  `8D   `88'   88'     88  `8D", " `8bd8'  88    88 88    88      88   88    88    88ooooo 88   88", "   88    88    88 88    88      88   88    88    88~~~~~ 88   88", "   88    `8b  d8' 88b  d88      88  .8D   .88.   88.     88  .8D", "   YP     `Y88P'  ~Y8888P'      Y8888D' Y888888P Y88888P Y8888D'"}






 local raw_lines0 = {"                                                ,,                 ,,   ", "`YMM'   `MM'                     `7MM\"\"\"Yb.     db               `7MM   ", "  VMA   ,V                         MM    `Yb.                      MM   ", "   VMA ,V ,pW\"Wq.`7MM  `7MM        MM     `Mb `7MM  .gP\"Ya    ,M\"\"bMM   ", "    VMMP 6W'   `Wb MM    MM        MM      MM   MM ,M'   Yb ,AP    MM   ", "     MM  8M     M8 MM    MM        MM     ,MP   MM 8M\"\"\"\"\"\" 8MI    MM   ", "     MM  YA.   ,A9 MM    MM        MM    ,dP'   MM YM.    , `Mb    MM   ", "   .JMML. `Ybmd9'  `Mbod\"YML.    .JMMmmmdP'   .JMML.`Mbmmd'  `Wbmd\"MML. ", "                                                                        "}










 local raw_lines1 = {".                                                            .", " dP    dP                      888888ba  oo                dP ", " Y8.  .8P                      88    `8b                   88 ", "  Y8aa8P  .d8888b. dP    dP    88     88 dP .d8888b. .d888b88 ", "    88    88'  `88 88    88    88     88 88 88ooood8 88'  `88 ", "    88    88.  .88 88.  .88    88    .8P 88 88.  ... 88.  .88 ", "    dP    `88888P' `88888P'    8888888P  dP `88888P' `88888P8 ", ".                                                            ."}








 local lines
 do local tbl_18_auto = {} local i_19_auto = 0 for _, line in ipairs(raw_lines1) do local val_20_auto
 do local parts = {} for lw, letters, tw in string.gmatch(line, "(%s*)(%S+)(%s*)") do
 table.insert(parts, {lw}) table.insert(parts, {letters, "@playtime.color.red"}) table.insert(parts, {tw}) parts = parts end val_20_auto = parts end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end lines = tbl_18_auto end



 return Component["set-content"](Component["set-size"](Component["set-position"](Component.build(), {row = 3, col = 3}), {width = 64, height = #raw_lines1}), lines) end




 M.menubar = function(menu_structure, _16_) local _arg_17_ = _16_ local view_width = _arg_17_["width"] local z = _arg_17_["z"] _G.assert((nil ~= z), "Missing argument z on fnl/playtime/common/components.fnl:123") _G.assert((nil ~= view_width), "Missing argument view-width on fnl/playtime/common/components.fnl:123") _G.assert((nil ~= menu_structure), "Missing argument menu-structure on fnl/playtime/common/components.fnl:123")
 local function pad_text(text) _G.assert((nil ~= text), "Missing argument text on fnl/playtime/common/components.fnl:124") return (" " .. text .. " ") end
 local function fill_text_width(text, width) _G.assert((nil ~= width), "Missing argument width on fnl/playtime/common/components.fnl:125") _G.assert((nil ~= text), "Missing argument text on fnl/playtime/common/components.fnl:125")
 return (text .. string.rep(" ", (width - #text))) end local hl = "@playtime.ui.menu"


 local function make_menubar_top_menu(text, tag, _18_, _3fchildren) local _arg_19_ = _18_ local row = _arg_19_["row"] local col = _arg_19_["col"] _G.assert((nil ~= col), "Missing argument col on fnl/playtime/common/components.fnl:129") _G.assert((nil ~= row), "Missing argument row on fnl/playtime/common/components.fnl:129") _G.assert((nil ~= tag), "Missing argument tag on fnl/playtime/common/components.fnl:129") _G.assert((nil ~= text), "Missing argument text on fnl/playtime/common/components.fnl:129")

 local function _20_(self, open_3f) self["set-content"](self, {{{text, hl}}})

 for _, c in ipairs((self.children or {})) do c["set-visible"](c, open_3f) end return nil end return Component["set-children"](Component["set-position"](Component["set-size"](Component["set-tag"](Component["set-content"](Component.build(_20_), {{{text, hl}}}), tag), {height = 1, width = #text}), {row = row, col = col, z = (z + 2)}), _3fchildren) end







 local function make_menubar_menu_entry(text, _3ftag, _21_, width) local _arg_22_ = _21_ local row = _arg_22_["row"] local col = _arg_22_["col"] _G.assert((nil ~= width), "Missing argument width on fnl/playtime/common/components.fnl:141") _G.assert((nil ~= col), "Missing argument col on fnl/playtime/common/components.fnl:141") _G.assert((nil ~= row), "Missing argument row on fnl/playtime/common/components.fnl:141") _G.assert((nil ~= text), "Missing argument text on fnl/playtime/common/components.fnl:141")
 return Component["set-visible"](Component["set-size"](Component["set-position"](Component["set-tag"](Component["set-content"](Component.build(), {{{fill_text_width(pad_text(text), width), hl}}}), _3ftag), {row = row, col = col, z = (z + 2)}), {height = 1, width = #fill_text_width(pad_text(text), width)}), false) end






 local top_menu_items do local top_items, col = {}, 1 for top_index, _23_ in ipairs(menu_structure) do
 local _each_24_ = _23_ local text = _each_24_[1] local _event = _each_24_[2] local _3fchildren = _each_24_[3]
 local top_text = pad_text(text) local widest_child
 do local w = #top_text for _, _25_ in ipairs((_3fchildren or {})) do local _each_26_ = _25_ local text0 = _each_26_[1]
 w = math.max(w, #pad_text(text0)) end widest_child = w end local children
 do local tbl_18_auto = {} local i_19_auto = 0 for child_index, _27_ in ipairs((_3fchildren or {})) do local _each_28_ = _27_ local text0 = _each_28_[1] local _event0 = _each_28_[2]
 local val_20_auto = make_menubar_menu_entry(text0, {"menu", top_index, child_index}, {row = child_index, col = (col - 1)}, widest_child) if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end children = tbl_18_auto end



 local item = make_menubar_top_menu(text, {"menu", top_index}, {row = 0, col = col}, children)


 top_items, col = table.insert(top_items, item), (col + 2 + #text) end top_menu_items = top_items, col end

 local menubar = Component["set-children"](Component["set-size"](Component["set-position"](Component["set-content"](Component.build(), {{{string.rep(" ", view_width), hl}}}), {row = 0, col = 0, z = (z + 1)}), {height = 1, width = view_width}), top_menu_items)




 do end (menubar)["menu"] = menu_structure
 return menubar end

 return M