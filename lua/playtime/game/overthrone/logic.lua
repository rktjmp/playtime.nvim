
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Deck = require("playtime.common.card.deck")
 local CardGameUtils = require("playtime.common.card.utils")

 local M = {Action = {}, Plan = {}, Query = {}}



 local _local_2_ = CardGameUtils local location_contents = _local_2_["location-contents"]
 local inc_moves = _local_2_["inc-moves"]
 local apply_events = _local_2_["apply-events"]
 M["iter-cards"] = CardGameUtils["make-iter-cards-fn"]({"foundation", "throne", "draw", "hand", "discard"})
 local _local_3_ = CardGameUtils["make-card-util-fns"]({value = {king = 13, queen = 12, jack = 11}, color = {diamonds = "red", hearts = "red", clubs = "black", spades = "black"}}) local card_value = _local_3_["card-value"] local card_color = _local_3_["card-color"] local card_rank = _local_3_["card-rank"]
 local card_suit = _local_3_["card-suit"] local rank_value = _local_3_["rank-value"] local suit_color = _local_3_["suit-color"]
 local card_face_up_3f = _local_3_["card-face-up?"] local card_face_down_3f = _local_3_["card-face-down?"]
 local flip_face_up = _local_3_["flip-face-up"]




 local function new_game_state(hand_size)


 local _4_ do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, hand_size do local val_20_auto = {} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end _4_ = tbl_18_auto end return {draw = {{}}, foundation = {{}, {}, {}, {}}, hand = _4_, throne = {{}}, discard = {{}}, moves = 0} end




 M.build = function(config, _3fseed) _G.assert((nil ~= config), "Missing argument config on fnl/playtime/game/overthrone/logic.fnl:32")
 math.randomseed((_3fseed or os.time()))
 local deck = table.shuffle(Deck.Standard54.build()) local deck0, lead = nil, nil


 do local t, l = {}, nil for _, c in ipairs(deck) do
 if ((_G.type(c) == "table") and (c[1] == "joker") and (c[2] == 2)) then
 t, l = t, l else local function _6_() local c0 = c return (10 < card_value(c0)) end if ((nil ~= c) and _6_()) then local c0 = c
 if (nil == l) then
 t, l = t, c0 else
 t, l = table.insert(t, c0), l end else local _0 = c
 t, l = table.insert(t, c), l end end end deck0, lead = t, l end
 local state = new_game_state(config["hand-size"])
 flip_face_up(lead)
 do end (state)["draw"][1] = deck0
 state["throne"][1] = {lead}
 return state end

 M.Action.deal = function(state)
 local moves do local t = {} for i = #state.hand, 1, -1 do
 t = table.join(t, {{"face-up", {"draw", 1, "top"}}, {"move", {"draw", 1, "top"}, {"hand", i, 1}}}) end moves = t end

 return apply_events(clone(state), moves) end

 M.Action.draw = function(state)
 local empty do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, #state.hand do local val_20_auto
 do local _9_ = state.hand[i] if ((_G.type(_9_) == "table") and (_9_[1] == nil)) then
 val_20_auto = i else val_20_auto = nil end end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end empty = tbl_18_auto end
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
 local function _21_() local data_5_auto = {} local resolve_6_auto local function _15_(name_7_auto) local _16_ = data_5_auto[name_7_auto] local function _17_() local t_8_auto = _16_ return ("table" == type(t_8_auto)) end if ((nil ~= _16_) and _17_()) then local t_8_auto = _16_ local _18_ = getmetatable(t_8_auto) if ((_G.type(_18_) == "table") and (nil ~= _18_.__tostring)) then local f_9_auto = _18_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _18_ return vim.inspect(t_8_auto) end elseif (nil ~= _16_) then local v_11_auto = _16_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _15_ return string.gsub("May only pick up from discard when joker is in play", "#{(.-)}", resolve_6_auto) end return nil, _21_() end else local _ = _12_
 local function _29_() local data_5_auto = {} local resolve_6_auto local function _23_(name_7_auto) local _24_ = data_5_auto[name_7_auto] local function _25_() local t_8_auto = _24_ return ("table" == type(t_8_auto)) end if ((nil ~= _24_) and _25_()) then local t_8_auto = _24_ local _26_ = getmetatable(t_8_auto) if ((_G.type(_26_) == "table") and (nil ~= _26_.__tostring)) then local f_9_auto = _26_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _26_ return vim.inspect(t_8_auto) end elseif (nil ~= _24_) then local v_11_auto = _24_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _23_ return string.gsub("Nothing to pick up", "#{(.-)}", resolve_6_auto) end return nil, _29_() end elseif ((_G.type(pick_up_from) == "table") and (nil ~= pick_up_from[1])) then local field = pick_up_from[1]

 local function _37_() local data_5_auto = {field = field} local resolve_6_auto local function _31_(name_7_auto) local _32_ = data_5_auto[name_7_auto] local function _33_() local t_8_auto = _32_ return ("table" == type(t_8_auto)) end if ((nil ~= _32_) and _33_()) then local t_8_auto = _32_ local _34_ = getmetatable(t_8_auto) if ((_G.type(_34_) == "table") and (nil ~= _34_.__tostring)) then local f_9_auto = _34_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _34_ return vim.inspect(t_8_auto) end elseif (nil ~= _32_) then local v_11_auto = _32_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _31_ return string.gsub("May not pick up from #{field}", "#{(.-)}", resolve_6_auto) end return nil, _37_() else return nil end end

 local function put_down(state, pick_up_from, dropped_on, held)
 local _39_, _40_, _41_ = pick_up_from, dropped_on, held local function _42_() local field = _39_[1] local col = _39_[2] local from_n = _39_[3] local on_n = _40_[3] local _ = _41_ return (from_n == (1 + on_n)) end if ((((_G.type(_39_) == "table") and (nil ~= _39_[1]) and (nil ~= _39_[2]) and (nil ~= _39_[3])) and ((_G.type(_40_) == "table") and (_39_[1] == _40_[1]) and (_39_[2] == _40_[2]) and (nil ~= _40_[3])) and true) and _42_()) then local field = _39_[1] local col = _39_[2] local from_n = _39_[3] local on_n = _40_[3] local _ = _41_


 return nil elseif (((_G.type(_39_) == "table") and (_39_[1] == "hand")) and ((_G.type(_40_) == "table") and (_40_[1] == "discard"))) then



 local moves = {{"move", pick_up_from, {"discard", 1, "top"}}}
 return apply_events(inc_moves(clone(state)), moves, {["unsafely?"] = true}) elseif (((_G.type(_39_) == "table") and true) and ((_G.type(_40_) == "table") and (_40_[1] == "throne")) and ((_G.type(_41_) == "table") and (nil ~= _41_[1]))) then local _ = _39_[1] local held_card = _41_[1]





 local throne_card = table.last(state.throne[1]) local find_rank
 local function _43_(against)
 local rank = nil for i = 1, 4 do if rank then break end
 local _44_ = table.last(state.foundation[i]) if (nil ~= _44_) then local c = _44_
 if (card_suit(against) == card_suit(c)) then
 rank = card_value(c) else rank = nil end else rank = nil end end return rank end find_rank = _43_
 local throne_rank = (find_rank(throne_card) or 0)
 local held_rank = (find_rank(held_card) or 0) local ok_3f, msg = nil, nil
 do local _47_, _48_ = card_rank(held_card), card_rank(throne_card) if ((_47_ == "king") and true) then local _0 = _48_ ok_3f, msg = true elseif ((_47_ == "queen") and (_48_ == "king")) then



 ok_3f, msg = ((held_rank == 1) or (throne_rank < held_rank)), "Queens may overthrow Kings when their foundation is a higher rank" elseif ((_47_ == "queen") and true) then local _0 = _48_ ok_3f, msg = true elseif ((_47_ == "jack") and (_48_ == "king")) then





 ok_3f, msg = (1 == held_rank), "Jacks may overthrow Kings when their foundation is an Ace" elseif ((_47_ == "jack") and (_48_ == "queen")) then


 ok_3f, msg = ((1 == held_rank) or (throne_rank < held_rank)), "Jacks may overthrow Queens when their foundation is a higher rank" elseif ((_47_ == "jack") and true) then local _0 = _48_ ok_3f, msg = true else ok_3f, msg = nil end end



 if ok_3f then
 local moves = {{"move", pick_up_from, {"throne", 1, "top"}}}
 return apply_events(inc_moves(clone(state)), moves, {["unsafely?"] = true}) else


 return nil, msg end elseif (((_G.type(_39_) == "table") and true) and ((_G.type(_40_) == "table") and (_40_[1] == "foundation") and (nil ~= _40_[2]) and (_40_[3] == 0)) and ((_G.type(_41_) == "table") and (nil ~= _41_[1]))) then local _ = _39_[1] local f_col = _40_[2] local held_card = _41_[1]




 local suits do local tbl_17_auto = {"joker"} for i = 1, 4 do
 local function _52_() local _51_ = state.foundation[i][1] if (nil ~= _51_) then local c = _51_
 return card_suit(c) else return nil end end table.insert(tbl_17_auto, _52_()) end suits = tbl_17_auto end
 if not eq_any_3f(card_suit(held_card), suits) then
 local moves = {{"move", pick_up_from, {"foundation", f_col, 1}}}
 return apply_events(inc_moves(clone(state)), moves, {["unsafely?"] = true}) else


 local function _60_() local data_5_auto = {} local resolve_6_auto local function _54_(name_7_auto) local _55_ = data_5_auto[name_7_auto] local function _56_() local t_8_auto = _55_ return ("table" == type(t_8_auto)) end if ((nil ~= _55_) and _56_()) then local t_8_auto = _55_ local _57_ = getmetatable(t_8_auto) if ((_G.type(_57_) == "table") and (nil ~= _57_.__tostring)) then local f_9_auto = _57_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _57_ return vim.inspect(t_8_auto) end elseif (nil ~= _55_) then local v_11_auto = _55_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _54_ return string.gsub("Can only start new foundations if suit not used", "#{(.-)}", resolve_6_auto) end return nil, _60_() end elseif (((_G.type(_39_) == "table") and true) and ((_G.type(_40_) == "table") and (_40_[1] == "foundation") and (nil ~= _40_[2]) and (nil ~= _40_[3])) and ((_G.type(_41_) == "table") and ((_G.type(_41_[1]) == "table") and (_41_[1][1] == "joker")))) then local _ = _39_[1] local f_col = _40_[2] local n = _40_[3]


 return apply_events(inc_moves(clone(state)), {{"move", pick_up_from, {"foundation", f_col, (1 + n)}}}) elseif (((_G.type(_39_) == "table") and true) and ((_G.type(_40_) == "table") and (_40_[1] == "foundation") and (nil ~= _40_[2]) and (nil ~= _40_[3])) and ((_G.type(_41_) == "table") and (nil ~= _41_[1]))) then local _ = _39_[1] local f_col = _40_[2] local n = _40_[3] local held_card = _41_[1]





 local lead_card = state.foundation[f_col][1]
 local lead_suit = card_suit(lead_card)
 local throne_card = table.last(state.throne[1]) local when_jack
 local function _62_()



 return ((1 == card_rank(held_card)) or (card_suit(held_card) == card_suit(throne_card))) end when_jack = _62_ local when_queen

 local function _63_()


 local function _67_() local vals do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, 4 do local val_20_auto
 do local _64_ = table.last(state.foundation[i]) if (nil ~= _64_) then local c = _64_
 val_20_auto = card_value(c) else val_20_auto = nil end end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end vals = tbl_18_auto end
 return eq_any_3f(card_value(held_card), vals) end return (when_jack() or _67_()) end when_queen = _63_ local when_king
 local function _68_()



 local function _71_() local on_card = table["get-in"](state, dropped_on)
 local on_value = card_value(on_card)
 local one_up = (on_value + 1) local one_down

 do local _69_ = (on_value - 1) if (_69_ == -1) then one_down = 13 elseif (nil ~= _69_) then local n0 = _69_ one_down = n0 else one_down = nil end end
 return eq_any_3f(card_value(held_card), {one_up, one_down}) end return (when_jack() or when_queen() or _71_()) end when_king = _68_ local check_fn
 do local _72_ = card_rank(throne_card) if (_72_ == "king") then
 check_fn = when_king elseif (_72_ == "queen") then
 check_fn = when_queen elseif (_72_ == "jack") then
 check_fn = when_jack else check_fn = nil end end
 if ((card_suit(held_card) == lead_suit) and check_fn()) then
 local moves = {{"move", pick_up_from, {"foundation", f_col, (n + 1)}}}
 return apply_events(inc_moves(clone(state)), moves, {["unsafely?"] = true}) else


 local _74_ = card_rank(throne_card) if (_74_ == "king") then
 return nil, "Must play same suit as throne, or any matching rank, or +1 -1 rank" elseif (_74_ == "queen") then
 return nil, "Must play same suit as throne, or any matching rank" elseif (_74_ == "jack") then
 return nil, "Must play same suit as throne" else return nil end end else return nil end end

 M.Action.move = function(state, pick_up_from, put_down_on)
 local function _78_(...) local _79_ = ... if (nil ~= _79_) then local held = _79_ local function _80_(...) local _81_, _82_ = ... if ((nil ~= _81_) and (nil ~= _82_)) then local next_state = _81_ local moves = _82_


 return next_state, moves else local __84_auto = _81_ return ... end end return _80_(put_down(state, pick_up_from, put_down_on, held)) else local __84_auto = _79_ return ... end end return _78_(check_pick_up(state, pick_up_from)) end

 M.Query["liftable?"] = function(state, location)
 return not (nil == check_pick_up(state, location)) end

 M.Query["droppable?"] = function(state, location)
 if ((_G.type(location) == "table") and (nil ~= location[1])) then local field = location[1]
 return eq_any_3f(field, {"foundation", "throne", "discard"}) else local _ = location return false end end


 M.Query["game-result"] = function(state)
 local count
 local function _86_() local sum = 0 for _, t in ipairs(state.hand) do
 sum = (sum + #t) end return sum end count = (#state.discard[1] + _86_())
 return count end

 M.Query["game-ended?"] = function(state)
 local count
 local function _87_() local sum = 0 for _, t in ipairs(state.hand) do
 sum = (sum + #t) end return sum end count = (#state.draw[1] + _87_())
 return (0 == count) end

 return M