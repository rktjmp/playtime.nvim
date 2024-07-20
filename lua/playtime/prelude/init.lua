

 local _2araw_string_2a = _G.string
 local _2araw_math_2a = _G.math
 local _2araw_type_2a = _G.type
 local _2araw_table_2a = _G.table
 local _2araw_unpack_2a = _G.unpack





 local math
 local function _1_(v, min, max)
 return _2araw_math_2a.min(_2araw_math_2a.max(v, min), max) end

 local function _2_(n) return (1 == (n % 2)) end
 local function _3_(n) return (0 == (n % 2)) end math = setmetatable({clamp = _1_, ["odd?"] = _2_, ["even?"] = _3_}, {__index = _2araw_math_2a})






 local type
 local function _4_(v) return ("table" == _2araw_type_2a(v)) end
 local function _5_(v) return ("string" == _2araw_type_2a(v)) end
 local function _6_(v) return ("number" == _2araw_type_2a(v)) end
 local function _7_(v) return ("thread" == _2araw_type_2a(v)) end
 local function _8_(v) return ("userdata" == _2araw_type_2a(v)) end
 local function _9_(v) return ("function" == _2araw_type_2a(v)) end
 local function _10_(_t, v) return _2araw_type_2a(v) end type = setmetatable({["table?"] = _4_, ["string?"] = _5_, ["number?"] = _6_, ["coroutine?"] = _7_, ["userdata?"] = _8_, ["function?"] = _9_}, {__call = _10_})





 local function eq_any_3f(x, ys) local ok_3f = false
 for _, y in ipairs(ys) do if ok_3f then break end
 ok_3f = (x == y) end return ok_3f end

 local function eq_all_3f(x, ys) local ok_3f = true
 for _, y in ipairs(ys) do if not ok_3f then break end
 ok_3f = (ok_3f and (x == y)) end return ok_3f end

 local function _2ainsert(t, ...)

 _2araw_table_2a.insert(t, ...) return t end

 local function _2aset(t, k, v)

 t[k] = v return t end

 local function split_at(t, index)

 local p if (0 <= index) then p = index else p = (#t + (1 + index)) end
 local a, b = {}, {} for i, v in ipairs(t) do
 if (i < p) then
 a, b = _2ainsert(a, v), b else
 a, b = a, _2ainsert(b, v) end end return a, b end








 local function merge(table_into, table_from, _3fresolver) _G.assert((nil ~= table_from), "Missing argument table-from on fnl/playtime/prelude/init.fnl:69") _G.assert((nil ~= table_into), "Missing argument table-into on fnl/playtime/prelude/init.fnl:69")
 local resolve local or_13_ = _3fresolver if not or_13_ then local function _14_(key, val_a, val_b) return val_b end or_13_ = _14_ end resolve = or_13_
 local tbl_16_auto = table_into for key, value in pairs(table_from) do local k_17_auto, v_18_auto = nil, nil
 do local _15_, _16_ = table_into[key], value if ((nil ~= _15_) and (_15_ == _16_)) then local same = _15_
 k_17_auto, v_18_auto = key, value elseif ((_15_ == nil) and (nil ~= _16_)) then local b = _16_
 k_17_auto, v_18_auto = key, b elseif ((nil ~= _15_) and (nil ~= _16_)) then local a = _15_ local b = _16_
 k_17_auto, v_18_auto = key, resolve(key, a, b) else k_17_auto, v_18_auto = nil end end if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end return tbl_16_auto end

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
 local tbl_19_auto = t for _, v in ipairs(select(1, ...)) do local val_20_auto = v table.insert(tbl_19_auto, val_20_auto) end return tbl_19_auto elseif (nil ~= _19_) then local n = _19_
 return join(join(t, (select(1, ...))), select(2, ...)) else return nil end end

 local function stable_insertion_sort(t, _3fcmp)
 local cmp local or_21_ = _3fcmp if not or_21_ then local function _22_(a, b) return (a < b) end or_21_ = _22_ end cmp = or_21_
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
 local function _26_() return val end return update_in(t, path, _26_) end

 local function insert_in(t, path, val)
 assert(type["table?"](t), string.format("target argument must be table, got %s", type(t)))
 assert(type["table?"](path), "path argument must be table")
 if ((_G.type(path) == "table") and (nil ~= path[1]) and (path[2] == nil)) then local key = path[1]
 table.insert(t, key, val) return t elseif ((_G.type(path) == "table") and (nil ~= path[1])) then local key = path[1] local rest = {select(2, (table.unpack or _G.unpack)(path))}


 insert_in(t[key], rest, val)
 return t else return nil end end

 local table
 do
 local function pack(...) local tmp_9_auto = {...} tmp_9_auto["n"] = select("#", ...) return tmp_9_auto end
 local function unpack(t, _3ffrom, _3fto) return _2araw_unpack_2a(t, (_3ffrom or 1), (_3fto or t.n)) end

 local function _28_(t) return (nil == next(t)) end
 local function _29_(t) return t[1] end
 local function _30_(t) return t[#t] end
 local function _31_(t) local tbl_21_auto = {} local i_22_auto = 0 for k, _ in pairs(t) do local val_23_auto = k if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end
 local function _33_(t) local tbl_21_auto = {} local i_22_auto = 0 for _, v in pairs(t) do local val_23_auto = v if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end
 local function _35_(t) local tbl_16_auto = {} for k, v in pairs(t) do local k_17_auto, v_18_auto = v, k if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end return tbl_16_auto end















 local function _37_(t, f)
 local g = {} for k, v in pairs(t) do
 local key = f(v, k)
 local _38_ = g[key] if (_38_ == nil) then
 g = _2aset(g, key, {v}) elseif (nil ~= _38_) then local sub_t = _38_
 g = _2aset(g, key, _2ainsert(sub_t, v)) else g = nil end end return g end table = setmetatable({["empty?"] = _28_, first = _29_, last = _30_, keys = _31_, values = _33_, invert = _35_, ["update-in"] = update_in, ["set-in"] = set_in, ["insert-in"] = insert_in, ["get-in"] = get_in, split = split_at, ["split-at"] = split_at, merge = merge, join = join, pack = pack, unpack = unpack, insert = _2ainsert, set = _2aset, sort = stable_insertion_sort, ["group-by"] = _37_, shuffle = shuffle}, {__index = _2araw_table_2a}) end















 local _2astring_2a

 local function _40_(_241) return vim.api.nvim_strwidth(_241) end _2astring_2a = setmetatable({fmt = _2araw_string_2a.format, ["col-width"] = _40_}, {__index = _2araw_string_2a})






 local function clone(data)


 local _41_ = type(data) if (_41_ == "table") then
 local mt = getmetatable(data)
 if ((_G.type(mt) == "table") and (nil ~= mt.__clone)) then local custom = mt.__clone
 return setmetatable(custom(data), mt) else local _ = mt

 local _42_ do local tbl_16_auto = {} for key, val in pairs(data) do local k_17_auto, v_18_auto = key, clone(val) if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end _42_ = tbl_16_auto end return setmetatable(_42_, mt) end else local _ = _41_

 return data end end

 return {math = math, string = _2astring_2a, type = type, table = table, clone = clone, ["eq-any?"] = eq_any_3f, ["eq-all?"] = eq_all_3f}