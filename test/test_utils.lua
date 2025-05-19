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
-- ###############################################################

function TestUtils:testCheckCircuitConditionWithoutCC()
    local retc, details = utils.checkCircuitCondition()
    lu.assertFalse(retc)
    lu.assertEquals(details, utils.CircuitConditionChecks.unknown)
end

function TestUtils:testCheckCircuitConditionWithoutFirstSignal()
    local cc = {
        first_signal = nil,
        second_signal = nil,
        constant = 1,
        comparator = ">"
    }
    local retc, details = utils.checkCircuitCondition(cc)
    lu.assertFalse(retc)
    lu.assertEquals(details, utils.CircuitConditionChecks.firstSignalEmpty)
end

function TestUtils:testCheckCircuitConditionWithSecondSignal()
    local cc = {
        first_signal = { name = "signal-A" },
        second_signal = { name = "signal-B" },
        constant = nil,
        comparator = ">"
    }
    local retc, details = utils.checkCircuitCondition(cc)
    lu.assertFalse(retc)
    lu.assertEquals(details, utils.CircuitConditionChecks.secondSignalNotSupported)
end

function TestUtils:testCheckCircuitConditionWithConstant()
    local cc = {
        first_signal = { name = "signal-A" },
        second_signal = nil,
        constant = 42,
        comparator = ">"
    }
    local retc, details = utils.checkCircuitCondition(cc)
    lu.assertFalse(retc)
    lu.assertEquals(details, utils.CircuitConditionChecks.noTrue)
end

function TestUtils:testCheckCircuitConditionNoTrueResult()
    local cc = {
        first_signal = { name = "signal-A" },
        second_signal = nil,
        constant = 0,
        comparator = ">"
    }
    local retc, details = utils.checkCircuitCondition(cc)
    lu.assertTrue(retc)
    lu.assertEquals(details, utils.CircuitConditionChecks.ok)
end

function TestUtils:testCheckCircuitConditionNoFalseResult()
    local cc = {
        first_signal = { name = "signal-A" },
        second_signal = nil,
        constant = -1,
        comparator = ">"
    }
    local retc, details = utils.checkCircuitCondition(cc)
    lu.assertFalse(retc)
    lu.assertEquals(details, utils.CircuitConditionChecks.noFalse)
end

-- Tests for different ComparatorString
function TestUtils:testCheckCircuitConditionOperators()
    local tests = {
        { op = "=",  const = 1, expected_retc = true,  expected_detail = utils.CircuitConditionChecks.ok },
        { op = "≠",  const = 0, expected_retc = true,  expected_detail = utils.CircuitConditionChecks.ok },
        { op = ">",  const = 0, expected_retc = true,  expected_detail = utils.CircuitConditionChecks.ok },
        { op = ">",  const = 2, expected_retc = false, expected_detail = utils.CircuitConditionChecks.noTrue },
        { op = ">=", const = 1, expected_retc = true,  expected_detail = utils.CircuitConditionChecks.ok },
        { op = "<",  const = 2, expected_retc = false, expected_detail = utils.CircuitConditionChecks.noFalse },
        { op = "<=", const = 1, expected_retc = false, expected_detail = utils.CircuitConditionChecks.noFalse },
        { op = "≥",  const = 1, expected_retc = true,  expected_detail = utils.CircuitConditionChecks.ok },
        { op = "≤",  const = 1, expected_retc = false, expected_detail = utils.CircuitConditionChecks.noFalse },
    }

    for _, test in ipairs(tests) do
        local cc = {
            first_signal = { name = "signal-A" },
            second_signal = nil,
            constant = test.const,
            comparator = test.op
        }
        local retc, details = utils.checkCircuitCondition(cc)
        lu.assertEquals(retc, test.expected_retc, 
            string.format("Operator %s mit constant %d sollte %s zurückgeben", 
            test.op, test.const, tostring(test.expected_retc)))
        lu.assertEquals(details, test.expected_detail)
    end
end

function TestUtils:testCheckCircuitConditionWithInvalidOperator()
    local cc = {
        first_signal = { name = "signal-A" },
        second_signal = nil,
        constant = 1,
        comparator = "invalid"
    }
    local retc, details = utils.checkCircuitCondition(cc)
    lu.assertFalse(retc)
    lu.assertEquals(details, utils.CircuitConditionChecks.invalidComparator)
end

-- Run the tests
BaseTest:hookTests()