
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Error = require("playtime.error")

 local M = {}
 local uv = (vim.loop or vim.uv)

 M.build = function(name, _3fopts) _G.assert((nil ~= name), "Missing argument name on fnl/playtime/app/state.fnl:10")
 local function with_delegates(delegates, namespace)
 local function __index(t, k)
 local _2_ do local t_3_ = delegates if (nil ~= t_3_) then t_3_ = t_3_[namespace] else end if (nil ~= t_3_) then t_3_ = t_3_.OnEvent else end if (nil ~= t_3_) then t_3_ = t_3_[namespace] else end if (nil ~= t_3_) then t_3_ = t_3_[k] else end _2_ = t_3_ end if (nil ~= _2_) then local f = _2_
 return f elseif (_2_ == nil) then
 local function _8_(app) return app end return _8_ else return nil end end
 return setmetatable({}, {__index = __index}) end
 local opts = (_3fopts or {}) local delegates
 local _11_ do local t_10_ = opts if (nil ~= t_10_) then t_10_ = t_10_.delegate else end if (nil ~= t_10_) then t_10_ = t_10_.app else end _11_ = t_10_ end
 local _15_ do local t_14_ = opts if (nil ~= t_14_) then t_14_ = t_14_.delegate else end if (nil ~= t_14_) then t_14_ = t_14_.input else end _15_ = t_14_ end delegates = {app = _11_, input = _15_}
 local base = {OnEvent = {app = with_delegates(delegates, "app"), input = with_delegates(delegates, "input")}, Delegate = delegates}


 local function _18_() return (name .. "State") end return setmetatable(base, {__tostring = _18_}) end









 M.DefaultAppState = M.build("DefaultAppState")


 local function _19_(_t, k) return error(Error("Failed to respond to app.#{k}", {k = k})) end setmetatable(M.DefaultAppState.OnEvent.app, {__index = _19_})

 M.DefaultAppState.OnEvent.app.load = function(app, _3ffilename) return app:load((_3ffilename or "latest")) end


 M.DefaultAppState.OnEvent.app.save = function(app, _3ffilename) return app:save((_3ffilename or "latest")) end


 M.DefaultAppState.OnEvent.app.noop = function(app)
 return app end

 M.DefaultAppState.OnEvent.app.quit = function(app)
 do app["quit?"] = true end
 if vim.api.nvim_win_is_valid(app.view.win) then
 return vim.api.nvim_win_close(app.view.win, true) else return nil end end

 M.DefaultAppState.OnEvent.app.undo = function(app)

 local _21_, _22_ = table.split(app["game-history"], -1) if (((_G.type(_21_) == "table") and (_21_[1] == nil)) and ((_G.type(_22_) == "table") and (_22_[1] == nil))) then return app:notify("Nothing to undo") elseif ((nil ~= _21_) and ((_G.type(_22_) == "table") and ((_G.type(_22_[1]) == "table") and (nil ~= _22_[1][1]) and true))) then local history = _21_ local new_state = _22_[1][1] local _ = _22_[1][2]

 app["game"] = new_state app["game-history"] = history return app else return nil end end








































 M.DefaultAnimatingState = M.build("DefaultAnimatingState", {delegate = {app = M.DefaultAppState}})


 M.DefaultAnimatingState.activated = function(app, animation)
 local animations if ((_G.type(animation) == "table") and (nil ~= animation["start-at"])) then local start_at = animation["start-at"]
 animations = {animation} elseif (nil ~= animation) then local timeline = animation
 animations = timeline else animations = nil end
 app.state.context.running = {}
 do
 local tbl_17_auto = app.state.context.running for _, animation0 in ipairs(animations) do
 local val_18_auto = animation0 table.insert(tbl_17_auto, val_18_auto) end end app["request-tick"](app)

 return app end

 M.DefaultAnimatingState.tick = function(app)
 local now = uv.now()
 local _25_ = app.state.context.running if ((_G.type(_25_) == "table") and (nil ~= _25_[1])) then local any = _25_[1] local animations = _25_




 local context = app.state.context local animations0
 do local tbl_19_auto = {} local i_20_auto = 0 for i, animation in ipairs(animations) do local val_21_auto
 do local _let_26_ = animation local finish_at = _let_26_["finish-at"] local start_at = _let_26_["start-at"] local tick = _let_26_["tick"]
 if (start_at <= now) then animation:tick(now)


 if (now < finish_at) then
 val_21_auto = animation else val_21_auto = nil end else
 val_21_auto = animation end end if (nil ~= val_21_auto) then i_20_auto = (i_20_auto + 1) do end (tbl_19_auto)[i_20_auto] = val_21_auto else end end animations0 = tbl_19_auto end
 context.running = animations0 return app["request-tick"](app) else return nil end end








 M.DefaultInMenuState = M.build("DefaultInMenuState", {delegate = {app = M.DefaultAppState}})

 M.DefaultInMenuState.activated = function(app, _31_) local _arg_32_ = _31_ local menu_item = _arg_32_["menu-item"]
 local _let_33_ = menu_item local _ = _let_33_[1] local idx = _let_33_[2]
 for i, menu in ipairs(app.components.menubar.children) do menu:update((i == idx)) end return nil end


 M.DefaultInMenuState.deactivated = function(app)
 for i, menu in ipairs(app.components.menubar.children) do menu:update(false) end return nil end


 M.DefaultInMenuState.OnEvent.input["<LeftDrag>"] = function(app, _34_, pos) local _arg_35_ = _34_ local location = _arg_35_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local first = location[2]


 for i, menu in ipairs(app.components.menubar.children) do menu:update((i == first)) end return nil else return nil end end


 M.DefaultInMenuState.OnEvent.input["<LeftRelease>"] = function(app, _37_, pos) local _arg_38_ = _37_ local location = _arg_38_[1]
 if ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (location[3] == nil)) then local first = location[2]


 for i, menu in ipairs(app.components.menubar.children) do menu:update((i == first)) end return nil elseif ((_G.type(location) == "table") and (location[1] == "menu") and (nil ~= location[2]) and (nil ~= location[3])) then local dropdown_index = location[2] local item_index = location[3]




 local tag do local t_39_ = app.components.menubar.menu if (nil ~= t_39_) then t_39_ = t_39_[dropdown_index] else end if (nil ~= t_39_) then t_39_ = t_39_[3] else end if (nil ~= t_39_) then t_39_ = t_39_[item_index] else end if (nil ~= t_39_) then t_39_ = t_39_[2] else end tag = t_39_ end
 for i, menu in ipairs(app.components.menubar.children) do menu:update(false) end

 if ((_G.type(tag) == "table") and (nil ~= tag[1]) and true) then local event_name = tag[1] local _3fargs = tag[2] app["queue-event"](app, "app", event_name, _3fargs) else end return app["pop-state"](app) else local _ = location return app["pop-state"](app) end end







 return M