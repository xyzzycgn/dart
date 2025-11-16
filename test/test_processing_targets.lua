---
--- Created by xyzzycgn.
--- DateTime: 03.11.25 16:00
---
require('test.BaseTest')
local lu = require('luaunit')

require('factorio_def')
local processing_targets = require("scripts.processing_targets")

-- Helper function to create mock asteroid entities
local function createMockedPrototype(asteroidType)
    return { name = asteroidType .. "-asteroid", }
end

-- Helper function to create mock asteroid entities
local function createMockedAsteroid(asteroidType, unitNumber, x, y)
    return {
        type = "asteroid",
        unit_number = unitNumber,
        valid = true,
        prototype = createMockedPrototype(asteroidType),
        position = { x = x, y = y }
    }
end

TestProcessingTargets = {}
local on_event_called = 0
local raised_events = {}

local function createCircuitCondition(type, name)
    return {
        first_signal = { type = type, name = name },
        comparator = ">",
        constant = 0
    }
end


function TestProcessingTargets:setUp()
    -- clear call count
    on_event_called = 0
    raised_events = {}

    -- simulated (global) storage object
    storage = {}

    -- mock the script object
    script.raise_event = function(event_type, event_data)
        on_event_called = on_event_called + 1
        raised_events[#raised_events + 1] = { event_type = event_type, event_data = event_data }
    end

    -- mock global events
    on_target_assigned_event = 1
    on_target_unassigned_event = 2
end
-- ###############################################################

function TestProcessingTargets:test_targeting_miss()
    local pons = {
        platform = {
            speed = 0
        },
        radarsOnPlatform = {
            [1] = {
                radar = {
                    position = { x = 0, y = 0 }
                },
                defenseRange = 50
            }
        }
    }

    local asteroid = {
        position = { x = 100, y = 100 },
        movement = { x = 1, y = 0 }
    }

    local D = processing_targets.targeting(pons, asteroid)

    lu.assertTrue(D < 0)
end
-- ###############################################################

function TestProcessingTargets:test_targeting_hit()
    local pons = {
        platform = {
            speed = 0
        },
        radarsOnPlatform = {
            [1] = {
                radar = {
                    position = { x = 0, y = 0 }
                },
                defenseRange = 50
            }
        }
    }

    local asteroid = {
        position = { x = 40, y = 0 },
        movement = { x = -1, y = 0 }
    }

    local D = processing_targets.targeting(pons, asteroid)

    lu.assertTrue(D > 0)
end
-- ###############################################################

function TestProcessingTargets:test_targeting_graze()
    local pons = {
        platform = {
            speed = 0
        },
        radarsOnPlatform = {
            [1] = {
                radar = {
                    position = { x = 0, y = 0 }
                },
                defenseRange = 50
            }
        }
    }

    local asteroid = {
        position = { x = 50, y = 50 },
        movement = { x = 0, y = -1 }
    }

    local D = processing_targets.targeting(pons, asteroid)

    lu.assertTrue(D >= 0)
end
-- ###############################################################

function TestProcessingTargets:test_targeting_multiple_radars_one_hit()
    local pons = {
        platform = {
            speed = 0
        },
        radarsOnPlatform = {
            [1] = {
                radar = {
                    position = { x = 0, y = 0 }
                },
                defenseRange = 20
            },
            [2] = {
                radar = {
                    position = { x = 100, y = 0 }
                },
                defenseRange = 50
            }
        }
    }

    local asteroid = {
        position = { x = 130, y = 0 },
        movement = { x = -1, y = 0 }
    }

    local D = processing_targets.targeting(pons, asteroid)

    lu.assertTrue(D > 0)
end
-- ###############################################################

function TestProcessingTargets:test_calculatePrio_in_range()
    local turret = {
        position = { x = 0, y = 0 },
        unit_number = 1   }

    local managedTurrets = {
        [1] = {
            turret = turret,
            range = 20,
            priority_targets_list = {},
            targets_of_turret = {}
        }
    }

    local target = {
        unit_number = 4711,
        position = { x = 10, y = 0 },
        prototype = {
            name = "LuaEntityPrototype-asteroid"
        }
    }

    processing_targets.addToTargetList(managedTurrets, target, 1)

    lu.assertNotNil(managedTurrets[1].targets_of_turret[4711])
    lu.assertAlmostEquals(managedTurrets[1].targets_of_turret[4711].distance, 10, 0.001)
end
-- ###############################################################

function TestProcessingTargets:test_calculatePrio_out_of_range()
    local turret = {
        position = { x = 0, y = 0 },
        unit_number = 1
    }

    local managedTurrets = {
        [1] = {
            turret = turret,
            range = 10,
            targets_of_turret = {},
            priority_targets_list = {}
        }
    }

    local target = {
        unit_number = 4711,
        position = { x = 20, y = 0 },
        prototype = {
            name = "LuaEntityPrototype-asteroid"
        }
    }

    processing_targets.addToTargetList(managedTurrets, target, 1)

    lu.assertNil(managedTurrets[1].targets_of_turret[4711])
end
-- ###############################################################

function TestProcessingTargets:test_calculatePrio_not_hitting()
    local turret = {
        position = { x = 0, y = 0 },
        unit_number = 1
    }

    local managedTurrets = {
        [1] = {
            turret = turret,
            range = 20,
            targets_of_turret = {},
            priority_targets_list = {}
        }
    }

    local target = {
        unit_number = 4711,
        position = { x = 10, y = 0 },
        prototype = {
            name = "LuaEntityPrototype-asteroid"
        }
    }

    processing_targets.addToTargetList(managedTurrets, target, -1)

    lu.assertNil(managedTurrets[1].targets_of_turret[4711])
end
-- ###############################################################

function TestProcessingTargets:test_calculatePrio_removes_out_of_range()
    local turret = {
        position = { x = 0, y = 0 },
        unit_number = 1
    }

    local managedTurrets = {
        [1] = {
            turret = turret,
            range = 20,
            targets_of_turret = {
                [4711] = {
                    distance = 10,
                    is_priority_target = false
                }
            },
            priority_targets_list = {}
        }
    }

    local target = {
        unit_number = 4711,
        position = { x = 30, y = 0 },
        prototype = {
            name = "LuaEntityPrototype-asteroid"
        }
    }

    processing_targets.addToTargetList(managedTurrets, target, 1)

    lu.assertNil(managedTurrets[1].targets_of_turret[4711])
end
-- ###############################################################

function TestProcessingTargets:test_assignTargets_single_turret_multiple_targets()
    local turret = {
        unit_number = 1,
        position = { x = 0, y = 0 }
    }

    local lls = {
        filters = {}
    }

    local fcc = {
        unit_number = 10,
        control_behavior = {
            get_section = function(_)
                return lls
            end
        }
    }

    local managedTurrets = {
        [1] = {
            turret = turret,
            fcc = fcc,
            targets_of_turret = {
                [4711] = {
                    distance = 15,
                    is_priority_target = false
                },
                [4712] = {
                    distance = 25,
                    is_priority_target = false
                },
            },
            circuit_condition = createCircuitCondition("item", "iron-ore")
        }
    }

    local asteroid1 = {
        unit_number = 4711,
        name = "small-metallic-asteroid"
    }
    local asteroid2 = {
        unit_number = 4712,
        name = "small-carbonic-asteroid"
    }

    local knownAsteroids = {
        [4711] = { entity = asteroid1 },
        [4712] = { entity = asteroid2 }
    }

    local pons = {
        fccsOnPlatform = {
            [10] = fcc
        }
    }

    processing_targets.assignTargets(pons, knownAsteroids, managedTurrets)

    lu.assertEquals(turret.shooting_target, asteroid1)
    lu.assertEquals(on_event_called, 1)
    lu.assertEquals(raised_events[1].event_type, on_target_assigned_event)
    lu.assertEquals(raised_events[1].event_data.tun, 1)
    lu.assertEquals(raised_events[1].event_data.target, 4711)
    lu.assertEquals(lls, { filters={
        {min = 1, value = {name = "iron-ore",   quality = "normal", type = "item"}}
    }})
end
-- ###############################################################

function TestProcessingTargets:test_assignTargets_no_targets()
    local turret = {
        unit_number = 1,
        position = { x = 0, y = 0 },
        shooting_target = {}
    }

    local lls = {
        filters = {}
    }

    local fcc = {
        unit_number = 10,
        control_behavior = {
            get_section = function(_)
                return lls
            end
        }
    }

    local managedTurrets = {
        [1] = {
            turret = turret,
            fcc = fcc,
            targets_of_turret = {},
            circuit_condition = createCircuitCondition("item", "iron-ore")
        }
    }

    local knownAsteroids = {}

    local pons = {
        fccsOnPlatform = {
            [10] = fcc
        }
    }

    processing_targets.assignTargets(pons, knownAsteroids, managedTurrets)

    lu.assertNil(turret.shooting_target)
    lu.assertEquals(on_event_called, 1)
    lu.assertEquals(raised_events[1].event_type, on_target_unassigned_event)
    lu.assertEquals(raised_events[1].event_data.tun, 1)
   lu.assertEquals(lls, { filters = {}})
end
-- ###############################################################

function TestProcessingTargets:test_assignTargets_multiple_turrets_multiple_targets()
    local turret1 = {
        unit_number = 1,
        position = { x = 0, y = 0 }
    }

    local turret2 = {
        unit_number = 2,
        position = { x = 10, y = 0 }
    }

    local lls = {
        filters = {}
    }

    local fcc = {
        unit_number = 10,
        control_behavior = {
            get_section = function(_)
                return lls
            end
        }
    }

    local managedTurrets = {
        [1] = {
            turret = turret1,
            fcc = fcc,
            targets_of_turret = {
                [4711] = {
                    distance = 10,
                    is_priority_target = false
                },
            },
            circuit_condition = createCircuitCondition("item", "iron-ore")
        },
        [2] = {
            turret = turret2,
            fcc = fcc,
            targets_of_turret = {
                [4712] = {
                    distance = 20,
                    is_priority_target = false
                },
            },
            circuit_condition = createCircuitCondition("item", "copper-ore")
        }
    }

    local asteroid1 = {
        unit_number = 4711,
        name = "small-metallic-asteroid"
    }
    local asteroid2 = {
        unit_number = 4712,
        name = "small-carbonic-asteroid"
    }
    local asteroid3 = {
        unit_number = 4713,
        name = "small-carbonic-asteroid"
    }

    local knownAsteroids = {
        [4711] = { entity = asteroid1 },
        [4712] = { entity = asteroid2 },
        [4713] = { entity = asteroid3 }
    }

    local pons = {
        fccsOnPlatform = {
            [10] = fcc
        }
    }

    processing_targets.assignTargets(pons, knownAsteroids, managedTurrets)

    lu.assertEquals(turret1.shooting_target, asteroid1)
    lu.assertEquals(turret2.shooting_target, asteroid2)
    lu.assertEquals(on_event_called, 2)
    lu.assertEquals(lls, { filters={
        {min = 1, value = {name = "copper-ore", quality = "normal", type = "item"}},
        {min = 1, value = {name = "iron-ore",   quality = "normal", type = "item"}}
    }})
end
-- ###############################################################

-- tests that priority targets are added to target list if ignore_unprioritised_targets is set
function TestProcessingTargets:test_addToTargetList_only_priority_targets()
    local target = createMockedAsteroid("metallic", 11, 4, 3)

    local asteroid_prototype = createMockedPrototype("metallic")
    local turret1 = {
        unit_number = 11,
        -- only metallic asteroids are priority
        priority_targets = {
            [1] = asteroid_prototype
        },
        position = { x = 0, y = 0 },
        ignore_unprioritised_targets = true
    }

    local managedTurrets = {
        [1] = {
            turret = turret1,
            targets_of_turret = {},
            range = 18,
            priority_targets_list = {
                [asteroid_prototype.name] = true
            }
        }
    }

    processing_targets.addToTargetList(managedTurrets, target, 5)

    lu.assertEquals(managedTurrets[1].targets_of_turret, { [11] = { distance = 5, is_priority_target = true }}, "Metallic asteroid should be marked as priority target")
end
-- ###############################################################

-- tests that non-priority targets are not added to target list if ignore_unprioritised_targets is set
function TestProcessingTargets:test_addToTargetList_only_priority_targets_ignore_not_on_list()
    local target = createMockedAsteroid("oxide", 11, 10, 10)

    local asteroid_prototype = createMockedPrototype("metallic")
    local turret1 = {
        unit_number = 11,
        -- only metallic asteroids are priority
        priority_targets = {
            [1] = asteroid_prototype
        },
        position = { x = 0, y = 0 },
        ignore_unprioritised_targets = true
    }

    local managedTurrets = {
        [1] = {
            turret = turret1,
            targets_of_turret = {},
            range = 18,
            priority_targets_list = {
                [asteroid_prototype.name] = true
            }
        }
    }

    processing_targets.addToTargetList(managedTurrets, target, 5)

    lu.assertEquals(managedTurrets[1].targets_of_turret, {}, "Oxide asteroid should not be marked target")
end
-- ###############################################################

-- tests that non priority targets are added to target list if ignore_unprioritised_targets is not set
function TestProcessingTargets:test_addToTargetList_non_prioritised_target()
    local target = createMockedAsteroid("oxide", 11, 3, 4)

    local asteroid_prototype = createMockedPrototype("metallic")
    local turret1 = {
        unit_number = 11,
        -- only metallic asteroids are priority
        priority_targets = {
            [1] = asteroid_prototype
        },
        position = { x = 0, y = 0 },
        ignore_unprioritised_targets = false
    }

    local managedTurrets = {
        [1] = {
            turret = turret1,
            targets_of_turret = {},
            range = 18,
            priority_targets_list = {
                [asteroid_prototype.name] = true
            }
        }
    }

    processing_targets.addToTargetList(managedTurrets, target, 5)

    lu.assertEquals(managedTurrets[1].targets_of_turret, { [11] = { distance = 5, is_priority_target = false }},
                    "non prio asteroid should be added")
end
-- ###############################################################

-- tests that priority targets are added to target list if ignore_unprioritised_targets is not set
function TestProcessingTargets:test_addToTargetList_prioritised_target()
    local target = createMockedAsteroid("metallic", 11, 3, 4)

    local asteroid_prototype = createMockedPrototype("metallic")
    local turret1 = {
        unit_number = 11,
        -- only metallic asteroids are priority
        priority_targets = {
            [1] = asteroid_prototype
        },
        position = { x = 0, y = 0 },
        ignore_unprioritised_targets = false
    }

    local managedTurrets = {
        [1] = {
            turret = turret1,
            targets_of_turret = {},
            range = 18,
            priority_targets_list = {
                [asteroid_prototype.name] = true
            }
        }
    }

    processing_targets.addToTargetList(managedTurrets, target, 5)

    lu.assertEquals(managedTurrets[1].targets_of_turret, { [11] = { distance = 5, is_priority_target = true }},
                    "prio asteroid should be added")
end
-- ###############################################################

-- tests that priority targets is removed from target list if no longer hitting
function TestProcessingTargets:test_addToTargetList_remove_prioritised_target()
    local target = createMockedAsteroid("metallic", 11, 3, 4)

    local asteroid_prototype = createMockedPrototype("metallic")
    local turret1 = {
        unit_number = 11,
        -- only metallic asteroids are priority
        priority_targets = {
            [1] = asteroid_prototype
        },
        position = { x = 0, y = 0 },
        ignore_unprioritised_targets = false
    }

    local managedTurrets = {
        [1] = {
            turret = turret1,
            targets_of_turret = {
                [11] = { distance = 15, is_priority_target = true }
            },
            range = 18,
            priority_targets_list = {
                [asteroid_prototype.name] = true
            }
        }
    }

    processing_targets.addToTargetList(managedTurrets, target, -5)

    lu.assertEquals(managedTurrets[1].targets_of_turret, {}, "prio asteroid should be removed")
end
-- ###############################################################

-- test with priority_targets set but ignore_unprioritised_targets = false
function TestProcessingTargets:test_assignTargets_with_priority_targets_and_ignore_disabled()
    local lls = {
        filters = {}
    }

    local fcc = {
        unit_number = 1000,
        control_behavior = {
            get_section = function(_)
                return lls
            end
        }
    }

    local pons = {
        platform = { name = "test" },
        fccsOnPlatform = {
            [1000] = fcc
        }
    }

    local asteroid_prototype = createMockedPrototype("metallic")
    local asteroid1 = createMockedAsteroid("metallic", 10)
    local asteroid2 = createMockedAsteroid("oxide", 11)
    local asteroid3 = createMockedAsteroid("metallic", 12)

    local knownAsteroids = {
        [10] = { entity = asteroid1 },
        [11] = { entity = asteroid2 },
        [12] = { entity = asteroid3 }
    }

    local turret1 = {
        unit_number = 100,
        targets_of_turret = {},
        -- only metallic asteroids are priority
        priority_targets = {
            [1] = asteroid_prototype
        },
        ignore_unprioritised_targets = false
    }

    local managedTurrets = {
        [1] = {
            turret = turret1,
            fcc = fcc,
            targets_of_turret = {
                [10] = {
                    distance = 10,
                    is_priority_target = true
                },
                [11] = {
                    distance = 5,
                    is_priority_target = false
                },
                [12] = {
                    distance = 7,
                    is_priority_target = true
                },
            },
            circuit_condition = createCircuitCondition("item", "iron-ore"),
            priority_targets_list = {
                [asteroid_prototype.name] = true
            }
        },

    }

    processing_targets.assignTargets(pons, knownAsteroids, managedTurrets)

    lu.assertEquals(turret1.shooting_target, asteroid3)
    lu.assertEquals(on_event_called, 1)
    lu.assertEquals(lls, { filters={
        {min = 1, value = {name = "iron-ore", quality = "normal", type = "item"}}
    }})
end
-- ###############################################################

-- test with priority_targets set but ignore_unprioritised_targets = true
function TestProcessingTargets:test_assignTargets_with_priority_targets_and_ignore_nonprio()
    local lls = {
        filters = {}
    }

    local fcc = {
        unit_number = 1000,
        control_behavior = {
            get_section = function(_)
                return lls
            end
        }
    }

    local pons = {
        platform = { name = "test" },
        fccsOnPlatform = {
            [1000] = fcc
        }
    }

    local asteroid_prototype = createMockedPrototype("metallic")
    local asteroid1 = createMockedAsteroid("metallic", 10)
    local asteroid2 = createMockedAsteroid("metallic", 11)

    local knownAsteroids = {
        [10] = { entity = asteroid1 },
        [11] = { entity = asteroid2 }
    }

    local turret1 = {
        unit_number = 100,
        targets_of_turret = {},
        priority_targets = {
            [1] = asteroid_prototype
        },
        ignore_unprioritised_targets = true
    }

    local managedTurrets = {
        [1] = {
            turret = turret1,
            fcc = fcc,
            targets_of_turret = {
                [10] = {
                    distance = 10,
                    is_priority_target = true
                },
                [11] = {
                    distance = 5,
                    is_priority_target = true
                },
            },
            circuit_condition = createCircuitCondition("item", "iron-ore"),
            priority_targets_list = {
                [asteroid_prototype.name] = true
            }
        },

    }

    processing_targets.assignTargets(pons, knownAsteroids, managedTurrets)

    lu.assertEquals(turret1.shooting_target, asteroid2)
    lu.assertEquals(on_event_called, 1)
    lu.assertEquals(raised_events[1].event_type, on_target_assigned_event)
    lu.assertEquals(raised_events[1].event_data.tun, 100)
    lu.assertEquals(raised_events[1].event_data.target, 11)
    lu.assertEquals(lls, { filters={
        {min = 1, value = {name = "iron-ore", quality = "normal", type = "item"}}
    }})
end
-- ###############################################################

function TestProcessingTargets:test_assignTargets_sorting_by_distance()
    local turret = {
        unit_number = 1,
        position = { x = 0, y = 0 }
    }

    local lls = {
        filters = {}
    }

    local fcc = {
        unit_number = 10,
        control_behavior = {
            get_section = function(_)
                return lls
            end
        }
    }

    local managedTurrets = {
        [1] = {
            turret = turret,
            fcc = fcc,
            targets_of_turret = {
                [4711] = {
                    distance = 30,
                    is_priority_target = false
                },
                [4712] = {
                    distance = 10,
                    is_priority_target = false
                },
                [4713] = {
                    distance = 20,
                    is_priority_target = false
                },
            },
            circuit_condition = createCircuitCondition("item", "iron-ore")
        }
    }

    local asteroid1 = { unit_number = 4711, name = "asteroid1" }
    local asteroid2 = { unit_number = 4712, name = "asteroid2" }
    local asteroid3 = { unit_number = 4713, name = "asteroid3" }

    local knownAsteroids = {
        [4711] = { entity = asteroid1 },
        [4712] = { entity = asteroid2 },
        [4713] = { entity = asteroid3 }
    }

    local pons = {
        fccsOnPlatform = {
            [10] = fcc
        }
    }

    processing_targets.assignTargets(pons, knownAsteroids, managedTurrets)

    lu.assertEquals(turret.shooting_target, asteroid2)
    lu.assertEquals(lls, { filters={
        {min = 1, value = {name = "iron-ore",   quality = "normal", type = "item"}}
    }})
end
-- ###############################################################

BaseTest:hookTests()
