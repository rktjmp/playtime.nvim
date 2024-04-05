
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
 local tbl_17_auto = t for _0, r in ipairs(rulesets) do
 local val_18_auto = {mod = meta.mod, ["game-name"] = r.cli, config = r.config} table.insert(tbl_17_auto, val_18_auto) end t = tbl_17_auto else local _0 = meta
 t = table.insert(t, {mod = meta.mod, ["game-name"] = meta.mod, config = {}}) end end flat_meta = t end local game_meta
 do local found = nil for _, meta in ipairs(flat_meta) do if found then break end
 if (game_name == meta["game-name"]) then found = meta else found = nil end end game_meta = found end

 local game_meta0 = (game_meta or {mod = game_name, ["game-name"] = game_name, config = {}})
 local _4_, _5_ = Config.set(setup_config) if (_4_ == true) then
 local function _6_(...) local _7_ = ... if ((_G.type(_7_) == "table") and (nil ~= _7_.mod) and (nil ~= _7_.config)) then local mod = _7_.mod local default_config = _7_.config local function _8_(...) local _9_ = ... if (nil ~= _9_) then local modname = _9_ local function _10_(...) local _11_ = ... if (nil ~= _11_) then local app_config = _11_ local function _12_(...) local _13_ = ... if (nil ~= _13_) then local game_config = _13_




 local _14_, _15_ = pcall(require, modname) if ((_14_ == true) and (nil ~= _15_)) then local mod0 = _15_
 return mod0.start(app_config, game_config, _3fseed) elseif ((_14_ == false) and (nil ~= _15_)) then local err = _15_
 return error(err) else return nil end else local _ = _13_

 local function _23_(...) local data_5_auto = {["game-name"] = game_name} local resolve_6_auto local function _17_(name_7_auto) local _18_ = data_5_auto[name_7_auto] local function _19_() local t_8_auto = _18_ return ("table" == type(t_8_auto)) end if ((nil ~= _18_) and _19_()) then local t_8_auto = _18_ local _20_ = getmetatable(t_8_auto) if ((_G.type(_20_) == "table") and (nil ~= _20_.__tostring)) then local f_9_auto = _20_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _20_ return vim.inspect(t_8_auto) end elseif (nil ~= _18_) then local v_11_auto = _18_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _17_ return string.gsub("Could not start game: #{game-name}", "#{(.-)}", resolve_6_auto) end return error(_23_(...)) end end return _12_(table.merge(clone(default_config), (_3fgame_config or {}))) else local _ = _11_ local function _31_(...) local data_5_auto = {["game-name"] = game_name} local resolve_6_auto local function _25_(name_7_auto) local _26_ = data_5_auto[name_7_auto] local function _27_() local t_8_auto = _26_ return ("table" == type(t_8_auto)) end if ((nil ~= _26_) and _27_()) then local t_8_auto = _26_ local _28_ = getmetatable(t_8_auto) if ((_G.type(_28_) == "table") and (nil ~= _28_.__tostring)) then local f_9_auto = _28_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _28_ return vim.inspect(t_8_auto) end elseif (nil ~= _26_) then local v_11_auto = _26_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _25_ return string.gsub("Could not start game: #{game-name}", "#{(.-)}", resolve_6_auto) end return error(_31_(...)) end end return _10_((_3fapp_config or table.merge({}, Config.get()))) else local _ = _9_ local function _39_(...) local data_5_auto = {["game-name"] = game_name} local resolve_6_auto local function _33_(name_7_auto) local _34_ = data_5_auto[name_7_auto] local function _35_() local t_8_auto = _34_ return ("table" == type(t_8_auto)) end if ((nil ~= _34_) and _35_()) then local t_8_auto = _34_ local _36_ = getmetatable(t_8_auto) if ((_G.type(_36_) == "table") and (nil ~= _36_.__tostring)) then local f_9_auto = _36_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _36_ return vim.inspect(t_8_auto) end elseif (nil ~= _34_) then local v_11_auto = _34_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _33_ return string.gsub("Could not start game: #{game-name}", "#{(.-)}", resolve_6_auto) end return error(_39_(...)) end end return _8_(("playtime.game." .. mod .. ".app")) else local _ = _7_ local function _47_(...) local data_5_auto = {["game-name"] = game_name} local resolve_6_auto local function _41_(name_7_auto) local _42_ = data_5_auto[name_7_auto] local function _43_() local t_8_auto = _42_ return ("table" == type(t_8_auto)) end if ((nil ~= _42_) and _43_()) then local t_8_auto = _42_ local _44_ = getmetatable(t_8_auto) if ((_G.type(_44_) == "table") and (nil ~= _44_.__tostring)) then local f_9_auto = _44_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _44_ return vim.inspect(t_8_auto) end elseif (nil ~= _42_) then local v_11_auto = _42_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _41_ return string.gsub("Could not start game: #{game-name}", "#{(.-)}", resolve_6_auto) end return error(_47_(...)) end end return _6_(game_meta0) elseif ((_4_ == false) and (nil ~= _5_)) then local e = _5_
 return vim.notify(("Playtime: some values passed to setup were invalid, " .. "please run `:checkhealth playtime`\n"), vim.log.levels.WARN) else return nil end end



 return M