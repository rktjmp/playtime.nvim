
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local Id = require("playtime.common.id")

 local M = {Action = {}, Plan = {}, Query = {}}



 M["location->index"] = function(_2_, _5_) local _arg_3_ = _2_ local _arg_4_ = _arg_3_["size"] local width = _arg_4_["width"] local height = _arg_4_["height"] local _arg_6_ = _5_ local x = _arg_6_["x"] local y = _arg_6_["y"]
 return (((y - 1) * width) + x) end

 local function location_content(state, location)
 local index = M["location->index"](state, location)
 return state.grid[index] end

 M["iter-cells"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/sweeper/logic.fnl:19")
 local _let_7_ = state local _let_8_ = _let_7_["size"] local width = _let_8_["width"] local height = _let_8_["height"]
 local function iter()
 for y = 1, height do
 for x = 1, width do
 local loc = {x = x, y = y}
 local i = M["location->index"](state, loc)
 coroutine.yield({x = x, y = y, i = i}, location_content(state, loc)) end end return nil end
 return coroutine.wrap(iter) end

 local function north_of(state, _9_) local _arg_10_ = _9_ local x = _arg_10_["x"] local y = _arg_10_["y"]
 local y0 = (y - 1)
 if (1 <= y0) then return {x = x, y = y0} else return nil end end

 local function south_of(_12_, _15_) local _arg_13_ = _12_ local _arg_14_ = _arg_13_["size"] local height = _arg_14_["height"] local _arg_16_ = _15_ local x = _arg_16_["x"] local y = _arg_16_["y"]
 local y0 = (y + 1)
 if (y0 <= height) then return {x = x, y = y0} else return nil end end

 local function east_of(state, _18_) local _arg_19_ = _18_ local x = _arg_19_["x"] local y = _arg_19_["y"]
 local x0 = (x - 1)
 if (1 <= x0) then return {x = x0, y = y} else return nil end end

 local function west_of(_21_, _24_) local _arg_22_ = _21_ local _arg_23_ = _arg_22_["size"] local width = _arg_23_["width"] local _arg_25_ = _24_ local x = _arg_25_["x"] local y = _arg_25_["y"]
 local x0 = (x + 1)
 if (x0 <= width) then return {x = x0, y = y} else return nil end end

 local function north_east_of(state, location)
 local _27_ = north_of(state, location) if (_27_ ~= nil) then return east_of(state, _27_) else return _27_ end end


 local function north_west_of(state, location)
 local _29_ = north_of(state, location) if (_29_ ~= nil) then return west_of(state, _29_) else return _29_ end end


 local function south_east_of(state, location)
 local _31_ = south_of(state, location) if (_31_ ~= nil) then return east_of(state, _31_) else return _31_ end end


 local function south_west_of(state, location)
 local _33_ = south_of(state, location) if (_33_ ~= nil) then return west_of(state, _33_) else return _33_ end end


 local function new_game_state(size, n_mines)
 local _let_35_ = size local width = _let_35_["width"] local height = _let_35_["height"] local grid
 do local tbl_18_auto = {} local i_19_auto = 0 for _, _0 in M["iter-cells"]({size = size, grid = {}}) do
 local val_20_auto = {id = Id.new(), mark = nil, count = 0, ["mine?"] = false, ["revealed?"] = false} if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end grid = tbl_18_auto end




 return {grid = grid, size = {width = width, height = height}, ["n-mines"] = n_mines, remaining = n_mines, ["saving-throw?"] = true, ["lost?"] = false, ["won?"] = false} end







 M.build = function(config, _3fseed) _G.assert((nil ~= config), "Missing argument config on fnl/playtime/game/sweeper/logic.fnl:77")
 local _37_ if ((_G.type(config) == "table") and (nil ~= config.width) and (nil ~= config.height) and (nil ~= config["n-mines"])) then local width = config.width local height = config.height local n_mines = config["n-mines"] _37_ = true else local __1_auto = config _37_ = false end assert(_37_, "Sweeper config must match {: width : height : n-mines}")

 math.randomseed((_3fseed or os.time()))
 local _let_41_ = config local width = _let_41_["width"] local height = _let_41_["height"] local n_mines = _let_41_["n-mines"]
 local state = new_game_state({width = width, height = height}, n_mines)
 return state end

 local function set_mines_21(state, not_at)
 local _let_42_ = state local _let_43_ = _let_42_["size"] local width = _let_43_["width"] local height = _let_43_["height"] local positions
 do local tbl_18_auto = {} local i_19_auto = 0 for _44_, _ in M["iter-cells"](state) do local _each_45_ = _44_ local x = _each_45_["x"] local y = _each_45_["y"] local val_20_auto
 if ((_G.type(not_at) == "table") and (not_at.x == x) and (not_at.y == y)) then
 val_20_auto = nil else local _0 = not_at
 val_20_auto = {x = x, y = y} end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end positions = tbl_18_auto end local random_indexes
 local function _48_() local tbl_18_auto = {} local i_19_auto = 0 for i, _ in ipairs(positions) do local val_20_auto = i if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto end random_indexes = table.shuffle(_48_()) local inc_count
 local function _50_(loc)
 if not (nil == loc) then
 local i = M["location->index"](state, loc)
 local cell = state.grid[i]
 cell.count = (cell.count + 1) return nil else return nil end end inc_count = _50_ local mines_at
 do local tbl_18_auto = {} local i_19_auto = 0 for i = 1, state["n-mines"] do local val_20_auto
 do local i0 = random_indexes[i]
 local center = positions[i0]
 local cell = location_content(state, center)
 do end (cell)["mine?"] = true
 inc_count(north_of(state, center))
 inc_count(north_east_of(state, center))
 inc_count(east_of(state, center))
 inc_count(south_east_of(state, center))
 inc_count(south_of(state, center))
 inc_count(south_west_of(state, center))
 inc_count(west_of(state, center))
 val_20_auto = inc_count(north_west_of(state, center)) end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end mines_at = tbl_18_auto end
 return state end

 local function maybe_update_won(state)
 local won_3f do local won_3f0 = true for _, cell in M["iter-cells"](state) do if not won_3f0 then break end
 if ((_G.type(cell) == "table") and (cell["mine?"] == true) and (cell.mark == "flag")) then won_3f0 = true elseif ((_G.type(cell) == "table") and (cell["revealed?"] == true)) then won_3f0 = true else local _0 = cell won_3f0 = false end end won_3f = won_3f0 end



 state["won?"] = (not state["lost?"] and won_3f)
 return state end

 M.Action["reveal-location"] = function(state, location) _G.assert((nil ~= location), "Missing argument location on fnl/playtime/game/sweeper/logic.fnl:121") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/sweeper/logic.fnl:121")
 local next_state = clone(state) local next_state0

 if next_state["saving-throw?"] then


 next_state["saving-throw?"] = false
 next_state0 = set_mines_21(next_state, location) else
 next_state0 = next_state end
 local cell = location_content(next_state0, location)
 if ((_G.type(cell) == "table") and (cell["revealed?"] == true)) then elseif ((_G.type(cell) == "table") and (cell.mark == "flag")) then elseif ((_G.type(cell) == "table") and (cell["mine?"] == true)) then next_state0["lost?"] = true









 for _, cell0 in M["iter-cells"](next_state0) do
 cell0["revealed?"] = (cell0["revealed?"] or cell0["mine?"]) end elseif ((_G.type(cell) == "table") and (cell["mine?"] == false)) then




 cell.mark = nil
 local queue = {location} for _, l in ipairs(queue) do
 local visit_cell = location_content(next_state0, l)
 if ((_G.type(visit_cell) == "table") and (visit_cell.mark == nil) and (visit_cell["revealed?"] == false)) then local visit_cell0 = visit_cell visit_cell0["revealed?"] = true






 if ((_G.type(visit_cell0) == "table") and (visit_cell0.count == 0)) then
 table.insert(queue, north_of(next_state0, l)) table.insert(queue, north_east_of(next_state0, l)) table.insert(queue, east_of(next_state0, l)) table.insert(queue, south_east_of(next_state0, l)) table.insert(queue, south_of(next_state0, l)) table.insert(queue, south_west_of(next_state0, l)) table.insert(queue, west_of(next_state0, l)) table.insert(queue, north_west_of(next_state0, l)) queue = queue elseif ((_G.type(visit_cell0) == "table") and (nil ~= visit_cell0.count)) then local n = visit_cell0.count








 queue = queue else queue = nil end else local _0 = visit_cell
 queue = queue end end else end
 maybe_update_won(next_state0)
 return next_state0 end

 M.Action["mark-location"] = function(state, location) _G.assert((nil ~= location), "Missing argument location on fnl/playtime/game/sweeper/logic.fnl:172") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/sweeper/logic.fnl:172")
 local next_state = clone(state)
 local cell = location_content(next_state, location)
 if ((_G.type(cell) == "table") and (cell.mark == nil) and (cell["revealed?"] == false)) then

 next_state.remaining = (next_state.remaining - 1) cell.mark = "flag" elseif ((_G.type(cell) == "table") and (cell.mark == "flag") and (cell["revealed?"] == false)) then


 next_state.remaining = (next_state.remaining + 1) cell.mark = "maybe" else local _ = cell

 cell.mark = nil end
 maybe_update_won(next_state)
 return next_state end

 M.Query["game-ended?"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/sweeper/logic.fnl:186")
 return (state["lost?"] or state["won?"]) end

 M.Query["game-result"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/sweeper/logic.fnl:189")
 if state["lost?"] then return "lost" elseif state["won?"] then return "won" else return "unknown" end end



 return M