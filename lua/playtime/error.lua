
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]


 local function Error(msg, _3fdetails)
 local function get_detail(name)
 local _2_ = (_3fdetails or {})[name] local function _3_() local t = _2_ return type["table?"](t) end if ((nil ~= _2_) and _3_()) then local t = _2_
 local _4_ = getmetatable(t) if ((_G.type(_4_) == "table") and (nil ~= _4_.__tostring)) then local f = _4_.__tostring
 return f(t) else local _ = _4_
 return vim.inspect(t) end elseif (nil ~= _2_) then local v = _2_
 return tostring(v) elseif (_2_ == nil) then
 return ("! missing detail value: " .. name .. " !") else return nil end end

 local msg0 = string.gsub(msg, "#{(.-)}", get_detail)
 local e = {msg = msg0, details = _3fdetails} local mt
 local function _7_() return msg0 end mt = {__tostring = _7_}
 return setmetatable(e, mt) end return Error