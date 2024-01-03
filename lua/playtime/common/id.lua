 local function build_counter()

 local function _1_(t) t.v = (t.v + 1) return t.v end return setmetatable({v = 0}, {__call = _1_}) end
 local id = build_counter()
 local ns_id = {}

 local function next_id(_3fnamespace)

 local _2_, _3_ = _3fnamespace, ns_id[_3fnamespace] if ((_2_ == nil) and true) then local _ = _3_
 return id() elseif ((nil ~= _2_) and (nil ~= _3_)) then local ns = _2_ local c = _3_
 return c() elseif ((nil ~= _2_) and (_3_ == nil)) then local ns = _2_

 ns_id[ns] = build_counter()
 return ns_id[ns]() else return nil end end

 return {new = next_id}