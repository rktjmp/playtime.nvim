
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Id = require("playtime.common.id")
 local Deck = require("playtime.common.card.deck")
 local M = setmetatable({Shenzhen = {}}, {__index = Deck})

 M.Shenzhen.build = function()
 local function new_card(suit, rank)
 return {suit, rank, id = Id.new(), face = "down"} end
 local dragons = {"red", "green", "white"}
 local suits = {"strings", "coins", "myriads"}
 local pips = {1, 2, 3, 4, 5, 6, 7, 8, 9}
 local cards = {}
 for _, suit in ipairs(suits) do
 local tbl_17_auto = cards for _0, pip in ipairs(pips) do
 local val_18_auto = new_card(suit, pip) table.insert(tbl_17_auto, val_18_auto) end end
 for _, dragon in ipairs(dragons) do
 local tbl_17_auto = cards for i = 1, 4 do
 local val_18_auto = new_card(dragon, i) table.insert(tbl_17_auto, val_18_auto) end end
 return table.insert(cards, new_card("flower", 1)) end

 return M