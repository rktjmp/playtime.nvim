
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local Animate = require("playtime.animate")

 local M = {}

 M["make-iter-cards-fn"] = function(default_fields)






 local function _2_(state, _3ffields)
 local function iter()
 for _, field in ipairs((_3ffields or default_fields)) do
 for col_n, column in ipairs(state[field]) do
 for card_n, card in ipairs(column) do
 coroutine.yield({field, col_n, card_n}, card) end end end return nil end
 return coroutine.wrap(iter) end return _2_ end


 M["location-contents"] = function(state, location) _G.assert((nil ~= location), "Missing argument location on fnl/playtime/common/card/utils.fnl:26") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/common/card/utils.fnl:26")
 if ((_G.type(location) == "table") and (nil ~= location[1]) and (location[2] == nil)) then local field = location[1]
 local t_3_ = state if (nil ~= t_3_) then t_3_ = t_3_[field] else end return t_3_ elseif ((_G.type(location) == "table") and (nil ~= location[1]) and (nil ~= location[2]) and (location[3] == nil)) then local field = location[1] local col = location[2]
 local t_5_ = state if (nil ~= t_5_) then t_5_ = t_5_[field] else end if (nil ~= t_5_) then t_5_ = t_5_[col] else end return t_5_ elseif ((_G.type(location) == "table") and (nil ~= location[1]) and (nil ~= location[2]) and (nil ~= location[3])) then local field = location[1] local col = location[2] local card_n = location[3]
 local t_8_ = state if (nil ~= t_8_) then t_8_ = t_8_[field] else end if (nil ~= t_8_) then t_8_ = t_8_[col] else end if (nil ~= t_8_) then t_8_ = t_8_[card_n] else end return t_8_ else local _ = location
 return error(Error("invalid location #{location}", {location = location})) end end

 M["same-location-field?"] = function(a, b)
 local _13_, _14_ = a, b if (((_G.type(_13_) == "table") and (nil ~= _13_[1])) and ((_G.type(_14_) == "table") and (_13_[1] == _14_[1]))) then local f = _13_[1] return true else local _ = _13_ return false end end



 M["same-location-field-column?"] = function(a, b)
 local _16_, _17_ = a, b if (((_G.type(_16_) == "table") and (nil ~= _16_[1]) and (nil ~= _16_[2])) and ((_G.type(_17_) == "table") and (_16_[1] == _17_[1]) and (_16_[2] == _17_[2]))) then local f = _16_[1] local c = _16_[2] return true else local _ = _16_ return false end end



 M["same-location-field-column-card?"] = function(a, b)
 local _19_, _20_ = a, b if (((_G.type(_19_) == "table") and (nil ~= _19_[1]) and (nil ~= _19_[2]) and (nil ~= _19_[3])) and ((_G.type(_20_) == "table") and (_19_[1] == _20_[1]) and (_19_[2] == _20_[2]) and (_19_[3] == _20_[3]))) then local f = _19_[1] local c = _19_[2] local n = _19_[3] return true else local _ = _19_ return false end end



 M["make-card-util-fns"] = function(spec) _G.assert((nil ~= spec), "Missing argument spec on fnl/playtime/common/card/utils.fnl:48")
 assert(spec.value, "must provide card value spec")
 assert(spec.color, "must provide card color spec")
 local fns = {}


 fns["flip-face-up"] = function(card)
 card["face"] = "up" return card end


 fns["flip-face-down"] = function(card)
 card["face"] = "down" return card end


 fns["card-face-up?"] = function(card)
 if ((_G.type(card) == "table") and (card.face == "up")) then return true elseif ((_G.type(card) == "table") and (card.face == "down")) then return false else local _ = card


 local function _29_() local data_5_auto = {card = card} local resolve_6_auto local function _22_(name_7_auto) local _23_ = data_5_auto[name_7_auto] local and_24_ = (nil ~= _23_) if and_24_ then local t_8_auto = _23_ and_24_ = ("table" == type(t_8_auto)) end if and_24_ then local t_8_auto = _23_ local _26_ = getmetatable(t_8_auto) if ((_G.type(_26_) == "table") and (nil ~= _26_.__tostring)) then local f_9_auto = _26_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _26_ return vim.inspect(t_8_auto) end elseif (nil ~= _23_) then local v_11_auto = _23_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _22_ return string.gsub("Not a card: #{card}", "#{(.-)}", resolve_6_auto) end return error(_29_()) end end

 fns["card-face-down?"] = function(card)
 return not fns["card-face-up?"](card) end

 fns["card-value"] = function(card)
 if ((_G.type(card) == "table") and true and (nil ~= card[2])) then local _suit = card[1] local rank = card[2]

 return (spec.value[rank] or rank) else local _ = card return error(Error("invalid card #{card}", {card = card})) end end


 fns["card-color"] = function(card)
 if ((_G.type(card) == "table") and (nil ~= card[1]) and (nil ~= card[2])) then local suit = card[1] local rank = card[2]
 local or_32_ = spec.color[suit] if not or_32_ then or_32_ = error(Error("invalid card #{card}", {card = card})) end return or_32_ else local _ = card return error(Error("invalid card #{card}", {card = card})) end end


 fns["card-rank"] = function(card)
 if ((_G.type(card) == "table") and true and (nil ~= card[2])) then local _suit = card[1] local rank = card[2]
 return rank else local _ = card return error(Error("invalid card #{card}", {card = card})) end end


 fns["card-suit"] = function(card)
 if ((_G.type(card) == "table") and (nil ~= card[1])) then local suit = card[1]
 return suit else local _ = card return error(Error("invalid card #{card}", {card = card})) end end


 fns["rank-value"] = function(rank)
 return fns["card-value"]({"any", rank}) end

 fns["suit-color"] = function(suit)
 return fns["card-color"]({suit, "any"}) end

 return fns end

 M["make-valid-sequence?-fn"] = function(comparitor_fn) _G.assert((nil ~= comparitor_fn), "Missing argument comparitor-fn on fnl/playtime/common/card/utils.fnl:100")
 local function _36_(sequence)
 if ((_G.type(sequence) == "table") and (nil ~= sequence[1])) then local top_card = sequence[1] local other_cards = {select(2, (table.unpack or _G.unpack)(sequence))}

 local ok_3f, checked_cards, memo = true, {top_card}, nil for _, card in ipairs(other_cards) do if not ok_3f then break end


 local ok_3f0, memo0 = comparitor_fn(card, checked_cards, memo)
 if ok_3f0 then
 ok_3f, checked_cards, memo = true, table.insert(checked_cards, 1, card), memo0 else
 ok_3f, checked_cards, memo = false end end return ok_3f, checked_cards, memo else local _ = sequence return false end end return _36_ end


 M["inc-moves"] = function(state, _3fcount)
 state["moves"] = ((_3fcount or 1) + state.moves) return state end


 M["apply-events"] = function(state, events) _G.assert((nil ~= events), "Missing argument events on fnl/playtime/common/card/utils.fnl:117") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/common/card/utils.fnl:117")
 local state0, true_events = state, {} for event_num, event in ipairs(events) do

 local matched_3f_39_, location_40_ = nil, nil if ((_G.type(event) == "table") and (event[1] == "face-up") and (nil ~= event[2])) then local location = event[2] matched_3f_39_, location_40_ = true, location elseif ((_G.type(event) == "table") and (event[1] == "face-down") and (nil ~= event[2])) then local location = event[2] matched_3f_39_, location_40_ = true, location else matched_3f_39_, location_40_ = nil end if matched_3f_39_ then local location = location_40_

 local index do local _42_ = table.last(location) if (_42_ == "top") then
 index = #table["get-in"](state0, table.split(location, -1)) elseif (_42_ == "bottom") then index = 1 elseif (nil ~= _42_) then local n = _42_

 index = n else index = nil end end
 local face_where = event[1] local _ = event[2]
 local location0 = table.set(clone(location), #location, index)
 do local _44_ = table["get-in"](state0, location0) if (nil ~= _44_) then local card = _44_
 if (face_where == "face-up") then card.face = "up" elseif (face_where == "face-down") then card.face = "down" else end else local _0 = _44_


 local function _53_() local data_5_auto = {event = event, ["event-num"] = event_num, events = events} local resolve_6_auto local function _46_(name_7_auto) local _47_ = data_5_auto[name_7_auto] local and_48_ = (nil ~= _47_) if and_48_ then local t_8_auto = _47_ and_48_ = ("table" == type(t_8_auto)) end if and_48_ then local t_8_auto = _47_ local _50_ = getmetatable(t_8_auto) if ((_G.type(_50_) == "table") and (nil ~= _50_.__tostring)) then local f_9_auto = _50_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _50_ return vim.inspect(t_8_auto) end elseif (nil ~= _47_) then local v_11_auto = _47_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _46_ return string.gsub("apply-events: no card, cannot apply #{event-num}: #{event}, #{events}", "#{(.-)}", resolve_6_auto) end error(_53_()) end end
 state0, true_events = state0, table.insert(true_events, {face_where, location0}) elseif ((_G.type(event) == "table") and (event[1] == "swap") and (nil ~= event[2]) and (nil ~= event[3])) then local a = event[2] local b = event[3]

 local a_index do local _55_ = table.last(a) if (_55_ == "bottom") then a_index = 1 elseif (_55_ == "top") then

 a_index = #table["get-in"](state0, table.split(a, -1)) elseif (nil ~= _55_) then local n = _55_
 a_index = n else a_index = nil end end local b_index
 do local _57_ = table.last(b) if (_57_ == "bottom") then b_index = 1 elseif (_57_ == "top") then

 b_index = #table["get-in"](state0, table.split(b, -1)) elseif (nil ~= _57_) then local n = _57_
 b_index = n else b_index = nil end end
 local a0 = table.set(clone(a), #a, a_index)

 local b0 = table.set(clone(b), #b, b_index)

 local temp = table["get-in"](state0, b0)
 table["set-in"](state0, b0, table["get-in"](state0, a0))
 table["set-in"](state0, a0, temp)
 state0, true_events = state0, table.insert(true_events, {"swap", a0, b0}) elseif ((_G.type(event) == "table") and (event[1] == "move") and (nil ~= event[2]) and (nil ~= event[3])) then local from = event[2] local to = event[3]

 local from_index do local _59_ = table.last(from) if (_59_ == "bottom") then from_index = 1 elseif (_59_ == "top") then

 from_index = #table["get-in"](state0, table.split(from, -1)) elseif (nil ~= _59_) then local n = _59_
 from_index = n else from_index = nil end end local mod_fn, to_index = nil, nil
 do local _61_ = table.last(to) if (_61_ == "bottom") then
 mod_fn, to_index = table["insert-in"], 1 elseif (_61_ == "top") then
 mod_fn, to_index = table["set-in"], (1 + #table["get-in"](state0, table.split(to, -1))) elseif (nil ~= _61_) then local n = _61_
 mod_fn, to_index = table["set-in"], n else mod_fn, to_index = nil end end
 local from0 = table.set(clone(from), #from, from_index)

 local to0 = table.set(clone(to), #to, to_index)








 mod_fn(state0, to0, table["get-in"](state0, from0))
 table["set-in"](state0, from0, nil)
 state0, true_events = state0, table.insert(true_events, {"move", from0, to0}) else local _ = event
 state0, true_events = error(Error("apply-events: unknown event #{event}", {event = event})) end end return state0, true_events end

 M["build-event-animation"] = function(app, events, after, _3fopts) _G.assert((nil ~= after), "Missing argument after on fnl/playtime/common/card/utils.fnl:176") _G.assert((nil ~= events), "Missing argument events on fnl/playtime/common/card/utils.fnl:176") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/common/card/utils.fnl:176")
 local opts = table.merge({["stagger-ms"] = 50, ["duration-ms"] = 120}, (_3fopts or {}))



 local memo = {} local timeline
 do local t, run_at_ms = {}, 0 for i, event in ipairs(events) do

 if ((_G.type(event) == "table") and (event[1] == "wait") and (nil ~= event[2])) then local n = event[2]

 local function _69_() return nil end t, run_at_ms = table.set(t, run_at_ms, {Animate.linear, n, _69_}), (run_at_ms + n) else local matched_3f_64_, location_65_ = nil, nil if ((_G.type(event) == "table") and (event[1] == "face-up") and (nil ~= event[2])) then local location = event[2] matched_3f_64_, location_65_ = true, location elseif ((_G.type(event) == "table") and (event[1] == "face-down") and (nil ~= event[2])) then local location = event[2] matched_3f_64_, location_65_ = true, location else matched_3f_64_, location_65_ = nil end if matched_3f_64_ then local location = location_65_


 local card_id local _72_ do local t_71_ = memo if (nil ~= t_71_) then t_71_ = t_71_[table.concat(location, ".")] else end _72_ = t_71_ end card_id = (_72_ or table["get-in"](app.game, location).id)

 local comp = app["card-id->components"][card_id]
 local memo0 = {once = false}
 local dir = event[1] local tween
 local function _74_(percent)
 if ((0.5 < percent) and not memo0.once) then memo0.once = true return comp["force-flip"](comp, dir) else return nil end end tween = _74_


 t, run_at_ms = table.set(t, run_at_ms, {Animate["ease-out-quad"], 1, tween}), (run_at_ms + 1) elseif ((_G.type(event) == "table") and (event[1] == "swap") and (nil ~= event[2]) and (nil ~= event[3])) then local a = event[2] local b = event[3]







 local id_a local _77_ do local t_76_ = memo if (nil ~= t_76_) then t_76_ = t_76_[table.concat(a, ".")] else end _77_ = t_76_ end local or_79_ = _77_
 if not or_79_ then local t_80_ = table["get-in"](app.game, a) if (nil ~= t_80_) then t_80_ = t_80_.id else end or_79_ = t_80_ end
 if not or_79_ then local function _89_() local data_5_auto = {a = a} local resolve_6_auto local function _82_(name_7_auto) local _83_ = data_5_auto[name_7_auto] local and_84_ = (nil ~= _83_) if and_84_ then local t_8_auto = _83_ and_84_ = ("table" == type(t_8_auto)) end if and_84_ then local t_8_auto = _83_ local _86_ = getmetatable(t_8_auto) if ((_G.type(_86_) == "table") and (nil ~= _86_.__tostring)) then local f_9_auto = _86_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _86_ return vim.inspect(t_8_auto) end elseif (nil ~= _83_) then local v_11_auto = _83_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _82_ return string.gsub("no card known #{a}", "#{(.-)}", resolve_6_auto) end or_79_ = error(_89_()) end id_a = or_79_ local id_b
 local _91_ do local t_90_ = memo if (nil ~= t_90_) then t_90_ = t_90_[table.concat(b, ".")] else end _91_ = t_90_ end local or_93_ = _91_
 if not or_93_ then local t_94_ = table["get-in"](app.game, b) if (nil ~= t_94_) then t_94_ = t_94_.id else end or_93_ = t_94_ end
 if not or_93_ then local function _103_() local data_5_auto = {b = b} local resolve_6_auto local function _96_(name_7_auto) local _97_ = data_5_auto[name_7_auto] local and_98_ = (nil ~= _97_) if and_98_ then local t_8_auto = _97_ and_98_ = ("table" == type(t_8_auto)) end if and_98_ then local t_8_auto = _97_ local _100_ = getmetatable(t_8_auto) if ((_G.type(_100_) == "table") and (nil ~= _100_.__tostring)) then local f_9_auto = _100_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _100_ return vim.inspect(t_8_auto) end elseif (nil ~= _97_) then local v_11_auto = _97_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _96_ return string.gsub("no card known #{b}", "#{(.-)}", resolve_6_auto) end or_93_ = error(_103_()) end id_b = or_93_ local _
 memo[table.concat(b, ".")] = id_a _ = nil local _0
 memo[table.concat(a, ".")] = id_b _0 = nil
 local t0, run_at_ms0 = t, run_at_ms for _1, _104_ in ipairs({{id_a, a, b}, {id_b, b, a}}) do
 local card_id = _104_[1] local from = _104_[2] local to = _104_[3]
 local comp = app["card-id->components"][card_id]
 local _let_105_ = app["location->position"](app, from) local from_row = _let_105_["row"] local from_col = _let_105_["col"]
 local _let_106_ = app["location->position"](app, to) local to_row = _let_106_["row"] local to_col = _let_106_["col"] local z = _let_106_["z"]
 local duration = opts["duration-ms"] local tween
 local function _107_(percent)



 local _108_ if (percent < 1) then _108_ = app["z-index-for-layer"](app, "animation", (10 + z)) else

 _108_ = z end return comp["set-position"](comp, {row = (from_row + math.ceil(((to_row - from_row) * percent))), col = (from_col + math.ceil(((to_col - from_col) * percent))), z = _108_}) end tween = _107_
 t0, run_at_ms0 = table.set(t0, run_at_ms0, {Animate["ease-out-quad"], duration, tween}), (run_at_ms0 + opts["stagger-ms"]) end t, run_at_ms = t0, run_at_ms0 else local matched_3f_66_, from_67_, to_68_ = nil, nil, nil if ((_G.type(event) == "table") and (event[1] == "move") and (nil ~= event[2]) and (nil ~= event[3])) then local from = event[2] local to = event[3] matched_3f_66_, from_67_, to_68_ = true, from, to elseif ((_G.type(event) == "table") and (nil ~= event[1]) and (nil ~= event[2])) then local from = event[1] local to = event[2] matched_3f_66_, from_67_, to_68_ = true, from, to else matched_3f_66_, from_67_, to_68_ = nil end if matched_3f_66_ then local from, to = from_67_, to_68_







 local card_id local _112_ do local t_111_ = memo if (nil ~= t_111_) then t_111_ = t_111_[table.concat(from, ".")] else end _112_ = t_111_ end local or_114_ = _112_
 if not or_114_ then local t_115_ = table["get-in"](app.game, from) if (nil ~= t_115_) then t_115_ = t_115_.id else end or_114_ = t_115_ end
 if not or_114_ then local function _124_() local data_5_auto = {from = from} local resolve_6_auto local function _117_(name_7_auto) local _118_ = data_5_auto[name_7_auto] local and_119_ = (nil ~= _118_) if and_119_ then local t_8_auto = _118_ and_119_ = ("table" == type(t_8_auto)) end if and_119_ then local t_8_auto = _118_ local _121_ = getmetatable(t_8_auto) if ((_G.type(_121_) == "table") and (nil ~= _121_.__tostring)) then local f_9_auto = _121_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _121_ return vim.inspect(t_8_auto) end elseif (nil ~= _118_) then local v_11_auto = _118_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _117_ return string.gsub("no card known #{from}", "#{(.-)}", resolve_6_auto) end or_114_ = error(_124_()) end card_id = or_114_ local _
 memo[table.concat(to, ".")] = card_id _ = nil
 local comp = app["card-id->components"][card_id]
 local _let_125_ = app["location->position"](app, from) local from_row = _let_125_["row"] local from_col = _let_125_["col"]
 local _let_126_ = app["location->position"](app, to) local to_row = _let_126_["row"] local to_col = _let_126_["col"] local z = _let_126_["z"]
 local duration = opts["duration-ms"] local tween
 local function _127_(percent)



 local _128_ if (percent < 1) then _128_ = app["z-index-for-layer"](app, "animation", (10 + z)) else

 _128_ = z end return comp["set-position"](comp, {row = (from_row + math.ceil(((to_row - from_row) * percent))), col = (from_col + math.ceil(((to_col - from_col) * percent))), z = _128_}) end tween = _127_
 t, run_at_ms = table.set(t, run_at_ms, {Animate["ease-out-quad"], duration, tween}), (run_at_ms + opts["stagger-ms"]) else local _ = event


 local function _137_() local data_5_auto = {event = event} local resolve_6_auto local function _130_(name_7_auto) local _131_ = data_5_auto[name_7_auto] local and_132_ = (nil ~= _131_) if and_132_ then local t_8_auto = _131_ and_132_ = ("table" == type(t_8_auto)) end if and_132_ then local t_8_auto = _131_ local _134_ = getmetatable(t_8_auto) if ((_G.type(_134_) == "table") and (nil ~= _134_.__tostring)) then local f_9_auto = _134_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _134_ return vim.inspect(t_8_auto) end elseif (nil ~= _131_) then local v_11_auto = _131_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _130_ return string.gsub("Unknown event, cant animate: #{event}", "#{(.-)}", resolve_6_auto) end t, run_at_ms = error(_137_()) end end end end timeline = t, run_at_ms end
 timeline["after"] = after
 return Animate.timeline(timeline) end
 return M