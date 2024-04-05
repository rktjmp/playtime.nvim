
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Error = require("playtime.error")
 local Id = require("playtime.common.id")
 local uv = (vim.loop or vim.uv)

 local M = {}

 M.build = function(_3fupdate_fn)






 local function _2_(_241) return _241 end return setmetatable({id = Id.new(), ["visible?"] = true, children = nil, ["animation-queue"] = {}, ["deferred-updates"] = {}}, {__index = M, __call = (_3fupdate_fn or _2_)}) end

 M["build-with"] = function(data)







 local function _3_(comp, ...)
 if ((_G.type(comp) == "table") and (nil ~= comp.update)) then local update = comp.update
 return update(comp, ...) else local _ = comp
 return comp end end return setmetatable(table.merge({id = Id.new(), ["visible?"] = true, children = nil, ["animation-queue"] = {}, ["deferred-updates"] = {}}, data), {__index = M, __call = _3_}) end

 M["set-visible"] = function(c, v_3f)
 c["visible?"] = v_3f return c end

 M["set-children"] = function(c, _3fchildren)
 c["children"] = _3fchildren return c end

 M["set-tag"] = function(c, tag)

 return table.set(c, "tag", tag) end

 M["set-size"] = function(c, _5_) local _arg_6_ = _5_ local width = _arg_6_["width"] local height = _arg_6_["height"]
 return table.merge(c, {width = width, height = height}) end

 M["set-position"] = function(c, _7_) local _arg_8_ = _7_ local row = _arg_8_["row"] local col = _arg_8_["col"] local z = _arg_8_["z"]
 return table.merge(c, {row = row, col = col, z = z}) end

 M["set-content"] = function(c, content)
 local function _draw(c0, lines, line_number)
 return (lines[line_number] or error(Error("No line #{line-number} for component #{id}", {["line-number"] = line_number, id = c0.id}))) end



 local lines do local _9_ = type(content) if (_9_ == "table") then
 lines = content elseif (_9_ == "function") then
 lines = content(c) elseif (nil ~= _9_) then local other = _9_
 local function _16_() local data_5_auto = {other = other} local resolve_6_auto local function _10_(name_7_auto) local _11_ = data_5_auto[name_7_auto] local function _12_() local t_8_auto = _11_ return ("table" == type(t_8_auto)) end if ((nil ~= _11_) and _12_()) then local t_8_auto = _11_ local _13_ = getmetatable(t_8_auto) if ((_G.type(_13_) == "table") and (nil ~= _13_.__tostring)) then local f_9_auto = _13_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _13_ return vim.inspect(t_8_auto) end elseif (nil ~= _11_) then local v_11_auto = _11_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _10_ return string.gsub("Unsupported content type #{other}", "#{(.-)}", resolve_6_auto) end lines = error(_16_()) else lines = nil end end local lines0
 do local tbl_19_auto = {} local i_20_auto = 0 for i, line in ipairs(lines) do local val_21_auto local function _18_(...)
 local t_19_ = c if (nil ~= t_19_) then t_19_ = t_19_.content else end if (nil ~= t_19_) then t_19_ = t_19_[i] else end if (nil ~= t_19_) then t_19_ = t_19_["extmark-id"] else end return t_19_ end val_21_auto = {["extmark-id"] = (_18_() or Id.new()), content = line} if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end lines0 = tbl_19_auto end

 c["content"] = lines0

 local function _24_(c0, line_number)
 return _draw(c0, c0.content, line_number) end c["content-at"] = _24_ return c end

 M["queue-animation"] = function(c, animation)
 return table.set(c, "animation-queue", table.insert(c["animation-queue"], animation)) end

 M.update = function(c, ...)
















 local args = table.pack(...) local call
 local function _25_() return c(table.unpack(args)) end call = _25_
 table.insert(c["deferred-updates"], call)
 if (0 < #c["animation-queue"]) then
 local now = uv.now() local animations
 do local tbl_19_auto = {} local i_20_auto = 0 for i, animation in ipairs(c["animation-queue"]) do local val_21_auto
 do local _let_26_ = animation local finish_at = _let_26_["finish-at"] local start_at = _let_26_["start-at"]
 if (start_at <= now) then animation:tick(now) else end

 if (now < finish_at) then
 val_21_auto = animation else val_21_auto = nil end end if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end animations = tbl_19_auto end
 c["animation-queue"] = animations else end
 if (0 == #c["animation-queue"]) then
 for _, deferred_update in ipairs(c["deferred-updates"]) do
 deferred_update() end
 c["deferred-updates"] = {} else end
 return c end

 return M