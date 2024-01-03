local function preprocessor(fnl, meta)
  if not string.match(meta.path, "prelude") then
    return "(require-macros :nep.prelude) (prelude) " .. fnl
  else
    return fnl
  end
end

local allowedGlobals = {}
for name,_val in pairs(_G) do
  table.insert(allowedGlobals, name)
end

return {
  build = {
    {verbose = false, force = false, atomic = true},
    {"fnl/**/*macros.fnl", false},
    {"fnl/**/*.fnl", true},
    {"plugin/*.fnl", true}
  },
  clean = true,
  compiler = {
    modules = {
      correlate = true,
      allowedGlobals = allowedGlobals
    },
    -- preprocessor = preprocessor
  }
}
