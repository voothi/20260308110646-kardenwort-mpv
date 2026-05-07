local lu = require("luaunit")
local U  = require("lls_utils")

TestUtf8 = {}

function TestUtf8:testAscii()
    lu.assertEquals(#U.utf8_to_table("hello"), 5)
end
function TestUtf8:testCyrillic()
    lu.assertEquals(#U.utf8_to_table("привет"), 6)
end
function TestUtf8:testGermanDiacritics()
    lu.assertEquals(#U.utf8_to_table("größe"), 6)
end
function TestUtf8:testCJK()
    lu.assertEquals(#U.utf8_to_table("日本語"), 3)
end
function TestUtf8:testEmpty()
    lu.assertEquals(#U.utf8_to_table(""), 0)
end
function TestUtf8:testMixed()
    lu.assertEquals(#U.utf8_to_table("héllo"), 5)
end
