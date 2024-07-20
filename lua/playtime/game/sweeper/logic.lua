
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Error = require("playtime.error")
 local Logger = require("playtime.logger")
 local Id = require("playtime.common.id")

 local M = {Action = {}, Plan = {}, Query = {}}



 M["location->index"] = function(_2_, _4_) local _arg_3_ = _2_["size"] local width = _arg_3_["width"] local height = _arg_3_["height"] local x = _4_["x"] local y = _4_["y"]
 return (((y - 1) * width) + x) end

 local function location_content(state, location)
 local index = M["location->index"](state, location)
 return state.grid[index] end

 M["iter-cells"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/sweeper/logic.fnl:19")
 local _let_5_ = state["size"] local width = _let_5_["width"] local height = _let_5_["height"]
 local function iter()
 for y = 1, height do
 for x = 1, width do
 local loc = {x = x, y = y}
 local i = M["location->index"](state, loc)
 coroutine.yield({x = x, y = y, i = i}, location_content(state, loc)) end end return nil end
 return coroutine.wrap(iter) end

 local function north_of(state, _6_) local x = _6_["x"] local y = _6_["y"]
 local y0 = (y - 1)
 if (1 <= y0) then return {x = x, y = y0} else return nil end end

 local function south_of(_8_, _10_) local _arg_9_ = _8_["size"] local height = _arg_9_["height"] local x = _10_["x"] local y = _10_["y"]
 local y0 = (y + 1)
 if (y0 <= height) then return {x = x, y = y0} else return nil end end

 local function east_of(state, _12_) local x = _12_["x"] local y = _12_["y"]
 local x0 = (x - 1)
 if (1 <= x0) then return {x = x0, y = y} else return nil end end

 local function west_of(_14_, _16_) local _arg_15_ = _14_["size"] local width = _arg_15_["width"] local x = _16_["x"] local y = _16_["y"]
 local x0 = (x + 1)
 if (x0 <= width) then return {x = x0, y = y} else return nil end end

 local function north_east_of(state, location)
 local tmp_6_auto = north_of(state, location) if (tmp_6_auto ~= nil) then return east_of(state, tmp_6_auto) else return nil end end


 local function north_west_of(state, location)
 local tmp_6_auto = north_of(state, location) if (tmp_6_auto ~= nil) then return west_of(state, tmp_6_auto) else return nil end end


 local function south_east_of(state, location)
 local tmp_6_auto = south_of(state, location) if (tmp_6_auto ~= nil) then return east_of(state, tmp_6_auto) else return nil end end


 local function south_west_of(state, location)
 local tmp_6_auto = south_of(state, location) if (tmp_6_auto ~= nil) then return west_of(state, tmp_6_auto) else return nil end end


 local function new_game_state(size, n_mines)
 local width = size["width"] local height = size["height"] local grid
 do local tbl_21_auto = {} local i_22_auto = 0 for _, _0 in M["iter-cells"]({size = size, grid = {}}) do
 local val_23_auto = {id = Id.new(), mark = nil, count = 0, ["mine?"] = false, ["revealed?"] = false} if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end grid = tbl_21_auto end




 return {grid = grid, size = {width = width, height = height}, ["n-mines"] = n_mines, remaining = n_mines, ["saving-throw?"] = true, ["lost?"] = false, ["won?"] = false} end







 M.build = function(config, _3fseed) _G.assert((nil ~= config), "Missing argument config on fnl/playtime/game/sweeper/logic.fnl:77")
 local _23_ if ((_G.type(config) == "table") and (nil ~= config.width) and (nil ~= config.height) and (nil ~= config["n-mines"])) then local width = config.width local height = config.height local n_mines = config["n-mines"] _23_ = true else local __1_auto = config _23_ = false end assert(_23_, "Sweeper config must match {: width : height : n-mines}")

 math.randomseed((_3fseed or os.time()))
 local width = config["width"] local height = config["height"] local n_mines = config["n-mines"]
 local state = new_game_state({width = width, height = height}, n_mines)
 return state end

 local function set_mines_21(state, not_at_locations)
 local _let_27_ = state["size"] local width = _let_27_["width"] local height = _let_27_["height"] local allowed_at_location_3f
 local function _29_(_28_) local x = _28_["x"] local y = _28_["y"]
 local _30_ do local t = false for _, loc in ipairs(not_at_locations) do if t then break end
 if ((_G.type(loc) == "table") and (loc.x == x) and (loc.y == y)) then t = true else local _0 = loc t = false end end _30_ = t end return not _30_ end allowed_at_location_3f = _29_ local positions


 do local tbl_21_auto = {} local i_22_auto = 0 for location, _ in M["iter-cells"](state) do local val_23_auto
 if allowed_at_location_3f(location) then
 val_23_auto = location else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end positions = tbl_21_auto end local random_indexes
 local function _34_() local tbl_21_auto = {} local i_22_auto = 0 for i, _ in ipairs(positions) do local val_23_auto = i if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end random_indexes = table.shuffle(_34_()) local inc_count
 local function _36_(loc)
 if not (nil == loc) then
 local i = M["location->index"](state, loc)
 local cell = state.grid[i]
 cell.count = (cell.count + 1) return nil else return nil end end inc_count = _36_ local mines_at
 do local tbl_21_auto = {} local i_22_auto = 0 for i = 1, state["n-mines"] do local val_23_auto
 do local i0 = random_indexes[i]
 local center = positions[i0]
 local cell = location_content(state, center)
 cell["mine?"] = true
 inc_count(north_of(state, center))
 inc_count(north_east_of(state, center))
 inc_count(east_of(state, center))
 inc_count(south_east_of(state, center))
 inc_count(south_of(state, center))
 inc_count(south_west_of(state, center))
 inc_count(west_of(state, center))
 val_23_auto = inc_count(north_west_of(state, center)) end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end mines_at = tbl_21_auto end
 return state end

 local function maybe_update_won(state)
 local won_3f do local won_3f0 = true for _, cell in M["iter-cells"](state) do if not won_3f0 then break end
 if ((_G.type(cell) == "table") and (cell["mine?"] == true) and (cell.mark == "flag")) then won_3f0 = true elseif ((_G.type(cell) == "table") and (cell["revealed?"] == true)) then won_3f0 = true else local _0 = cell won_3f0 = false end end won_3f = won_3f0 end



 state["won?"] = (not state["lost?"] and won_3f)
 return state end

 M.Action["reveal-location"] = function(state, location) _G.assert((nil ~= location), "Missing argument location on fnl/playtime/game/sweeper/logic.fnl:125") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/sweeper/logic.fnl:125")
 local next_state = clone(state) local next_state0

 if next_state["saving-throw?"] then
 local fns = {north_west_of, north_of, north_east_of, west_of, east_of, south_west_of, south_of, south_east_of} local safe_locations


 do local tbl_19_auto = {location} for _, f in ipairs(fns) do
 local val_20_auto = f(state, location) table.insert(tbl_19_auto, val_20_auto) end safe_locations = tbl_19_auto end

 next_state["saving-throw?"] = false
 next_state0 = set_mines_21(next_state, safe_locations) else
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

 M.Action["mark-location"] = function(state, location) _G.assert((nil ~= location), "Missing argument location on fnl/playtime/game/sweeper/logic.fnl:180") _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/sweeper/logic.fnl:180")
 local next_state = clone(state)
 local cell = location_content(next_state, location)
 if ((_G.type(cell) == "table") and (cell.mark == nil) and (cell["revealed?"] == false)) then

 next_state.remaining = (next_state.remaining - 1) cell.mark = "flag" elseif ((_G.type(cell) == "table") and (cell.mark == "flag") and (cell["revealed?"] == false)) then


 next_state.remaining = (next_state.remaining + 1) cell.mark = "maybe" else local _ = cell

 cell.mark = nil end
 maybe_update_won(next_state)
 return next_state end

 M.Query["game-ended?"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/sweeper/logic.fnl:194")
 return (state["lost?"] or state["won?"]) end

 M.Query["game-result"] = function(state) _G.assert((nil ~= state), "Missing argument state on fnl/playtime/game/sweeper/logic.fnl:197")
 if state["lost?"] then return "lost" elseif state["won?"] then return "won" else return "unknown" end end



 return M