
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Id = require("playtime.common.id")
 local M = {Standard54 = {}, Standard52 = {}}
 setmetatable(M.Standard52, {__index = M})
 setmetatable(M.Standard54, {__index = M})

 M.shuffle = function(deck)

 return table.shuffle(clone(deck)) end

 M.split = function(deck, pred)





 local td, fd = {}, {} for i, card in ipairs(deck) do
 if pred(card, i) then
 td, fd = table.insert(td, card), fd else
 td, fd = td, table.insert(fd, card) end end return td, fd end

 M.slice = function(deck, n)

 return error("TODO?") end


 M["flip-card"] = function(card)
 local _3_ = card.face if (_3_ == "up") then
 card["face"] = "down" return card elseif (_3_ == "down") then
 card["face"] = "up" return card else return nil end end

 M.Standard54.build = function()
 local function new_card(suit, rank)
 return {suit, rank, id = Id.new(), face = "down"} end



 local suits = {"spades", "clubs", "hearts", "diamonds"}
 local faces = {"jack", "queen", "king"}
 local pips = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
 local cards = {}
 for _, suit in ipairs(suits) do
 for _0, pip in ipairs(pips) do
 table.insert(cards, new_card(suit, pip)) end
 for i, face in ipairs(faces) do
 table.insert(cards, new_card(suit, face)) end end
 table.insert(cards, new_card("joker", 1))
 table.insert(cards, new_card("joker", 2))
 return cards end

 M.Standard52.build = function()
 local tbl_19_auto = {} local i_20_auto = 0 for _, card in ipairs(M.Standard54.build()) do local val_21_auto
 if ((_G.type(card) == "table") and (card[1] == "joker")) then
 val_21_auto = nil else local _0 = card
 val_21_auto = card end if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end return tbl_19_auto end

 return M