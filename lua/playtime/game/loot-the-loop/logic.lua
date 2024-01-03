
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}




 local _local_2_ = CardGameUtils local location_contents = _local_2_["location-contents"]
 local inc_moves = _local_2_["inc-moves"]
 local apply_events = _local_2_["apply-events"]
 M["iter-cards"] = CardGameUtils["make-iter-cards-fn"]({"foundation", "throne", "draw", "hand", "discard"})
 local _local_3_ = CardGameUtils["make-card-util-fns"]({value = {14, king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_3_["card-value"] local card_color = _local_3_["card-color"] local card_rank = _local_3_["card-rank"]
 local card_suit = _local_3_["card-suit"] local rank_value = _local_3_["rank-value"] local suit_color = _local_3_["suit-color"]
 local card_face_up_3f = _local_3_["card-face-up?"] local card_face_down_3f = _local_3_["card-face-down?"]
 local flip_face_up = _local_3_["flip-face-up"]




 local function new_game_state() end


 M.build = function(_config, _3fseed) _G.assert((nil ~= _config), "Missing argument _config on fnl/playtime/game/loot-the-loop/logic.fnl:28")
 math.randomseed((_3fseed or os.time()))

 local deck


 local function _4_(_241) if ((_G.type(_241) == "table") and (_241[1] == "joker") and (_241[2] == 2)) then return false else return nil end end deck = Deck.split(Deck.shuffle(Deck.Standard54.build()), _4_)

 local state = {deck = deck, indy = {"deck", 1}, trinkets = {}, notes = {{}, {}, {}}}



 return state end






 return M