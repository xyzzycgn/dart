---
--- Created by xyzzycgn.
--- DateTime: 04.05.25 06:00
---
require('test.BaseTest')
local lu = require('lib.luaunit')
local utils = require('scripts.utils')

TestUtils = {}

function TestUtils:testEmptyTable()
    local result = utils.sort({}, true, function(a, b) return a < b end)
    lu.assertEquals(result, {})
end

function TestUtils:testAscendingSort()
    local input = {5, 3, 1, 4, 2}
    local result = utils.sort(input, true, function(a, b) return a < b end)
    lu.assertEquals(result, {1, 2, 3, 4, 5})
end

function TestUtils:testDescendingSort()
    local input = {5, 3, 1, 4, 2}
    local result = utils.sort(input, false, function(a, b) return a < b end)
    lu.assertEquals(result, {5, 4, 3, 2, 1})
end

function TestUtils:testTableWithGaps()
    local input = {}
    input[1] = 5
    input[3] = 3
    input[5] = 1
    local result = utils.sort(input, true, function(a, b) return a < b end)
    lu.assertEquals(result, {1, 3, 5})
end

function TestUtils:testCustomComparisonFunction()
    local input = {
        {wert = 3},
        {wert = 1},
        {wert = 2}
    }
    local result = utils.sort(input, true, function(a, b)
        return a.wert < b.wert
    end)
    lu.assertEquals(result, {{wert = 1}, {wert = 2}, {wert = 3}})
end

-- Run the tests
BaseTest:hookTests()