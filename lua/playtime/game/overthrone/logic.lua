
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}



 local location_contents = CardGameUtils["location-contents"]
 local inc_moves = CardGameUtils["inc-moves"]
 local apply_events = CardGameUtils["apply-events"]
 M["iter-cards"] = CardGameUtils["make-iter-cards-fn"]({"foundation", "throne", "draw", "hand", "discard"})
 local _local_2_ = CardGameUtils["make-card-util-fns"]({value = {king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_2_["card-value"] local card_color = _local_2_["card-color"] local card_rank = _local_2_["card-rank"]
 local card_suit = _local_2_["card-suit"] local rank_value = _local_2_["rank-value"] local suit_color = _local_2_["suit-color"]
 local card_face_up_3f = _local_2_["card-face-up?"] local card_face_down_3f = _local_2_["card-face-down?"]
 local flip_face_up = _local_2_["flip-face-up"]




 local function new_game_state(hand_size)


 local _3_ do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, hand_size do local val_23_auto = {} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end _3_ = tbl_21_auto end return {draw = {{}}, foundation = {{}, {}, {}, {}}, hand = _3_, throne = {{}}, discard = {{}}, moves = 0} end




 M.build = function(config, _3fseed) _G.assert((nil ~= config), "Missing argument config on fnl/playtime/game/overthrone/logic.fnl:32")
 math.randomseed((_3fseed or os.time()))
 local deck = table.shuffle(Deck.Standard54.build()) local deck0, lead = nil, nil


 do local t, l = {}, nil for _, c in ipairs(deck) do
 if ((_G.type(c) == "table") and (c[1] == "joker") and (c[2] == 2)) then
 t, l = t, l else local and_5_ = (nil ~= c) if and_5_ then local c0 = c and_5_ = (10 < card_value(c0)) end if and_5_ then local c0 = c
 if (nil == l) then
 t, l = t, c0 else
 t, l = table.insert(t, c0), l end else local _0 = c
 t, l = table.insert(t, c), l end end end deck0, lead = t, l end
 local state = new_game_state(config["hand-size"])
 flip_face_up(lead)
 state["draw"][1] = deck0
 state["throne"][1] = {lead}
 return state end

 M.Action.deal = function(state)
 local moves do local t = {} for i = #state.hand, 1, -1 do
 t = table.join(t, {{"face-up", {"draw", 1, "top"}}, {"move", {"draw", 1, "top"}, {"hand", i, 1}}}) end moves = t end

 return apply_events(clone(state), moves) end

 M.Action.draw = function(state)
 local empty do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, #state.hand do local val_23_auto
 do local _9_ = state.hand[i] if ((_G.type(_9_) == "table") and (_9_[1] == nil)) then
 val_23_auto = i else val_23_auto = nil end end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end empty = tbl_21_auto end
 local draw_count = math.min(#state.draw[1], #empty) local moves
 do local t = {} for i = draw_count, 1, -1 do
 t = table.join(t, {{"face-up", {"draw", 1, "top"}}, {"move", {"draw", 1, "top"}, {"hand", empty[i], 1}}}) end moves = t end

 return apply_events(clone(state), moves) end

 local function check_pick_up(state, pick_up_from)
 if ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "hand") and (nil ~= pick_up_from[2]) and (pick_up_from[3] == 1)) then local col_n = pick_up_from[2]
 return state.hand[col_n] elseif ((_G.type(pick_up_from) == "table") and (pick_up_from[1] == "discard") and (nil ~= pick_up_from[2]) and (nil ~= pick_up_from[3])) then local col_n = pick_up_from[2] local card_n = pick_up_from[3]
 local _12_ = table["get-in"](state, pick_up_from) if (nil ~= _12_) then local card = _12_
 local joker_3f do local joker_3f0 = false for i = 1, 4 do if joker_3f0 then break end
 local _13_ = table.last(state.foundation[i]) if ((_G.type(_13_) == "table") and (_13_[1] == "joker")) then joker_3f0 = true else joker_3f0 = nil end end joker_3f = joker_3f0 end

 if joker_3f then
 return {card} else
 local function _22_() local data_5_auto = {} local resolve_6_auto local function _15_(name_7_auto) local _16_ = data_5_auto[name_7_auto] local and_17_ = (nil ~= _16_) if and_17_ then local t_8_auto = _16_ and_17_ = ("table" == type(t_8_auto)) end if and_17_ then local t_8_auto = _16_ local _19_ = getmetatable(t_8_auto) if ((_G.type(_19_) == "table") and (nil ~= _19_.__tostring)) then local f_9_auto = _19_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _19_ return vim.inspect(t_8_auto) end elseif (nil ~= _16_) then local v_11_auto = _16_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _15_ return string.gsub("May only pick up from discard when joker is in play", "#{(.-)}", resolve_6_auto) end return nil, _22_() end else local _ = _12_
 local function _31_() local data_5_auto = {} local resolve_6_auto local function _24_(name_7_auto) local _25_ = data_5_auto[name_7_auto] local and_26_ = (nil ~= _25_) if and_26_ then local t_8_auto = _25_ and_26_ = ("table" == type(t_8_auto)) end if and_26_ then local t_8_auto = _25_ local _28_ = getmetatable(t_8_auto) if ((_G.type(_28_) == "table") and (nil ~= _28_.__tostring)) then local f_9_auto = _28_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _28_ return vim.inspect(t_8_auto) end elseif (nil ~= _25_) then local v_11_auto = _25_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _24_ return string.gsub("Nothing to pick up", "#{(.-)}", resolve_6_auto) end return nil, _31_() end elseif ((_G.type(pick_up_from) == "table") and (nil ~= pick_up_from[1])) then local field = pick_up_from[1]

 local function _40_() local data_5_auto = {field = field} local resolve_6_auto local function _33_(name_7_auto) local _34_ = data_5_auto[name_7_auto] local and_35_ = (nil ~= _34_) if and_35_ then local t_8_auto = _34_ and_35_ = ("table" == type(t_8_auto)) end if and_35_ then local t_8_auto = _34_ local _37_ = getmetatable(t_8_auto) if ((_G.type(_37_) == "table") and (nil ~= _37_.__tostring)) then local f_9_auto = _37_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _37_ return vim.inspect(t_8_auto) end elseif (nil ~= _34_) then local v_11_auto = _34_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _33_ return string.gsub("May not pick up from #{field}", "#{(.-)}", resolve_6_auto) end return nil, _40_() else return nil end end

 local function put_down(state, pick_up_from, dropped_on, held)
 local _42_, _43_, _44_ = pick_up_from, dropped_on, held local and_45_ = (((_G.type(_42_) == "table") and (nil ~= _42_[1]) and (nil ~= _42_[2]) and (nil ~= _42_[3])) and ((_G.type(_43_) == "table") and (_42_[1] == _43_[1]) and (_42_[2] == _43_[2]) and (nil ~= _43_[3])) and true) if and_45_ then local field = _42_[1] local col = _42_[2] local from_n = _42_[3] local on_n = _43_[3] local _ = _44_ and_45_ = (from_n == (1 + on_n)) end if and_45_ then local field = _42_[1] local col = _42_[2] local from_n = _42_[3] local on_n = _43_[3] local _ = _44_


 return nil elseif (((_G.type(_42_) == "table") and (_42_[1] == "hand")) and ((_G.type(_43_) == "table") and (_43_[1] == "discard"))) then



 local moves = {{"move", pick_up_from, {"discard", 1, "top"}}}
 return apply_events(inc_moves(clone(state)), moves, {["unsafely?"] = true}) elseif (((_G.type(_42_) == "table") and true) and ((_G.type(_43_) == "table") and (_43_[1] == "throne")) and ((_G.type(_44_) == "table") and (nil ~= _44_[1]))) then local _ = _42_[1] local held_card = _44_[1]





 local throne_card = table.last(state.throne[1]) local find_rank
 local function _47_(against)
 local rank = nil for i = 1, 4 do if rank then break end
 local _48_ = table.last(state.foundation[i]) if (nil ~= _48_) then local c = _48_
 if (card_suit(against) == card_suit(c)) then
 rank = card_value(c) else rank = nil end else rank = nil end end return rank end find_rank = _47_
 local throne_rank = (find_rank(throne_card) or 0)
 local held_rank = (find_rank(held_card) or 0) local ok_3f, msg = nil, nil
 do local _51_, _52_ = card_rank(held_card), card_rank(throne_card) if ((_51_ == "king") and true) then local _0 = _52_ ok_3f, msg = true elseif ((_51_ == "queen") and (_52_ == "king")) then



 ok_3f, msg = ((held_rank == 1) or (throne_rank < held_rank)), "Queens may overthrow Kings when their foundation is a higher rank" elseif ((_51_ == "queen") and true) then local _0 = _52_ ok_3f, msg = true elseif ((_51_ == "jack") and (_52_ == "king")) then





 ok_3f, msg = (1 == held_rank), "Jacks may overthrow Kings when their foundation is an Ace" elseif ((_51_ == "jack") and (_52_ == "queen")) then


 ok_3f, msg = ((1 == held_rank) or (throne_rank < held_rank)), "Jacks may overthrow Queens when their foundation is a higher rank" elseif ((_51_ == "jack") and true) then local _0 = _52_ ok_3f, msg = true else ok_3f, msg = nil end end



 if ok_3f then
 local moves = {{"move", pick_up_from, {"throne", 1, "top"}}}
 return apply_events(inc_moves(clone(state)), moves, {["unsafely?"] = true}) else


 return nil, msg end elseif (((_G.type(_42_) == "table") and true) and ((_G.type(_43_) == "table") and (_43_[1] == "foundation") and (nil ~= _43_[2]) and (_43_[3] == 0)) and ((_G.type(_44_) == "table") and (nil ~= _44_[1]))) then local _ = _42_[1] local f_col = _43_[2] local held_card = _44_[1]




 local suits do local tbl_19_auto = {"joker"} for i = 1, 4 do local val_20_auto
 do local _55_ = state.foundation[i][1] if (nil ~= _55_) then local c = _55_
 val_20_auto = card_suit(c) else val_20_auto = nil end end table.insert(tbl_19_auto, val_20_auto) end suits = tbl_19_auto end
 if not eq_any_3f(card_suit(held_card), suits) then
 local moves = {{"move", pick_up_from, {"foundation", f_col, 1}}}
 return apply_events(inc_moves(clone(state)), moves, {["unsafely?"] = true}) else


 local function _64_() local data_5_auto = {} local resolve_6_auto local function _57_(name_7_auto) local _58_ = data_5_auto[name_7_auto] local and_59_ = (nil ~= _58_) if and_59_ then local t_8_auto = _58_ and_59_ = ("table" == type(t_8_auto)) end if and_59_ then local t_8_auto = _58_ local _61_ = getmetatable(t_8_auto) if ((_G.type(_61_) == "table") and (nil ~= _61_.__tostring)) then local f_9_auto = _61_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _61_ return vim.inspect(t_8_auto) end elseif (nil ~= _58_) then local v_11_auto = _58_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _57_ return string.gsub("Can only start new foundations if suit not used", "#{(.-)}", resolve_6_auto) end return nil, _64_() end elseif (((_G.type(_42_) == "table") and true) and ((_G.type(_43_) == "table") and (_43_[1] == "foundation") and (nil ~= _43_[2]) and (nil ~= _43_[3])) and ((_G.type(_44_) == "table") and ((_G.type(_44_[1]) == "table") and (_44_[1][1] == "joker")))) then local _ = _42_[1] local f_col = _43_[2] local n = _43_[3]


 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col, (1 + n)}}}) elseif (((_G.type(_42_) == "table") and true) and ((_G.type(_43_) == "table") and (_43_[1] == "foundation") and (nil ~= _43_[2]) and (nil ~= _43_[3])) and ((_G.type(_44_) == "table") and (nil ~= _44_[1]))) then local _ = _42_[1] local f_col = _43_[2] local n = _43_[3] local held_card = _44_[1]





 local lead_card = state.foundation[f_col][1]
 local lead_suit = card_suit(lead_card)
 local throne_card = table.last(state.throne[1]) local when_jack
 local function _66_()



 return ((1 == card_rank(held_card)) or (card_suit(held_card) == card_suit(throne_card))) end when_jack = _66_ local when_queen

 local function _67_()

 local or_68_ = when_jack()
 if not or_68_ then local vals do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, 4 do local val_23_auto
 do local _70_ = table.last(state.foundation[i]) if (nil ~= _70_) then local c = _70_
 val_23_auto = card_value(c) else val_23_auto = nil end end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end vals = tbl_21_auto end
 or_68_ = eq_any_3f(card_value(held_card), vals) end return or_68_ end when_queen = _67_ local when_king
 local function _73_()

 local or_74_ = when_jack() or when_queen()

 if not or_74_ then local on_card = table["get-in"](state, dropped_on)
 local on_value = card_value(on_card)
 local one_up = (on_value + 1) local one_down

 do local _76_ = (on_value - 1) if (_76_ == -1) then one_down = 13 elseif (nil ~= _76_) then local n0 = _76_ one_down = n0 else one_down = nil end end
 or_74_ = eq_any_3f(card_value(held_card), {one_up, one_down}) end return or_74_ end when_king = _73_ local check_fn
 do local _78_ = card_rank(throne_card) if (_78_ == "king") then
 check_fn = when_king elseif (_78_ == "queen") then
 check_fn = when_queen elseif (_78_ == "jack") then
 check_fn = when_jack else check_fn = nil end end
 if ((card_suit(held_card) == lead_suit) and check_fn()) then
 local moves = {{"move", pick_up_from, {"foundation", f_col, (n + 1)}}}
 return apply_events(inc_moves(clone(state)), moves, {["unsafely?"] = true}) else


 local _80_ = card_rank(throne_card) if (_80_ == "king") then
 return nil, "Must play same suit as throne, or any matching rank, or +1 -1 rank" elseif (_80_ == "queen") then
 return nil, "Must play same suit as throne, or any matching rank" elseif (_80_ == "jack") then
 return nil, "Must play same suit as throne" else return nil end end else return nil end end

 M.Action.move = function(state, pick_up_from, put_down_on)
 local function _84_(...) local _85_ = ... if (nil ~= _85_) then local held = _85_ local function _86_(...) local _87_, _88_ = ... if ((nil ~= _87_) and (nil ~= _88_)) then local next_state = _87_ local moves = _88_


 return next_state, moves else local __85_auto = _87_ return ... end end return _86_(put_down(state, pick_up_from, put_down_on, held)) else local __85_auto = _85_ return ... end end return _84_(check_pick_up(state, pick_up_from)) end

 M.Query["liftable?"] = function(state, location)
 return not (nil == check_pick_up(state, location)) end

 M.Query["droppable?"] = function(state, location)
 if ((_G.type(location) == "table") and (nil ~= location[1])) then local field = location[1]
 return eq_any_3f(field, {"foundation", "throne", "discard"}) else local _ = location return false end end


 M.Query["game-result"] = function(state)
 local count
 local _92_ do local sum = 0 for _, t in ipairs(state.hand) do
 sum = (sum + #t) end _92_ = sum end count = (#state.discard[1] + _92_)
 return count end

 M.Query["game-ended?"] = function(state)
 local count
 local _93_ do local sum = 0 for _, t in ipairs(state.hand) do
 sum = (sum + #t) end _93_ = sum end count = (#state.draw[1] + _93_)
 return (0 == count) end

 return M