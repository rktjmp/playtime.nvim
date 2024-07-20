 local game_names = nil
 local function list_games()
 if not game_names then
 local _let_1_ = require("playtime.meta") local find = _let_1_["find"] local games
 do local t = {} for _, game in ipairs(find()) do
 if ((_G.type(game) == "table") and (game.rulesets == nil)) then
 table.insert(t, game.mod) t = t elseif ((_G.type(game) == "table") and (nil ~= game.rulesets)) then local rulesets = game.rulesets
 local t0 = t for _0, _2_ in ipairs(rulesets) do local cli = _2_["cli"] local config = _2_["config"]
 table.insert(t0, cli) t0 = t0 end t = t0 else t = nil end end games = t end
 game_names = games
 table.sort(game_names) else end
 return game_names end

 local function load_diskette(game_name, args) _G.assert((nil ~= args), "Missing argument args on plugin/playtime.fnl:14") _G.assert((nil ~= game_name), "Missing argument game-name on plugin/playtime.fnl:14")
 local Playtime = require("playtime")
 local _3fseed = args[1]
 return Playtime.play(game_name, _3fseed) end

 local function eq_any_3f(x, ys) local ok_3f = false
 for _, y in ipairs(ys) do if ok_3f then break end
 ok_3f = (x == y) end return ok_3f end

 local function run(_5_) local fargs = _5_["fargs"]
 if ((_G.type(fargs) == "table") and (fargs[1] == nil)) then

 return load_diskette("playtime", {}) elseif ((_G.type(fargs) == "table") and (nil ~= fargs[1])) then local game = fargs[1] local args = {select(2, (table.unpack or _G.unpack)(fargs))}
 return load_diskette(game, args) else local _ = fargs


 return error("Usage: `:Playtime <game-name> <game-seed> <game-options>` or `:Playtime` for menu") end end

 local function complete(arg_lead, cmd_line, cursor_pos)
 local tbl_21_auto = {} local i_22_auto = 0 for _, name in ipairs(list_games()) do local val_23_auto
 if (1 == string.find(name, arg_lead, 1, true)) then
 val_23_auto = name else val_23_auto = nil end if (nil ~= val_23_auto) then i_22_auto = (i_22_auto + 1) tbl_21_auto[i_22_auto] = val_23_auto else end end return tbl_21_auto end

 return vim.api.nvim_create_user_command("Playtime", run, {nargs = "*", complete = complete})