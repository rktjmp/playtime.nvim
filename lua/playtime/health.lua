
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local M = {}
 local uv = (vim.uv or vim.loop)

 local function _4_(...) local _3_ = vim.health if ((_G.type(_3_) == "table") and (nil ~= _3_.ok) and (nil ~= _3_.info) and (nil ~= _3_.error) and (nil ~= _3_.start)) then local ok = _3_.ok local info = _3_.info local error = _3_.error local start = _3_.start

 return {report_start = start, report_info = info, report_error = error, report_ok = ok} elseif (nil ~= _3_) then local other = _3_




 return other else return nil end end local _local_2_ = _4_(...) local report_start = _local_2_["report_start"] local report_info = _local_2_["report_info"] local report_ok = _local_2_["report_ok"] local report_error = _local_2_["report_error"]

 local function check_config()
 report_start("Playtime Configuration")
 local Config = require("playtime.config")
 local _6_, _7_ = Config.health() if (_6_ == true) then
 return report_ok("Config is ok") elseif ((_6_ == false) and (nil ~= _7_)) then local e = _7_
 for _, msg in ipairs(e) do
 report_error(msg) end return nil else return nil end end

 local function check_disk()
 report_start("Playtime Data")

 local dir = vim.fs.normalize(string.format("%s/playtime", vim.fn.stdpath("data")))

 local paths = vim.fn.globpath(dir, "**", true, true, true)
 local count = #paths local size
 do local size0 = 0 for _, p in ipairs(paths) do local function _9_(...)
 local t_10_ = uv.fs_stat(p) if (nil ~= t_10_) then t_10_ = t_10_.size else end return t_10_ end size0 = (size0 + _9_() + 0) end size = size0 end
 local size0 = math.floor((size / 1024))
 local function _18_() local data_5_auto = {dir = dir} local resolve_6_auto local function _12_(name_7_auto) local _13_ = data_5_auto[name_7_auto] local function _14_() local t_8_auto = _13_ return ("table" == type(t_8_auto)) end if ((nil ~= _13_) and _14_()) then local t_8_auto = _13_ local _15_ = getmetatable(t_8_auto) if ((_G.type(_15_) == "table") and (nil ~= _15_.__tostring)) then local f_9_auto = _15_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _15_ return vim.inspect(t_8_auto) end elseif (nil ~= _13_) then local v_11_auto = _13_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _12_ return string.gsub("Data-dir: #{dir}", "#{(.-)}", resolve_6_auto) end report_info(_18_())
 local function _25_() local data_5_auto = {count = count, size = size0} local resolve_6_auto local function _19_(name_7_auto) local _20_ = data_5_auto[name_7_auto] local function _21_() local t_8_auto = _20_ return ("table" == type(t_8_auto)) end if ((nil ~= _20_) and _21_()) then local t_8_auto = _20_ local _22_ = getmetatable(t_8_auto) if ((_G.type(_22_) == "table") and (nil ~= _22_.__tostring)) then local f_9_auto = _22_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _22_ return vim.inspect(t_8_auto) end elseif (nil ~= _20_) then local v_11_auto = _20_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _19_ return string.gsub("#{count} files, #{size}kb", "#{(.-)}", resolve_6_auto) end return report_info(_25_()) end

 M.check = function()
 check_config()
 return check_disk() end

 return M