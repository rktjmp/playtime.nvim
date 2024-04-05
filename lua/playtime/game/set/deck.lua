
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Id = require("playtime.common.id")
 local Deck = require("playtime.common.card.deck")
 local M = setmetatable({Set = {}}, {__index = Deck})

 M.Set.build = function()
 local colors = {"red", "green", "blue"}
 local counts = {1, 2, 3}
 local styles = {"solid", "split", "outline"}
 local shapes = {"square", "circle", "triangle"}
 local cards = {}
 for _color_index, color in ipairs(colors) do
 for _style_index, style in ipairs(styles) do
 for _count_index, count in ipairs(counts) do
 for _shape_index, shape in ipairs(shapes) do
 local card = {id = Id.new(), color = color, style = style, count = count, shape = shape, face = "down"}





 table.insert(cards, card) end end end end
 return cards end

 return M