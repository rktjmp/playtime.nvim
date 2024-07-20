
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local Deck = require("playtime.game.set.deck")

 local CardGameUtils = require("playtime.common.card.utils")
 local apply_events = CardGameUtils["apply-events"]

 local M = {Action = {}, Plan = {}, Query = {}}



 local function card__3evector(card)
 local vals = {color = {red = 0, green = 1, blue = 2}, count = {0, 1, 2}, style = {solid = 0, split = 1, outline = 2}, shape = {square = 0, circle = 1, triangle = 2}}



 local color = card["color"] local count = card["count"] local style = card["style"] local shape = card["shape"]
 return {vals.color[color], vals.count[count], vals.style[style], vals.shape[shape]} end




 local function set_3f(a, b, c) _G.assert((nil ~= c), "Missing argument c on fnl/playtime/game/set/logic.fnl:26") _G.assert((nil ~= b), "Missing argument b on fnl/playtime/game/set/logic.fnl:26") _G.assert((nil ~= a), "Missing argument a on fnl/playtime/game/set/logic.fnl:26")
 local function vector_report(vector)
 local bads do local tbl_21_auto = {} local i_22_auto = 0 for i, name in ipairs({"color", "count", "style", "shape"}) do local val_23_auto
 if not (0 == vector[i]) then
 val_23_auto = name else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end bads = tbl_21_auto end
 if ((_G.type(bads) == "table") and (bads[1] == nil)) then
 return nil elseif (nil ~= bads) then local bads0 = bads
 return ("Not a set, check " .. table.concat(bads0, ", ")) else return nil end end
 local sum do local function _5_() local tbl_21_auto = {} local i_22_auto = 0 for _, c0 in ipairs({a, b, c}) do local val_23_auto = card__3evector(c0) if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end local _let_7_ = _5_() local av = _let_7_[1] local bv = _let_7_[2] local cv = _let_7_[3]
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



 do local len_deal do local _10_ = #state.deal local and_11_ = (nil ~= _10_) if and_11_ then local n = _10_ and_11_ = (12 < n) end if and_11_ then local n = _10_
 len_deal = n else local _ = _10_ len_deal = 12 end end

 for i = 1, len_deal do
 local _14_ = state.deal[i] if (nil ~= _14_) then local card = _14_
 coroutine.yield({"deal", i}, card) else end end end
 for i, card in ipairs(state.discard) do
 coroutine.yield({"discard", i}, card) end return nil end
 return coroutine.wrap(iter) end

 M.Action["generate-puzzle"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:80")
 Logger.info("generate-puzzle")
 local cards = nil for _ = 1, 100 do if cards then break end
 local indexes = table.shuffle(table.keys(state.draw)) local cards0

 do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 12 do
 local val_23_auto = state.draw[indexes[i]] if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end cards0 = tbl_21_auto end
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
 local _18_, _19_ = #state.draw, #state.deal if ((_18_ == 0) and true) then local _ = _19_
 return nil, Error("No additional cards to deal") else local _ = _18_



 local moves do local moves0 = {} for _0 = 1, 3 do
 moves0 = table.insert(table.insert(moves0, {"move", {"draw", "top"}, {"deal", "top"}}), {"face-up", {"deal", "top"}}) end moves = moves0 end


 return apply_events(clone(state), moves) end end

 M.Action["submit-set"] = function(state, deal_indexes) _G.assert((nil ~= deal_indexes), "Missing argument deal-indexes on fnl/playtime/game/set/logic.fnl:113") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:113")
 local _21_, _22_ = M.Query["set?"](state, deal_indexes) if (_21_ == true) then
 local moves do local moves0 = {} for _, i in ipairs(deal_indexes) do
 moves0 = table.insert(table.insert(moves0, {"move", {"deal", i}, {"discard", "top"}}), {"face-down", {"discard", "top"}}) end moves = moves0 end local moves0

 do local _23_ = #state.deal local and_24_ = (nil ~= _23_) if and_24_ then local n_dealt = _23_ and_24_ = (12 < n_dealt) end if and_24_ then local n_dealt = _23_



 local hole_indexes do local tbl_21_auto = {} local i_22_auto = 0 for _, i in ipairs(deal_indexes) do local val_23_auto
 if (i <= 12) then val_23_auto = i else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end hole_indexes = tbl_21_auto end local shift_indexes
 do local discarding = table.invert(deal_indexes)
 local tbl_21_auto = {} local i_22_auto = 0 for i = 13, n_dealt do local val_23_auto
 if (nil == discarding[i]) then
 val_23_auto = i else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end shift_indexes = tbl_21_auto end
 local moves1 = moves for i, _ in ipairs(shift_indexes) do
 moves1 = table.insert(moves1, {"move", {"deal", shift_indexes[i]}, {"deal", hole_indexes[i]}}) end moves0 = moves1 else local _ = _23_



 local _30_ = #state.draw if (_30_ == 0) then
 moves0 = moves else local _0 = _30_
 local moves1 = moves for _1, i in ipairs(deal_indexes) do
 moves1 = table.insert(table.insert(moves1, {"move", {"draw", "top"}, {"deal", i}}), {"face-up", {"deal", i}}) end moves0 = moves1 end end end

 return apply_events(clone(state), moves0) elseif ((_21_ == false) and true) then local _3fmsg = _22_
 return nil, Error((_3fmsg or "not a set")) else return nil end end

 M.Query["find-sets"] = function(state)
 local dealt_cards do local tbl_16_auto = {} for loc, c in M["iter-cards"](state) do local k_17_auto, v_18_auto = nil, nil
 if ((_G.type(loc) == "table") and (loc[1] == "deal")) then
 k_17_auto, v_18_auto = loc, c else k_17_auto, v_18_auto = nil end if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end dealt_cards = tbl_16_auto end
 local sets = find_sets(table.values(dealt_cards)) local dealt_indexes
 do local tbl_21_auto = {} local i_22_auto = 0 for _, a_set in ipairs(sets) do local val_23_auto
 do local tbl_21_auto0 = {} local i_22_auto0 = 0 for _0, card in ipairs(a_set) do local val_23_auto0
 do local i = nil for _36_, c in pairs(dealt_cards) do local _1 = _36_[1] local n = _36_[2] if i then break end
 local _37_, _38_ = c, card if (((_G.type(_37_) == "table") and (nil ~= _37_.id)) and ((_G.type(_38_) == "table") and (_37_.id == _38_.id))) then local id = _37_.id
 i = n else i = nil end end val_23_auto0 = i end if (nil ~= val_23_auto0) then i_22_auto0 = (i_22_auto0 + 1) tbl_21_auto0[i_22_auto0] = val_23_auto0 else end end val_23_auto = tbl_21_auto0 end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end dealt_indexes = tbl_21_auto end
 return dealt_indexes end

 M.Query["set?"] = function(state, dealt_indexes) _G.assert((nil ~= dealt_indexes), "Missing argument dealt-indexes on fnl/playtime/game/set/logic.fnl:153") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:153")
 local cards do local tbl_21_auto = {} local i_22_auto = 0 for _, i in ipairs(dealt_indexes) do local val_23_auto = state.deal[i] if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end cards = tbl_21_auto end
 if ((_G.type(cards) == "table") and (nil ~= cards[1]) and (nil ~= cards[2]) and (nil ~= cards[3]) and (cards[4] == nil)) then local a = cards[1] local b = cards[2] local c = cards[3]
 return set_3f(a, b, c) else local _ = cards return false end end


 M.Query["hint-for-set"] = function(state, dealt_indexes) _G.assert((nil ~= dealt_indexes), "Missing argument dealt-indexes on fnl/playtime/game/set/logic.fnl:159") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:159")
 assert(M.Query["set?"](state, dealt_indexes), "unable to hint set, cards are not a set!")
 local cards do local tbl_21_auto = {} local i_22_auto = 0 for _, i in ipairs(dealt_indexes) do local val_23_auto = state.deal[i] if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end cards = tbl_21_auto end local tbl_16_auto = {}
 for _, key in ipairs({"shape", "color", "style", "count"}) do local k_17_auto, v_18_auto = nil, nil
 do local vals do local tbl_21_auto = {} local i_22_auto = 0 for _0, card in ipairs(cards) do local val_23_auto = card[key] if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end vals = tbl_21_auto end local result
 if ((_G.type(vals) == "table") and (nil ~= vals[1]) and (vals[1] == vals[2]) and (vals[1] == vals[3])) then local a = vals[1] result = "same" else local _0 = vals result = "diff" end


 k_17_auto, v_18_auto = key, result end if ((k_17_auto ~= nil) and (v_18_auto ~= nil)) then tbl_16_auto[k_17_auto] = v_18_auto else end end return tbl_16_auto end

 M.Query["game-ended?"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:169")
 local sets = M.Query["find-sets"](state)
 return (table["empty?"](sets) and table["empty?"](state.draw)) end


 M.Query["game-result"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/set/logic.fnl:174")

 local _48_ do local tbl_21_auto = {} local i_22_auto = 0 for loc, _ in M["iter-cards"](state) do local val_23_auto
 if ((_G.type(loc) == "table") and (loc[1] == "deal")) then val_23_auto = true else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end _48_ = tbl_21_auto end return {sets = (#state.discard / 3), remaining = #_48_} end


 return M