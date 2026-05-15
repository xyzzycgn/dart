---
--- Created by xyzzycgn.
---
local Require = require("test.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)

require("spec.common")
serpent = require("serpent") -- must be global

describe("Radars", function()
    local radars
    local constants

    setup(function()
        radars = require("scripts.entities.radars")
        constants = require("scripts.constants")
    end)

    before_each(function()
        -- Mock storage for tests.
        storage.forces = {}
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    local function factor(level)
        return 1 + constants.range_bonus[level]
    end

    describe("addIncreaseBasedOnQuality", function()
        it("calculates the range increase for each quality level", function()
            local expected = {
                8, 14, 18, 20, 21, 22,
                [0] = 0
            }

            -- Mock RadarOnPlatform.
            local rop = {
                radar = {
                    valid = true,
                    quality = {}
                }
            }

            for level, expectedValue in pairs(expected) do
                rop.radar.quality.level = level

                local result = radars.addIncreaseBasedOnQuality(rop, 0) -- Use zero to verify the delta values.

                assert.is_not_nil(result, string.format("result is nil for level=%d", level))
                assert.are.equal(expectedValue, result, string.format("wrong calculation for level=%d", level))
            end
        end)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("calculateRangeBonus", function()
        it("calculates the cumulative range bonus for each technology level", function()
            local f1 = factor(1)
            local f2 = factor(2)
            local f3 = factor(3)

            local expected = {
                f1,
                f1 * f2,
                f1 * f2 * f3,
                -- Levels above 3 should use the level 3 factor.
                f1 * f2 * f3 * f3,
                f1 * f2 * f3 * f3 * f3,
                [0] = 1,
            }

            for level, expectedValue in pairs(expected) do
                local result = radars.calculateRangeBonus(level)

                assert.is_not_nil(result, string.format("result is nil for level=%d", level))
                assert.are.equal(expectedValue, result, string.format("wrong calculation for level=%d", level))
            end
        end)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("module structure", function()
        it("exports the expected functions", function()
            assert.are.equal("table", type(radars))

            -- Check existence of functions.
            local expectedFunctions = {
                "calculateRangeBonus",
                "addIncreaseBasedOnQuality",
            }

            for _, functionName in ipairs(expectedFunctions) do
                assert.is_not_nil(radars[functionName], string.format("%s should exist", functionName))
                assert.are.equal("function", type(radars[functionName]), string.format("%s should be a function", functionName))
            end
        end)
    end)
end)
