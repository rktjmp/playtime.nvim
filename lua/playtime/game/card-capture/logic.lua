
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}



 local _local_2_ = CardGameUtils local apply_events = _local_2_["apply-events"]
 local _local_3_ = CardGameUtils["make-card-util-fns"]({value = {14, king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_3_["card-value"] local card_color = _local_3_["card-color"] local card_rank = _local_3_["card-rank"] local card_suit = _local_3_["card-suit"]
 local rank_value = _local_3_["rank-value"]
 local suit_color = _local_3_["suit-color"]
 local card_face_up_3f = _local_3_["card-face-up?"] local card_face_down_3f = _local_3_["card-face-down?"]
 local flip_face_up = _local_3_["flip-face-up"] local flip_face_down = _local_3_["flip-face-down"]




 M["iter-cards"] = function(state)
 local function iter()
 for _, side in ipairs({"enemy", "player"}) do
 for _0, field in ipairs({"draw", "discard"}) do
 for card_n, card in ipairs((state[side][field] or {})) do
 coroutine.yield({side, field, card_n}, card) end end
 for i = 1, 4 do
 local card = state[side].hand[i]
 if card then
 coroutine.yield({side, "hand", i}, card) else end end end return nil end
 return coroutine.wrap(iter) end

 local function new_game_state()
 return {enemy = {draw = {}, hand = {}, discard = {}}, player = {draw = {}, hand = {}, discard = {}}, moves = 0, winner = false} end








 M.build = function(_config, _3fseed) _G.assert((nil ~= _config), "Missing argument _config on fnl/playtime/game/card-capture/logic.fnl:45")
 local function ensure_no_faces_in_enemy_hand(enemy)




 local top = #enemy local no_faces_3f
 do local ok_3f = true for i = top, (top - 4), -1 do
 ok_3f = (ok_3f and (card_value(enemy[i]) <= 10)) end no_faces_3f = ok_3f end
 if no_faces_3f then
 return enemy else
 return ensure_no_faces_in_enemy_hand(table.shuffle(enemy)) end end
 math.randomseed((_3fseed or os.time()))
 local deck = table.shuffle(Deck.Standard54.build()) local enemy, player = nil, nil

 do local e, p = {}, {} for _, c in ipairs(deck) do
 if ((card_value(c) <= 4) or ("joker" == card_suit(c))) then
 e, p = e, table.insert(p, c) else
 e, p = table.insert(e, c), p end end enemy, player = e, p end
 local enemy0 = ensure_no_faces_in_enemy_hand(enemy)
 local state = new_game_state()
 do end (state)["enemy"]["draw"] = enemy0
 state["player"]["draw"] = player
 return state end

 local function fetch_by_index(seq, indexes) _G.assert((nil ~= indexes), "Missing argument indexes on fnl/playtime/game/card-capture/logic.fnl:70") _G.assert((nil ~= seq), "Missing argument seq on fnl/playtime/game/card-capture/logic.fnl:70")
 local tbl_18_auto = {} local i_19_auto = 0 for _, i in ipairs(indexes) do
 local val_20_auto = seq[i] if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto end

 local function sum_hand(hand) _G.assert((nil ~= hand), "Missing argument hand on fnl/playtime/game/card-capture/logic.fnl:74")
 local hand_values, joker_count = nil, nil do local vs, js = {}, 0 for _, c in ipairs(hand) do

 local _8_ = card_suit(c) if (_8_ == "joker") then
 vs, js = vs, (js + 1) else local _0 = _8_
 vs, js = table.insert(vs, card_value(c)), js end end hand_values, joker_count = vs, js end
 local max = math.max(0, table.unpack(hand_values)) local sum
 do local sum0 = 0 for _, v in ipairs(hand_values) do sum0 = (sum0 + v) end sum = sum0 end
 return (sum + (max * joker_count)) end

 local function maybe_set_winner(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/card-capture/logic.fnl:84")


 local discard_poisoned_3f do local die = false for _, c in ipairs(state.enemy.discard) do if die then break end


 die = (not ("joker" == card_suit(c)) and (10 < card_value(c))) end discard_poisoned_3f = die end

 local draw_empty_3f = (0 == #state.enemy.draw) local hand_empty_3f
 local _10_ do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 4 do local val_20_auto = state.enemy.hand[i] if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end _10_ = tbl_18_auto end hand_empty_3f = (0 == #_10_) local winner
 if discard_poisoned_3f then winner = "enemy" elseif (draw_empty_3f and hand_empty_3f) then winner = "player" else winner = nil end

 return table.set(state, "winner", winner) end

 M.Action["both-draw"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/card-capture/logic.fnl:98")



 local function _13_(...) local _14_, _15_ = ... if ((nil ~= _14_) and (nil ~= _15_)) then local next_state = _14_ local moves = _15_ local function _16_(...) local _17_, _18_ = ... if ((nil ~= _17_) and (nil ~= _18_)) then local next_state0 = _17_ local more_moves = _18_


 local moves0 do local tbl_17_auto = moves for _, m in ipairs(more_moves) do table.insert(tbl_17_auto, m) end moves0 = tbl_17_auto end
 return next_state0, moves0 else local __84_auto = _17_ return ... end end return _16_(M.Action["player-draw"](next_state)) else local __84_auto = _14_ return ... end end return _13_(M.Action["enemy-draw"](state)) end


 local function describe_pack_left_indexes(seq)
 local seq0, moves = seq, {} for i = 1, 4 do

 local _21_ = seq0[i] if (_21_ == nil) then
 local pull do local index = nil for i0 = (i + 1), 4 do if index then break end
 if not (nil == seq0[i0]) then index = i0 else index = nil end end pull = index end
 if pull then
 seq0[i] = seq0[pull]
 seq0[pull] = nil
 table.insert(moves, {pull, i}) else end
 seq0, moves = seq0, moves else local _ = _21_
 seq0, moves = seq0, moves end end return seq0, moves end

 M.Action["enemy-draw"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/card-capture/logic.fnl:122")

 local next_state = clone(state)
 local hand, hand_moves = describe_pack_left_indexes(next_state.enemy.hand) local moves
 do local t = {} for _, _25_ in ipairs(hand_moves) do local _each_26_ = _25_ local from = _each_26_[1] local to = _each_26_[2]
 t = table.insert(t, {"move", {"enemy", "hand", from}, {"enemy", "hand", to}}) end moves = t end
 local len_draw = #next_state.enemy.draw local draw_moves
 do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, math.min(len_draw, math.max(0, (4 - #hand))) do
 local val_20_auto = {(len_draw - (i - 1)), (#hand + i)} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end draw_moves = tbl_18_auto end local _
 do local t = moves for _0, _28_ in ipairs(draw_moves) do local _each_29_ = _28_ local from = _each_29_[1] local to = _each_29_[2]
 t = table.join(t, {{"move", {"enemy", "draw", from}, {"enemy", "hand", to}}, {"face-up", {"enemy", "hand", to}}}) end _ = t end

 local next_state0, moves0 = apply_events(clone(state), moves, {["unsafely?"] = true})
 return next_state0, moves0 end

 M.Action["player-draw"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/card-capture/logic.fnl:137")

 local state0 = clone(state) local missing_indexes
 do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 4 do local val_20_auto if not state0.player.hand[i] then val_20_auto = i else val_20_auto = nil end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end missing_indexes = tbl_18_auto end
 local n_draw = #state0.player.draw local fill

 do local t = {} for i = 1, math.min(#state0.player.draw, #missing_indexes) do

 t = table.join(t, {{"move", {"player", "draw", (#state0.player.draw - (i - 1))}, {"player", "hand", missing_indexes[i]}}, {"face-up", {"player", "hand", missing_indexes[i]}}}) end fill = t end



 local state1, moves = apply_events(state0, fill, {["unsafely?"] = true}) local missing_indexes0

 do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 4 do local val_20_auto if not state1.player.hand[i] then val_20_auto = i else val_20_auto = nil end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end missing_indexes0 = tbl_18_auto end local state2, moves0 = nil, nil

 if (0 < #missing_indexes0) then
 local shift do local t = {} for i = #state1.player.discard, 1, -1 do
 t = table.insert(t, {"move", {"player", "discard", i}, {"player", "draw", "top"}}) end shift = t end


 local state3, shift0 = apply_events(state1, shift, {["unsafely?"] = true})
 local _ = table.join(moves, shift0)












 local _0 = table.shuffle(state3.player.draw) local fill0








 do local t = {} for i = 1, math.min(#state3.player.draw, #missing_indexes0) do

 t = table.join(t, {{"move", {"player", "draw", (#state3.player.draw - (i - 1))}, {"player", "hand", missing_indexes0[i]}}, {"face-up", {"player", "hand", missing_indexes0[i]}}}) end fill0 = t end



 local state4, fill1 = apply_events(state3, fill0, {["unsafely?"] = true})
 local _1 = table.join(moves, fill1)
 state2, moves0 = state4, moves else
 state2, moves0 = state1, moves end
 return state2, moves0 end

 M.Action.discard = function(state, hand_cards) _G.assert((nil ~= hand_cards), "Missing argument hand-cards on fnl/playtime/game/card-capture/logic.fnl:193") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/card-capture/logic.fnl:193")

 local moves do local t = {} for i, hand_i in ipairs(hand_cards) do
 t = table.insert(table.insert(t, {"move", {"player", "hand", hand_i}, {"player", "discard", "top"}}), {"face-down", {"player", "discard", "top"}}) end moves = t end



 local next_state, moves0 = apply_events(clone(state), moves, {["unsafely?"] = true})
 return next_state, moves0 end

 M.Action.capture = function(state, hand_indexes, enemy_index) _G.assert((nil ~= enemy_index), "Missing argument enemy-index on fnl/playtime/game/card-capture/logic.fnl:203") _G.assert((nil ~= hand_indexes), "Missing argument hand-indexes on fnl/playtime/game/card-capture/logic.fnl:203") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/card-capture/logic.fnl:203")
 local hand_cards = fetch_by_index(state.player.hand, hand_indexes)
 local _let_35_ = fetch_by_index(state.enemy.hand, {enemy_index}) local enemy_card = _let_35_[1] local hand_suits
 local function _36_() local tbl_14_auto = {} for _, c in ipairs(hand_cards) do local k_15_auto, v_16_auto = nil, nil
 do local _37_ = card_suit(c) if (_37_ == "joker") then
 k_15_auto, v_16_auto = nil elseif (nil ~= _37_) then local suit = _37_
 k_15_auto, v_16_auto = suit, true else k_15_auto, v_16_auto = nil end end if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then tbl_14_auto[k_15_auto] = v_16_auto else end end return tbl_14_auto end hand_suits = table.keys(_36_())

 local hand_value = sum_hand(hand_cards)
 local enemy_suit = card_suit(enemy_card)
 local enemy_value = card_value(enemy_card)
 if ((1 == #hand_suits) and (enemy_suit == hand_suits[1]) and (enemy_value <= hand_value)) then


 local moves do local t = {} for _, i in ipairs(hand_indexes) do
 t = table.insert(table.insert(t, {"move", {"player", "hand", i}, {"player", "discard", "top"}}), {"face-down", {"player", "discard", "top"}}) end moves = t end



 local _ = table.insert(table.insert(moves, {"move", {"enemy", "hand", enemy_index}, {"player", "discard", "top"}}), {"face-down", {"player", "discard", "top"}})



 local state0, moves0 = apply_events(clone(state), moves, {["unsafely?"] = true})
 local state1 = maybe_set_winner(state0)
 return state1, moves0 else
 return nil, Error("Must select same suit and equal or greater combined value for capture") end end

 M.Action.yield = function(state, hand_indexes) _G.assert((nil ~= hand_indexes), "Missing argument hand-indexes on fnl/playtime/game/card-capture/logic.fnl:231") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/card-capture/logic.fnl:231")
 if (1 == #hand_indexes) then
 local moves do local t = {} for _, i in ipairs(hand_indexes) do
 t = table.insert(table.insert(t, {"move", {"player", "hand", i}, {"enemy", "discard", "top"}}), {"face-down", {"enemy", "discard", "top"}}) end moves = t end



 local _ = table.insert(table.insert(moves, {"move", {"enemy", "hand", 1}, {"enemy", "discard", "top"}}), {"face-down", {"enemy", "discard", "top"}})



 local state0, moves0 = apply_events(clone(state), moves, {["unsafely?"] = true})
 local state1 = maybe_set_winner(state0)
 return state1, moves0 else
 return nil, Error("Must select only one card to yield") end end

 M.Action.sacrifice = function(state, hand_indexes, enemy_index) _G.assert((nil ~= enemy_index), "Missing argument enemy-index on fnl/playtime/game/card-capture/logic.fnl:247") _G.assert((nil ~= hand_indexes), "Missing argument hand-indexes on fnl/playtime/game/card-capture/logic.fnl:247") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/card-capture/logic.fnl:247")
 if (2 == #hand_indexes) then
 local moves do local t = {} for _, i in ipairs(hand_indexes) do
 t = table.insert(table.insert(t, {"move", {"player", "hand", i}, {"enemy", "discard", "top"}}), {"face-down", {"enemy", "discard", "top"}}) end moves = t end



 local _ = table.insert(table.insert(moves, {"move", {"enemy", "hand", enemy_index}, {"enemy", "draw", "bottom"}}), {"face-down", {"enemy", "draw", "bottom"}})



 local state0, moves0 = apply_events(clone(state), moves, {["unsafely?"] = true})
 local state1 = maybe_set_winner(state0)
 return state1, moves0 else
 return nil, Error("Must select two cards to sacrifice") end end

 M.Query["game-ended?"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/card-capture/logic.fnl:263")
 return state.winner end

 M.Query["game-result"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/card-capture/logic.fnl:266")
 return state.winner end

 return M