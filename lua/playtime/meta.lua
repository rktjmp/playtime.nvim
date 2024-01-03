
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local M = {}

 M.find = function()
 local files = vim.api.nvim_get_runtime_file("lua/playtime/game/*/meta.lua", true)

 local tbl_18_auto = {} local i_19_auto = 0 for _, f in ipairs(files) do local val_20_auto
 do local mod = string.match(f, "game.(.-).meta.lua$")
 local _2_, _3_ = nil, nil local function _10_() local data_5_auto = {mod = mod} local resolve_6_auto local function _4_(name_7_auto) local _5_ = data_5_auto[name_7_auto] local function _6_() local t_8_auto = _5_ return ("table" == type(t_8_auto)) end if ((nil ~= _5_) and _6_()) then local t_8_auto = _5_ local _7_ = getmetatable(t_8_auto) if ((_G.type(_7_) == "table") and (nil ~= _7_.__tostring)) then local f_9_auto = _7_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _7_ return vim.inspect(t_8_auto) end elseif (nil ~= _5_) then local v_11_auto = _5_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _4_ return string.gsub("playtime.game.#{mod}.meta", "#{(.-)}", resolve_6_auto) end _2_, _3_ = pcall(require, _10_()) if ((_2_ == true) and (nil ~= _3_)) then local mod0 = _3_
 val_20_auto = mod0 elseif ((_2_ == false) and (nil ~= _3_)) then local err = _3_
 val_20_auto = nil else val_20_auto = nil end end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto end

 return M