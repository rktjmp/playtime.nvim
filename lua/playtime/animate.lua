
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local M = {}
 local uv = (vim.loop or vim.uv)

 M.timeline = function(config) _G.assert((nil ~= config), "Missing argument config on fnl/playtime/animate.fnl:7")
 local animations, after_start_at = nil, nil do local animations0, max_finish_at = {}, -1 for delay, spec in pairs(config) do

 if type["number?"](delay) then
 local f = spec[1] local duration = spec[2] local tick = spec[3]
 local ani = f((uv.now() + delay), duration, tick)
 animations0, max_finish_at = table.insert(animations0, ani), math.max(max_finish_at, ani["finish-at"]) else

 animations0, max_finish_at = animations0, max_finish_at end end animations, after_start_at = animations0, max_finish_at end
 if config.after then
 local function _3_() return config.after() end table.insert(animations, M.linear(after_start_at, 0, _3_)) else end
 return animations end

 local function animation(easing, start_at, duration, on_tick)
 local function tick(ani, now)
 local start_at0 = ani["start-at"] local duration0 = ani["duration"]
 local percent = easing(math.clamp(((now - start_at0) / duration0), 0, 1))

 return on_tick(percent) end
 return {["start-at"] = start_at, ["finish-at"] = (start_at + duration), tick = tick, duration = duration} end




 M.linear = function(...)
 local function _5_(percent) return math.max(0, math.min(1, percent)) end return animation(_5_, ...) end

 M["ease-out-quad"] = function(...)
 local function _6_(percent) return (1 - ((1 - percent) * (1 - percent))) end return animation(_6_, ...) end

 M["ease-in-quad"] = function(...)
 local function _7_(percent) return (percent * percent) end return animation(_7_, ...) end

 M["ease-in-back"] = function(...) local c1 = 1.70156

 local c3 = (c1 + 1)
 local function _8_(_241) return ((c3 * _241 * _241 * _241) - (c1 * _241 * _241)) end return animation(_8_, ...) end

 M["ease-out-back"] = function(...) local c1 = 1.70156

 local c3 = (c1 + 1)
 local function _9_(_241) return (1 + (c3 * math.pow((_241 - 1), 3)) + (c1 * math.pow((_241 - 1), 2))) end return animation(_9_, ...) end

 M["ease-in-out-back"] = function(...) local c1 = 1.70156

 local c2 = (c1 * 1.525)
 local function f(x)
 if (x < 0.5) then
 return ((math.pow((2 * x), 2) * (((c2 + 1) * (2 * x)) - c2)) / 2) else
 return (((math.pow(((2 * x) - 2), 2) * (((c2 + 1) * ((x * 2) - 2)) + c2)) + 2) / 2) end end
 return animation(f, ...) end

 return M