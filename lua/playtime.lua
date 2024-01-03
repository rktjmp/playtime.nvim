
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local M = {}

 M.setup = function(_3fconfig)
 local config = (_3fconfig or {})
 local Config = require("playtime.config")
 local _2_, _3_ = Config.set(config) if ((_2_ == false) and (nil ~= _3_)) then local e = _3_
 return vim.notify(("Playtime: some values passed to setup were invalid, " .. "please run `:checkhealth playtime`\n"), vim.log.levels.WARN) else return nil end end



 M.play = function(game_name, _3fseed, _3fgame_config, _3fapp_config)
 local Config = require("playtime.config")
 local Meta = require("playtime.meta") local flat_meta
 do local t = {} for _, meta in ipairs(Meta.find()) do
 if ((_G.type(meta) == "table") and (nil ~= meta.rulesets)) then local rulesets = meta.rulesets
 local tbl_17_auto = t for _0, r in ipairs(rulesets) do table.insert(tbl_17_auto, {mod = meta.mod, ["game-name"] = r.cli, config = r.config}) end t = tbl_17_auto else local _0 = meta

 t = table.insert(t, {mod = meta.mod, ["game-name"] = meta.mod, config = {}}) end end flat_meta = t end local game_meta
 do local found = nil for _, meta in ipairs(flat_meta) do if found then break end
 if (game_name == meta["game-name"]) then found = meta else found = nil end end game_meta = found end

 local game_meta0 = (game_meta or {mod = game_name, ["game-name"] = game_name, config = {}})
 local function _7_(...) local _8_ = ... if ((_G.type(_8_) == "table") and (nil ~= _8_.mod) and (nil ~= _8_.config)) then local mod = _8_.mod local default_config = _8_.config local function _9_(...) local _10_ = ... if (nil ~= _10_) then local modname = _10_ local function _11_(...) local _12_ = ... if (nil ~= _12_) then local app_config = _12_ local function _13_(...) local _14_ = ... if (nil ~= _14_) then local game_config = _14_




 local _15_, _16_ = pcall(require, modname) if ((_15_ == true) and (nil ~= _16_)) then local mod0 = _16_
 return mod0.start(app_config, game_config, _3fseed) elseif ((_15_ == false) and (nil ~= _16_)) then local err = _16_
 return error(err) else return nil end else local _ = _14_

 local function _24_(...) local data_5_auto = {["game-name"] = game_name} local resolve_6_auto local function _18_(name_7_auto) local _19_ = data_5_auto[name_7_auto] local function _20_() local t_8_auto = _19_ return ("table" == type(t_8_auto)) end if ((nil ~= _19_) and _20_()) then local t_8_auto = _19_ local _21_ = getmetatable(t_8_auto) if ((_G.type(_21_) == "table") and (nil ~= _21_.__tostring)) then local f_9_auto = _21_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _21_ return vim.inspect(t_8_auto) end elseif (nil ~= _19_) then local v_11_auto = _19_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _18_ return string.gsub("Could not start game: #{game-name}", "#{(.-)}", resolve_6_auto) end return error(_24_(...)) end end return _13_(table.merge(clone(default_config), (_3fgame_config or {}))) else local _ = _12_ local function _32_(...) local data_5_auto = {["game-name"] = game_name} local resolve_6_auto local function _26_(name_7_auto) local _27_ = data_5_auto[name_7_auto] local function _28_() local t_8_auto = _27_ return ("table" == type(t_8_auto)) end if ((nil ~= _27_) and _28_()) then local t_8_auto = _27_ local _29_ = getmetatable(t_8_auto) if ((_G.type(_29_) == "table") and (nil ~= _29_.__tostring)) then local f_9_auto = _29_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _29_ return vim.inspect(t_8_auto) end elseif (nil ~= _27_) then local v_11_auto = _27_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _26_ return string.gsub("Could not start game: #{game-name}", "#{(.-)}", resolve_6_auto) end return error(_32_(...)) end end return _11_((_3fapp_config or table.merge({}, Config.get()))) else local _ = _10_ local function _40_(...) local data_5_auto = {["game-name"] = game_name} local resolve_6_auto local function _34_(name_7_auto) local _35_ = data_5_auto[name_7_auto] local function _36_() local t_8_auto = _35_ return ("table" == type(t_8_auto)) end if ((nil ~= _35_) and _36_()) then local t_8_auto = _35_ local _37_ = getmetatable(t_8_auto) if ((_G.type(_37_) == "table") and (nil ~= _37_.__tostring)) then local f_9_auto = _37_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _37_ return vim.inspect(t_8_auto) end elseif (nil ~= _35_) then local v_11_auto = _35_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _34_ return string.gsub("Could not start game: #{game-name}", "#{(.-)}", resolve_6_auto) end return error(_40_(...)) end end return _9_(("playtime.game." .. mod .. ".app")) else local _ = _8_ local function _48_(...) local data_5_auto = {["game-name"] = game_name} local resolve_6_auto local function _42_(name_7_auto) local _43_ = data_5_auto[name_7_auto] local function _44_() local t_8_auto = _43_ return ("table" == type(t_8_auto)) end if ((nil ~= _43_) and _44_()) then local t_8_auto = _43_ local _45_ = getmetatable(t_8_auto) if ((_G.type(_45_) == "table") and (nil ~= _45_.__tostring)) then local f_9_auto = _45_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _45_ return vim.inspect(t_8_auto) end elseif (nil ~= _43_) then local v_11_auto = _43_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _42_ return string.gsub("Could not start game: #{game-name}", "#{(.-)}", resolve_6_auto) end return error(_48_(...)) end end return _7_(game_meta0) end

 return M