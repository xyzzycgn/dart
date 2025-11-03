---
--- Created by xyzzycgn.
--- DateTime: 03.11.25 16:00
---
require('test.BaseTest')
local lu = require('luaunit')

require('factorio_def')
local processing_targets = require('scripts.processing_targets')

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
        unit_number = 1
    }

    local managedTurrets = {
        [1] = {
            turret = turret,
            range = 20,
            targets_of_turret = {}
        }
    }

    local target = {
        unit_number = 4711,
        position = { x = 10, y = 0 }
    }

    processing_targets.calculatePrio(managedTurrets, target, 1)

    lu.assertNotNil(managedTurrets[1].targets_of_turret[4711])
    lu.assertAlmostEquals(managedTurrets[1].targets_of_turret[4711], 10, 0.001)
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
            targets_of_turret = {}
        }
    }

    local target = {
        unit_number = 4711,
        position = { x = 20, y = 0 }
    }

    processing_targets.calculatePrio(managedTurrets, target, 1)

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
            targets_of_turret = {}
        }
    }

    local target = {
        unit_number = 4711,
        position = { x = 10, y = 0 }
    }

    processing_targets.calculatePrio(managedTurrets, target, -1)

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
                [4711] = 10
            }
        }
    }

    local target = {
        unit_number = 4711,
        position = { x = 30, y = 0 }
    }

    processing_targets.calculatePrio(managedTurrets, target, 1)

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
                [4711] = 15,
                [4712] = 25
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
                [4711] = 10
            },
            circuit_condition = createCircuitCondition("item", "iron-ore")
        },
        [2] = {
            turret = turret2,
            fcc = fcc,
            targets_of_turret = {
                [4712] = 20
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
                [4711] = 30,
                [4712] = 10,
                [4713] = 20
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
