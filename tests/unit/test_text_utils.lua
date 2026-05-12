local lu = require("luaunit")
local U  = require("kardenwort.utils")

TestTextUtils = {}

function TestTextUtils:testUtf8LowerCyrillicAndLatin()
    lu.assertEquals(U.utf8_to_lower("ÄÖÜẞ ПрИвЕт"), "äöüß привет")
end

function TestTextUtils:testBuildWordListInternal()
    local tokens = U.build_word_list_internal("Hello, мир!", true)
    lu.assertTrue(#tokens >= 4)
    lu.assertEquals(tokens[1].text, "Hello")
    lu.assertTrue(tokens[1].is_word)
end

function TestTextUtils:testFuzzyIndices()
    local idx = U.find_fuzzy_indices("subtitle", "stl")
    lu.assertNotNil(idx)
    lu.assertEquals(#idx, 3)
end

function TestTextUtils:testMatchScoreOrdering()
    local exact = U.calculate_match_score("hello", "hello")
    local fuzzy = U.calculate_match_score("hello world", "hlo")
    lu.assertTrue(exact > fuzzy)
end

function TestTextUtils:testMatchScoreReturnsSortedIndices()
    local score, indices = U.calculate_match_score("subtitle", "stl")
    lu.assertTrue(type(score) == "number")
    lu.assertTrue(type(indices) == "table")
    lu.assertEquals(#indices, 3)
    lu.assertTrue(indices[1] < indices[2] and indices[2] < indices[3])
end
