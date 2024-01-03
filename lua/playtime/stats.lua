
 local _local_1_ = require("playtime.prelude") local clone = _local_1_["clone"] local eq_all_3f = _local_1_["eq-all?"] local eq_any_3f = _local_1_["eq-any?"] local math = _local_1_["math"] local string = _local_1_["string"] local table = _local_1_["table"] local type = _local_1_["type"]

 local Logger = require("playtime.logger")
 local Error = require("playtime.error")
 local Serializer = require("playtime.serializer")

 local uv = (vim.loop or vim.uv)
 local M = {}

 local function stat_path(app)
 return vim.fs.normalize(string.format("%s/stats.json", app["data-dir"])) end











 local function save(app, data) _G.assert((nil ~= data), "Missing argument data on fnl/playtime/stats.fnl:24") _G.assert((nil ~= app), "Missing argument app on fnl/playtime/stats.fnl:24")
 return Serializer.write(stat_path(data)) end






 local function load(app) _G.assert((nil ~= app), "Missing argument app on fnl/playtime/stats.fnl:32")
 return Serializer.read(stat_path(app)) end

 return M