
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Id = require("playtime.common.id")
 local Logger = require("playtime.logger")
 local Error = require("playtime.error")
 local Highlight = require("playtime.highlight")
 local Component = require("playtime.component")
 local api = vim["api"]
 local M = {}

 local function position__3ecomponent_tags(_2_, row, col) local buf = _2_["buf"] local ns = _2_["ns"] local win = _2_["win"] local extmark_tags = _2_["extmark-tags"] local view = _2_
 local all_extmarks = vim.api.nvim_buf_get_extmarks(buf, ns, {row, 0}, {row, col}, {details = true}) local between_extmarks



 do local between = {} for i = #all_extmarks, 1, -1 do
 local _let_3_ = all_extmarks[i] local id = _let_3_[1] local _row = _let_3_[2] local extmark_col_start = _let_3_[3] local details = _let_3_[4]
 local extmark_col_end = details["end_col"] local z = details["priority"]
 local is_between_3f = ((extmark_col_start <= col) and (col < extmark_col_end))
 local function _4_() if is_between_3f then return {id = id, z = z} else return nil end end between = table.insert(between, _4_()) end between_extmarks = between end local sorted_extmarks
 local function _7_(_5_, _6_) local a = _5_["z"] local b = _6_["z"] return (a > b) end sorted_extmarks = table.sort(between_extmarks, _7_)
 local tbl_21_auto = {} local i_22_auto = 0 for _, _8_ in ipairs(sorted_extmarks) do local id = _8_["id"]
 local val_23_auto = extmark_tags[id] if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end

 local function mouse_defaults()
 local bindings = {}
 for _, side in ipairs({"Left", "Right"}) do
 for _0, sub in ipairs({"Mouse", "Drag", "Release"}) do
 local function _10_() return nil end table.set(bindings, ("<" .. side .. sub .. ">"), _10_) end end
 for _, count in ipairs({"2-", "3-", "4-"}) do
 local function _11_() return nil end table.set(bindings, ("<" .. count .. "LeftMouse" .. ">"), _11_) end
 for _, count in ipairs({"2-", "3-", "4-"}) do
 local function _12_() return nil end table.set(bindings, ("<" .. count .. "RightMouse" .. ">"), _12_) end
 return bindings end

 local function bind_mouse(_13_, lhs, desc, callback) local win = _13_["win"] local buf = _13_["buf"] local view = _13_ _G.assert((nil ~= callback), "Missing argument callback on fnl/playtime/app/window.fnl:37") _G.assert((nil ~= desc), "Missing argument desc on fnl/playtime/app/window.fnl:37") _G.assert((nil ~= lhs), "Missing argument lhs on fnl/playtime/app/window.fnl:37") _G.assert((nil ~= view), "Missing argument view on fnl/playtime/app/window.fnl:37") _G.assert((nil ~= buf), "Missing argument buf on fnl/playtime/app/window.fnl:37") _G.assert((nil ~= win), "Missing argument win on fnl/playtime/app/window.fnl:37")
 local cb
 local function _14_() local _15_ = vim.fn.getmousepos() if ((_G.type(_15_) == "table") and (_15_.winid == win) and (nil ~= _15_.line) and (nil ~= _15_.column)) then local line = _15_.line local column = _15_.column

 local row = (line - 1)
 local col = (column - 1)
 local tags = position__3ecomponent_tags(view, (line - 1), (column - 1))
 return callback(lhs, tags, {row = row, col = col}) else local _ = _15_

 return vim.cmd(string.format("normal! %s", api.nvim_eval(string.format("\"\\%s\"", lhs)))) end end cb = vim.schedule_wrap(_14_)
 return api.nvim_buf_set_keymap(buf, "n", lhs, "", {callback = cb, desc = desc}) end

 local function bind_key(_17_, lhs, desc, callback) local buf = _17_["buf"]
 return api.nvim_buf_set_keymap(buf, "n", lhs, "", {callback = callback, desc = desc}) end

 M.open = function(filetype, dispatch, _18_) local width = _18_["width"] local height = _18_["height"] local window_position = _18_["window-position"] local minimise_position = _18_["minimise-position"] _G.assert((nil ~= minimise_position), "Missing argument minimise-position on fnl/playtime/app/window.fnl:52") _G.assert((nil ~= window_position), "Missing argument window-position on fnl/playtime/app/window.fnl:52") _G.assert((nil ~= height), "Missing argument height on fnl/playtime/app/window.fnl:52") _G.assert((nil ~= width), "Missing argument width on fnl/playtime/app/window.fnl:52") _G.assert((nil ~= dispatch), "Missing argument dispatch on fnl/playtime/app/window.fnl:52") _G.assert((nil ~= filetype), "Missing argument filetype on fnl/playtime/app/window.fnl:52")
 local function mutate_configs_to_geometry_21(max_config, min_config) _G.assert((nil ~= min_config), "Missing argument min-config on fnl/playtime/app/window.fnl:53") _G.assert((nil ~= max_config), "Missing argument max-config on fnl/playtime/app/window.fnl:53")
 local max_pos local function _19_(...) local _20_ = ... if ((_G.type(_20_) == "table") and (nil ~= _20_.row) and (nil ~= _20_.col)) then local row = _20_.row local col = _20_.col






 return {row = row, col = col} else local _3fpos = _20_

 local function _28_(...) local data_5_auto = {["?pos"] = _3fpos} local resolve_6_auto local function _21_(name_7_auto) local _22_ = data_5_auto[name_7_auto] local and_23_ = (nil ~= _22_) if and_23_ then local t_8_auto = _22_ and_23_ = ("table" == type(t_8_auto)) end if and_23_ then local t_8_auto = _22_ local _25_ = getmetatable(t_8_auto) if ((_G.type(_25_) == "table") and (nil ~= _25_.__tostring)) then local f_9_auto = _25_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _25_ return vim.inspect(t_8_auto) end elseif (nil ~= _22_) then local v_11_auto = _22_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _21_ return string.gsub("Unsupported window position: #{?pos}", "#{(.-)}", resolve_6_auto) end return error(_28_(...)) end end local function _32_() if (window_position == "center") then return {row = 1, col = ((vim.o.columns / 2) - (width / 2))} elseif (window_position == "ne") then return {row = 1, col = (vim.o.columns - width)} elseif (window_position == "nw") then return {row = 1, col = 1} elseif ((_G.type(window_position) == "table") and (nil ~= window_position.row) and (nil ~= window_position.col)) then local row = window_position.row local col = window_position.col return {row = row, col = col} else local and_30_ = (nil ~= window_position) if and_30_ then local f = window_position and_30_ = type["function?"](f) end if and_30_ then local f = window_position return f() else return nil end end end max_pos = _19_(_32_()) local min_pos
 local function _33_(...) local _34_ = ... if ((_G.type(_34_) == "table") and (nil ~= _34_.row) and (nil ~= _34_.col)) then local row = _34_.row local col = _34_.col









 return {row = row, col = col} else local _3fpos = _34_

 local function _42_(...) local data_5_auto = {["?pos"] = _3fpos} local resolve_6_auto local function _35_(name_7_auto) local _36_ = data_5_auto[name_7_auto] local and_37_ = (nil ~= _36_) if and_37_ then local t_8_auto = _36_ and_37_ = ("table" == type(t_8_auto)) end if and_37_ then local t_8_auto = _36_ local _39_ = getmetatable(t_8_auto) if ((_G.type(_39_) == "table") and (nil ~= _39_.__tostring)) then local f_9_auto = _39_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _39_ return vim.inspect(t_8_auto) end elseif (nil ~= _36_) then local v_11_auto = _36_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _35_ return string.gsub("Unsupported minimise position: #{?pos}", "#{(.-)}", resolve_6_auto) end return error(_42_(...)) end end local function _46_() if (minimise_position == "ne") then return {row = 0, col = (vim.o.columns - 18)} elseif (minimise_position == "nw") then return {row = 0, col = 0} elseif (minimise_position == "sw") then return {row = (vim.o.lines - (2 + vim.o.cmdheight)), col = 0} elseif (minimise_position == "se") then return {row = (vim.o.lines - (2 + vim.o.cmdheight)), col = (vim.o.columns - 18)} elseif ((_G.type(minimise_position) == "table") and (nil ~= minimise_position.row) and (nil ~= minimise_position.col)) then local row = minimise_position.row local col = minimise_position.col return {row = row, col = col} else local and_44_ = (nil ~= minimise_position) if and_44_ then local f = minimise_position and_44_ = type["function?"](f) end if and_44_ then local f = minimise_position return f() else return nil end end end min_pos = _33_(_46_())
 max_config.height = math.min(height, (vim.o.lines - 4))
 max_config.row = max_pos.row
 max_config.col = max_pos.col
 min_config.row = min_pos.row
 min_config.col = min_pos.col return nil end

 local win_maxi_config = {relative = "editor", width = width, height = height, style = "minimal", border = "shadow"}




 local win_mini_config = {relative = "editor", width = 18, height = 1, style = "minimal", border = "none"}




 local _ = mutate_configs_to_geometry_21(win_maxi_config, win_mini_config)
 local buf = api.nvim_create_buf(false, true)
 local win = api.nvim_open_win(buf, true, win_maxi_config)
 local internal_name = string.format("%s-%s", filetype, Id.new())
 local ns = api.nvim_create_namespace((internal_name .. "-ns"))
 local augroup = api.nvim_create_augroup((internal_name .. "-augroup"), {clear = true})
 local user_guicursor_value = vim.o.guicursor
 local logo_component = Component["set-content"](Component["set-size"](Component["set-position"](Component.build(), {row = 0, col = 1, z = 500}), {width = string["col-width"]("\240\159\133\191 \240\159\133\187 \240\159\133\176 \240\159\134\136 \240\159\134\131i\240\159\133\184 \240\159\133\188 \240\159\133\180 "), height = 1}), {{{"\240\159\132\191 \240\159\132\187 \240\159\132\176 \240\159\133\136 \240\159\133\131 \240\159\132\184 \240\159\132\188 \240\159\132\180 ", "@playtime.ui.menu"}}})



 local view = {width = width, height = height, buf = buf, win = win, ns = ns, augroup = augroup, ["logo-component"] = logo_component}





 local function _47_() local tbl_21_auto = {} local i_22_auto = 0 for row = 1, (height * 2) do local val_23_auto = string.rep(" ", width) if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end api.nvim_buf_set_lines(buf, 0, -1, false, _47_())
 api.nvim_buf_set_option(buf, "modifiable", false)
 api.nvim_buf_set_option(buf, "filetype", ("playtime." .. filetype))
 api.nvim_win_set_option(win, "wrap", false)
 Highlight["define-highlights"]() vim.o.guicursor = "a:PlaytimeHiddenCursor"


 local _50_ do local t_49_ = dispatch if (nil ~= t_49_) then t_49_ = t_49_.window else end if (nil ~= t_49_) then t_49_ = t_49_.via else end _50_ = t_49_ end assert(_50_, "Must provide dispatch.window.via function")


 local function _54_(_53_) local winid = _53_["match"]
 if (winid == tostring(win)) then
 dispatch.window.via("quit")
 api.nvim_del_augroup_by_id(augroup) return true else return nil end end api.nvim_create_autocmd("WinClosed", {group = augroup, callback = _54_})



 local function _56_()
 mutate_configs_to_geometry_21(win_maxi_config, win_mini_config)
 if view["minimised?"] then
 api.nvim_win_set_config(win, win_mini_config) else
 api.nvim_win_set_config(win, win_maxi_config) end return false end api.nvim_create_autocmd("VimResized", {group = augroup, callback = _56_})



 local function _58_()
 Highlight["define-highlights"]() return false end api.nvim_create_autocmd("ColorScheme", {group = augroup, callback = _58_})





 local function _59_()
 vim.o.guicursor = user_guicursor_value view["minimised?"] = true

 api.nvim_win_set_cursor(win, {1, 0})
 api.nvim_win_set_config(win, win_mini_config) view:render({{logo_component}}) return false end api.nvim_create_autocmd("BufLeave", {group = augroup, buffer = buf, callback = _59_})





 local function _60_() vim.o.guicursor = "a:PlaytimeHiddenCursor" view["minimised?"] = false


 api.nvim_win_set_cursor(win, {1, 0})
 api.nvim_win_set_config(win, win_maxi_config)

 dispatch.window.via("noop") return false end api.nvim_create_autocmd("BufEnter", {group = augroup, buffer = buf, callback = _60_})


 do local _61_ = dispatch.mouse if ((_G.type(_61_) == "table") and (nil ~= _61_.via) and (nil ~= _61_.events)) then local via = _61_.via local events = _61_.events

 local bindings local function _62_() local tbl_16_auto = {} for _0, event in ipairs(events) do
 local k_17_auto, v_18_auto = event, via if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end return tbl_16_auto end bindings = table.merge(mouse_defaults(), _62_())
 for key, cb in pairs(bindings) do
 local _64_ do local data_5_auto = {filetype = filetype} local resolve_6_auto local function _65_(name_7_auto) local _66_ = data_5_auto[name_7_auto] local and_67_ = (nil ~= _66_) if and_67_ then local t_8_auto = _66_ and_67_ = ("table" == type(t_8_auto)) end if and_67_ then local t_8_auto = _66_ local _69_ = getmetatable(t_8_auto) if ((_G.type(_69_) == "table") and (nil ~= _69_.__tostring)) then local f_9_auto = _69_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _69_ return vim.inspect(t_8_auto) end elseif (nil ~= _66_) then local v_11_auto = _66_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _65_ _64_ = string.gsub("playtime #{filetype} dispatch", "#{(.-)}", resolve_6_auto) end bind_mouse(view, key, _64_, cb) end else local _0 = _61_
 for key, cb in pairs(mouse_defaults) do
 local _72_ do local data_5_auto = {filetype = filetype} local resolve_6_auto local function _73_(name_7_auto) local _74_ = data_5_auto[name_7_auto] local and_75_ = (nil ~= _74_) if and_75_ then local t_8_auto = _74_ and_75_ = ("table" == type(t_8_auto)) end if and_75_ then local t_8_auto = _74_ local _77_ = getmetatable(t_8_auto) if ((_G.type(_77_) == "table") and (nil ~= _77_.__tostring)) then local f_9_auto = _77_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _77_ return vim.inspect(t_8_auto) end elseif (nil ~= _74_) then local v_11_auto = _74_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _73_ _72_ = string.gsub("playtime #{filetype} dispatch", "#{(.-)}", resolve_6_auto) end bind_mouse(view, key, _72_, cb) end end end
 return setmetatable(view, {__index = M}) end

 M.render = function(view, component_layers)
















 local component_layers0 if view["minimised?"] then
 component_layers0 = {{view["logo-component"]}} else
 component_layers0 = component_layers end
 local frame_width = view["width"] local frame_height = view["height"] local ns = view["ns"] local buf = view["buf"] local win = view["win"]
 local nvim_buf_set_extmark = vim.api["nvim_buf_set_extmark"]
 local extmark_tags = {}
 local overflow_height = (frame_height * 2)
 local function draw(component)
 if component["visible?"] then
 do local row = component["row"] local col = component["col"] local width = component["width"] local height = component["height"] local _3ftag = component["tag"] local z = component["z"]
 for line = 1, height do







 if ((row + (line - 1)) <= (overflow_height - 1)) then
 local _let_82_ = component["content-at"](component, line) local extmark_id = _let_82_["extmark-id"] local content = _let_82_["content"]
 nvim_buf_set_extmark(buf, ns, (row + line + -1), col, {id = extmark_id, virt_text = content, virt_text_pos = "overlay", priority = z, end_col = math.clamp((col + width), 0, (frame_width - 1))})







 extmark_tags[extmark_id] = _3ftag else end end end
 for _, child in ipairs((component.children or {})) do
 draw(child) end return nil else return nil end end

 api.nvim_buf_clear_namespace(buf, ns, 0, -1)
 for _, layer in ipairs(component_layers0) do
 for _0, comp in ipairs(layer) do
 local and_85_ = ((_G.type(comp) == "table") and (nil ~= comp.row) and (nil ~= comp.col)) if and_85_ then local row = comp.row local col = comp.col local comp0 = comp and_85_ = (((0 <= col) and (col <= frame_width)) and ((0 <= row) and (row <= (overflow_height - 1)))) end if and_85_ then local row = comp.row local col = comp.col local comp0 = comp


 draw(comp0) else end end end

 view["extmark-tags"] = extmark_tags return nil end

 return M