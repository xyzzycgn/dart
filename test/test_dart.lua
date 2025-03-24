---
--- Created by xyzzycgn.
--- DateTime: 23.12.24 16:43
---
require('test.BaseTest')
local lu = require('lib.luaunit')

require('factorio_def')
local dart = require('scripts.dart')
local serpent = require('lib.serpent')


TestDart = {}
local on_event_called = 0


function TestDart:setUp()
    -- clear call count
    on_event_called = 0

    -- simulated (global) storage object
    storage = {
        dart = {}
    }
    -- and the player
    player = {}

    -- mock the game object
    game = {
        surfaces = {}
    }
    --game.tick = 4711
    --game.connected_players = {}

    -- mock the prototypes
    prototypes = {
        asteroid_chunk = {}
    }

    -- mock the script object
    script.on_event = function()
        on_event_called = on_event_called + 1
    end
end

function TestDart:test_entityCreated()
    -- mock dart-radar
    local entity = {
        valid = true,
        unit_number = 4711,
        name = "dart-radar",
        position = { 1, 2 },
        force = "A-Team",
        surface = {
            create_entity = function(arg)
                lu.assertEquals(arg.name, "dart-output")
                lu.assertEquals(arg.position, { 1, 2 })
                lu.assertEquals(arg.force, "A-Team")

                return {
                    unit_number = 0815,
                    get_or_create_control_behavior = function()
                        return "mocked CB"
                    end
                }
            end
        }
    }

    -- mock event
    local event = {
        entity = entity,
    }

    -- test
    local eventhandler =  dart.events[defines.events.on_space_platform_built_entity]
    lu.assertEquals(type(eventhandler), "function")

    eventhandler(event)

    lu.assertNotNil(storage.dart[0815])
    lu.assertNotNil(storage.dart[4711])
end
-- ###############################################################

local called_destroy = 0

local function createDart(valid)
    called_destroy = 0
    local dart = {
        radar_un = 4711,
        output_un = 0815,
        output =  {
            valid = valid,
            destroy = function()
                called_destroy = called_destroy + 1
            end
        },
    }

    return dart
end

local function entityRemovedWithValidOutput(valid, expected)
    -- prepare storage entries
    local dartarray = createDart(valid)
    storage.dart[4711] = dartarray
    storage.dart[0815] = dartarray

    -- mock entity in event
    local entity = {
        unit_number = 4711
    }
    -- mock event
    local event = {
        entity = entity,
    }

    -- test
    local eventhandler =  dart.events[defines.events.script_raised_destroy]
    lu.assertEquals(type(eventhandler), "function")

    eventhandler(event)

    lu.assertNil(storage.dart[0815])
    lu.assertNil(storage.dart[4711])
    lu.assertEquals(called_destroy, expected)
end

function TestDart:test_entityRemovedWithValidOutput()
    entityRemovedWithValidOutput(true, 1)
end

function TestDart:test_entityRemovedWithInvalidOutput()
    entityRemovedWithValidOutput(false, 0)
end
-- ###############################################################

function TestDart:test_on_init()
    -- here we start with an empty storage
    storage = {}

    dart.on_init()

    lu.assertNotNil(storage.dart)
    lu.assertNotNil(storage.players)
    lu.assertEquals(on_event_called, 5)
end
-- ###############################################################

function TestDart:test_on_load()
    dart.on_load()

    lu.assertNotNil(storage.dart)
    lu.assertEquals(on_event_called, 5)
end
-- ###############################################################

function TestDart:test_on_config_changed()
    -- here we start with a filled storage
    storage.player = { set = true }
    storage.dart.set = true

    dart.on_configuration_changed()

    -- storage should be unchanged
    lu.assertNotNil(storage.dart)
    lu.assertTrue(storage.dart.set)
    lu.assertNotNil(storage.player)
    lu.assertTrue(storage.player.set)

    lu.assertEquals(on_event_called, 0)
end
-- ###############################################################

BaseTest:hookTests()


