local lu = require("luaunit")
local U  = require("kardenwort.utils")

TestAssAlpha = {}

function TestAssAlpha:testFullyOpaque()
    lu.assertEquals(U.calculate_ass_alpha(1), "00")
end
function TestAssAlpha:testFullyTransparent()
    lu.assertEquals(U.calculate_ass_alpha(0), "FF")
end
function TestAssAlpha:testHalfOpacity()
    lu.assertEquals(U.calculate_ass_alpha(0.5), "80")
end
function TestAssAlpha:testHexPassthrough()
    lu.assertEquals(U.calculate_ass_alpha("aa"), "AA")
end
function TestAssAlpha:testInvalidInputDefaults()
    lu.assertEquals(U.calculate_ass_alpha("garbage"), "00")
end
function TestAssAlpha:testNilInputDefaults()
    lu.assertEquals(U.calculate_ass_alpha(nil), "00")
end


