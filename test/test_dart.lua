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
        fccsOnPlatform = {},
    }
end

function TestDart:setUp()
    -- clear call count
    on_event_called = 0

    -- simulated (global) storage object
    storage = {
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


    rendering = {
        draw_animation = function()
            return "mocked Animation"
        end
    }

    -- mock the prototypes
    prototypes = {
        asteroid_chunk = {},
        entity = {
            ["gun-turret"] = {
                attack_parameters = {
                    range = 18
                }
            }
        }
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
        name = "dart-fcc",
        position = { 1, 2 },
        force = "A-Team",
        surface = {
            index = 2,
        },
        get_or_create_control_behavior = function()
            return "mocked CB"
        end
    }

    storage.platforms = {
        [2] = {
            turrets = {},
            fccsOnPlatform = {}
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

    local dart = storage.platforms[2].fccsOnPlatform[4711]
    lu.assertNotNil(dart)
    lu.assertEquals(dart.control_behavior, "mocked CB")
end
-- ###############################################################

local function createDart(valid)
    local dart = {
        radar_un = 4711,
        radar =  {
            valid = valid,
        },
    }

    return dart
end

local function entityRemovedWithValidOutput(valid, expected)
    -- prepare storage entries
    init_storagePlatforms()

    local radarAndOutput = createDart(valid)
    storage.platforms[2].fccsOnPlatform[4711] = radarAndOutput

    -- mock entity in event
    local entity = {
        unit_number = 4711,
        name = "dart-fcc",
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

    lu.assertNil(storage.platforms[2].fccsOnPlatform[4711])
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
    local platform = {
        index = 4711,
        force = {
            players = {
                [1] = { index = 3 }
            }
        }
    }
    local surface = { platform = platform, index = 2 }


    game.surfaces[event.surface_index] = surface

    storage.players[3] = { pons = {} }

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

-- TODO function to test is local and not reachable from here and no longer called from dart.events - make it global?
--function TestDart:test_surfaceDeleted()
--    -- simulate event and old platform
--    local event = {
--        entity = {
--            type = "space-platform-hub"
--        }
--    }
--
--    init_storagePlatforms()
--
--    -- test
--    dart.events[defines.events.on_pre_surface_deleted](event)
--
--    lu.assertEquals(getTableSize(storage.platforms), 0)
--end
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
            index = 2,     -- index of surface
            platform = {
                index = 1, -- index of platform
                force = {
                    players = {
                        { index = 1 } -- index of player
                    }
                }
            },
            find_entities_filtered = function()
                return {
                    tur1 = {
                        unit_number = 4711,
                        get_or_create_control_behavior = function()
                            return "simulated CB"
                        end,
                        name = "gun-turret"
                    }
                }
            end
        }
    }

    dart.on_init()

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
end
-- ###############################################################

function TestDart:test_on_load()
    dart.on_load()

    lu.assertEquals(on_event_called, 3)
end
-- ###############################################################

function TestDart:test_on_config_changed()
    -- here we start with a filled storage
    storage.player = { set = true }

    dart.on_configuration_changed()

    -- storage should be unchanged
    lu.assertNotNil(storage.player)
    lu.assertTrue(storage.player.set)

    lu.assertEquals(on_event_called, 0)
end
-- ###############################################################

BaseTest:hookTests()


