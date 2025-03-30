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

---  utility function to get size of table
local function getTableSize(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

local function init_storagePlatforms()
    local platform = { index = 4711 }
    local surface = { platform = platform, index = 2 }
    storage.platforms[2] = {
        surface = surface,
        platform = platform,
        dartsOnPlatform = {},
    }
end

function TestDart:setUp()
    -- clear call count
    on_event_called = 0

    -- simulated (global) storage object
    storage = {
        dart = {},
        players = {},
        platforms = {},
    }
    -- and the player
    player = {}

    -- mock the game object
    game = {
        surfaces = {},
        platforms = {}
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
-- ###############################################################

function TestDart:test_entityCreated()
    -- mock dart-radar
    local entity = {
        valid = true,
        unit_number = 4711,
        name = "dart-radar",
        position = { 1, 2 },
        force = "A-Team",
        surface = {
            index = 2,
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

    storage.platforms = {
        [2] = {
            turrets = {},
            dartsOnPlatform = {}
        }
    }

    -- mock event
    local event = {
        entity = entity,
    }

    -- test
    local eventhandler = dart.events[defines.events.on_entity_cloned]
    lu.assertEquals(type(eventhandler), "function")
    eventhandler(event)

    local dart = storage.platforms[2].dartsOnPlatform[4711]
    lu.assertNotNil(dart)
    lu.assertEquals(dart.control_behavior, "mocked CB")
    local out = dart.output
    lu.assertNotNil(out)
    lu.assertEquals(out.unit_number, 0815)
    local out = storage.platforms[2].dartsOnPlatform[0815]
    lu.assertEquals(out, dart)
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
    init_storagePlatforms()

    local radarAndOutput = createDart(valid)
    storage.platforms[2].dartsOnPlatform[4711] = radarAndOutput
    storage.platforms[2].dartsOnPlatform[0815] = radarAndOutput

    -- mock entity in event
    local entity = {
        unit_number = 4711,
        surface = {
            index = 2
        }
    }
    -- mock event
    local event = {
        entity = entity,
    }

    -- test
    local eventhandler =  dart.events[defines.events.script_raised_destroy]
    lu.assertEquals(type(eventhandler), "function")

    eventhandler(event)

    lu.assertNil(storage.platforms[2].dartsOnPlatform[0815])
    lu.assertNil(storage.platforms[2].dartsOnPlatform[4711])
    lu.assertEquals(called_destroy, expected)
end

function TestDart:test_entityRemovedWithValidOutput()
    entityRemovedWithValidOutput(true, 1)
end

function TestDart:test_entityRemovedWithInvalidOutput()
    entityRemovedWithValidOutput(false, 0)
end
-- ###############################################################

function TestDart:test_surfaceCreatedNoPlatform()
    local event = {
        surface_index = 2
    }
    game.surfaces[event.surface_index] = {}

    -- test
    dart.events[defines.events.on_surface_created](event)

    lu.assertEquals(getTableSize(storage.platforms), 0)
end
-- ###############################################################

function TestDart:test_surfaceCreatedPlatform()
    -- simulate event and new platform
    local event = {
        surface_index = 2
    }
    local platform = { index = 4711}
    local surface = { platform = platform, index = 2 }


    game.surfaces[event.surface_index] = surface

    -- test
    dart.events[defines.events.on_surface_created](event)

    lu.assertEquals(getTableSize(storage.platforms), 1)
    local pons = storage.platforms[2]
    lu.assertNotNil(pons)
    lu.assertEquals(pons.surface, surface)
    lu.assertEquals(pons.platform, platform)
    lu.assertEquals(pons.turretsOnPlatform, {})
    lu.assertEquals(pons.knownAsteroids, {})
end
-- ###############################################################

function TestDart:test_surfaceDeleted()
    -- simulate event and old platform
    local event = {
        surface_index = 2
    }

    init_storagePlatforms()

    -- test
    dart.events[defines.events.on_pre_surface_deleted](event)

    lu.assertEquals(getTableSize(storage.platforms), 0)
end
-- ###############################################################

function TestDart:test_on_init()
    -- here we start with an empty storage
    storage = {}
    -- simulate 2 surfaces, one of them a platform with a turret
    game.surfaces ={
        nauvis = {
            index = 1,
        },
        platform_1 =  {
            index = 2,
            platform = {},
            find_entities_filtered = function()
                return {
                    tur1 = {
                        unit_number = 4711,
                        get_or_create_control_behavior = function()
                            return "simulated CB"
                        end
                    }
                }
            end
        }
    }

    dart.on_init()

    lu.assertNotNil(storage.dart)
    lu.assertNotNil(storage.players)
    lu.assertEquals(on_event_called, 3)

    -- check results from call of searchDartInfrastructure()
    lu.assertEquals(getTableSize(storage.platforms), 1)
    local plat = storage.platforms[2]
    lu.assertNotNil(plat)
    lu.assertEquals(getTableSize(plat.turretsOnPlatform), 1)
    local tur = plat.turretsOnPlatform[4711]
    lu.assertNotNil(tur)
    lu.assertEquals(tur.control_behavior, "simulated CB")
    lu.assertEquals(tur.targets_of_turret, {})
end
-- ###############################################################

function TestDart:test_on_load()
    dart.on_load()

    lu.assertNotNil(storage.dart)
    lu.assertEquals(on_event_called, 3)
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


