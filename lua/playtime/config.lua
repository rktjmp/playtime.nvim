
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local M = {}

 local schema
 local function _2_(_241) return (type["number?"](_241) and (1 <= _241)) end
 local function _3_(_241) return type["string?"](_241) end
 local function _4_(_241) local or_5_ = eq_any_3f(_241, {"center", "nw", "ne"})
 if not or_5_ then if ((_G.type(_241) == "table") and (nil ~= _241.row) and (nil ~= _241.col)) then local row = _241.row local col = _241.col or_5_ = true else local __1_auto = _241 or_5_ = false end end return (or_5_ or type["function?"](_241)) end


 local function _9_(_241) local or_10_ = eq_any_3f(_241, {"ne", "nw", "se", "sw"})
 if not or_10_ then if ((_G.type(_241) == "table") and (nil ~= _241.row) and (nil ~= _241.col)) then local row = _241.row local col = _241.col or_10_ = true else local __1_auto = _241 or_10_ = false end end return (or_10_ or type["function?"](_241)) end


 local function _14_(_241) return eq_any_3f(_241, {"minimise"}) end

 local function _15_(_241) return eq_any_3f(_241, {"wide", nil}) end schema = {fps = {_2_, "must be positive integer"}, ["window-border"] = {_3_, "must be valid window border name"}, ["window-position"] = {_4_, "must be `center`, `nw`, `ne` or a table or function returning`{row=row, col=col}`"}, ["minimise-position"] = {_9_, "must be `ne`, `nw`, `se`, `sw` or a table or function returning`{row=row, col=col}`"}, unfocused = {_14_, "must be `minimise`"}, ["__beta-game-set-font-glyph-width"] = {_15_, "must be `wide` or `nil`"}}









 local defaults = {fps = 30, ["window-border"] = nil, ["window-position"] = "center", ["minimise-position"] = "se", unfocused = "minimise", ["__beta-game-set-font-glyph-width"] = nil}






 local user_config = {}
 local errors = nil

 local function lua_name_to_fennel_name(name)

 return string.gsub(name, "([^_])_", "%1-") end

 M["valid?"] = function(config)
 if type["table?"](config) then
 local e do local tbl_21_ = {} local i_22_ = 0 for k, v in pairs(config) do local val_23_
 do local _16_ = schema[lua_name_to_fennel_name(k)] if ((_G.type(_16_) == "table") and (nil ~= _16_[1]) and (nil ~= _16_[2])) then local f = _16_[1] local msg = _16_[2]
 if not f(v) then local data_5_auto = {k = k, msg = msg}
 local resolve_6_auto local function _17_(name_7_auto) local _18_ = data_5_auto[name_7_auto] local and_19_ = (nil ~= _18_) if and_19_ then local t_8_auto = _18_ and_19_ = ("table" == type(t_8_auto)) end if and_19_ then local t_8_auto = _18_ local _21_ = getmetatable(t_8_auto) if ((_G.type(_21_) == "table") and (nil ~= _21_.__tostring)) then local f_9_auto = _21_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _21_ return vim.inspect(t_8_auto) end elseif (nil ~= _18_) then local v_11_auto = _18_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _17_ val_23_ = string.gsub("config key `#{k}` did not pass validation, #{msg}", "#{(.-)}", resolve_6_auto) else val_23_ = nil end else local _ = _16_ local data_5_auto = {k = k}
 local resolve_6_auto local function _25_(name_7_auto) local _26_ = data_5_auto[name_7_auto] local and_27_ = (nil ~= _26_) if and_27_ then local t_8_auto = _26_ and_27_ = ("table" == type(t_8_auto)) end if and_27_ then local t_8_auto = _26_ local _29_ = getmetatable(t_8_auto) if ((_G.type(_29_) == "table") and (nil ~= _29_.__tostring)) then local f_9_auto = _29_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _29_ return vim.inspect(t_8_auto) end elseif (nil ~= _26_) then local v_11_auto = _26_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _25_ val_23_ = string.gsub("config key `#{k}` not recognised", "#{(.-)}", resolve_6_auto) end end if (nil ~= val_23_) then i_22_ = (i_22_ + 1) tbl_21_[i_22_] = val_23_ else end end e = tbl_21_ end
 return table["empty?"](e), e else
 return false, {"config must be a table"} end end

 M.set = function(config)
 errors = nil
 local function _35_(...) local _36_, _37_ = ... if (_36_ == true) then

 local c do local tbl_16_ = {} for k, v in pairs(config) do
 local k_17_, v_18_ = lua_name_to_fennel_name(k), v if ((k_17_ ~= nil) and (v_18_ ~= nil)) then tbl_16_[k_17_] = v_18_ else end end c = tbl_16_ end
 user_config = clone(c) return true elseif ((_36_ == false) and (nil ~= _37_)) then local errs = _37_



 errors = errs
 return false, errors else return nil end end return _35_(M["valid?"](config)) end

 M.get = function()
 return table.merge(clone(defaults), user_config) end

 M.health = function()
 if (errors == nil) then return true else local _ = errors

 return false, errors end end

 return M