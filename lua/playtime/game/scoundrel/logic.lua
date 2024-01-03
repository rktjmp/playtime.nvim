
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




 local function new_game_state()
 return {room = {}, deck = {}, weapon = {}, health = 20, ["won?"] = false} end





 M.build = function(_config, _3fseed) _G.assert((nil ~= _config), "Missing argument _config on fnl/playtime/game/scoundrel/logic.fnl:30")
 math.randomseed((_3fseed or os.time()))
 local deck = table.shuffle(Deck.Standard52.build()) local enemy, player = nil, nil

 do local e, p = {}, {} for _, c in ipairs(deck) do
 if ((card_value(c) <= 4) or ("joker" == card_suit(c))) then
 e, p = e, table.insert(p, c) else
 e, p = table.insert(e, c), p end end enemy, player = e, p end

 local state = new_game_state()
 do end (state)["enemy"]["draw"] = enemy
 state["player"]["draw"] = player
 return state end

 return M