package.path = package.path .. ";tests/lua/?.lua;tests/unit/?.lua;scripts/?.lua"
local lu = require("luaunit")
for _, name in ipairs({ "test_ass_alpha", "test_utf8" }) do
    require(name)
end
os.exit(lu.LuaUnit.run())


