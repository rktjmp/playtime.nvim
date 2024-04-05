
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"] local enabled_3f = false


 local M = {}

 local function view(x)
 local _2_, _3_ = pcall(require, "fennel") if ((_2_ == true) and ((_G.type(_3_) == "table") and (nil ~= _3_.view))) then local view0 = _3_.view
 return view0(x) elseif ((_2_ == false) and true) then local _ = _3_
 return vim.inspect(x) else return nil end end

 local fd = io.open(vim.fs.normalize((vim.fn.stdpath("log") .. "/playtime.log")), "a")

 M.info = function(msg, _3fdetails)
 local function get_detail(name)
 local _5_ = (_3fdetails or {})[name] local function _6_() local t = _5_ return type["table?"](t) end if ((nil ~= _5_) and _6_()) then local t = _5_
 local _7_ = getmetatable(t) local function _8_() local mt = _7_ return mt.__tostring end if ((nil ~= _7_) and _8_()) then local mt = _7_
 return mt.__tostring(t) else local _ = _7_
 return view(t) end elseif (nil ~= _5_) then local v = _5_
 return tostring(v) elseif (_5_ == nil) then
 return ("! missing detail value: " .. name .. " !") else return nil end end
 if enabled_3f then
 local msg0 if type["string?"](msg) then
 msg0 = string.gsub(msg, "#{(.-)}", get_detail) else
 msg0 = view(msg) end fd:write((os.date() .. " -- " .. msg0 .. "\n")) fd:flush() else end


 return nil end

 M.enable = function() enabled_3f = true return nil end
 M.disable = function() enabled_3f = false return nil end

 return M