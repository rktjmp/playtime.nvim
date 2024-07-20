
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}



 local apply_events = CardGameUtils["apply-events"]
 local _local_2_ = CardGameUtils["make-card-util-fns"]({value = {king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_2_["card-value"] local card_color = _local_2_["card-color"] local card_rank = _local_2_["card-rank"] local card_suit = _local_2_["card-suit"]
 local rank_value = _local_2_["rank-value"]
 local suit_color = _local_2_["suit-color"]
 local card_face_up_3f = _local_2_["card-face-up?"] local card_face_down_3f = _local_2_["card-face-down?"]
 local flip_face_up = _local_2_["flip-face-up"] local flip_face_down = _local_2_["flip-face-down"]




 local function kingdom_suit(state)
 return card_suit(state.kingdom[state["at-kingdom"]][1]) end

 M["card-value"] = card_value

 M.build = function(_config, _3fseed)
 math.randomseed((_3fseed or os.time()))
 local deck = Deck.shuffle(Deck.Standard52.build()) local numbered, court = nil, nil

 local function _3_(card) return type["number?"](card[2]) end numbered, court = Deck.split(deck, _3_) local advisors, rulers = nil, nil
 local function _4_(card) return ("jack" == card[2]) end advisors, rulers = Deck.split(court, _4_) local draw, _not_used = nil, nil
 local function _5_(card) return (card[2] < 9) end draw, _not_used = Deck.split(numbered, _5_)
 local state = {["at-kingdom"] = nil, kingdom = {{}, {}, {}, {}, {}, {}, {}, {}}, discard = {}, score = {}, debate = {}, draw = {}, hand = {}, advisor = {hearts = {}, diamonds = {}, spades = {}, clubs = {}}}











 for i, c in ipairs(rulers) do
 state["kingdom"][i][1] = flip_face_up(c) end
 for _, c in ipairs(advisors) do
 state["advisor"][card_suit(c)][1] = flip_face_up(c) end
 state["draw"] = draw
 return state end

 local function sort_hand_21(hand)
 local function _6_(a, b)
 return (card_value(a) < card_value(b)) end

 local function _7_(a, b)
 local t = {hearts = 1, spades = 2, diamonds = 3, clubs = 4}
 local a0 = t[card_suit(a)]
 local b0 = t[card_suit(b)]
 return (a0 < b0) end return table.sort(table.sort(hand, _6_), _7_) end

 local function moves_to_pack_hand(old_hand, new_hand)
 local packed do local t, to = {}, 1 for i = 1, #old_hand do
 local _8_ = new_hand[i] if (_8_ == nil) then
 t, to = t, to elseif (nil ~= _8_) then local any = _8_
 local _9_ do table.insert(t, {i, to}) _9_ = t end t, to = _9_, (to + 1) else t, to = nil end end packed = t, to end
 local tbl_21_auto = {} local i_22_auto = 0 for _, _11_ in ipairs(packed) do local a = _11_[1] local b = _11_[2] local val_23_auto
 if not (a == b) then
 val_23_auto = {"move", {"hand", a}, {"hand", b}} else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end

 M.Action.deal = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:73")
 local top = #state.draw local events
 do local t = {} for i = top, (top - 7), -1 do
 t = table.insert(table.insert(t, {"move", {"draw", i}, {"hand", "top"}}), {"face-up", {"hand", "top"}}) end events = t end

 local state0, events0 = apply_events(clone(state), events)
 state0.hand = sort_hand_21(state0.hand)
 return state0, events0 end

 M.Action["pick-kingdom"] = function(state, n) _G.assert((nil ~= n), "Missing argument n on fnl/playtime/game/the-emissary/logic.fnl:82") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:82")
 local _14_ = state.kingdom[n] if ((_G.type(_14_) == "table") and ((_G.type(_14_[1]) == "table") and (_14_[1].face == "up"))) then
 return table.set(clone(state), "at-kingdom", n) else local _ = _14_
 return nil, Error("Cant pick kingdom #{n}", {n = n}) end end

 M.Action.draw = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:87")
 if not state["at-kingdom"] then
 return nil, Error("Cant draw, not visiting a kingdom") else
 local state0, moves = nil, nil if (0 == #state.draw) then
 local moves0 do local t = {} for i, _ in ipairs(state.discard) do
 t = table.insert(table.insert(t, {"face-down", {"discard", i}}), {"move", {"discard", i}, {"draw", "top"}}) end moves0 = t end

 local state1, moves1 = apply_events(clone(state), moves0)
 table.shuffle(state1.draw)
 state0, moves = state1, moves1 else
 state0, moves = clone(state), {} end
 local state1, more_moves = apply_events(state0, {{"move", {"draw", "top"}, {"debate", "top"}}, {"face-up", {"debate", "top"}}}) local moves0

 do local tbl_19_auto = moves for _, m in ipairs(more_moves) do local val_20_auto = m table.insert(tbl_19_auto, val_20_auto) end moves0 = tbl_19_auto end
 return state1, moves0 end end

 M.Action["play-hand"] = function(state, hand_n) _G.assert((nil ~= hand_n), "Missing argument hand-n on fnl/playtime/game/the-emissary/logic.fnl:103") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:103")
 local against_card = table.last(state.debate)
 local against_suit = card_suit(against_card)
 local against_value = card_value(against_card)
 local played_card = state.hand[hand_n]
 local played_suit = card_suit(played_card)
 local played_value = card_value(played_card) local has_suit_3f
 do local yes_3f = false for _, c in ipairs(state.hand) do if yes_3f then break end
 yes_3f = (against_suit == card_suit(c)) end has_suit_3f = yes_3f end
 local playing_suit_3f = (against_suit == played_suit)
 if (has_suit_3f and not playing_suit_3f) then
 return nil, Error("Must follow suit if you can, you have a #{suit} in hand", {suit = against_suit}) else
 local trump_suit = card_suit(state.kingdom[state["at-kingdom"]][1]) local won_3f
 do local _18_, _19_, _20_, _21_ = against_suit, against_value, played_suit, played_value if ((nil ~= _18_) and (nil ~= _19_) and (_18_ == _20_) and (nil ~= _21_)) then local suit = _18_ local against = _19_ local played = _21_

 won_3f = (against < played) elseif (true and true and (_20_ == trump_suit) and true) then local _ = _18_ local _0 = _19_ local _1 = _21_ won_3f = true else local _ = _18_ won_3f = false end end



 local moves = {{"move", {"hand", hand_n}, {"debate", "top"}}} local moves0
 if won_3f then
 moves0 = table.insert(table.insert(moves, {"move", {"debate", 2}, {"score", "top"}}), {"move", {"debate", 1}, {"discard", "top"}}) else


 moves0 = table.insert(table.insert(moves, {"move", {"debate", 2}, {"discard", "top"}}), {"move", {"debate", 1}, {"discard", "top"}}) end local moves1


 do local tbl_19_auto = moves0 for i = (hand_n + 1), #state.hand do
 local val_20_auto = {"move", {"hand", i}, {"hand", (i - 1)}} table.insert(tbl_19_auto, val_20_auto) end moves1 = tbl_19_auto end
 return apply_events(clone(state), moves1, {["unsafely?"] = true}) end end

 M.Action["finish-kingdom"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:134")
 local wins_wanted = state["at-kingdom"]
 local wins_count = #state.score local advisor_moves
 if (wins_count == wins_wanted) then
 advisor_moves = {{"move", {"kingdom", wins_wanted, 1}, {"advisor", kingdom_suit(state), "top"}}} else
 advisor_moves = {{"face-down", {"kingdom", wins_wanted, 1}}} end local draw_moves
 do local into_draw = {}
 for i, _ in ipairs(state.discard) do
 table.join(into_draw, {{"move", {"discard", i}, {"draw", "top"}}, {"face-down", {"draw", "top"}}}) end

 for i, _ in ipairs(state.score) do
 table.join(into_draw, {{"move", {"score", i}, {"draw", "top"}}, {"face-down", {"draw", "top"}}}) end

 draw_moves = into_draw end local refresh_moves
 do local refresh = {}
 for _, suit in ipairs({"hearts", "clubs", "spades", "diamonds"}) do
 for i, c in ipairs(state.advisor[suit]) do
 if ("jack" == card_rank(c)) then
 table.join(refresh, {{"face-up", {"advisor", suit, i}}}) else end end end
 refresh_moves = refresh end
 local events = table.join(advisor_moves, draw_moves, refresh_moves)
 local next_state, events0 = apply_events(clone(state), events)
 next_state["at-kingdom"] = nil
 for _, suit in ipairs({"hearts", "clubs", "spades", "diamonds"}) do


 local function _27_(a, b) return (card_value(b) < card_value(a)) end table.sort(next_state.advisor[suit], _27_) end
 table.shuffle(next_state.draw)
 return next_state, events0 end

 M.Action.diplomacy = function(state, advisor_n) _G.assert((nil ~= advisor_n), "Missing argument advisor-n on fnl/playtime/game/the-emissary/logic.fnl:164") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:164")

 local function _28_(...) local _29_ = ... if (_29_ == true) then

 local moves do local tbl_21_auto = {} local i_22_auto = 0 for i, c in ipairs(state.hand) do local val_23_auto
 if (card_suit(c) == kingdom_suit(state)) then
 val_23_auto = {"move", {"hand", i}, {"discard", "top"}} else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end moves = tbl_21_auto end
 local next_state, discard_events = apply_events(clone(state), moves)
 local moves0 = moves_to_pack_hand(state.hand, next_state.hand)
 local next_state0, hand_events = apply_events(next_state, moves0)
 local next_state1, exhausted = apply_events(next_state0, {{"face-down", {"advisor", "hearts", advisor_n}}})
 return next_state1, table.join(discard_events, hand_events, exhausted) else local __85_auto = _29_ return ... end end return _28_(M.Query.diplomacy(state, advisor_n)) end

 M.Action.military = function(state, advisor_n) _G.assert((nil ~= advisor_n), "Missing argument advisor-n on fnl/playtime/game/the-emissary/logic.fnl:177") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:177")

 local function _33_(...) local _34_ = ... if (_34_ == true) then

 local count do local sum = 0 for _, c in ipairs(state.hand) do
 if ("clubs" == card_suit(c)) then
 sum = (sum + 1) else sum = sum end end count = sum end
 local pull = math.min(count, #state.draw) local moves
 do local t = {} for i = 1, pull do
 t = table.join(t, {{"move", {"draw", "top"}, {"hand", "top"}}, {"face-up", {"hand", "top"}}}) end moves = t end

 local next_state, draw_events = apply_events(clone(state), moves)
 local next_state0, exhausted = apply_events(next_state, {{"face-down", {"advisor", "clubs", advisor_n}}})
 sort_hand_21(next_state0.hand)
 return next_state0, table.join(draw_events, exhausted) else local __85_auto = _34_ return ... end end return _33_(M.Query.military(state, advisor_n)) end

 M.Action.politics = function(state, advisor_n, kingdom_n) _G.assert((nil ~= kingdom_n), "Missing argument kingdom-n on fnl/playtime/game/the-emissary/logic.fnl:193") _G.assert((nil ~= advisor_n), "Missing argument advisor-n on fnl/playtime/game/the-emissary/logic.fnl:193") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:193")




 local function _37_(...) local _38_, _39_ = ... if (_38_ == true) then local function _40_(...) local _41_, _42_ = ... if (nil ~= _41_) then local card = _41_ local function _43_(...) local _44_, _45_ = ... if (_44_ == true) then



 local events = {{"swap", {"kingdom", state["at-kingdom"], 1}, {"kingdom", kingdom_n, 1}}}


 local next_state, swap_events = apply_events(clone(state), events)
 local next_state0, exhausted = apply_events(next_state, {{"face-down", {"advisor", "spades", advisor_n}}})
 return next_state0, table.join(swap_events, exhausted) elseif ((_44_ == nil) and (nil ~= _45_)) then local err = _45_

 return nil, err elseif (_44_ == false) then
 local function _53_(...) local data_5_auto = {} local resolve_6_auto local function _46_(name_7_auto) local _47_ = data_5_auto[name_7_auto] local and_48_ = (nil ~= _47_) if and_48_ then local t_8_auto = _47_ and_48_ = ("table" == type(t_8_auto)) end if and_48_ then local t_8_auto = _47_ local _50_ = getmetatable(t_8_auto) if ((_G.type(_50_) == "table") and (nil ~= _50_.__tostring)) then local f_9_auto = _50_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _50_ return vim.inspect(t_8_auto) end elseif (nil ~= _47_) then local v_11_auto = _47_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _46_ return string.gsub("cant swap with an exhausted kingdom", "#{(.-)}", resolve_6_auto) end return nil, _53_(...) elseif (_44_ == nil) then
 local function _61_(...) local data_5_auto = {} local resolve_6_auto local function _54_(name_7_auto) local _55_ = data_5_auto[name_7_auto] local and_56_ = (nil ~= _55_) if and_56_ then local t_8_auto = _55_ and_56_ = ("table" == type(t_8_auto)) end if and_56_ then local t_8_auto = _55_ local _58_ = getmetatable(t_8_auto) if ((_G.type(_58_) == "table") and (nil ~= _58_.__tostring)) then local f_9_auto = _58_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _58_ return vim.inspect(t_8_auto) end elseif (nil ~= _55_) then local v_11_auto = _55_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _54_ return string.gsub("cant swap with kingdom", "#{(.-)}", resolve_6_auto) end return nil, _61_(...) else return nil end end return _43_(card_face_up_3f(card)) elseif ((_41_ == nil) and (nil ~= _42_)) then local err = _42_ return nil, err elseif (_41_ == false) then local function _70_(...) local data_5_auto = {} local resolve_6_auto local function _63_(name_7_auto) local _64_ = data_5_auto[name_7_auto] local and_65_ = (nil ~= _64_) if and_65_ then local t_8_auto = _64_ and_65_ = ("table" == type(t_8_auto)) end if and_65_ then local t_8_auto = _64_ local _67_ = getmetatable(t_8_auto) if ((_G.type(_67_) == "table") and (nil ~= _67_.__tostring)) then local f_9_auto = _67_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _67_ return vim.inspect(t_8_auto) end elseif (nil ~= _64_) then local v_11_auto = _64_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _63_ return string.gsub("cant swap with an exhausted kingdom", "#{(.-)}", resolve_6_auto) end return nil, _70_(...) elseif (_41_ == nil) then local function _78_(...) local data_5_auto = {} local resolve_6_auto local function _71_(name_7_auto) local _72_ = data_5_auto[name_7_auto] local and_73_ = (nil ~= _72_) if and_73_ then local t_8_auto = _72_ and_73_ = ("table" == type(t_8_auto)) end if and_73_ then local t_8_auto = _72_ local _75_ = getmetatable(t_8_auto) if ((_G.type(_75_) == "table") and (nil ~= _75_.__tostring)) then local f_9_auto = _75_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _75_ return vim.inspect(t_8_auto) end elseif (nil ~= _72_) then local v_11_auto = _72_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _71_ return string.gsub("cant swap with kingdom", "#{(.-)}", resolve_6_auto) end return nil, _78_(...) else return nil end end return _40_(state.kingdom[kingdom_n][1]) elseif ((_38_ == nil) and (nil ~= _39_)) then local err = _39_ return nil, err elseif (_38_ == false) then local function _87_(...) local data_5_auto = {} local resolve_6_auto local function _80_(name_7_auto) local _81_ = data_5_auto[name_7_auto] local and_82_ = (nil ~= _81_) if and_82_ then local t_8_auto = _81_ and_82_ = ("table" == type(t_8_auto)) end if and_82_ then local t_8_auto = _81_ local _84_ = getmetatable(t_8_auto) if ((_G.type(_84_) == "table") and (nil ~= _84_.__tostring)) then local f_9_auto = _84_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _84_ return vim.inspect(t_8_auto) end elseif (nil ~= _81_) then local v_11_auto = _81_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _80_ return string.gsub("cant swap with an exhausted kingdom", "#{(.-)}", resolve_6_auto) end return nil, _87_(...) elseif (_38_ == nil) then local function _95_(...) local data_5_auto = {} local resolve_6_auto local function _88_(name_7_auto) local _89_ = data_5_auto[name_7_auto] local and_90_ = (nil ~= _89_) if and_90_ then local t_8_auto = _89_ and_90_ = ("table" == type(t_8_auto)) end if and_90_ then local t_8_auto = _89_ local _92_ = getmetatable(t_8_auto) if ((_G.type(_92_) == "table") and (nil ~= _92_.__tostring)) then local f_9_auto = _92_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _92_ return vim.inspect(t_8_auto) end elseif (nil ~= _89_) then local v_11_auto = _89_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _88_ return string.gsub("cant swap with kingdom", "#{(.-)}", resolve_6_auto) end return nil, _95_(...) else return nil end end return _37_(M.Query.politics(state, advisor_n)) end

 M.Action.commerce = function(state, advisor_n, _3fdiscards) _G.assert((nil ~= advisor_n), "Missing argument advisor-n on fnl/playtime/game/the-emissary/logic.fnl:213") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:213")

 local function _97_(...) local _98_ = ... if (_98_ == true) then

 if (_3fdiscards == nil) then

 local pull = math.min(2, #state.draw) local moves
 do local t = {} for i = 1, pull do
 t = table.join(t, {{"move", {"draw", "top"}, {"hand", "top"}}, {"face-up", {"hand", "top"}}}) end moves = t end

 local next_state, draw_events = apply_events(clone(state), moves)
 sort_hand_21(next_state.hand)
 return next_state, draw_events elseif ((_G.type(_3fdiscards) == "table") and (nil ~= _3fdiscards[1]) and (nil ~= _3fdiscards[2])) then local a = _3fdiscards[1] local b = _3fdiscards[2]

 local moves = {{"move", {"hand", a}, {"discard", "top"}}, {"move", {"hand", b}, {"discard", "top"}}}

 local next_state, discard_events = apply_events(clone(state), moves)
 local moves0 = moves_to_pack_hand(state.hand, next_state.hand)
 local next_state0, hand_events = apply_events(next_state, moves0)
 local next_state1, exhausted = apply_events(next_state0, {{"face-down", {"advisor", "diamonds", advisor_n}}})
 return next_state1, table.join(discard_events, hand_events, exhausted) else return nil end else local __85_auto = _98_ return ... end end return _97_(M.Query.commerce(state, advisor_n)) end

 local function check_advisor(state, suit, advisor_n)
 local _101_ = state.advisor[suit][advisor_n] if (nil ~= _101_) then local card = _101_
 if card_face_up_3f(card) then return true else

 local function _109_() local data_5_auto = {} local resolve_6_auto local function _102_(name_7_auto) local _103_ = data_5_auto[name_7_auto] local and_104_ = (nil ~= _103_) if and_104_ then local t_8_auto = _103_ and_104_ = ("table" == type(t_8_auto)) end if and_104_ then local t_8_auto = _103_ local _106_ = getmetatable(t_8_auto) if ((_G.type(_106_) == "table") and (nil ~= _106_.__tostring)) then local f_9_auto = _106_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _106_ return vim.inspect(t_8_auto) end elseif (nil ~= _103_) then local v_11_auto = _103_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _102_ return string.gsub("advisor exhausted", "#{(.-)}", resolve_6_auto) end return nil, _109_() end elseif (_101_ == nil) then
 local function _118_() local data_5_auto = {["advisor-n"] = advisor_n} local resolve_6_auto local function _111_(name_7_auto) local _112_ = data_5_auto[name_7_auto] local and_113_ = (nil ~= _112_) if and_113_ then local t_8_auto = _112_ and_113_ = ("table" == type(t_8_auto)) end if and_113_ then local t_8_auto = _112_ local _115_ = getmetatable(t_8_auto) if ((_G.type(_115_) == "table") and (nil ~= _115_.__tostring)) then local f_9_auto = _115_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _115_ return vim.inspect(t_8_auto) end elseif (nil ~= _112_) then local v_11_auto = _112_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _111_ return string.gsub("no advisor at #{advisor-n}", "#{(.-)}", resolve_6_auto) end return nil, _118_() else return nil end end

 M.Query.diplomacy = function(state, advisor_n) _G.assert((nil ~= advisor_n), "Missing argument advisor-n on fnl/playtime/game/the-emissary/logic.fnl:242") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:242")
 return check_advisor(state, "hearts", advisor_n) end

 M.Query.military = function(state, advisor_n) _G.assert((nil ~= advisor_n), "Missing argument advisor-n on fnl/playtime/game/the-emissary/logic.fnl:245") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:245")
 return check_advisor(state, "clubs", advisor_n) end

 M.Query.politics = function(state, advisor_n) _G.assert((nil ~= advisor_n), "Missing argument advisor-n on fnl/playtime/game/the-emissary/logic.fnl:248") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:248")
 return check_advisor(state, "spades", advisor_n) end

 M.Query.commerce = function(state, advisor_n) _G.assert((nil ~= advisor_n), "Missing argument advisor-n on fnl/playtime/game/the-emissary/logic.fnl:251") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:251")
 return check_advisor(state, "diamonds", advisor_n) end

 M["iter-cards"] = function(state, _3ffields) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:254")
 local function iter()
 for _, field in ipairs((_3ffields or {"kingdom"})) do
 for col_n, column in ipairs(state[field]) do
 for card_n, card in ipairs(column) do
 coroutine.yield({field, col_n, card_n}, card) end end end
 for _, suit in ipairs({"hearts", "clubs", "spades", "diamonds"}) do
 for i, card in ipairs(state.advisor[suit]) do
 coroutine.yield({"advisor", suit, i}, card) end end
 for _, field in ipairs({"draw", "debate", "discard", "score", "hand"}) do
 for card_n, card in ipairs(state[field]) do
 coroutine.yield({field, card_n}, card) end end return nil end
 return coroutine.wrap(iter) end

 M.Query["hand-exhausted?"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:268")
 return (0 == #state.hand) end


 M.Query["game-ended?"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:272") local yes_3f = true


 for _, k in ipairs(state.kingdom) do if not yes_3f then break end
 if ((_G.type(k) == "table") and (k[1] == nil)) then yes_3f = true elseif ((_G.type(k) == "table") and (nil ~= k[1])) then local c = k[1]

 yes_3f = card_face_down_3f(c) else yes_3f = nil end end return yes_3f end

 M.Query["game-result"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/the-emissary/logic.fnl:280")

 local supporting do local tbl_21_auto = {} local i_22_auto = 0 for _, k in ipairs(state.kingdom) do local val_23_auto
 if ((_G.type(k) == "table") and (k[1] == nil)) then val_23_auto = true else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end supporting = tbl_21_auto end

 local unused = {} local _
 for suit, t in pairs(state.advisor) do
 for _0, c in ipairs(t) do
 if (not ("jack" == card_rank(c)) and card_face_up_3f(c)) then

 table.insert(unused, true) else end end end _ = nil
 local won_3f = (8 == #supporting)
 local score_3f = (#supporting + #unused)
 return {won_3f, score_3f} end

 return M