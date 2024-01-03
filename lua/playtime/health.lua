
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local M = {}
 local uv = (vim.uv or vim.loop)

 local function check_config()
 vim.health.report_start("Playtime Configuration")
 local Config = require("playtime.config")
 local _2_, _3_ = Config.health() if (_2_ == true) then
 return vim.health.report_ok("Config is ok") elseif ((_2_ == false) and (nil ~= _3_)) then local e = _3_
 for _, msg in ipairs(e) do
 vim.health.report_error(msg) end return nil else return nil end end

 local function check_disk()
 vim.health.report_start("Playtime Data")

 local dir = vim.fs.normalize(string.format("%s/playtime", vim.fn.stdpath("data")))

 local paths = vim.fn.globpath(dir, "**", true, true, true)
 local count = #paths local size
 do local size0 = 0 for _, p in ipairs(paths) do local function _5_(...)
 local t_6_ = uv.fs_stat(p) if (nil ~= t_6_) then t_6_ = t_6_.size else end return t_6_ end size0 = (size0 + _5_() + 0) end size = size0 end
 local size0 = math.floor((size / 1024))
 local function _14_() local data_5_auto = {dir = dir} local resolve_6_auto local function _8_(name_7_auto) local _9_ = data_5_auto[name_7_auto] local function _10_() local t_8_auto = _9_ return ("table" == type(t_8_auto)) end if ((nil ~= _9_) and _10_()) then local t_8_auto = _9_ local _11_ = getmetatable(t_8_auto) if ((_G.type(_11_) == "table") and (nil ~= _11_.__tostring)) then local f_9_auto = _11_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _11_ return vim.inspect(t_8_auto) end elseif (nil ~= _9_) then local v_11_auto = _9_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _8_ return string.gsub("Data-dir: #{dir}", "#{(.-)}", resolve_6_auto) end vim.health.report_info(_14_())
 local function _21_() local data_5_auto = {count = count, size = size0} local resolve_6_auto local function _15_(name_7_auto) local _16_ = data_5_auto[name_7_auto] local function _17_() local t_8_auto = _16_ return ("table" == type(t_8_auto)) end if ((nil ~= _16_) and _17_()) then local t_8_auto = _16_ local _18_ = getmetatable(t_8_auto) if ((_G.type(_18_) == "table") and (nil ~= _18_.__tostring)) then local f_9_auto = _18_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _18_ return vim.inspect(t_8_auto) end elseif (nil ~= _16_) then local v_11_auto = _16_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _15_ return string.gsub("#{count} files, #{size}kb", "#{(.-)}", resolve_6_auto) end return vim.health.report_info(_21_()) end

 M.check = function()
 check_config()
 return check_disk() end

 return M