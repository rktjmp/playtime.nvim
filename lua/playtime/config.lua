
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local M = {}

 local schema
 local function _2_(_241) return (type["number?"](_241) and (1 <= _241)) end
 local function _3_(_241) local function _4_(...)
 if ((_G.type(_241) == "table") and (nil ~= _241.row) and (nil ~= _241.col)) then local row = _241.row local col = _241.col return true else local __1_auto = _241 return false end end return (eq_any_3f(_241, {"center", "nw", "ne"}) or _4_() or type["function?"](_241)) end


 local function _6_(_241) local function _7_(...)
 if ((_G.type(_241) == "table") and (nil ~= _241.row) and (nil ~= _241.col)) then local row = _241.row local col = _241.col return true else local __1_auto = _241 return false end end return (eq_any_3f(_241, {"ne", "nw", "se", "sw"}) or _7_() or type["function?"](_241)) end


 local function _9_(_241) return eq_any_3f(_241, {"minimise"}) end schema = {fps = {_2_, "must be positive integer"}, ["window-position"] = {_3_, "must be `center`, `nw`, `ne` or a table or function returning`{row=row, col=col}`"}, ["minimise-position"] = {_6_, "must be `ne`, `nw`, `se`, `sw` or a table or function returning`{row=row, col=col}`"}, unfocused = {_9_, "must be `minimise`"}}



 local defaults = {fps = 30, ["window-position"] = "center", ["minimise-position"] = "se", unfocused = "minimise"}




 local user_config = {}
 local errors = nil

 M["valid?"] = function(config)
 if type["table?"](config) then
 local e do local tbl_18_auto = {} local i_19_auto = 0 for k, v in pairs(config) do local val_20_auto
 do local _10_ = schema[k] if ((_G.type(_10_) == "table") and (nil ~= _10_[1]) and (nil ~= _10_[2])) then local f = _10_[1] local msg = _10_[2]
 if not f(v) then local data_5_auto = {k = k, msg = msg}
 local resolve_6_auto local function _11_(name_7_auto) local _12_ = data_5_auto[name_7_auto] local function _13_() local t_8_auto = _12_ return ("table" == type(t_8_auto)) end if ((nil ~= _12_) and _13_()) then local t_8_auto = _12_ local _14_ = getmetatable(t_8_auto) if ((_G.type(_14_) == "table") and (nil ~= _14_.__tostring)) then local f_9_auto = _14_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _14_ return vim.inspect(t_8_auto) end elseif (nil ~= _12_) then local v_11_auto = _12_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _11_ val_20_auto = string.gsub("config key `#{k}` did not pass validation, #{msg}", "#{(.-)}", resolve_6_auto) else val_20_auto = nil end else local _ = _10_ local data_5_auto = {k = k}
 local resolve_6_auto local function _18_(name_7_auto) local _19_ = data_5_auto[name_7_auto] local function _20_() local t_8_auto = _19_ return ("table" == type(t_8_auto)) end if ((nil ~= _19_) and _20_()) then local t_8_auto = _19_ local _21_ = getmetatable(t_8_auto) if ((_G.type(_21_) == "table") and (nil ~= _21_.__tostring)) then local f_9_auto = _21_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _21_ return vim.inspect(t_8_auto) end elseif (nil ~= _19_) then local v_11_auto = _19_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _18_ val_20_auto = string.gsub("config key `#{k}` not recognised", "#{(.-)}", resolve_6_auto) end end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end e = tbl_18_auto end
 return table["empty?"](e), e else
 return false, {"config must be a table"} end end

 M.set = function(config)
 errors = nil
 local function _27_(...) local _28_, _29_ = ... if (_28_ == true) then

 user_config = clone(config) return nil elseif ((_28_ == false) and (nil ~= _29_)) then local errs = _29_


 errors = errs
 return false, errors else return nil end end return _27_(M["valid?"](config)) end

 M.get = function()
 return table.merge(clone(defaults), user_config) end

 M.health = function()
 if (errors == nil) then return true else local _ = errors

 return false, errors end end

 return M