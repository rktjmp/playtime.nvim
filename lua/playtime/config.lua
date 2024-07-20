
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local M = {}

 local schema
 local function _2_(_241) return (type["number?"](_241) and (1 <= _241)) end
 local function _3_(_241) local or_4_ = eq_any_3f(_241, {"center", "nw", "ne"})
 if not or_4_ then if ((_G.type(_241) == "table") and (nil ~= _241.row) and (nil ~= _241.col)) then local row = _241.row local col = _241.col or_4_ = true else local __1_auto = _241 or_4_ = false end end return (or_4_ or type["function?"](_241)) end


 local function _8_(_241) local or_9_ = eq_any_3f(_241, {"ne", "nw", "se", "sw"})
 if not or_9_ then if ((_G.type(_241) == "table") and (nil ~= _241.row) and (nil ~= _241.col)) then local row = _241.row local col = _241.col or_9_ = true else local __1_auto = _241 or_9_ = false end end return (or_9_ or type["function?"](_241)) end


 local function _13_(_241) return eq_any_3f(_241, {"minimise"}) end

 local function _14_(_241) return eq_any_3f(_241, {"wide", nil}) end schema = {fps = {_2_, "must be positive integer"}, ["window-position"] = {_3_, "must be `center`, `nw`, `ne` or a table or function returning`{row=row, col=col}`"}, ["minimise-position"] = {_8_, "must be `ne`, `nw`, `se`, `sw` or a table or function returning`{row=row, col=col}`"}, unfocused = {_13_, "must be `minimise`"}, ["__beta-game-set-font-glyph-width"] = {_14_, "must be `wide` or `nil`"}}









 local defaults = {fps = 30, ["window-position"] = "center", ["minimise-position"] = "se", unfocused = "minimise", ["__beta-game-set-font-glyph-width"] = nil}





 local user_config = {}
 local errors = nil

 M["valid?"] = function(config)
 if type["table?"](config) then
 local e do local tbl_21_auto = {} local i_22_auto = 0 for k, v in pairs(config) do local val_23_auto
 do local _15_ = schema[k] if ((_G.type(_15_) == "table") and (nil ~= _15_[1]) and (nil ~= _15_[2])) then local f = _15_[1] local msg = _15_[2]
 if not f(v) then local data_5_auto = {k = k, msg = msg}
 local resolve_6_auto local function _16_(name_7_auto) local _17_ = data_5_auto[name_7_auto] local and_18_ = (nil ~= _17_) if and_18_ then local t_8_auto = _17_ and_18_ = ("table" == type(t_8_auto)) end if and_18_ then local t_8_auto = _17_ local _20_ = getmetatable(t_8_auto) if ((_G.type(_20_) == "table") and (nil ~= _20_.__tostring)) then local f_9_auto = _20_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _20_ return vim.inspect(t_8_auto) end elseif (nil ~= _17_) then local v_11_auto = _17_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _16_ val_23_auto = string.gsub("config key `#{k}` did not pass validation, #{msg}", "#{(.-)}", resolve_6_auto) else val_23_auto = nil end else local _ = _15_ local data_5_auto = {k = k}
 local resolve_6_auto local function _24_(name_7_auto) local _25_ = data_5_auto[name_7_auto] local and_26_ = (nil ~= _25_) if and_26_ then local t_8_auto = _25_ and_26_ = ("table" == type(t_8_auto)) end if and_26_ then local t_8_auto = _25_ local _28_ = getmetatable(t_8_auto) if ((_G.type(_28_) == "table") and (nil ~= _28_.__tostring)) then local f_9_auto = _28_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _28_ return vim.inspect(t_8_auto) end elseif (nil ~= _25_) then local v_11_auto = _25_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _24_ val_23_auto = string.gsub("config key `#{k}` not recognised", "#{(.-)}", resolve_6_auto) end end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end e = tbl_21_auto end
 return table["empty?"](e), e else
 return false, {"config must be a table"} end end

 M.set = function(config)
 errors = nil
 local function _34_(...) local _35_, _36_ = ... if (_35_ == true) then


 user_config = clone(config) return true elseif ((_35_ == false) and (nil ~= _36_)) then local errs = _36_



 errors = errs
 return false, errors else return nil end end return _34_(M["valid?"](config)) end

 M.get = function()
 return table.merge(clone(defaults), user_config) end

 M.health = function()
 if (errors == nil) then return true else local _ = errors

 return false, errors end end

 return M