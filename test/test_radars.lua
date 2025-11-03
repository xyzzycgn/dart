---
--- Created by xyzzycgn.
--- DateTime: 27.10.25 
---
require('test.BaseTest')
local lu = require('luaunit')
local radars = require('scripts.entities.radars')
local constants = require('scripts.constants')

TestForce = {}

function TestForce:setUp()
    -- mock storage for tests
    storage = storage or {}
    storage.forces = {}
end

-- ###############################################################

local function factor(lvl)
    return 1 + constants.range_bonus[lvl]
end


function TestForce:test_addIncreaseBasedOnQuality()
    local expected = {
        8, 14, 18, 20, 21, 22,
        [0] = 0
    }

    -- mock RadarOnPlatform
    local rop = {
        radar = {
            valid = true,
            quality = {}
        }
    }

    for lvl, exp in pairs(expected) do
        rop.radar.quality.level = lvl

        local calc = radars.addIncreaseBasedOnQuality(rop, 0) -- wanna see the deltas
        lu.assertNotIsNil(calc, string.format("calc is nil for lvl=%d", lvl))
        lu.assertEquals(calc, exp, string.format("wrong calculation for lvl=%d", lvl))
    end
end
-- ###############################################################

function TestForce:test_calculateRangeBonus()
    local f1 = factor(1)
    local f2 = factor(2)
    local f3 = factor(3)

    local expected = {
        f1,
        f1 * f2,
        f1 * f2 * f3,
        -- lvl > 3 should use f3
        f1 * f2 * f3 * f3,
        f1 * f2 * f3 * f3 * f3,
        [0] = 1,
    }

    for lvl, exp in pairs(expected) do
        local calc = radars.calculateRangeBonus(lvl)
        lu.assertNotIsNil(calc, string.format("calc is nil for lvl=%d", lvl))
        lu.assertEquals(calc, exp, string.format("wrong calculation for lvl=%d", lvl))
    end
end
-- ###############################################################

function TestForce:test_module_structure()
    lu.assertEquals('table', type(radars))

    -- check existence of functions
    local expectedFunctions = {
        'calculateRangeBonus',
    }
    
    for _, fName in ipairs(expectedFunctions) do
        lu.assertNotIsNil(radars[fName], string.format("%s should exist", fName))
        lu.assertEquals('function', type(radars[fName]), string.format("%s should be a function", fName))
    end
end

BaseTest:hookTests()
