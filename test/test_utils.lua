--- Created by xyzzycgn.
--- DateTime: 04.05.25 06:00
---
require('test.BaseTest')
local lu = require('luaunit')
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

function TestUtils:testBitOperAND()
    -- simple cases
    lu.assertEquals(utils.bitoper(0, 0, utils.bitOps.AND), 0)
    lu.assertEquals(utils.bitoper(1, 0, utils.bitOps.AND), 0)
    lu.assertEquals(utils.bitoper(0, 1, utils.bitOps.AND), 0)
    lu.assertEquals(utils.bitoper(1, 1, utils.bitOps.AND), 1)
    
    -- more complex
    lu.assertEquals(utils.bitoper(6, 4, utils.bitOps.AND), 4)  -- 110 AND 100 = 100
    lu.assertEquals(utils.bitoper(7, 5, utils.bitOps.AND), 5)  -- 111 AND 101 = 101
    lu.assertEquals(utils.bitoper(15, 7, utils.bitOps.AND), 7) -- 1111 AND 0111 = 0111
end

function TestUtils:testBitOperOR()
    -- simple cases
    lu.assertEquals(utils.bitoper(0, 0, utils.bitOps.OR), 0)
    lu.assertEquals(utils.bitoper(1, 0, utils.bitOps.OR), 1)
    lu.assertEquals(utils.bitoper(0, 1, utils.bitOps.OR), 1)
    lu.assertEquals(utils.bitoper(1, 1, utils.bitOps.OR), 1)
    
    -- more complex
    lu.assertEquals(utils.bitoper(6, 3, utils.bitOps.OR), 7)   -- 110 OR 011 = 111
    lu.assertEquals(utils.bitoper(10, 5, utils.bitOps.OR), 15) -- 1010 OR 0101 = 1111
    lu.assertEquals(utils.bitoper(12, 3, utils.bitOps.OR), 15) -- 1100 OR 0011 = 1111
end

function TestUtils:testBitOperXOR()
    -- simplest cases
    lu.assertEquals(utils.bitoper(0, 0, utils.bitOps.XOR), 0)
    lu.assertEquals(utils.bitoper(1, 0, utils.bitOps.XOR), 1)
    lu.assertEquals(utils.bitoper(0, 1, utils.bitOps.XOR), 1)
    lu.assertEquals(utils.bitoper(1, 1, utils.bitOps.XOR), 0)
    
    -- greater numbers
    lu.assertEquals(utils.bitoper(6, 3, utils.bitOps.XOR), 5)   -- 110 XOR 011 = 101
    lu.assertEquals(utils.bitoper(10, 5, utils.bitOps.XOR), 15) -- 1010 XOR 0101 = 1111
    lu.assertEquals(utils.bitoper(15, 7, utils.bitOps.XOR), 8)  -- 1111 XOR 0111 = 1000
end

function TestUtils:testBitOperBordercases()
    local maxUint = 4294967295  -- maximum for 32-Bit uint (2^32 - 1)
    
    -- Maximum uint Tests
    lu.assertEquals(utils.bitoper(maxUint, 0, utils.bitOps.AND), 0)
    lu.assertEquals(utils.bitoper(maxUint, maxUint, utils.bitOps.AND), maxUint)
    lu.assertEquals(utils.bitoper(maxUint, 0, utils.bitOps.OR), maxUint)
    lu.assertEquals(utils.bitoper(maxUint, maxUint, utils.bitOps.XOR), 0)
    
    local halfMax = 2147483647  -- 2^31 - 1
    lu.assertEquals(utils.bitoper(halfMax, halfMax, utils.bitOps.AND), halfMax)
    lu.assertEquals(utils.bitoper(halfMax, 0, utils.bitOps.AND), 0)
    
    -- tests some patterns
    local pattern1 = 0xAAAAAAAA  -- 10101010...
    local pattern2 = 0x55555555  -- 01010101...
    lu.assertEquals(utils.bitoper(pattern1, pattern2, utils.bitOps.AND), 0)
    lu.assertEquals(utils.bitoper(pattern1, pattern2, utils.bitOps.OR), maxUint)
    lu.assertEquals(utils.bitoper(pattern1, pattern2, utils.bitOps.XOR), maxUint)
end
-- ###############################################################

function TestUtils:testDistFromTurretHorizontalRight()
    local target = { position = { x = 13, y = 10 } }
    local turret = { position = { x = 10, y = 10 } }

    local dist, angle = utils.distFromTurret(target, turret)

    lu.assertAlmostEquals(dist, 3.0, 1e-9)
    -- dy = 0, dx = 3  => angle = 0
    lu.assertAlmostEquals(angle, 0.25, 1e-9)
end

function TestUtils:testDistFromTurretHorizontalLeft()
    local target = { position = { x = 7, y = 10 } }
    local turret = { position = { x = 10, y = 10 } }

    local dist, angle = utils.distFromTurret(target, turret)

    lu.assertAlmostEquals(dist, 3.0, 1e-9)
    -- dy = 0, dx = -3 => angle = pi
    lu.assertAlmostEquals(angle, 0.75, 1e-9)
end

function TestUtils:testDistFromTurretVerticalUp()
    local target = { position = { x = 10, y = 14 } }
    local turret = { position = { x = 10, y = 10 } }

    local dist, angle = utils.distFromTurret(target, turret)

    lu.assertAlmostEquals(dist, 4.0, 1e-9)
    -- dy = 4, dx = 0  => angle = pi/2
    lu.assertAlmostEquals(angle, 0, 1e-9)
end

function TestUtils:testDistFromTurretVerticalDown()
    local target = { position = { x = 10, y =  6 } }
    local turret = { position = { x = 10, y = 10 } }

    local dist, angle = utils.distFromTurret(target, turret)

    lu.assertAlmostEquals(dist, 4.0, 1e-9)
    -- dy = -4, dx = 0 => angle = -pi/2
    lu.assertAlmostEquals(angle, 0.5, 1e-9)
end

function TestUtils:testDistFromTurretDiagonal()
    local target = { position = { x = 4, y = 5 } }
    local turret = { position = { x = 1, y = 2 } }

    local dist, angle = utils.distFromTurret(target, turret)

    lu.assertAlmostEquals(dist, math.sqrt(18), 1e-9)
    lu.assertAlmostEquals(angle, 0.125, 1e-9)
end
-- ###############################################################

-- Run the tests
BaseTest:hookTests()