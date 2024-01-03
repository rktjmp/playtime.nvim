
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


 local function _28_() local data_5_auto = {card = card} local resolve_6_auto local function _22_(name_7_auto) local _23_ = data_5_auto[name_7_auto] local function _24_() local t_8_auto = _23_ return ("table" == type(t_8_auto)) end if ((nil ~= _23_) and _24_()) then local t_8_auto = _23_ local _25_ = getmetatable(t_8_auto) if ((_G.type(_25_) == "table") and (nil ~= _25_.__tostring)) then local f_9_auto = _25_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _25_ return vim.inspect(t_8_auto) end elseif (nil ~= _23_) then local v_11_auto = _23_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _22_ return string.gsub("Not a card: #{card}", "#{(.-)}", resolve_6_auto) end return error(_28_()) end end

 fns["card-face-down?"] = function(card)
 return not fns["card-face-up?"](card) end

 fns["card-value"] = function(card)
 if ((_G.type(card) == "table") and true and (nil ~= card[2])) then local _suit = card[1] local rank = card[2]

 return (spec.value[rank] or rank) else local _ = card return error(Error("invalid card #{card}", {card = card})) end end


 fns["card-color"] = function(card)
 if ((_G.type(card) == "table") and (nil ~= card[1]) and (nil ~= card[2])) then local suit = card[1] local rank = card[2] local function _31_(...) return error(Error("invalid card #{card}", {card = card})) end
 return (spec.color[suit] or _31_()) else local _ = card return error(Error("invalid card #{card}", {card = card})) end end


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
 local function _35_(sequence)
 if ((_G.type(sequence) == "table") and (nil ~= sequence[1])) then local top_card = sequence[1] local other_cards = {select(2, (table.unpack or _G.unpack)(sequence))}

 local ok_3f, checked_cards, memo = true, {top_card}, nil for _, card in ipairs(other_cards) do if not ok_3f then break end


 local ok_3f0, memo0 = comparitor_fn(card, checked_cards, memo)
 if ok_3f0 then
 ok_3f, checked_cards, memo = true, table.insert(checked_cards, 1, card), memo0 else
 ok_3f, checked_cards, memo = false end end return ok_3f, checked_cards, memo else local _ = sequence return false end end return _35_ end


 M["inc-moves"] = function(state, _3fcount)
 state["moves"] = ((_3fcount or 1) + state.moves) return state end


 M["apply-events"] = function(state, events) _G.assert((nil ~= events), "Missing argument events on fnl/playtime/common/card/utils.fnl:117") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/common/card/utils.fnl:117")
 local state0, true_events = state, {} for event_num, event in ipairs(events) do

 local matched_3f_38_, location_39_ = nil, nil if ((_G.type(event) == "table") and (event[1] == "face-up") and (nil ~= event[2])) then local location = event[2] matched_3f_38_, location_39_ = true, location elseif ((_G.type(event) == "table") and (event[1] == "face-down") and (nil ~= event[2])) then local location = event[2] matched_3f_38_, location_39_ = true, location else matched_3f_38_, location_39_ = nil end if matched_3f_38_ then local location = location_39_

 local index do local _41_ = table.last(location) if (_41_ == "top") then
 index = #table["get-in"](state0, table.split(location, -1)) elseif (_41_ == "bottom") then index = 1 elseif (nil ~= _41_) then local n = _41_

 index = n else index = nil end end
 local _let_43_ = event local face_where = _let_43_[1] local _ = _let_43_[2]
 local location0 = table.set(clone(location), #location, index)
 do local _44_ = table["get-in"](state0, location0) if (nil ~= _44_) then local card = _44_
 if (face_where == "face-up") then card.face = "up" elseif (face_where == "face-down") then card.face = "down" else end else local _0 = _44_


 local function _52_() local data_5_auto = {event = event, ["event-num"] = event_num, events = events} local resolve_6_auto local function _46_(name_7_auto) local _47_ = data_5_auto[name_7_auto] local function _48_() local t_8_auto = _47_ return ("table" == type(t_8_auto)) end if ((nil ~= _47_) and _48_()) then local t_8_auto = _47_ local _49_ = getmetatable(t_8_auto) if ((_G.type(_49_) == "table") and (nil ~= _49_.__tostring)) then local f_9_auto = _49_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _49_ return vim.inspect(t_8_auto) end elseif (nil ~= _47_) then local v_11_auto = _47_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _46_ return string.gsub("apply-events: no card, cannot apply #{event-num}: #{event}, #{events}", "#{(.-)}", resolve_6_auto) end error(_52_()) end end
 state0, true_events = state0, table.insert(true_events, {face_where, location0}) elseif ((_G.type(event) == "table") and (event[1] == "swap") and (nil ~= event[2]) and (nil ~= event[3])) then local a = event[2] local b = event[3]

 local a_index do local _54_ = table.last(a) if (_54_ == "bottom") then a_index = 1 elseif (_54_ == "top") then

 a_index = #table["get-in"](state0, table.split(a, -1)) elseif (nil ~= _54_) then local n = _54_
 a_index = n else a_index = nil end end local b_index
 do local _56_ = table.last(b) if (_56_ == "bottom") then b_index = 1 elseif (_56_ == "top") then

 b_index = #table["get-in"](state0, table.split(b, -1)) elseif (nil ~= _56_) then local n = _56_
 b_index = n else b_index = nil end end
 local a0 = table.set(clone(a), #a, a_index)

 local b0 = table.set(clone(b), #b, b_index)

 local temp = table["get-in"](state0, b0)
 table["set-in"](state0, b0, table["get-in"](state0, a0))
 table["set-in"](state0, a0, temp)
 state0, true_events = state0, table.insert(true_events, {"swap", a0, b0}) elseif ((_G.type(event) == "table") and (event[1] == "move") and (nil ~= event[2]) and (nil ~= event[3])) then local from = event[2] local to = event[3]

 local from_index do local _58_ = table.last(from) if (_58_ == "bottom") then from_index = 1 elseif (_58_ == "top") then

 from_index = #table["get-in"](state0, table.split(from, -1)) elseif (nil ~= _58_) then local n = _58_
 from_index = n else from_index = nil end end local mod_fn, to_index = nil, nil
 do local _60_ = table.last(to) if (_60_ == "bottom") then
 mod_fn, to_index = table["insert-in"], 1 elseif (_60_ == "top") then
 mod_fn, to_index = table["set-in"], (1 + #table["get-in"](state0, table.split(to, -1))) elseif (nil ~= _60_) then local n = _60_
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

 local function _68_() return nil end t, run_at_ms = table.set(t, run_at_ms, {Animate.linear, n, _68_}), (run_at_ms + n) else local matched_3f_63_, location_64_ = nil, nil if ((_G.type(event) == "table") and (event[1] == "face-up") and (nil ~= event[2])) then local location = event[2] matched_3f_63_, location_64_ = true, location elseif ((_G.type(event) == "table") and (event[1] == "face-down") and (nil ~= event[2])) then local location = event[2] matched_3f_63_, location_64_ = true, location else matched_3f_63_, location_64_ = nil end if matched_3f_63_ then local location = location_64_


 local card_id local function _70_(...) local t_71_ = memo if (nil ~= t_71_) then t_71_ = t_71_[table.concat(location, ".")] else end return t_71_ end card_id = (_70_() or table["get-in"](app.game, location).id)

 local comp = app["card-id->components"][card_id]
 local memo0 = {once = false}
 local dir = event[1] local tween
 local function _73_(percent)
 if ((0.5 < percent) and not memo0.once) then memo0.once = true return comp["force-flip"](comp, dir) else return nil end end tween = _73_


 t, run_at_ms = table.set(t, run_at_ms, {Animate["ease-out-quad"], 1, tween}), (run_at_ms + 1) elseif ((_G.type(event) == "table") and (event[1] == "swap") and (nil ~= event[2]) and (nil ~= event[3])) then local a = event[2] local b = event[3]







 local id_a local function _75_(...) local t_76_ = memo if (nil ~= t_76_) then t_76_ = t_76_[table.concat(a, ".")] else end return t_76_ end local function _78_(...)
 local t_79_ = table["get-in"](app.game, a) if (nil ~= t_79_) then t_79_ = t_79_.id else end return t_79_ end
 local function _87_() local data_5_auto = {a = a} local resolve_6_auto local function _81_(name_7_auto) local _82_ = data_5_auto[name_7_auto] local function _83_() local t_8_auto = _82_ return ("table" == type(t_8_auto)) end if ((nil ~= _82_) and _83_()) then local t_8_auto = _82_ local _84_ = getmetatable(t_8_auto) if ((_G.type(_84_) == "table") and (nil ~= _84_.__tostring)) then local f_9_auto = _84_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _84_ return vim.inspect(t_8_auto) end elseif (nil ~= _82_) then local v_11_auto = _82_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _81_ return string.gsub("no card known #{a}", "#{(.-)}", resolve_6_auto) end id_a = (_75_() or _78_() or error(_87_())) local id_b local function _88_(...)
 local t_89_ = memo if (nil ~= t_89_) then t_89_ = t_89_[table.concat(b, ".")] else end return t_89_ end local function _91_(...)
 local t_92_ = table["get-in"](app.game, b) if (nil ~= t_92_) then t_92_ = t_92_.id else end return t_92_ end
 local function _100_() local data_5_auto = {b = b} local resolve_6_auto local function _94_(name_7_auto) local _95_ = data_5_auto[name_7_auto] local function _96_() local t_8_auto = _95_ return ("table" == type(t_8_auto)) end if ((nil ~= _95_) and _96_()) then local t_8_auto = _95_ local _97_ = getmetatable(t_8_auto) if ((_G.type(_97_) == "table") and (nil ~= _97_.__tostring)) then local f_9_auto = _97_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _97_ return vim.inspect(t_8_auto) end elseif (nil ~= _95_) then local v_11_auto = _95_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _94_ return string.gsub("no card known #{b}", "#{(.-)}", resolve_6_auto) end id_b = (_88_() or _91_() or error(_100_())) local _
 do end (memo)[table.concat(b, ".")] = id_a _ = nil local _0
 memo[table.concat(a, ".")] = id_b _0 = nil
 local t0, run_at_ms0 = t, run_at_ms for _1, _101_ in ipairs({{id_a, a, b}, {id_b, b, a}}) do
 local _each_102_ = _101_ local card_id = _each_102_[1] local from = _each_102_[2] local to = _each_102_[3]
 local comp = app["card-id->components"][card_id]
 local _let_103_ = app["location->position"](app, from) local from_row = _let_103_["row"] local from_col = _let_103_["col"]
 local _let_104_ = app["location->position"](app, to) local to_row = _let_104_["row"] local to_col = _let_104_["col"] local z = _let_104_["z"]
 local duration = opts["duration-ms"] local tween
 local function _105_(percent)



 local _106_ if (percent < 1) then _106_ = app["z-index-for-layer"](app, "animation", (10 + z)) else

 _106_ = z end return comp["set-position"](comp, {row = (from_row + math.ceil(((to_row - from_row) * percent))), col = (from_col + math.ceil(((to_col - from_col) * percent))), z = _106_}) end tween = _105_
 t0, run_at_ms0 = table.set(t0, run_at_ms0, {Animate["ease-out-quad"], duration, tween}), (run_at_ms0 + opts["stagger-ms"]) end t, run_at_ms = t0, run_at_ms0 else local matched_3f_65_, from_66_, to_67_ = nil, nil, nil if ((_G.type(event) == "table") and (event[1] == "move") and (nil ~= event[2]) and (nil ~= event[3])) then local from = event[2] local to = event[3] matched_3f_65_, from_66_, to_67_ = true, from, to elseif ((_G.type(event) == "table") and (nil ~= event[1]) and (nil ~= event[2])) then local from = event[1] local to = event[2] matched_3f_65_, from_66_, to_67_ = true, from, to else matched_3f_65_, from_66_, to_67_ = nil end if matched_3f_65_ then local from, to = from_66_, to_67_







 local card_id local function _109_(...) local t_110_ = memo if (nil ~= t_110_) then t_110_ = t_110_[table.concat(from, ".")] else end return t_110_ end local function _112_(...)
 local t_113_ = table["get-in"](app.game, from) if (nil ~= t_113_) then t_113_ = t_113_.id else end return t_113_ end
 local function _121_() local data_5_auto = {from = from} local resolve_6_auto local function _115_(name_7_auto) local _116_ = data_5_auto[name_7_auto] local function _117_() local t_8_auto = _116_ return ("table" == type(t_8_auto)) end if ((nil ~= _116_) and _117_()) then local t_8_auto = _116_ local _118_ = getmetatable(t_8_auto) if ((_G.type(_118_) == "table") and (nil ~= _118_.__tostring)) then local f_9_auto = _118_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _118_ return vim.inspect(t_8_auto) end elseif (nil ~= _116_) then local v_11_auto = _116_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _115_ return string.gsub("no card known #{from}", "#{(.-)}", resolve_6_auto) end card_id = (_109_() or _112_() or error(_121_())) local _
 do end (memo)[table.concat(to, ".")] = card_id _ = nil
 local comp = app["card-id->components"][card_id]
 local _let_122_ = app["location->position"](app, from) local from_row = _let_122_["row"] local from_col = _let_122_["col"]
 local _let_123_ = app["location->position"](app, to) local to_row = _let_123_["row"] local to_col = _let_123_["col"] local z = _let_123_["z"]
 local duration = opts["duration-ms"] local tween
 local function _124_(percent)



 local _125_ if (percent < 1) then _125_ = app["z-index-for-layer"](app, "animation", (10 + z)) else

 _125_ = z end return comp["set-position"](comp, {row = (from_row + math.ceil(((to_row - from_row) * percent))), col = (from_col + math.ceil(((to_col - from_col) * percent))), z = _125_}) end tween = _124_
 t, run_at_ms = table.set(t, run_at_ms, {Animate["ease-out-quad"], duration, tween}), (run_at_ms + opts["stagger-ms"]) else local _ = event


 local function _133_() local data_5_auto = {event = event} local resolve_6_auto local function _127_(name_7_auto) local _128_ = data_5_auto[name_7_auto] local function _129_() local t_8_auto = _128_ return ("table" == type(t_8_auto)) end if ((nil ~= _128_) and _129_()) then local t_8_auto = _128_ local _130_ = getmetatable(t_8_auto) if ((_G.type(_130_) == "table") and (nil ~= _130_.__tostring)) then local f_9_auto = _130_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _130_ return vim.inspect(t_8_auto) end elseif (nil ~= _128_) then local v_11_auto = _128_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _127_ return string.gsub("Unknown event, cant animate: #{event}", "#{(.-)}", resolve_6_auto) end t, run_at_ms = error(_133_()) end end end end timeline = t, run_at_ms end
 timeline["after"] = after
 return Animate.timeline(timeline) end
 return M