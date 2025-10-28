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
    storage.forces = {}
end

function TestForce:test_onForceCreated_exists()
    lu.assertNotIsNil(force.onForceCreated)
    lu.assertEquals('function', type(force.onForceCreated))
end
-- ###############################################################

function TestForce:test_onForcesMerged_exists()
    lu.assertNotIsNil(force.onForcesMerged)
    lu.assertEquals('function', type(force.onForcesMerged))
end
-- ###############################################################

function TestForce:test_onForceReset_exists()
    lu.assertNotIsNil(force.onForceReset)
    lu.assertEquals('function', type(force.onForceReset))
end
-- ###############################################################

function TestForce:test_onForceCreated_with_mock_event()
    -- Mock ein Force-Creation Event
    local mockEvent = {
        force = {
            name = "test-force",
            index = 1,
            valid = true
        },
        tick = 100
    }

    force.onForceCreated(mockEvent)
end
-- ###############################################################

function TestForce:test_onForcesMerged_with_mock_event()
    -- mocked event
    local mockEvent = {
        source = "source-force",
        source_index = 1,
        destination = {
            name = "destination-force",
            index = 2,
            valid = true
        },
        tick = 200
    }

    force.onForcesMerged(mockEvent)
end
-- ###############################################################

function TestForce:test_onForceReset_with_mock_event()
    -- mocked event
    local mockEvent = {
        force = {
            name = "reset-force",
            index = 3,
            valid = true
        },
        tick = 300
    }

    force.onForceReset(mockEvent)
end
-- ###############################################################

function TestForce:test_force_module_structure()
    lu.assertEquals('table', type(force))

    -- check existence of functions
    local expectedFunctions = {
        'onForceCreated',
        'onForcesMerged', 
        'onForceReset'
    }
    
    for _, funcName in ipairs(expectedFunctions) do
        lu.assertNotIsNil(force[funcName], 
            string.format("function %s should exist", funcName))
        lu.assertEquals('function', type(force[funcName]),
            string.format("%s should be a function", funcName))
    end
end

BaseTest:hookTests()
