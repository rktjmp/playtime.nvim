

 local _2araw_string_2a = string
 local _2araw_math_2a = math
 local _2araw_type_2a = type
 local _2araw_table_2a = table
 local _2araw_unpack_2a = unpack





 local math local function _1_(v, min, max)
 return _2araw_math_2a.min(_2araw_math_2a.max(v, min), max) end

 local function _2_(n) return (1 == (n % 2)) end
 local function _3_(n) return (0 == (n % 2)) end math = setmetatable({clamp = _1_, ["odd?"] = _2_, ["even?"] = _3_}, {__index = _2araw_math_2a})






 local type local function _4_(v) return ("table" == _2araw_type_2a(v)) end
 local function _5_(v) return ("string" == _2araw_type_2a(v)) end
 local function _6_(v) return ("number" == _2araw_type_2a(v)) end
 local function _7_(v) return ("thread" == _2araw_type_2a(v)) end
 local function _8_(v) return ("userdata" == _2araw_type_2a(v)) end
 local function _9_(v) return ("function" == _2araw_type_2a(v)) end
 local function _10_(_t, v) return _2araw_type_2a(v) end type = setmetatable({["table?"] = _4_, ["string?"] = _5_, ["number?"] = _6_, ["coroutine?"] = _7_, ["userdata?"] = _8_, ["function?"] = _9_}, {__call = _10_})






 local function _2ainsert(t, ...) _2araw_table_2a.insert(t, ...) return t end

 local function _2aset(t, k, v) t[k] = v return t end

 local function split_at(t, index)

 local p if (0 <= index) then p = index else p = (#t + (1 + index)) end
 local a, b = {}, {} for i, v in ipairs(t) do
 if (i < p) then
 a, b = _2ainsert(a, v), b else
 a, b = a, _2ainsert(b, v) end end return a, b end

 local function split_by(t, f)

 local a, b = {}, {} for i, v in ipairs(t) do
 if f(v, i) then
 a, b = _2ainsert(a, v), b else
 a, b = a, _2ainsert(b, v) end end return a, b end

 local function merge(table_into, table_from, _3fresolver) _G.assert((nil ~= table_from), "Missing argument table-from on fnl/playtime/prelude/init.fnl:56") _G.assert((nil ~= table_into), "Missing argument table-into on fnl/playtime/prelude/init.fnl:56")
 local resolve local function _14_(key, val_a, val_b) return val_b end resolve = (_3fresolver or _14_)
 local tbl_14_auto = table_into for key, value in pairs(table_from) do local k_15_auto, v_16_auto = nil, nil
 do local _15_, _16_ = table_into[key], value if ((nil ~= _15_) and (_15_ == _16_)) then local same = _15_
 k_15_auto, v_16_auto = key, value elseif ((_15_ == nil) and (nil ~= _16_)) then local b = _16_
 k_15_auto, v_16_auto = key, b elseif ((nil ~= _15_) and (nil ~= _16_)) then local a = _15_ local b = _16_
 k_15_auto, v_16_auto = key, resolve(key, a, b) else k_15_auto, v_16_auto = nil end end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end return tbl_14_auto end

 local function shuffle(t)

 for i = #t, 2, -1 do
 local j = math.random(i)
 local a = t[j]
 local b = t[i]
 t[i] = a
 t[j] = b end
 return t end

 local function join(t, ...)
 assert(type["table?"](t), "table.join first argument must be a table")
 local _19_ = select("#", ...) if (_19_ == 0) then
 return t elseif (_19_ == 1) then
 local tbl_17_auto = t for _, v in ipairs(select(1, ...)) do local val_18_auto = v table.insert(tbl_17_auto, val_18_auto) end return tbl_17_auto elseif (nil ~= _19_) then local n = _19_
 local function _21_(...) local _20_ = select(1, ...) return _20_ end return join(join(t, _21_(...)), select(2, ...)) else return nil end end

 local function stable_insertion_sort(t, _3fcmp)
 local cmp local function _23_(a, b) return (a < b) end cmp = (_3fcmp or _23_)
 for i = 2, #t do
 local val = t[i] local stop_3f = false
 for j = i, 1, -1 do if stop_3f then break end


 if ((1 < j) and cmp(val, t[(j - 1)])) then

 t[j] = t[(j - 1)] stop_3f = false else


 t[j] = val stop_3f = true end end end

 return t end

 local function get_in(t, path)
 assert(type["table?"](t), string.format("target argument must be table, got %s", type(t)))
 assert(type["table?"](path), "path argument must be table")
 if ((_G.type(path) == "table") and (nil ~= path[1]) and (path[2] == nil)) then local key = path[1]
 return t[key] elseif ((_G.type(path) == "table") and (nil ~= path[1])) then local key = path[1] local rest = {select(2, (table.unpack or _G.unpack)(path))}
 return get_in(t[key], rest) else return nil end end

 local function update_in(t, path, f)
 assert(type["table?"](t), string.format("target argument must be table, got %s", type(t)))
 assert(type["table?"](path), "path argument must be table")
 assert(type["function?"](f), "f argument must be function")
 if ((_G.type(path) == "table") and (nil ~= path[1]) and (path[2] == nil)) then local key = path[1]
 t[key] = f(t[key]) return t elseif ((_G.type(path) == "table") and (nil ~= path[1])) then local key = path[1] local rest = {select(2, (table.unpack or _G.unpack)(path))}

 update_in(t[key], rest, f)
 return t else return nil end end

 local function set_in(t, path, val)
 local function _27_() return val end return update_in(t, path, _27_) end

 local function insert_in(t, path, val)
 assert(type["table?"](t), string.format("target argument must be table, got %s", type(t)))
 assert(type["table?"](path), "path argument must be table")
 if ((_G.type(path) == "table") and (nil ~= path[1]) and (path[2] == nil)) then local key = path[1]
 table.insert(t, key, val) return t elseif ((_G.type(path) == "table") and (nil ~= path[1])) then local key = path[1] local rest = {select(2, (table.unpack or _G.unpack)(path))}


 insert_in(t[key], rest, val)
 return t else return nil end end

 local table local function _29_(t) return (nil == next(t)) end
 local function _30_(t) return t[1] end
 local function _31_(t) return t[#t] end
 local function _32_(t) local tbl_19_auto = {} local i_20_auto = 0 for k, _ in pairs(t) do local val_21_auto = k if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end return tbl_19_auto end
 local function _34_(t) local tbl_19_auto = {} local i_20_auto = 0 for _, v in pairs(t) do local val_21_auto = v if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end return tbl_19_auto end
 local function _36_(t) local tbl_14_auto = {} for k, v in pairs(t) do local k_15_auto, v_16_auto = v, k if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end return tbl_14_auto end










 local function _38_(...) local _39_ = {...} _39_["n"] = select("#", ...) return _39_ end
 local function _40_(t) return unpack(t, 1, t.n) end



 local function _41_(t, f)
 local g = {} for k, v in pairs(t) do
 local key = f(v, k)
 local _42_ = g[key] if (_42_ == nil) then
 g = _2aset(g, key, {v}) elseif (nil ~= _42_) then local sub_t = _42_
 g = _2aset(g, key, _2ainsert(sub_t, v)) else g = nil end end return g end table = setmetatable({["empty?"] = _29_, first = _30_, last = _31_, keys = _32_, values = _34_, invert = _36_, ["update-in"] = update_in, ["set-in"] = set_in, ["insert-in"] = insert_in, ["get-in"] = get_in, split = split_at, ["split-at"] = split_at, merge = merge, join = join, pack = _38_, unpack = _40_, insert = _2ainsert, set = _2aset, sort = stable_insertion_sort, ["group-by"] = _41_, shuffle = shuffle}, {__index = _2araw_table_2a})















 local _2astring_2a

 local function _44_(_241) return vim.api.nvim_strwidth(_241) end _2astring_2a = setmetatable({fmt = _2araw_string_2a.format, ["col-width"] = _44_}, {__index = _2araw_string_2a})






 local function clone(data)


 local _45_ = type(data) if (_45_ == "table") then
 local mt = getmetatable(data)
 if ((_G.type(mt) == "table") and (nil ~= mt.__clone)) then local custom = mt.__clone
 return setmetatable(custom(data), mt) else local _ = mt

 local _46_ do local tbl_14_auto = {} for key, val in pairs(data) do local k_15_auto, v_16_auto = key, clone(val) if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end _46_ = tbl_14_auto end return setmetatable(_46_, mt) end else local _ = _45_

 return data end end

 local function eq_any_3f(x, ys) local ok_3f = false
 for _, y in ipairs(ys) do if ok_3f then break end
 ok_3f = (x == y) end return ok_3f end

 local function eq_all_3f(x, ys) local ok_3f = true
 for _, y in ipairs(ys) do if not ok_3f then break end
 ok_3f = (ok_3f and (x == y)) end return ok_3f end

 return {math = math, string = _2astring_2a, type = type, table = table, clone = clone, ["eq-any?"] = eq_any_3f, ["eq-all?"] = eq_all_3f}