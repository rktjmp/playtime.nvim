
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local M = {}

 local schema
 local function _2_(_241) return (type["number?"](_241) and (1 <= _241)) end
 local function _3_(_241) local function _4_(...)
 if ((_G.type(_241) == "table") and (nil ~= _241.row) and (nil ~= _241.col)) then local row = _241.row local col = _241.col return true else local __1_auto = _241 return false end end return (eq_any_3f(_241, {"center", "nw", "ne"}) or _4_() or type["function?"](_241)) end


 local function _6_(_241) local function _7_(...)
 if ((_G.type(_241) == "table") and (nil ~= _241.row) and (nil ~= _241.col)) then local row = _241.row local col = _241.col return true else local __1_auto = _241 return false end end return (eq_any_3f(_241, {"ne", "nw", "se", "sw"}) or _7_() or type["function?"](_241)) end


 local function _9_(_241) return eq_any_3f(_241, {"minimise"}) end

 local function _10_(_241) return eq_any_3f(_241, {"wide", nil}) end schema = {fps = {_2_, "must be positive integer"}, ["window-position"] = {_3_, "must be `center`, `nw`, `ne` or a table or function returning`{row=row, col=col}`"}, ["minimise-position"] = {_6_, "must be `ne`, `nw`, `se`, `sw` or a table or function returning`{row=row, col=col}`"}, unfocused = {_9_, "must be `minimise`"}, ["__beta-game-set-font-glyph-width"] = {_10_, "must be `wide` or `nil`"}}









 local defaults = {fps = 30, ["window-position"] = "center", ["minimise-position"] = "se", unfocused = "minimise", ["__beta-game-set-font-glyph-width"] = nil}





 local user_config = {}
 local errors = nil

 M["valid?"] = function(config)
 if type["table?"](config) then
 local e do local tbl_19_auto = {} local i_20_auto = 0 for k, v in pairs(config) do local val_21_auto
 do local _11_ = schema[k] if ((_G.type(_11_) == "table") and (nil ~= _11_[1]) and (nil ~= _11_[2])) then local f = _11_[1] local msg = _11_[2]
 if not f(v) then local data_5_auto = {k = k, msg = msg}
 local resolve_6_auto local function _12_(name_7_auto) local _13_ = data_5_auto[name_7_auto] local function _14_() local t_8_auto = _13_ return ("table" == type(t_8_auto)) end if ((nil ~= _13_) and _14_()) then local t_8_auto = _13_ local _15_ = getmetatable(t_8_auto) if ((_G.type(_15_) == "table") and (nil ~= _15_.__tostring)) then local f_9_auto = _15_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _15_ return vim.inspect(t_8_auto) end elseif (nil ~= _13_) then local v_11_auto = _13_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _12_ val_21_auto = string.gsub("config key `#{k}` did not pass validation, #{msg}", "#{(.-)}", resolve_6_auto) else val_21_auto = nil end else local _ = _11_ local data_5_auto = {k = k}
 local resolve_6_auto local function _19_(name_7_auto) local _20_ = data_5_auto[name_7_auto] local function _21_() local t_8_auto = _20_ return ("table" == type(t_8_auto)) end if ((nil ~= _20_) and _21_()) then local t_8_auto = _20_ local _22_ = getmetatable(t_8_auto) if ((_G.type(_22_) == "table") and (nil ~= _22_.__tostring)) then local f_9_auto = _22_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _22_ return vim.inspect(t_8_auto) end elseif (nil ~= _20_) then local v_11_auto = _20_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _19_ val_21_auto = string.gsub("config key `#{k}` not recognised", "#{(.-)}", resolve_6_auto) end end if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end e = tbl_19_auto end
 return table["empty?"](e), e else
 return false, {"config must be a table"} end end

 M.set = function(config)
 errors = nil
 local function _28_(...) local _29_, _30_ = ... if (_29_ == true) then


 user_config = clone(config) return true elseif ((_29_ == false) and (nil ~= _30_)) then local errs = _30_



 errors = errs
 return false, errors else return nil end end return _28_(M["valid?"](config)) end

 M.get = function()
 return table.merge(clone(defaults), user_config) end

 M.health = function()
 if (errors == nil) then return true else local _ = errors

 return false, errors end end

 return M