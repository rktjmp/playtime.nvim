
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local M = {}
 local Error = require("playtime.error")

 M.blank = function(_2_) local _arg_3_ = _2_ local width = _arg_3_["width"] local height = _arg_3_["height"] local style = _arg_3_
 assert(((width == 7) and (height == 5)), "only supports w=7, h=5") local hl = "@playtime.game.card.back"

 return {{{"\226\149\173\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\149\174", hl}}, {{"\226\148\130     \226\148\130", hl}}, {{"\226\148\130     \226\148\130", hl}}, {{"\226\148\130     \226\148\130", hl}}, {{"\226\149\176\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\149\175", hl}}} end





 M.regular = function(card, _4_) local _arg_5_ = _4_ local width = _arg_5_["width"] local height = _arg_5_["height"] local style = _arg_5_
 assert(((width == 7) and (height == 5)), "only supports w=7, h=5")
 local _let_6_ = card local suit = _let_6_[1] local rank = _let_6_[2] local text
 if ((_G.type(card) == "table") and (card[1] == "red")) then text = "\197\160" elseif ((_G.type(card) == "table") and (card[1] == "green")) then text = "\195\145" elseif ((_G.type(card) == "table") and (card[1] == "white")) then text = "\195\149" elseif ((_G.type(card) == "table") and (card[1] == "flower")) then text = "\198\146" elseif ((_G.type(card) == "table") and true and (nil ~= card[2])) then local _ = card[1] local pip = card[2]




 text = tostring(pip) else text = nil end local suit_text do

 local _ = suit suit_text = " " end local color










 local function _8_() if (suit == "green") then return "dragon.green" elseif (suit == "red") then return "dragon.red" elseif (suit == "white") then return "dragon.white" elseif (nil ~= suit) then local suit0 = suit



 return suit0 else return nil end end color = ("@playtime.game.shenzhen." .. _8_())

 local padding = string.rep(" ", 3)
 local details = (text .. padding .. suit_text)

 return {{{"\226\149\173\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\149\174", color}}, {{"\226\148\130", color}, {details, color}, {"\226\148\130", color}}, {{"\226\148\130     \226\148\130", color}}, {{"\226\148\130     \226\148\130", color}}, {{"\226\149\176\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\149\175", color}}} end





 return M