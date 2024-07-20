
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local M = {}

 local setup_config = {}
 M.setup = function(_3fconfig)



 setup_config = (_3fconfig or {}) return true end


 M.play = function(game_name, _3fseed, _3fgame_config, _3fapp_config)
 local Config = require("playtime.config")
 local Meta = require("playtime.meta") local flat_meta
 do local t = {} for _, meta in ipairs(Meta.find()) do
 if ((_G.type(meta) == "table") and (nil ~= meta.rulesets)) then local rulesets = meta.rulesets
 local tbl_19_auto = t for _0, r in ipairs(rulesets) do
 local val_20_auto = {mod = meta.mod, ["game-name"] = r.cli, config = r.config} table.insert(tbl_19_auto, val_20_auto) end t = tbl_19_auto else local _0 = meta
 t = table.insert(t, {mod = meta.mod, ["game-name"] = meta.mod, config = {}}) end end flat_meta = t end local game_meta
 do local found = nil for _, meta in ipairs(flat_meta) do if found then break end
 if (game_name == meta["game-name"]) then found = meta else found = nil end end game_meta = found end

 local game_meta0 = (game_meta or {mod = game_name, ["game-name"] = game_name, config = {}})
 local _4_, _5_ = Config.set(setup_config) if (_4_ == true) then
 local function _6_(...) local _7_ = ... if ((_G.type(_7_) == "table") and (nil ~= _7_.mod) and (nil ~= _7_.config)) then local mod = _7_.mod local default_config = _7_.config local function _8_(...) local _9_ = ... if (nil ~= _9_) then local modname = _9_ local function _10_(...) local _11_ = ... if (nil ~= _11_) then local app_config = _11_ local function _12_(...) local _13_ = ... if (nil ~= _13_) then local game_config = _13_




 local _14_, _15_ = pcall(require, modname) if ((_14_ == true) and (nil ~= _15_)) then local mod0 = _15_
 return mod0.start(app_config, game_config, _3fseed) elseif ((_14_ == false) and (nil ~= _15_)) then local err = _15_


 return error(err) else return nil end else local _ = _13_

 local function _24_(...) local data_5_auto = {["game-name"] = game_name} local resolve_6_auto local function _17_(name_7_auto) local _18_ = data_5_auto[name_7_auto] local and_19_ = (nil ~= _18_) if and_19_ then local t_8_auto = _18_ and_19_ = ("table" == type(t_8_auto)) end if and_19_ then local t_8_auto = _18_ local _21_ = getmetatable(t_8_auto) if ((_G.type(_21_) == "table") and (nil ~= _21_.__tostring)) then local f_9_auto = _21_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _21_ return vim.inspect(t_8_auto) end elseif (nil ~= _18_) then local v_11_auto = _18_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _17_ return string.gsub("Could not start game: #{game-name}", "#{(.-)}", resolve_6_auto) end return error(_24_(...)) end end return _12_(table.merge(clone(default_config), (_3fgame_config or {}))) else local _ = _11_ local function _33_(...) local data_5_auto = {["game-name"] = game_name} local resolve_6_auto local function _26_(name_7_auto) local _27_ = data_5_auto[name_7_auto] local and_28_ = (nil ~= _27_) if and_28_ then local t_8_auto = _27_ and_28_ = ("table" == type(t_8_auto)) end if and_28_ then local t_8_auto = _27_ local _30_ = getmetatable(t_8_auto) if ((_G.type(_30_) == "table") and (nil ~= _30_.__tostring)) then local f_9_auto = _30_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _30_ return vim.inspect(t_8_auto) end elseif (nil ~= _27_) then local v_11_auto = _27_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _26_ return string.gsub("Could not start game: #{game-name}", "#{(.-)}", resolve_6_auto) end return error(_33_(...)) end end return _10_((_3fapp_config or table.merge({}, Config.get()))) else local _ = _9_ local function _42_(...) local data_5_auto = {["game-name"] = game_name} local resolve_6_auto local function _35_(name_7_auto) local _36_ = data_5_auto[name_7_auto] local and_37_ = (nil ~= _36_) if and_37_ then local t_8_auto = _36_ and_37_ = ("table" == type(t_8_auto)) end if and_37_ then local t_8_auto = _36_ local _39_ = getmetatable(t_8_auto) if ((_G.type(_39_) == "table") and (nil ~= _39_.__tostring)) then local f_9_auto = _39_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _39_ return vim.inspect(t_8_auto) end elseif (nil ~= _36_) then local v_11_auto = _36_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _35_ return string.gsub("Could not start game: #{game-name}", "#{(.-)}", resolve_6_auto) end return error(_42_(...)) end end return _8_(("playtime.game." .. mod .. ".app")) else local _ = _7_ local function _51_(...) local data_5_auto = {["game-name"] = game_name} local resolve_6_auto local function _44_(name_7_auto) local _45_ = data_5_auto[name_7_auto] local and_46_ = (nil ~= _45_) if and_46_ then local t_8_auto = _45_ and_46_ = ("table" == type(t_8_auto)) end if and_46_ then local t_8_auto = _45_ local _48_ = getmetatable(t_8_auto) if ((_G.type(_48_) == "table") and (nil ~= _48_.__tostring)) then local f_9_auto = _48_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _48_ return vim.inspect(t_8_auto) end elseif (nil ~= _45_) then local v_11_auto = _45_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _44_ return string.gsub("Could not start game: #{game-name}", "#{(.-)}", resolve_6_auto) end return error(_51_(...)) end end return _6_(game_meta0) elseif ((_4_ == false) and (nil ~= _5_)) then local e = _5_
 return vim.notify(("Playtime: some values passed to setup were invalid, " .. "please run `:checkhealth playtime`\n"), vim.log.levels.WARN) else return nil end end



 return M