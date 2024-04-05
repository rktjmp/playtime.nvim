
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Id = require("playtime.common.id")
 local Logger = require("playtime.logger")

 local M = {}




 M.encode = function(data)
 return vim.json.encode(data) end

 M.decode = function(data)
 local function re_id(data0)
 local _2_ = type(data0) if (_2_ == "table") then local tbl_14_auto = {}
 for key, val in pairs(data0) do local k_15_auto, v_16_auto = nil, nil
 do local key0 do local _3_ = tonumber(key) if (nil ~= _3_) then local num = _3_
 key0 = num elseif (_3_ == nil) then
 key0 = key else key0 = nil end end
 if ("id" == key0) then
 k_15_auto, v_16_auto = key0, Id.new() else
 k_15_auto, v_16_auto = key0, re_id(val) end end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end return tbl_14_auto else local _ = _2_
 return data0 end end
 return re_id(vim.json.decode(data, {luanil = {array = false, object = false}})) end


 M.write = function(path, data) _G.assert((nil ~= data), "Missing argument data on fnl/playtime/serializer.fnl:30") _G.assert((nil ~= path), "Missing argument path on fnl/playtime/serializer.fnl:30")
 local function _8_(...) local _9_ = ... if (nil ~= _9_) then local dir = _9_ local function _10_(...) local _11_ = ... if (_11_ == 1) then local function _12_(...) local _13_ = ... if (nil ~= _13_) then local fd = _13_ local function _14_(...) local _15_ = ... if (nil ~= _15_) then local ok = _15_ local function _16_(...) local _17_ = ... if (nil ~= _17_) then local ok0 = _17_ return true else local __85_auto = _17_ return ... end end return _16_(fd:close()) else local __85_auto = _15_ return ... end end return _14_(fd:write(M.encode(data))) else local __85_auto = _13_ return ... end end return _12_(io.open(path, "w")) else local __85_auto = _11_ return ... end end return _10_(vim.fn.mkdir(dir, "p")) else local __85_auto = _9_ return ... end end return _8_(vim.fs.dirname(path)) end







 M.read = function(path) _G.assert((nil ~= path), "Missing argument path on fnl/playtime/serializer.fnl:39")
 local function _23_(...) local _24_ = ... if (nil ~= _24_) then local fd = _24_ local function _25_(...) local _26_ = ... if (nil ~= _26_) then local json = _26_ local function _27_(...) local _28_ = ... if (nil ~= _28_) then local ok = _28_



 return M.decode(json) else local __85_auto = _28_ return ... end end return _27_(fd:close()) else local __85_auto = _26_ return ... end end return _25_(fd:read("*a")) else local __85_auto = _24_ return ... end end return _23_(io.open(path)) end

 return M