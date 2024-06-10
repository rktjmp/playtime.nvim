
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Error = require("playtime.error")
 local State = require("playtime.app.state")
 local CommonComponents = require("playtime.common.components")
 local Serializer = require("playtime.serializer")

 local M = {State = State}
 local uv = (vim.loop or vim.uv)

 M.build = function(name, app_id, app_config, game_config) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/app/init.fnl:13") _G.assert((nil ~= app_config), "Missing argument app-config on fnl/playtime/app/init.fnl:13") _G.assert((nil ~= app_id), "Missing argument app-id on fnl/playtime/app/init.fnl:13") _G.assert((nil ~= name), "Missing argument name on fnl/playtime/app/init.fnl:13")



























 local function _2_(t, k)
 if (k == "context") then
 local t_3_ = t if (nil ~= t_3_) then t_3_ = t_3_[1] else end if (nil ~= t_3_) then t_3_ = t_3_[2] else end return t_3_ elseif (k == "module") then
 local t_6_ = t if (nil ~= t_6_) then t_6_ = t_6_[1] else end if (nil ~= t_6_) then t_6_ = t_6_[1] else end return t_6_ else return nil end end
 local function _10_(t, k, v)
 if (k == "context") then
 t[1][2] = v return nil else return nil end end return {name = name, ["app-id"] = app_id, filetype = ("playtime-" .. app_id), ["data-dir"] = vim.fs.normalize(string.format("%s/playtime/%s", vim.fn.stdpath("data"), app_id)), ["app-config"] = app_config, ["started-at"] = os.time(), ["ended-at"] = nil, seed = Error("Seed not initialised"), game = Error("Game not initialised"), ["game-config"] = game_config, ["game-history"] = {}, view = Error("View not initialised"), ["z-layers"] = {base = 0, report = 500, menubar = 600}, ["tick-rate-ms"] = math.floor((1000 / (app_config.fps or 30))), components = {menubar = CommonComponents.menubar({{"Playtime", {"todo"}}}, {width = 80, z = 100}), cheating = (function(tgt, m, ...) return tgt[m](tgt, ...) end)(CommonComponents.cheating(), "set-visible", false)}, state = setmetatable({{State.DefaultAppState, {}}}, {__index = _2_, __newindex = _10_}), ["event-queue"] = {}, throttle = {render = {["requested?"] = false}, tick = {["last-at"] = 0, ["scheduled?"] = false}}, ["quit?"] = false} end





 M["build-default-window-dispatch-options"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/init.fnl:53")

 local function _12_(...) return app["queue-event"](app, "input", ...) end









 local function _13_(...) return app["queue-event"](app, "app", ...) end return {mouse = {via = _12_, events = {"<LeftMouse>", "<2-LeftMouse>", "<3-LeftMouse>", "<LeftDrag>", "<LeftRelease>", "<MiddleMouse>", "<RightMouse>", "<RightDrag>", "<RightRelease>"}}, window = {via = _13_}} end

 M["z-index-for-layer"] = function(app, layer, _3fplus)
 local _14_ do local t_15_ = app["z-layers"] if (nil ~= t_15_) then t_15_ = t_15_[layer] else end _14_ = t_15_ end if (nil ~= _14_) then local n = _14_
 return (n + (_3fplus or 0)) else local _ = _14_
 local function _23_() local data_5_auto = {layer = layer} local resolve_6_auto local function _17_(name_7_auto) local _18_ = data_5_auto[name_7_auto] local function _19_() local t_8_auto = _18_ return ("table" == type(t_8_auto)) end if ((nil ~= _18_) and _19_()) then local t_8_auto = _18_ local _20_ = getmetatable(t_8_auto) if ((_G.type(_20_) == "table") and (nil ~= _20_.__tostring)) then local f_9_auto = _20_.__tostring return f_9_auto(t_8_auto) else local __10_auto = _20_ return vim.inspect(t_8_auto) end elseif (nil ~= _18_) then local v_11_auto = _18_ return tostring(v_11_auto) else return nil end end resolve_6_auto = _17_ return string.gsub("Unknown layer name for z-index: #{layer}", "#{(.-)}", resolve_6_auto) end return error(_23_()) end end

 M["new-game"] = function(app, game_builder, game_config, _3fseed) _G.assert((nil ~= game_config), "Missing argument game-config on fnl/playtime/app/init.fnl:72") _G.assert((nil ~= game_builder), "Missing argument game-builder on fnl/playtime/app/init.fnl:72") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/init.fnl:72")
 local seed = (_3fseed or os.time())
 local game = game_builder(game_config, seed)
 app["started-at"] = os.time()
 app["ended-at"] = nil
 app.seed = seed
 app["game-config"] = game_config
 app["game-history"] = {}
 Logger.info("Built #{name} seed: #{seed}", {name = app.name, seed = seed}) return app["update-game"](app, game, {}) end


 M["update-game"] = function(app, next_game, replay) _G.assert((nil ~= replay), "Missing argument replay on fnl/playtime/app/init.fnl:83") _G.assert((nil ~= next_game), "Missing argument next-game on fnl/playtime/app/init.fnl:83") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/init.fnl:83")

 table.insert(app["game-history"], {app.game, replay})
 app.game = next_game
 return app end

 local function throttled_tick(app)
 if not app["quit?"] then
 app.throttle.tick["last-at"] = uv.now() app:tick()

 if app.throttle.render["requested?"] then app.throttle.render["requested?"] = false app:render() else end else end


 return app end

 M["request-tick"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/init.fnl:98")

 if not app.throttle.tick["scheduled?"] then app.throttle.tick["scheduled?"] = true

 local now = uv.now()
 local next_tick_at = (app.throttle.tick["last-at"] + app["tick-rate-ms"])
 local time_to_next_tick_ms = math.max(0, (next_tick_at - now)) local run
 local function _27_() app.throttle.tick["scheduled?"] = false

 return throttled_tick(app) end run = _27_
 vim.defer_fn(run, time_to_next_tick_ms) else end
 return app end

 M["request-render"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/init.fnl:111") app.throttle.render["requested?"] = true


 return app end

 M["queue-event"] = function(app, namespace, event, ...) _G.assert((nil ~= event), "Missing argument event on fnl/playtime/app/init.fnl:116") _G.assert((nil ~= namespace), "Missing argument namespace on fnl/playtime/app/init.fnl:116") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/init.fnl:116")








 do local index do local _29_, _30_ = namespace, table.last(app["event-queue"]) if ((_29_ == "input") and ((_G.type(_30_) == "table") and (_30_[1] == "input") and (_30_[2] == event))) then
 index = #app["event-queue"] else local _ = _29_
 index = (1 + #app["event-queue"]) end end
 app["event-queue"][index] = {namespace, event, table.pack(...)} app["request-tick"](app) end

 return app end

 M["process-next-event"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/init.fnl:132")



 local _32_ = app["event-queue"] if ((_G.type(_32_) == "table") and ((_G.type(_32_[1]) == "table") and (nil ~= _32_[1][1]) and (nil ~= _32_[1][2]) and (nil ~= _32_[1][3]))) then local ns = _32_[1][1] local event = _32_[1][2] local args = _32_[1][3] local other_events = {select(2, (table.unpack or _G.unpack)(_32_))} app["request-tick"](app)





 app["event-queue"] = other_events
 local _33_ do local t_34_ = app if (nil ~= t_34_) then t_34_ = t_34_.state else end if (nil ~= t_34_) then t_34_ = t_34_.module else end if (nil ~= t_34_) then t_34_ = t_34_.OnEvent else end if (nil ~= t_34_) then t_34_ = t_34_[ns] else end if (nil ~= t_34_) then t_34_ = t_34_[event] else end _33_ = t_34_ end if (nil ~= _33_) then local f = _33_
 return f(app, table.unpack(args)) else local _ = _33_
 return Logger.info("#{state} had no handler for event #{ns}.#{event}", {state = app.state[1], ns = ns, event = event}) end else return nil end end


 M["switch-state"] = function(app, new_state, _3fcontext)

 M["pop-state"](app)
 M["push-state"](app, new_state, _3fcontext)
 return app end

 M["push-state"] = function(app, new_state, _3fcontext)



 local context = (_3fcontext or {})
 table.insert(app.state, 1, {new_state, context})
 if new_state.activated then
 new_state.activated(app, context) else end
 return app end

 M["pop-state"] = function(app)



 do local _43_ = table.remove(app.state, 1) if ((_G.type(_43_) == "table") and (nil ~= _43_[1]) and true) then local state = _43_[1] local _3fcontext = _43_[2]
 if state.deactivated then state.deactivated(app, _3fcontext) else end else end end
 return app end

 M.notify = function(app, msg)

 return vim.notify(tostring(msg)) end

 M.save = function(app, filename, data) _G.assert((nil ~= data), "Missing argument data on fnl/playtime/app/init.fnl:176") _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/app/init.fnl:176") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/init.fnl:176")

 local dir = app["data-dir"]
 local path = vim.fs.normalize(string.format("%s/%s.json", dir, filename))

 local function _46_(...) local _47_, _48_ = ... if (_47_ == 1) then local function _49_(...) local _50_, _51_ = ... if (_50_ == true) then return app:notify(string.format("Saved to %s", path)) elseif ((_50_ == nil) and (nil ~= _51_)) then local err = _51_ return app:notify(err) else return nil end end return _49_(Serializer.write(path, data)) elseif ((_47_ == nil) and (nil ~= _48_)) then local err = _48_ return app:notify(err) else return nil end end return _46_(vim.fn.mkdir(dir, "p")) end






 M.load = function(app, filename) _G.assert((nil ~= filename), "Missing argument filename on fnl/playtime/app/init.fnl:188") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/init.fnl:188")



 local path = vim.fs.normalize(string.format("%s/%s.json", app["data-dir"], filename))

 local function _54_(...) local _55_, _56_ = ... if (nil ~= _55_) then local data = _55_ app:notify(string.format("Loaded %s", path))



 return data elseif ((_55_ == nil) and (nil ~= _56_)) then local err = _56_ return app:notify(err) else return nil end end return _54_(Serializer.read(path)) end



 M["update-statistics"] = function(app, updater_fn) _G.assert((nil ~= updater_fn), "Missing argument updater-fn on fnl/playtime/app/init.fnl:202") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/init.fnl:202")
 local path = vim.fs.normalize(string.format("%s/%s.json", app["data-dir"], "stats"))

 local function _58_(...) local _59_, _60_ = ... if (nil ~= _59_) then local data = _59_ local function _61_(...) local _62_, _63_ = ... if (nil ~= _62_) then local new_data = _62_ local function _64_(...) local _65_, _66_ = ... if (_65_ == true) then



 return app elseif ((_65_ == nil) and (nil ~= _66_)) then local err = _66_ return app:notify(err) else return nil end end return _64_(Serializer.write(path, new_data)) elseif ((_62_ == nil) and (nil ~= _63_)) then local err = _63_ return app:notify(err) else return nil end end return _61_(updater_fn(data)) elseif ((_59_ == nil) and (nil ~= _60_)) then local err = _60_ return app:notify(err) else return nil end end return _58_((Serializer.read(path) or {})) end



 M["fetch-statistics"] = function(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/app/init.fnl:213")
 local path = vim.fs.normalize(string.format("%s/%s.json", app["data-dir"], "stats"))

 return (Serializer.read(path) or {}) end

 return M