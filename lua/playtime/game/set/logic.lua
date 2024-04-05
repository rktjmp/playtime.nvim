
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local Deck = require("playtime.game.set.deck")

 local CardGameUtils = require("playtime.common.card.utils")
 local _local_2_ = CardGameUtils local apply_events = _local_2_["apply-events"]

 local M = {Action = {}, Plan = {}, Query = {}}



 local function card__3evector(card)
 local vals = {color = {red = 0, green = 1, blue = 2}, count = {0, 1, 2}, style = {solid = 0, split = 1, outline = 2}, shape = {square = 0, circle = 1, triangle = 2}}



 local _let_3_ = card local color = _let_3_["color"] local count = _let_3_["count"] local style = _let_3_["style"] local shape = _let_3_["shape"]
 return {vals.color[color], vals.count[count], vals.style[style], vals.shape[shape]} end




 local function set_3f(a, b, c) _G.assert((nil ~= c), "Missing argument c on fnl/playtime/game/set/logic.fnl:26") _G.assert((nil ~= b), "Missing argument b on fnl/playtime/game/set/logic.fnl:26") _G.assert((nil ~= a), "Missing argument a on fnl/playtime/game/set/logic.fnl:26")
 local function vector_report(vector)
 local bads do local tbl_19_auto = {} local i_20_auto = 0 for i, name in ipairs({"color", "count", "style", "shape"}) do local val_21_auto
 if not (0 == vector[i]) then
 val_21_auto = name else val_21_auto = nil end if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end bads = tbl_19_auto end
 if ((_G.type(bads) == "table") and (bads[1] == nil)) then
 return nil elseif (nil ~= bads) then local bads0 = bads
 return ("Not a set, check " .. table.concat(bads0, ", ")) else return nil end end
 local sum do local function _8_() local tbl_19_auto = {} local i_20_auto = 0 for _, c0 in ipairs({a, b, c}) do local val_21_auto = card__3evector(c0) if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end return tbl_19_auto end local _let_7_ = _8_() local av = _let_7_[1] local bv = _let_7_[2] local cv = _let_7_[3]
 local sum0 = {0, 0, 0, 0} for i = 1, 4 do
 sum0 = table.set(sum0, i, ((av[i] + bv[i] + cv[i]) % 3)) end sum = sum0 end

 if ((_G.type(sum) == "table") and (sum[1] == 0) and (sum[2] == 0) and (sum[3] == 0) and (sum[4] == 0)) then return true elseif (nil ~= sum) then local sum0 = sum

 return false, vector_report(sum0) else return nil end end

 local function find_sets(cards) _G.assert((nil ~= cards), "Missing argument cards on fnl/playtime/game/set/logic.fnl:42")
 local sets = {}
 local limit = #cards
 for a = 1, (limit - 3) do
 for b = (a + 1), (limit - 1) do
 for c = limit, (b + 1), -1 do
 local ca = cards[a]
 local cb = cards[b]
 local cc = cards[c]
 if set_3f(ca, cb, cc) then
 table.insert(sets, {ca, cb, cc}) else end end end end
 return sets end

 M.build = function(config, _3fseed) _G.assert((nil ~= config), "Missing argument config on fnl/playtime/game/set/logic.fnl:55")
 math.randomseed((_3fseed or os.time()))
 local state = {draw = Deck.shuffle(Deck.Set.build()), deal = {}, discard = {}}



 return state end

 M["iter-cards"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:63")
 local function iter()
 for i, card in ipairs(state.draw) do
 coroutine.yield({"draw", i}, card) end



 do local len_deal do local _12_ = #state.deal local function _13_() local n = _12_ return (12 < n) end if ((nil ~= _12_) and _13_()) then local n = _12_
 len_deal = n else local _ = _12_ len_deal = 12 end end

 for i = 1, len_deal do
 local _15_ = state.deal[i] if (nil ~= _15_) then local card = _15_
 coroutine.yield({"deal", i}, card) else end end end
 for i, card in ipairs(state.discard) do
 coroutine.yield({"discard", i}, card) end return nil end
 return coroutine.wrap(iter) end

 M.Action["generate-puzzle"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:80")
 Logger.info("generate-puzzle")
 local cards = nil for _ = 1, 100 do if cards then break end
 local indexes = table.shuffle(table.keys(state.draw)) local cards0

 do local tbl_19_auto = {} local i_20_auto = 0 for i = 1, 12 do
 local val_21_auto = state.draw[indexes[i]] if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end cards0 = tbl_19_auto end
 local sets = find_sets(cards0)
 if (6 <= #sets) then

 Logger.info("Found 6 in  #{sets}", {sets = sets})
 cards = cards0 else
 cards = Logger.info({"found", #sets}) end end return cards end

 M.Action.deal = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:94")
 local moves do local moves0 = {} for _ = 1, 12 do
 moves0 = table.insert(table.insert(moves0, {"move", {"draw", "top"}, {"deal", "top"}}), {"face-up", {"deal", "top"}}) end moves = moves0 end


 return apply_events(clone(state), moves) end

 M.Action["deal-more"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:101")
 local _19_, _20_ = #state.draw, #state.deal if ((_19_ == 0) and true) then local _ = _20_
 return nil, Error("No additional cards to deal") else local _ = _19_



 local moves do local moves0 = {} for _0 = 1, 3 do
 moves0 = table.insert(table.insert(moves0, {"move", {"draw", "top"}, {"deal", "top"}}), {"face-up", {"deal", "top"}}) end moves = moves0 end


 return apply_events(clone(state), moves) end end

 M.Action["submit-set"] = function(state, deal_indexes) _G.assert((nil ~= deal_indexes), "Missing argument deal-indexes on fnl/playtime/game/set/logic.fnl:113") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:113")
 local _22_, _23_ = M.Query["set?"](state, deal_indexes) if (_22_ == true) then
 local moves do local moves0 = {} for _, i in ipairs(deal_indexes) do
 moves0 = table.insert(table.insert(moves0, {"move", {"deal", i}, {"discard", "top"}}), {"face-down", {"discard", "top"}}) end moves = moves0 end local moves0

 do local _24_ = #state.deal local function _25_() local n_dealt = _24_ return (12 < n_dealt) end if ((nil ~= _24_) and _25_()) then local n_dealt = _24_



 local hole_indexes do local tbl_19_auto = {} local i_20_auto = 0 for _, i in ipairs(deal_indexes) do local val_21_auto
 if (i <= 12) then val_21_auto = i else val_21_auto = nil end if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end hole_indexes = tbl_19_auto end local shift_indexes
 do local discarding = table.invert(deal_indexes)
 local tbl_19_auto = {} local i_20_auto = 0 for i = 13, n_dealt do local val_21_auto
 if (nil == discarding[i]) then
 val_21_auto = i else val_21_auto = nil end if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end shift_indexes = tbl_19_auto end
 local moves1 = moves for i, _ in ipairs(shift_indexes) do
 moves1 = table.insert(moves1, {"move", {"deal", shift_indexes[i]}, {"deal", hole_indexes[i]}}) end moves0 = moves1 else local _ = _24_



 local _30_ = #state.draw if (_30_ == 0) then
 moves0 = moves else local _0 = _30_
 local moves1 = moves for _1, i in ipairs(deal_indexes) do
 moves1 = table.insert(table.insert(moves1, {"move", {"draw", "top"}, {"deal", i}}), {"face-up", {"deal", i}}) end moves0 = moves1 end end end

 return apply_events(clone(state), moves0) elseif ((_22_ == false) and true) then local _3fmsg = _23_
 return nil, Error((_3fmsg or "not a set")) else return nil end end

 M.Query["find-sets"] = function(state)
 local dealt_cards do local tbl_14_auto = {} for loc, c in M["iter-cards"](state) do local k_15_auto, v_16_auto = nil, nil
 if ((_G.type(loc) == "table") and (loc[1] == "deal")) then
 k_15_auto, v_16_auto = loc, c else k_15_auto, v_16_auto = nil end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end dealt_cards = tbl_14_auto end
 local sets = find_sets(table.values(dealt_cards)) local dealt_indexes
 do local tbl_19_auto = {} local i_20_auto = 0 for _, a_set in ipairs(sets) do local val_21_auto
 do local tbl_19_auto0 = {} local i_20_auto0 = 0 for _0, card in ipairs(a_set) do local val_21_auto0
 do local i = nil for _36_, c in pairs(dealt_cards) do local _each_37_ = _36_ local _1 = _each_37_[1] local n = _each_37_[2] if i then break end
 local _38_, _39_ = c, card if (((_G.type(_38_) == "table") and (nil ~= _38_.id)) and ((_G.type(_39_) == "table") and (_38_.id == _39_.id))) then local id = _38_.id
 i = n else i = nil end end val_21_auto0 = i end if (nil ~= val_21_auto0) then i_20_auto0 = (i_20_auto0 + 1) do end (tbl_19_auto0)[i_20_auto0] = val_21_auto0 else end end val_21_auto = tbl_19_auto0 end if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end dealt_indexes = tbl_19_auto end
 return dealt_indexes end

 M.Query["set?"] = function(state, dealt_indexes) _G.assert((nil ~= dealt_indexes), "Missing argument dealt-indexes on fnl/playtime/game/set/logic.fnl:153") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:153")
 local cards do local tbl_19_auto = {} local i_20_auto = 0 for _, i in ipairs(dealt_indexes) do local val_21_auto = state.deal[i] if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end cards = tbl_19_auto end
 if ((_G.type(cards) == "table") and (nil ~= cards[1]) and (nil ~= cards[2]) and (nil ~= cards[3]) and (cards[4] == nil)) then local a = cards[1] local b = cards[2] local c = cards[3]
 return set_3f(a, b, c) else local _ = cards return false end end


 M.Query["hint-for-set"] = function(state, dealt_indexes) _G.assert((nil ~= dealt_indexes), "Missing argument dealt-indexes on fnl/playtime/game/set/logic.fnl:159") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:159")
 assert(M.Query["set?"](state, dealt_indexes), "unable to hint set, cards are not a set!")
 local cards do local tbl_19_auto = {} local i_20_auto = 0 for _, i in ipairs(dealt_indexes) do local val_21_auto = state.deal[i] if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end cards = tbl_19_auto end local tbl_14_auto = {}
 for _, key in ipairs({"shape", "color", "style", "count"}) do local k_15_auto, v_16_auto = nil, nil
 do local vals do local tbl_19_auto = {} local i_20_auto = 0 for _0, card in ipairs(cards) do local val_21_auto = card[key] if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end vals = tbl_19_auto end local result
 if ((_G.type(vals) == "table") and (nil ~= vals[1]) and (vals[1] == vals[2]) and (vals[1] == vals[3])) then local a = vals[1] result = "same" else local _0 = vals result = "diff" end


 k_15_auto, v_16_auto = key, result end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end return tbl_14_auto end

 M.Query["game-ended?"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:169")
 local sets = M.Query["find-sets"](state)
 return (table["empty?"](sets) and table["empty?"](state.draw)) end


 M.Query["game-result"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:174")

 local _49_ do local tbl_19_auto = {} local i_20_auto = 0 for loc, _ in M["iter-cards"](state) do local val_21_auto
 if ((_G.type(loc) == "table") and (loc[1] == "deal")) then val_21_auto = true else val_21_auto = nil end if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end _49_ = tbl_19_auto end return {sets = (#state.discard / 3), remaining = #_49_} end


 return M