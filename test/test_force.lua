---
--- Created by xyzzycgn.
--- DateTime: 27.10.25 
---
require('test.BaseTest')
local lu = require('lib.luaunit')
local force = require('scripts.events.force')

TestForce = {}

function TestForce:setUp()
    -- mock storage for tests
    storage = storage or {}
    storage.forces = {
        { techLevel = 0 },
        { techLevel = 1 }
    }
end

-- ###############################################################

function TestForce:test_onForceCreated()
    -- Mock ein Force-Creation Event
    local mockEvent = {
        name = defines.events.on_force_created,
        force = {
            name = "test-force",
            index = 3,
            valid = true
        },
        tick = 100
    }

    local expected = {
        { techLevel = 0 },
        { techLevel = 1 },
        { techLevel = 0 }
    }
    force.onForceCreated(mockEvent)
    lu.assertEquals(storage.forces, expected)
end
-- ###############################################################

function TestForce:test_onForcesMerged()
    -- mocked event
    local mockEvent = {
        name = defines.events.on_forces_merged,
        source = "source-force",
        source_index = 1,
        destination = {
            name = "destination-force",
            index = 2,
            valid = true
        },
        tick = 200
    }

    local expected = {
       [2] = { techLevel = 1 },
    }
    force.onForcesMerged(mockEvent)
    lu.assertEquals(storage.forces, expected)
end
-- ###############################################################

function TestForce:test_onForceReset()
    -- mocked event
    local mockEvent = {
        name = defines.events.on_force_reset,
        force = {
            name = "reseted-force",
            index = 2,
            valid = true
        },
        tick = 300
    }
    local expected = {
        { techLevel = 0 },
        { techLevel = 0 }
    }

    force.onForceReset(mockEvent)
    lu.assertEquals(storage.forces, expected)
end
-- ###############################################################

function TestForce:test_onForceReset_forceunknown()
    -- mocked event
    local mockEvent = {
        name = defines.events.on_force_reset,
        force = {
            name = "reseted-force",
            index = 3,
            valid = true
        },
        tick = 300
    }
    local expected = {
        { techLevel = 0 },
        { techLevel = 1 }
    }

    force.onForceReset(mockEvent)
    lu.assertEquals(storage.forces, expected)
end
-- ###############################################################

function TestForce:test_module_structure()
    lu.assertEquals('table', type(force))

    -- check existence of functions
    local expectedFunctions = {
        'onForceCreated',
        'onForcesMerged', 
        'onForceReset'
    }
    
    for _, funcName in ipairs(expectedFunctions) do
        lu.assertNotIsNil(force[funcName], string.format("%s should exist", funcName))
        lu.assertEquals('function', type(force[funcName]), string.format("%s should be a function", funcName))
    end
end

BaseTest:hookTests()
