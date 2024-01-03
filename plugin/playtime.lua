 local game_names = nil
 local function list_games()
 if not game_names then
 local _let_1_ = require("playtime.meta") local find = _let_1_["find"] local games
 do local t = {} for _, game in ipairs(find()) do
 if ((_G.type(game) == "table") and (game.rulesets == nil)) then
 table.insert(t, game.mod) t = t elseif ((_G.type(game) == "table") and (nil ~= game.rulesets)) then local rulesets = game.rulesets
 local t0 = t for _0, _2_ in ipairs(rulesets) do local _each_3_ = _2_ local cli = _each_3_["cli"] local config = _each_3_["config"]
 table.insert(t0, cli) t0 = t0 end t = t0 else t = nil end end games = t end
 game_names = games
 table.sort(game_names) else end
 return game_names end

 local function load_diskette(game_name, args) _G.assert((nil ~= args), "Missing argument args on plugin/playtime.fnl:14") _G.assert((nil ~= game_name), "Missing argument game-name on plugin/playtime.fnl:14")
 local Playtime = require("playtime")
 local _let_6_ = args local _3fseed = _let_6_[1]
 return Playtime.play(game_name, _3fseed) end

 local function eq_any_3f(x, ys) local ok_3f = false
 for _, y in ipairs(ys) do if ok_3f then break end
 ok_3f = (x == y) end return ok_3f end

 local function run(_7_) local _arg_8_ = _7_ local fargs = _arg_8_["fargs"]
 if ((_G.type(fargs) == "table") and (fargs[1] == nil)) then

 return load_diskette("playtime", {}) elseif ((_G.type(fargs) == "table") and (nil ~= fargs[1])) then local game = fargs[1] local args = {select(2, (table.unpack or _G.unpack)(fargs))}
 return load_diskette(game, args) else local _ = fargs


 return error("Usage: `:Playtime <game-name> <game-seed> <game-options>` or `:Playtime` for menu") end end

 local function complete(arg_lead, cmd_line, cursor_pos)
 local tbl_18_auto = {} local i_19_auto = 0 for _, name in ipairs(list_games()) do local val_20_auto
 if (1 == string.find(name, arg_lead, 1, true)) then
 val_20_auto = name else val_20_auto = nil end if (nil ~= val_20_auto) then i_19_auto = (i_19_auto + 1) do end (tbl_18_auto)[i_19_auto] = val_20_auto else end end return tbl_18_auto end

 return vim.api.nvim_create_user_command("Playtime", run, {nargs = "*", complete = complete})