
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Id = require("playtime.common.id")
 local Logger = require("playtime.logger")
 local Error = require("playtime.error")
 local Highlight = require("playtime.highlight")
 local Component = require("playtime.component")
 local _local_2_ = vim local api = _local_2_["api"]
 local M = {}

 local function position__3ecomponent_tags(_3_, row, col) local _arg_4_ = _3_ local buf = _arg_4_["buf"] local ns = _arg_4_["ns"] local win = _arg_4_["win"] local extmark_tags = _arg_4_["extmark-tags"] local view = _arg_4_
 local all_extmarks = vim.api.nvim_buf_get_extmarks(buf, ns, {row, 0}, {row, col}, {details = true}) local between_extmarks



 do local between = {} for i = #all_extmarks, 1, -1 do
 local _let_5_ = all_extmarks[i] local id = _let_5_[1] local _row = _let_5_[2] local extmark_col_start = _let_5_[3] local details = _let_5_[4]
 local _let_6_ = details local extmark_col_end = _let_6_["end_col"] local z = _let_6_["priority"]
 local is_between_3f = ((extmark_col_start <= col) and (col < extmark_col_end))
 local function _7_() if is_between_3f then return {id = id, z = z} else return nil end end between = table.insert(between, _7_()) end between_extmarks = between end local sorted_extmarks
 local function _12_(_8_, _10_) local _arg_9_ = _8_ local a = _arg_9_["z"] local _arg_11_ = _10_ local b = _arg_11_["z"] return (a > b) end sorted_extmarks = table.sort(between_extmarks, _12_)
 local tbl_18_auto = {} local i_19_auto = 0 for _, _13_ in ipairs(sorted_extmarks) do local _each_14_ = _13_ local id = _each_14_["id"]
 local val_20_auto = extmark_tags[id] if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto end

 local function mouse_defaults()
 local bindings = {}
 for _, side in ipairs({"Left", "Right"}) do
 for _0, sub in ipairs({"Mouse", "Drag", "Release"}) do
 local function _16_() return nil end table.set(bindings, ("<" .. side .. sub .. ">"), _16_) end end
 for _, count in ipairs({"2-", "3-", "4-"}) do
 local function _17_() return nil end table.set(bindings, ("<" .. count .. "LeftMouse" .. ">"), _17_) end
 for _, count in ipairs({"2-", "3-", "4-"}) do
 local function _18_() return nil end table.set(bindings, ("<" .. count .. "RightMouse" .. ">"), _18_) end
 return bindings end

 local function bind_mouse(_19_, lhs, desc, callback) local _arg_20_ = _19_ local win = _arg_20_["win"] local buf = _arg_20_["buf"] local view = _arg_20_ _G.assert((nil ~= callback), "Missing argument callback on fnl/playtime/app/window.fnl:37") _G.assert((nil ~= desc), "Missing argument desc on fnl/playtime/app/window.fnl:37") _G.assert((nil ~= lhs), "Missing argument lhs on fnl/playtime/app/window.fnl:37") _G.assert((nil ~= view), "Missing argument view on fnl/playtime/app/window.fnl:37") _G.assert((nil ~= buf), "Missing argument buf on fnl/playtime/app/window.fnl:37") _G.assert((nil ~= win), "Missing argument win on fnl/playtime/app/window.fnl:37")
 local eval_er = string.format("\"\\%s\"", lhs) local cb

 local function _21_() local _22_ = vim.fn.getmousepos() if ((_G.type(_22_) == "table") and (_22_.winid == win) and (nil ~= _22_.line) and (nil ~= _22_.column)) then local line = _22_.line local column = _22_.column

 local row = (line - 1)
 local col = (column - 1)
 local tags = position__3ecomponent_tags(view, (line - 1), (column - 1))
 return callback(lhs, tags, {row = row, col = col}) else local _ = _22_

 return vim.cmd(string.format("normal! %s", api.nvim_eval(string.format("\"\\%s\"", lhs)))) end end cb = vim.schedule_wrap(_21_)
 return api.nvim_buf_set_keymap(buf, "n", lhs, "", {callback = cb, desc = desc}) end

 local function bind_key(_24_, lhs, desc, callback) local _arg_25_ = _24_ local buf = _arg_25_["buf"]
 return api.nvim_buf_set_keymap(buf, "n", lhs, "", {callback = callback, desc = desc}) end

 M.open = function(filetype, dispatch, _26_) local _arg_27_ = _26_ local width = _arg_27_["width"] local height = _arg_27_["height"] local window_position = _arg_27_["window-position"] local minimise_position = _arg_27_["minimise-position"] _G.assert((nil ~= minimise_position), "Missing argument minimise-position on fnl/playtime/app/window.fnl:53") _G.assert((nil ~= window_position), "Missing argument window-position on fnl/playtime/app/window.fnl:53") _G.assert((nil ~= height), "Missing argument height on fnl/playtime/app/window.fnl:53") _G.assert((nil ~= width), "Missing argument width on fnl/playtime/app/window.fnl:53") _G.assert((nil ~= dispatch), "Missing argument dispatch on fnl/playtime/app/window.fnl:53") _G.assert((nil ~= filetype), "Missing argument filetype on fnl/playtime/app/window.fnl:53")
 local function sync_configs_to_geometry_21(max_config, min_config) _G.assert((nil ~= min_config), "Missing argument min-config on fnl/playtime/app/window.fnl:54") _G.assert((nil ~= max_config), "Missing argument max-config on fnl/playtime/app/window.fnl:54")
 local max_pos local function _28_(...) local _29_ = ... if ((_G.type(_29_) == "table") and (nil ~= _29_.row) and (nil ~= _29_.col)) then local row = _29_.row local col = _29_.col






 return {row = row, col = col} else local _3fpos = _29_

 local function _36_(...) local data_5_auto = {["?pos"] = _3fpos} local resolve_6_auto local function _30_(name_7_auto) local _31_ = data_5_auto[name_7_auto] local function _32_() local t_8_auto = _31_ return ("table" == type(t_8_auto)) end if ((nil ~= _31_) and _32_()) then local t_8_auto = _31_ local _33_ = getmetatable(t_8_auto) if ((_G.type(_33_) == "table") and (nil ~= _33_.__tostring)) then local f_9_auto = _33_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _33_ return vim.inspect(t_8_auto) end elseif (nil ~= _31_) then local v_11_auto = _31_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _30_ return string.gsub("Unsupported window position: #{?pos}", "#{(.-)}", resolve_6_auto) end return error(_36_(...)) end end local function _39_() if (window_position == "center") then return {row = 1, col = ((vim.o.columns / 2) - (width / 2))} elseif (window_position == "ne") then return {row = 1, col = (vim.o.columns - width)} elseif (window_position == "nw") then return {row = 1, col = 1} elseif ((_G.type(window_position) == "table") and (nil ~= window_position.row) and (nil ~= window_position.col)) then local row = window_position.row local col = window_position.col return {row = row, col = col} else local function _38_() local f = window_position return type["function?"](f) end if ((nil ~= window_position) and _38_()) then local f = window_position return f() else return nil end end end max_pos = _28_(_39_()) local min_pos
 local function _40_(...) local _41_ = ... if ((_G.type(_41_) == "table") and (nil ~= _41_.row) and (nil ~= _41_.col)) then local row = _41_.row local col = _41_.col







 return {row = row, col = col} else local _3fpos = _41_

 local function _48_(...) local data_5_auto = {["?pos"] = _3fpos} local resolve_6_auto local function _42_(name_7_auto) local _43_ = data_5_auto[name_7_auto] local function _44_() local t_8_auto = _43_ return ("table" == type(t_8_auto)) end if ((nil ~= _43_) and _44_()) then local t_8_auto = _43_ local _45_ = getmetatable(t_8_auto) if ((_G.type(_45_) == "table") and (nil ~= _45_.__tostring)) then local f_9_auto = _45_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _45_ return vim.inspect(t_8_auto) end elseif (nil ~= _43_) then local v_11_auto = _43_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _42_ return string.gsub("Unsupported minimise position: #{?pos}", "#{(.-)}", resolve_6_auto) end return error(_48_(...)) end end local function _51_() if (minimise_position == "ne") then return {row = 0, col = (vim.o.columns - 18)} elseif (minimise_position == "nw") then return {row = 0, col = 0} elseif (minimise_position == "sw") then return {row = (vim.o.lines - 3), col = 0} elseif (minimise_position == "se") then return {row = (vim.o.lines - 3), col = (vim.o.columns - 18)} elseif ((_G.type(minimise_position) == "table") and (nil ~= minimise_position.row) and (nil ~= minimise_position.col)) then local row = minimise_position.row local col = minimise_position.col return {row = row, col = col} else local function _50_() local f = minimise_position return type["function?"](f) end if ((nil ~= minimise_position) and _50_()) then local f = minimise_position return f() else return nil end end end min_pos = _40_(_51_())
 max_config.height = math.min(height, (vim.o.lines - 4))
 max_config.row = max_pos.row
 max_config.col = max_pos.col
 min_config.row = min_pos.row
 min_config.col = min_pos.col return nil end

 local win_maxi_config = {relative = "editor", width = width, height = height, style = "minimal", border = "shadow"}




 local win_mini_config = {relative = "editor", width = 18, height = 1, style = "minimal", border = "none"}




 local _ = sync_configs_to_geometry_21(win_maxi_config, win_mini_config)
 local buf = api.nvim_create_buf(false, true)
 local win = api.nvim_open_win(buf, true, win_maxi_config)
 local internal_name = string.format("%s-%s", filetype, Id.new())
 local ns = api.nvim_create_namespace((internal_name .. "-ns"))
 local augroup = api.nvim_create_augroup((internal_name .. "-augroup"), {clear = true})
 local user_guicursor_value = vim.o.guicursor
 local logo_component = Component["set-content"](Component["set-size"](Component["set-position"](Component.build(), {row = 0, col = 1, z = 500}), {width = vim.str_utfindex("\240\159\133\191 \240\159\133\187 \240\159\133\176 \240\159\134\136 \240\159\134\131i\240\159\133\184 \240\159\133\188 \240\159\133\180 "), height = 1}), {{{"\240\159\132\191 \240\159\132\187 \240\159\132\176 \240\159\133\136 \240\159\133\131 \240\159\132\184 \240\159\132\188 \240\159\132\180 ", "@playtime.ui.menu"}}})



 local view = {width = width, height = height, buf = buf, win = win, ns = ns, augroup = augroup, ["logo-component"] = logo_component}





 local function _52_() local tbl_18_auto = {} local i_19_auto = 0 for row = 1, (height * 2) do local val_20_auto = string.rep(" ", width) if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto end api.nvim_buf_set_lines(buf, 0, -1, false, _52_())
 api.nvim_buf_set_option(buf, "modifiable", false)
 api.nvim_buf_set_option(buf, "filetype", filetype)
 api.nvim_win_set_option(win, "wrap", false)
 api.nvim_win_set_hl_ns(win, ns)

 Highlight["define-highlights"](ns) vim.o.guicursor = "a:PlaytimeHiddenCursor"


 local _55_ do local t_54_ = dispatch if (nil ~= t_54_) then t_54_ = t_54_.window else end if (nil ~= t_54_) then t_54_ = t_54_.via else end _55_ = t_54_ end assert(_55_, "Must provide dispatch.window.via function")


 local function _60_(_58_) local _arg_59_ = _58_ local winid = _arg_59_["match"]
 if (winid == tostring(win)) then
 dispatch.window.via("quit")
 api.nvim_del_augroup_by_id(augroup)
 return true else return nil end end api.nvim_create_autocmd("WinClosed", {group = augroup, callback = _60_})


 local function _62_()
 local _0 = sync_configs_to_geometry_21(win_maxi_config, win_mini_config)

 if view["minimised?"] then
 return api.nvim_win_set_config(win, win_mini_config) else
 return api.nvim_win_set_config(win, win_maxi_config) end end api.nvim_create_autocmd("VimResized", {group = augroup, callback = _62_})


 local function _64_() return Highlight["define-highlights"](ns) end api.nvim_create_autocmd("ColorScheme", {group = augroup, callback = _64_})




 local function _65_()
 vim.o.guicursor = user_guicursor_value view["minimised?"] = true

 api.nvim_win_set_cursor(win, {1, 0})
 api.nvim_win_set_config(win, win_mini_config) return view:render({{logo_component}}) end api.nvim_create_autocmd("BufLeave", {group = augroup, buffer = buf, callback = _65_})







 local function _66_() vim.o.guicursor = "a:PlaytimeHiddenCursor" view["minimised?"] = false


 api.nvim_win_set_cursor(win, {1, 0})
 api.nvim_win_set_config(win, win_maxi_config)

 return dispatch.window.via("noop") end api.nvim_create_autocmd("BufEnter", {group = augroup, buffer = buf, callback = _66_})




 do local _67_ = dispatch.mouse if ((_G.type(_67_) == "table") and (nil ~= _67_.via) and (nil ~= _67_.events)) then local via = _67_.via local events = _67_.events

 local bindings local function _68_() local tbl_14_auto = {} for _0, event in ipairs(events) do
 local k_15_auto, v_16_auto = event, via if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end return tbl_14_auto end bindings = table.merge(mouse_defaults(), _68_())
 for key, cb in pairs(bindings) do
 local _70_ do local data_5_auto = {filetype = filetype} local resolve_6_auto local function _71_(name_7_auto) local _72_ = data_5_auto[name_7_auto] local function _73_() local t_8_auto = _72_ return ("table" == type(t_8_auto)) end if ((nil ~= _72_) and _73_()) then local t_8_auto = _72_ local _74_ = getmetatable(t_8_auto) if ((_G.type(_74_) == "table") and (nil ~= _74_.__tostring)) then local f_9_auto = _74_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _74_ return vim.inspect(t_8_auto) end elseif (nil ~= _72_) then local v_11_auto = _72_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _71_ _70_ = string.gsub("playtime #{filetype} dispatch", "#{(.-)}", resolve_6_auto) end bind_mouse(view, key, _70_, cb) end else local _0 = _67_
 for key, cb in pairs(mouse_defaults) do
 local _77_ do local data_5_auto = {filetype = filetype} local resolve_6_auto local function _78_(name_7_auto) local _79_ = data_5_auto[name_7_auto] local function _80_() local t_8_auto = _79_ return ("table" == type(t_8_auto)) end if ((nil ~= _79_) and _80_()) then local t_8_auto = _79_ local _81_ = getmetatable(t_8_auto) if ((_G.type(_81_) == "table") and (nil ~= _81_.__tostring)) then local f_9_auto = _81_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _81_ return vim.inspect(t_8_auto) end elseif (nil ~= _79_) then local v_11_auto = _79_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _78_ _77_ = string.gsub("playtime #{filetype} dispatch", "#{(.-)}", resolve_6_auto) end bind_mouse(view, key, _77_, cb) end end end

 return setmetatable(view, {__index = M}) end









































































 M.render = function(view, component_layers)
















 local component_layers0 if view["minimised?"] then
 component_layers0 = {{view["logo-component"]}} else
 component_layers0 = component_layers end
 local _let_86_ = view local frame_width = _let_86_["width"] local frame_height = _let_86_["height"] local ns = _let_86_["ns"] local buf = _let_86_["buf"] local win = _let_86_["win"]
 local _let_87_ = vim.api local nvim_buf_set_extmark = _let_87_["nvim_buf_set_extmark"]
 local extmark_tags = {}
 local overflow_height = (frame_height * 2)
 local function draw(component)
 if component["visible?"] then
 do local _let_88_ = component local row = _let_88_["row"] local col = _let_88_["col"] local width = _let_88_["width"] local height = _let_88_["height"] local _3ftag = _let_88_["tag"] local z = _let_88_["z"]
 for line = 1, height do







 if ((row + (line - 1)) <= (overflow_height - 1)) then
 local _let_89_ = component["content-at"](component, line) local extmark_id = _let_89_["extmark-id"] local content = _let_89_["content"]
 nvim_buf_set_extmark(buf, ns, (row + line + -1), col, {id = extmark_id, virt_text = content, virt_text_pos = "overlay", priority = z, end_col = math.clamp((col + width), 0, (frame_width - 1))})







 do end (extmark_tags)[extmark_id] = _3ftag else end end end
 for _, child in ipairs((component.children or {})) do
 draw(child) end return nil else return nil end end

 api.nvim_buf_clear_namespace(buf, ns, 0, -1)
 for _, layer in ipairs(component_layers0) do
 for _0, comp in ipairs(layer) do
 local function _92_() local row = comp.row local col = comp.col local comp0 = comp return (((0 <= col) and (col <= frame_width)) and (function(_93_,_94_,_95_) return (_93_ <= _94_) and (_94_ <= _95_) end)(0,row,(overflow_height - 1))) end if (((_G.type(comp) == "table") and (nil ~= comp.row) and (nil ~= comp.col)) and _92_()) then local row = comp.row local col = comp.col local comp0 = comp


 draw(comp0) else end end end

 view["extmark-tags"] = extmark_tags return nil end

 return M