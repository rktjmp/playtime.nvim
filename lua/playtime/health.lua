
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local M = {}
 local uv = (vim.uv or vim.loop)

 local function _3_(...) local _2_ = vim.health if ((_G.type(_2_) == "table") and (nil ~= _2_.ok) and (nil ~= _2_.info) and (nil ~= _2_.error) and (nil ~= _2_.start)) then local ok = _2_.ok local info = _2_.info local error = _2_.error local start = _2_.start

 return {report_start = start, report_info = info, report_error = error, report_ok = ok} elseif (nil ~= _2_) then local other = _2_




 return other else return nil end end local _local_5_ = _3_(...) local report_start = _local_5_["report_start"] local report_info = _local_5_["report_info"] local report_ok = _local_5_["report_ok"] local report_error = _local_5_["report_error"]

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
 do local size0 = 0 for _, p in ipairs(paths) do
 local _10_ do local t_9_ = uv.fs_stat(p) if (nil ~= t_9_) then t_9_ = t_9_.size else end _10_ = t_9_ end size0 = (size0 + _10_ + 0) end size = size0 end
 local size0 = math.floor((size / 1024))
 local function _19_() local data_5_auto = {dir = dir} local resolve_6_auto local function _12_(name_7_auto) local _13_ = data_5_auto[name_7_auto] local and_14_ = (nil ~= _13_) if and_14_ then local t_8_auto = _13_ and_14_ = ("table" == type(t_8_auto)) end if and_14_ then local t_8_auto = _13_ local _16_ = getmetatable(t_8_auto) if ((_G.type(_16_) == "table") and (nil ~= _16_.__tostring)) then local f_9_auto = _16_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _16_ return vim.inspect(t_8_auto) end elseif (nil ~= _13_) then local v_11_auto = _13_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _12_ return string.gsub("Data-dir: #{dir}", "#{(.-)}", resolve_6_auto) end report_info(_19_())
 local function _27_() local data_5_auto = {count = count, size = size0} local resolve_6_auto local function _20_(name_7_auto) local _21_ = data_5_auto[name_7_auto] local and_22_ = (nil ~= _21_) if and_22_ then local t_8_auto = _21_ and_22_ = ("table" == type(t_8_auto)) end if and_22_ then local t_8_auto = _21_ local _24_ = getmetatable(t_8_auto) if ((_G.type(_24_) == "table") and (nil ~= _24_.__tostring)) then local f_9_auto = _24_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _24_ return vim.inspect(t_8_auto) end elseif (nil ~= _21_) then local v_11_auto = _21_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _20_ return string.gsub("#{count} files, #{size}kb", "#{(.-)}", resolve_6_auto) end return report_info(_27_()) end

 M.check = function()
 check_config()
 return check_disk() end

 return M