---
--- Created by xyzzycgn.
---
local Require = require("test.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)

require("spec.common")
require("scripts.internalEvents")

describe("Utils", function()
    local utils

    setup(function()
        utils = require("scripts.utils")
    end)

    describe("sort", function()
        it("returns an empty table for an empty input table", function()
            local result = utils.sort({}, true, function(a, b) return a < b end)

            assert.are.same({}, result)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("sorts values in ascending order", function()
            local input = { 5, 3, 1, 4, 2 }

            local result = utils.sort(input, true, function(a, b) return a < b end)

            assert.are.same({ 1, 2, 3, 4, 5 }, result)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("sorts values in descending order", function()
            local input = { 5, 3, 1, 4, 2 }

            local result = utils.sort(input, false, function(a, b) return a < b end)

            assert.are.same({ 5, 4, 3, 2, 1 }, result)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("sorts tables with gaps as a compact result table", function()
            local input = {}
            input[1] = 5
            input[3] = 3
            input[5] = 1

            local result = utils.sort(input, true, function(a, b) return a < b end)

            assert.are.same({ 1, 3, 5 }, result)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("sorts values with a custom comparison function", function()
            local input = {
                { wert = 3 },
                { wert = 1 },
                { wert = 2 }
            }

            local result = utils.sort(input, true, function(a, b)
                return a.wert < b.wert
            end)

            assert.are.same({ { wert = 1 }, { wert = 2 }, { wert = 3 } }, result)
        end)
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("checkCircuitCondition", function()
        it("returns unknown when no circuit condition is given", function()
            local retc, details = utils.checkCircuitCondition()

            assert.is_false(retc)
            assert.are.equal(utils.CircuitConditionChecks.unknown, details)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns firstSignalEmpty when the first signal is missing", function()
            local cc = {
                first_signal = nil,
                second_signal = nil,
                constant = 1,
                comparator = ">"
            }

            local retc, details = utils.checkCircuitCondition(cc)

            assert.is_false(retc)
            assert.are.equal(utils.CircuitConditionChecks.firstSignalEmpty, details)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns secondSignalNotSupported when a second signal is configured", function()
            local cc = {
                first_signal = { name = "signal-A" },
                second_signal = { name = "signal-B" },
                constant = nil,
                comparator = ">"
            }

            local retc, details = utils.checkCircuitCondition(cc)

            assert.is_false(retc)
            assert.are.equal(utils.CircuitConditionChecks.secondSignalNotSupported, details)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns noTrue when the condition can never become true", function()
            local cc = {
                first_signal = { name = "signal-A" },
                second_signal = nil,
                constant = 42,
                comparator = ">"
            }

            local retc, details = utils.checkCircuitCondition(cc)

            assert.is_false(retc)
            assert.are.equal(utils.CircuitConditionChecks.noTrue, details)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns ok when the condition can become true and false", function()
            local cc = {
                first_signal = { name = "signal-A" },
                second_signal = nil,
                constant = 0,
                comparator = ">"
            }

            local retc, details = utils.checkCircuitCondition(cc)

            assert.is_true(retc)
            assert.are.equal(utils.CircuitConditionChecks.ok, details)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns noFalse when the condition can never become false", function()
            local cc = {
                first_signal = { name = "signal-A" },
                second_signal = nil,
                constant = -1,
                comparator = ">"
            }

            local retc, details = utils.checkCircuitCondition(cc)

            assert.is_false(retc)
            assert.are.equal(utils.CircuitConditionChecks.noFalse, details)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("handles all supported comparator strings", function()
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

                assert.are.equal(
                        test.expected_retc,
                        retc,
                        string.format(
                                "Operator %s with constant %d should return %s",
                                test.op,
                                test.const,
                                tostring(test.expected_retc)
                        )
                )
                assert.are.equal(test.expected_detail, details)
            end
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns invalidComparator for unsupported operators", function()
            local cc = {
                first_signal = { name = "signal-A" },
                second_signal = nil,
                constant = 1,
                comparator = "invalid"
            }

            local retc, details = utils.checkCircuitCondition(cc)

            assert.is_false(retc)
            assert.are.equal(utils.CircuitConditionChecks.invalidComparator, details)
        end)
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("bitoper", function()
        it("calculates bitwise AND", function()
            -- Simple cases.
            assert.are.equal(0, utils.bitoper(0, 0, utils.bitOps.AND))
            assert.are.equal(0, utils.bitoper(1, 0, utils.bitOps.AND))
            assert.are.equal(0, utils.bitoper(0, 1, utils.bitOps.AND))
            assert.are.equal(1, utils.bitoper(1, 1, utils.bitOps.AND))

            -- More complex cases.
            assert.are.equal(4, utils.bitoper(6, 4, utils.bitOps.AND))  -- 110 AND 100 = 100
            assert.are.equal(5, utils.bitoper(7, 5, utils.bitOps.AND))  -- 111 AND 101 = 101
            assert.are.equal(7, utils.bitoper(15, 7, utils.bitOps.AND)) -- 1111 AND 0111 = 0111
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates bitwise OR", function()
            -- Simple cases.
            assert.are.equal(0, utils.bitoper(0, 0, utils.bitOps.OR))
            assert.are.equal(1, utils.bitoper(1, 0, utils.bitOps.OR))
            assert.are.equal(1, utils.bitoper(0, 1, utils.bitOps.OR))
            assert.are.equal(1, utils.bitoper(1, 1, utils.bitOps.OR))

            -- More complex cases.
            assert.are.equal(7, utils.bitoper(6, 3, utils.bitOps.OR))   -- 110 OR 011 = 111
            assert.are.equal(15, utils.bitoper(10, 5, utils.bitOps.OR)) -- 1010 OR 0101 = 1111
            assert.are.equal(15, utils.bitoper(12, 3, utils.bitOps.OR)) -- 1100 OR 0011 = 1111
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates bitwise XOR", function()
            -- Simple cases.
            assert.are.equal(0, utils.bitoper(0, 0, utils.bitOps.XOR))
            assert.are.equal(1, utils.bitoper(1, 0, utils.bitOps.XOR))
            assert.are.equal(1, utils.bitoper(0, 1, utils.bitOps.XOR))
            assert.are.equal(0, utils.bitoper(1, 1, utils.bitOps.XOR))

            -- Larger numbers.
            assert.are.equal(5, utils.bitoper(6, 3, utils.bitOps.XOR))   -- 110 XOR 011 = 101
            assert.are.equal(15, utils.bitoper(10, 5, utils.bitOps.XOR)) -- 1010 XOR 0101 = 1111
            assert.are.equal(8, utils.bitoper(15, 7, utils.bitOps.XOR))  -- 1111 XOR 0111 = 1000
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("handles boundary cases and bit patterns", function()
            local maxUint = 4294967295 -- Maximum 32-bit uint: 2^32 - 1.

            -- Maximum uint tests.
            assert.are.equal(0, utils.bitoper(maxUint, 0, utils.bitOps.AND))
            assert.are.equal(maxUint, utils.bitoper(maxUint, maxUint, utils.bitOps.AND))
            assert.are.equal(maxUint, utils.bitoper(maxUint, 0, utils.bitOps.OR))
            assert.are.equal(0, utils.bitoper(maxUint, maxUint, utils.bitOps.XOR))

            local halfMax = 2147483647 -- 2^31 - 1.
            assert.are.equal(halfMax, utils.bitoper(halfMax, halfMax, utils.bitOps.AND))
            assert.are.equal(0, utils.bitoper(halfMax, 0, utils.bitOps.AND))

            -- Pattern tests.
            local pattern1 = 0xAAAAAAAA -- 10101010...
            local pattern2 = 0x55555555 -- 01010101...
            assert.are.equal(0, utils.bitoper(pattern1, pattern2, utils.bitOps.AND))
            assert.are.equal(maxUint, utils.bitoper(pattern1, pattern2, utils.bitOps.OR))
            assert.are.equal(maxUint, utils.bitoper(pattern1, pattern2, utils.bitOps.XOR))
        end)
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("distFromTurret", function()
        it("calculates distance and angle for a target to the right", function()
            local turret = { position = { x = 10, y = 10 } }
            local target = { position = { x = 13, y = 10 } }

            local dist, angle = utils.distFromTurret(target, turret)

            assert.near(3.0, dist, 1e-9)
            assert.near(0.25, angle, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates distance and angle for a target to the left", function()
            local turret = { position = { x = 10, y = 10 } }
            local target = { position = { x = 7, y = 10 } }

            local dist, angle = utils.distFromTurret(target, turret)

            assert.near(3.0, dist, 1e-9)
            assert.near(0.75, angle, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates distance and angle for a target above", function()
            local turret = { position = { x = 10, y = 10 } }
            local target = { position = { x = 10, y = 6 } }

            local dist, angle = utils.distFromTurret(target, turret)

            assert.near(4.0, dist, 1e-9)
            assert.near(0, angle, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates distance and angle for a target below", function()
            local turret = { position = { x = 10, y = 10 } }
            local target = { position = { x = 10, y = 14 } }

            local dist, angle = utils.distFromTurret(target, turret)

            assert.near(4.0, dist, 1e-9)
            assert.near(0.5, angle, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates distance and angle for a target diagonally right and above", function()
            local turret = { position = { x = 1, y = 2 } }
            local target = { position = { x = 4, y = -1 } }

            local dist, angle = utils.distFromTurret(target, turret)

            assert.near(math.sqrt(18), dist, 1e-9)
            assert.near(0.125, angle, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates distance and angle for a target diagonally left and above", function()
            local turret = { position = { x = 1, y = 2 } }
            local target = { position = { x = -2, y = -1 } }

            local dist, angle = utils.distFromTurret(target, turret)

            assert.near(math.sqrt(18), dist, 1e-9)
            assert.near(0.875, angle, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates distance and angle for a target diagonally left and above in the negative quadrant", function()
            local turret = { position = { x = -2, y = -2 } }
            local target = { position = { x = -5, y = -5 } }

            local dist, angle = utils.distFromTurret(target, turret)

            assert.near(math.sqrt(18), dist, 1e-9)
            assert.near(0.875, angle, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates distance and angle for a far target diagonally left and above", function()
            local turret = { position = { x = -3, y = -12 } }
            local target = { position = { x = -38.7109375, y = -56.38671875 } }

            local dist, angle = utils.distFromTurret(target, turret)

            assert.near(56.9688, dist, 1e-4)
            assert.near(0.8921719291134842, angle, 1e-8)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates distance and angle for a target diagonally right and below", function()
            local turret = { position = { x = 1, y = 2 } }
            local target = { position = { x = 4, y = 5 } }

            local dist, angle = utils.distFromTurret(target, turret)

            assert.near(math.sqrt(18), dist, 1e-9)
            assert.near(0.375, angle, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates distance and angle for a target diagonally left and below", function()
            local turret = { position = { x = 1, y = 2 } }
            local target = { position = { x = -2, y = 5 } }

            local dist, angle = utils.distFromTurret(target, turret)

            assert.near(math.sqrt(18), dist, 1e-9)
            assert.near(0.625, angle, 1e-9)
        end)
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("leftRightAngle", function()
        it("calculates left and right angles for north", function()
            local left, right = utils.leftRightAngle(defines.direction.north, 0.5)

            assert.near(0.75, left, 1e-9)
            assert.near(0.25, right, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates left and right angles for north-northeast", function()
            local left, right = utils.leftRightAngle(defines.direction.northnortheast, 0.25)

            assert.near(0.9375, left, 1e-9)
            assert.near(0.1875, right, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates left and right angles for northeast", function()
            local left, right = utils.leftRightAngle(defines.direction.northeast, 0.25)

            assert.near(0, left, 1e-9)
            assert.near(0.25, right, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates left and right angles for east-northeast", function()
            local left, right = utils.leftRightAngle(defines.direction.eastnortheast, 0.5)

            assert.near(0.9375, left, 1e-9)
            assert.near(0.4375, right, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates left and right angles for east", function()
            local left, right = utils.leftRightAngle(defines.direction.east, 0.5)

            assert.near(0, left, 1e-9)
            assert.near(0.5, right, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates left and right angles for east-southeast", function()
            local left, right = utils.leftRightAngle(defines.direction.eastsoutheast, 0.5)

            assert.near(0.0625, left, 1e-9)
            assert.near(0.5625, right, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates left and right angles for south", function()
            local left, right = utils.leftRightAngle(defines.direction.south, 0.5)

            assert.near(0.25, left, 1e-9)
            assert.near(0.75, right, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates left and right angles for west", function()
            local left, right = utils.leftRightAngle(defines.direction.west, 0.5)

            assert.near(0.5, left, 1e-9)
            assert.near(0, right, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates left and right angles for west-northwest", function()
            local left, right = utils.leftRightAngle(defines.direction.westnorthwest, 0.5)

            assert.near(0.5625, left, 1e-9)
            assert.near(0.0625, right, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates left and right angles for northwest", function()
            local left, right = utils.leftRightAngle(defines.direction.northwest, 0.25)

            assert.near(0.75, left, 1e-9)
            assert.near(0, right, 1e-9)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("calculates left and right angles for north-northwest", function()
            local left, right = utils.leftRightAngle(defines.direction.northnorthwest, 0.25)

            assert.near(0.8125, left, 1e-9)
            assert.near(0.0625, right, 1e-9)
        end)
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("directionToRealOrientation", function()
        it("converts every Factorio direction to a real orientation", function()
            for dir, val in pairs(defines.direction) do
                assert.are.equal(val * 0.0625, utils.directionToRealOrientation(defines.direction[dir]), dir)
            end
        end)
    end)
end)