---
--- Created by xyzzycgn.
---
local Require = require("test.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)

require("spec.common")
serpent = require("serpent") -- must be global

describe("ProcessingTargets", function()
    local processing_targets
    local on_event_called
    local raised_events

    setup(function()
        processing_targets = require("scripts.processing_targets")
        -- Mock global custom events.
        _G.on_target_assigned_event = 1
        _G.on_target_unassigned_event = 2

        _G.script.raise_event = spy.new(function() end)
    end)

    before_each(function()
        -- clear history of spy
        _G.script.raise_event:clear()
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    local function createMockedPrototype(asteroidType)
        return {
            name = asteroidType .. "-asteroid",
        }
    end

    local function createMockedAsteroid(asteroidType, unitNumber, x, y)
        return {
            type = "asteroid",
            unit_number = unitNumber,
            valid = true,
            prototype = createMockedPrototype(asteroidType),
            position = {
                x = x,
                y = y
            }
        }
    end

    local function createCircuitCondition(type, name)
        return {
            first_signal = {
                type = type,
                name = name
            },
            comparator = ">",
            constant = 0
        }
    end
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("targeting", function()
        it("returns a negative value when the asteroid misses all radar ranges", function()
            local pons = {
                platform = {
                    speed = 0
                },
                radarsOnPlatform = {
                    [1] = {
                        radar = {
                            position = {
                                x = 0,
                                y = 0
                            }
                        },
                        defenseRange = 50
                    }
                }
            }

            local asteroid = {
                position = {
                    x = 100,
                    y = 100
                },
                movement = {
                    x = 1,
                    y = 0
                }
            }

            local result = processing_targets.targeting(pons, asteroid)

            assert.is_true(result < 0)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns a positive value when the asteroid hits a radar range", function()
            local pons = {
                platform = {
                    speed = 0
                },
                radarsOnPlatform = {
                    [1] = {
                        radar = {
                            position = {
                                x = 0,
                                y = 0
                            }
                        },
                        defenseRange = 50
                    }
                }
            }

            local asteroid = {
                position = {
                    x = 40,
                    y = 0
                },
                movement = {
                    x = -1,
                    y = 0
                }
            }

            local result = processing_targets.targeting(pons, asteroid)

            assert.is_true(result > 0)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns a non-negative value when the asteroid grazes a radar range", function()
            local pons = {
                platform = {
                    speed = 0
                },
                radarsOnPlatform = {
                    [1] = {
                        radar = {
                            position = {
                                x = 0,
                                y = 0
                            }
                        },
                        defenseRange = 50
                    }
                }
            }

            local asteroid = {
                position = {
                    x = 50,
                    y = 50
                },
                movement = {
                    x = 0,
                    y = -1
                }
            }

            local result = processing_targets.targeting(pons, asteroid)

            assert.is_true(result >= 0)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns a positive value when one of multiple radars is hit", function()
            local pons = {
                platform = {
                    speed = 0
                },
                radarsOnPlatform = {
                    [1] = {
                        radar = {
                            position = {
                                x = 0,
                                y = 0
                            }
                        },
                        defenseRange = 20
                    },
                    [2] = {
                        radar = {
                            position = {
                                x = 100,
                                y = 0
                            }
                        },
                        defenseRange = 50
                    }
                }
            }

            local asteroid = {
                position = {
                    x = 130,
                    y = 0
                },
                movement = {
                    x = -1,
                    y = 0
                }
            }

            local result = processing_targets.targeting(pons, asteroid)

            assert.is_true(result > 0)
        end)
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("addToTargetList", function()
        it("adds a target that is in range", function()
            local turret = {
                position = {
                    x = 0,
                    y = 0
                },
                orientation = 0,
                unit_number = 1
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
                    range = 20,
                    min_range = 0,
                    turn_range = 1,
                    priority_targets_list = {},
                    targets_of_turret = {}
                }
            }

            local target = {
                unit_number = 4711,
                position = {
                    x = 10,
                    y = 0
                },
                prototype = {
                    name = "LuaEntityPrototype-asteroid"
                }
            }

            processing_targets.addToTargetList(managedTurrets, target, 1)

            assert.is_not_nil(managedTurrets[1].targets_of_turret[4711])
            assert.near(10, managedTurrets[1].targets_of_turret[4711].distance, 0.001)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("does not add a target inside minimum range", function()
            local turret = {
                position = {
                    x = 0,
                    y = 0
                },
                orientation = 0,
                unit_number = 1
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
                    range = 20,
                    min_range = 11,
                    turn_range = 1,
                    priority_targets_list = {},
                    targets_of_turret = {}
                }
            }

            local target = {
                unit_number = 4711,
                position = {
                    x = 10,
                    y = 0
                },
                prototype = {
                    name = "LuaEntityPrototype-asteroid"
                }
            }

            processing_targets.addToTargetList(managedTurrets, target, 1)

            assert.is_nil(managedTurrets[1].targets_of_turret[4711])
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("adds a target inside the turret turn range", function()
            local turret = {
                position = {
                    x = 10,
                    y = 20
                },
                direction = defines.direction.north,
                unit_number = 1
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
                    range = 20,
                    min_range = 0,
                    turn_range = 0.25,
                    priority_targets_list = {},
                    targets_of_turret = {}
                }
            }

            local target = {
                unit_number = 4711,
                position = {
                    x = 10,
                    y = 10
                },
                prototype = {
                    name = "LuaEntityPrototype-asteroid"
                }
            }

            processing_targets.addToTargetList(managedTurrets, target, 1)

            assert.are.same({
                distance = 10,
                is_priority_target = false
            }, managedTurrets[1].targets_of_turret[4711])
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("adds a target on the border of the turret turn range", function()
            local turret = {
                position = {
                    x = 10,
                    y = 20
                },
                direction = defines.direction.northeast,
                unit_number = 1
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
                    range = 20,
                    min_range = 0,
                    turn_range = 0.25,
                    priority_targets_list = {},
                    targets_of_turret = {}
                }
            }

            local target = {
                unit_number = 4711,
                position = {
                    x = 10,
                    y = 10
                },
                prototype = {
                    name = "LuaEntityPrototype-asteroid"
                }
            }

            processing_targets.addToTargetList(managedTurrets, target, 1)

            assert.are.same({
                distance = 10,
                is_priority_target = false
            }, managedTurrets[1].targets_of_turret[4711])
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("does not add a target outside the turret turn range", function()
            local turret = {
                position = {
                    x = 10,
                    y = 20
                },
                direction = defines.direction.northeast,
                unit_number = 1
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
                    range = 20,
                    min_range = 0,
                    turn_range = 0.25,
                    priority_targets_list = {},
                    targets_of_turret = {}
                }
            }

            local target = {
                unit_number = 4711,
                position = {
                    x = 9,
                    y = 30
                },
                prototype = {
                    name = "LuaEntityPrototype-asteroid"
                }
            }

            processing_targets.addToTargetList(managedTurrets, target, 1)

            assert.is_nil(managedTurrets[1].targets_of_turret[4711])
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("does not add a target outside turret range", function()
            local turret = {
                position = {
                    x = 0,
                    y = 0
                },
                orientation = 0,
                unit_number = 1
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
                    range = 10,
                    min_range = 0,
                    turn_range = 1,
                    targets_of_turret = {},
                    priority_targets_list = {}
                }
            }

            local target = {
                unit_number = 4711,
                position = {
                    x = 20,
                    y = 0
                },
                prototype = {
                    name = "LuaEntityPrototype-asteroid"
                }
            }

            processing_targets.addToTargetList(managedTurrets, target, 1)

            assert.is_nil(managedTurrets[1].targets_of_turret[4711])
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("does not add a target when the targeting result is negative", function()
            local turret = {
                position = {
                    x = 0,
                    y = 0
                },
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
                position = {
                    x = 10,
                    y = 0
                },
                prototype = {
                    name = "LuaEntityPrototype-asteroid"
                }
            }

            processing_targets.addToTargetList(managedTurrets, target, -1)

            assert.is_nil(managedTurrets[1].targets_of_turret[4711])
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("removes an existing target when it moves out of range", function()
            local turret = {
                position = {
                    x = 0,
                    y = 0
                },
                orientation = 0,
                unit_number = 1
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
                    range = 20,
                    min_range = 0,
                    turn_range = 1,
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
                position = {
                    x = 30,
                    y = 0
                },
                prototype = {
                    name = "LuaEntityPrototype-asteroid"
                }
            }

            processing_targets.addToTargetList(managedTurrets, target, 1)

            assert.is_nil(managedTurrets[1].targets_of_turret[4711])
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("adds a priority target when only priority targets are allowed", function()
            local target = createMockedAsteroid("metallic", 11, 4, 3)
            local asteroidPrototype = createMockedPrototype("metallic")

            local turret = {
                unit_number = 11,
                priority_targets = {
                    [1] = asteroidPrototype
                },
                position = {
                    x = 0,
                    y = 0
                },
                orientation = 0,
                ignore_unprioritised_targets = true
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
                    targets_of_turret = {},
                    range = 18,
                    min_range = 0,
                    turn_range = 1,
                    priority_targets_list = {
                        [asteroidPrototype.name] = true
                    }
                }
            }

            processing_targets.addToTargetList(managedTurrets, target, 5)

            assert.are.same({
                [11] = {
                    distance = 5,
                    is_priority_target = true
                }
            }, managedTurrets[1].targets_of_turret)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("does not add a non-priority target when only priority targets are allowed", function()
            local target = createMockedAsteroid("oxide", 11, 10, 10)
            local asteroidPrototype = createMockedPrototype("metallic")

            local turret = {
                unit_number = 11,
                priority_targets = {
                    [1] = asteroidPrototype
                },
                position = {
                    x = 0,
                    y = 0
                },
                ignore_unprioritised_targets = true
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
                    targets_of_turret = {},
                    range = 18,
                    priority_targets_list = {
                        [asteroidPrototype.name] = true
                    }
                }
            }

            processing_targets.addToTargetList(managedTurrets, target, 5)

            assert.are.same({}, managedTurrets[1].targets_of_turret)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("adds a non-priority target when non-priority targets are allowed", function()
            local target = createMockedAsteroid("oxide", 11, 3, 4)
            local asteroidPrototype = createMockedPrototype("metallic")

            local turret = {
                unit_number = 11,
                priority_targets = {
                    [1] = asteroidPrototype
                },
                position = {
                    x = 0,
                    y = 0
                },
                orientation = 0,
                ignore_unprioritised_targets = false
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
                    targets_of_turret = {},
                    range = 18,
                    min_range = 0,
                    turn_range = 1,
                    priority_targets_list = {
                        [asteroidPrototype.name] = true
                    }
                }
            }

            processing_targets.addToTargetList(managedTurrets, target, 5)

            assert.are.same({
                [11] = {
                    distance = 5,
                    is_priority_target = false
                }
            }, managedTurrets[1].targets_of_turret)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("adds a priority target when non-priority targets are allowed", function()
            local target = createMockedAsteroid("metallic", 11, 3, 4)
            local asteroidPrototype = createMockedPrototype("metallic")

            local turret = {
                unit_number = 11,
                priority_targets = {
                    [1] = asteroidPrototype
                },
                position = {
                    x = 0,
                    y = 0
                },
                orientation = 0,
                ignore_unprioritised_targets = false
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
                    targets_of_turret = {},
                    range = 18,
                    min_range = 0,
                    turn_range = 1,
                    priority_targets_list = {
                        [asteroidPrototype.name] = true
                    }
                }
            }

            processing_targets.addToTargetList(managedTurrets, target, 5)

            assert.are.same({
                [11] = {
                    distance = 5,
                    is_priority_target = true
                }
            }, managedTurrets[1].targets_of_turret)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("removes a priority target when it is no longer hitting", function()
            local target = createMockedAsteroid("metallic", 11, 3, 4)
            local asteroidPrototype = createMockedPrototype("metallic")

            local turret = {
                unit_number = 11,
                priority_targets = {
                    [1] = asteroidPrototype
                },
                position = {
                    x = 0,
                    y = 0
                },
                ignore_unprioritised_targets = false
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
                    targets_of_turret = {
                        [11] = {
                            distance = 15,
                            is_priority_target = true
                        }
                    },
                    range = 18,
                    priority_targets_list = {
                        [asteroidPrototype.name] = true
                    }
                }
            }

            processing_targets.addToTargetList(managedTurrets, target, -5)

            assert.are.same({}, managedTurrets[1].targets_of_turret)
        end)
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("assignTargets", function()
        it("assigns the closest target to a single turret and updates the FCC filters", function()
            local turret = {
                unit_number = 1,
                position = {
                    x = 0,
                    y = 0
                },
                valid = true
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
                },
                valid = true
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
                name = "small-metallic-asteroid",
                valid = true
            }
            local asteroid2 = {
                unit_number = 4712,
                name = "small-carbonic-asteroid",
                valid = true
            }

            local knownAsteroids = {
                [4711] = {
                    entity = asteroid1
                },
                [4712] = {
                    entity = asteroid2
                }
            }

            local pons = {
                fccsOnPlatform = {
                    [10] = fcc
                }
            }

            processing_targets.assignTargets(pons, knownAsteroids, managedTurrets)

            assert.are.equal(asteroid1, turret.shooting_target)
            assert.spy(script.raise_event).was_called_with(on_target_assigned_event, {
                reason = 'assign', tun = 1, target = 4711
            })
            assert.are.same({
                filters = {
                    {
                        min = 1,
                        value = {
                            name = "iron-ore",
                            quality = "normal",
                            type = "item"
                        }
                    }
                }
            }, lls)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("clears the shooting target when no targets are available", function()
            local turret = {
                unit_number = 1,
                position = {
                    x = 0,
                    y = 0
                },
                shooting_target = {},
                valid = true
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
                },
                valid = true
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
                    fcc = fcc,
                    targets_of_turret = {},
                    circuit_condition = createCircuitCondition("item", "iron-ore")
                }
            }

            local pons = {
                fccsOnPlatform = {
                    [10] = fcc
                }
            }

            processing_targets.assignTargets(pons, {}, managedTurrets)

            assert.is_nil(turret.shooting_target)
            assert.spy(script.raise_event).was_called_with(on_target_unassigned_event, { reason = 'unassign', tun = 1 })
            assert.are.same({
                filters = {}
            }, lls)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("assigns targets to multiple turrets and updates merged FCC filters", function()
            local turret1 = {
                unit_number = 1,
                position = {
                    x = 0,
                    y = 0
                },
                valid = true
            }

            local turret2 = {
                unit_number = 2,
                position = {
                    x = 10,
                    y = 0
                },
                valid = true
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
                },
                valid = true
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
                name = "small-metallic-asteroid",
                valid = true
            }
            local asteroid2 = {
                unit_number = 4712,
                name = "small-carbonic-asteroid",
                valid = true
            }
            local asteroid3 = {
                unit_number = 4713,
                name = "small-carbonic-asteroid",
                valid = true
            }

            local knownAsteroids = {
                [4711] = {
                    entity = asteroid1
                },
                [4712] = {
                    entity = asteroid2
                },
                [4713] = {
                    entity = asteroid3
                }
            }

            local pons = {
                fccsOnPlatform = {
                    [10] = fcc
                }
            }

            processing_targets.assignTargets(pons, knownAsteroids, managedTurrets)

            assert.are.equal(asteroid1, turret1.shooting_target)
            assert.are.equal(asteroid2, turret2.shooting_target)
            assert.spy(script.raise_event).was_called_with(on_target_assigned_event, {
                reason = 'assign', tun = 1, target = 4711
            })
            assert.spy(script.raise_event).was_called_with(on_target_assigned_event, {
                reason = 'assign', tun = 2, target = 4712
            })
            assert.are.same({
                filters = {
                    {
                        min = 1,
                        value = {
                            name = "copper-ore",
                            quality = "normal",
                            type = "item"
                        }
                    },
                    {
                        min = 1,
                        value = {
                            name = "iron-ore",
                            quality = "normal",
                            type = "item"
                        }
                    }
                }
            }, lls)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("skips invalid asteroid entities while assigning targets", function()
            local turret1 = {
                unit_number = 1,
                position = {
                    x = 0,
                    y = 0
                },
                valid = true
            }

            local turret2 = {
                unit_number = 2,
                position = {
                    x = 10,
                    y = 0
                },
                valid = true
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
                },
                valid = true
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
                name = "small-carbonic-asteroid",
                valid = true
            }
            local asteroid3 = {
                unit_number = 4713,
                name = "small-carbonic-asteroid",
                valid = true
            }

            local knownAsteroids = {
                [4711] = {
                    entity = asteroid1
                },
                [4712] = {
                    entity = asteroid2
                },
                [4713] = {
                    entity = asteroid3
                }
            }

            local pons = {
                fccsOnPlatform = {
                    [10] = fcc
                }
            }

            processing_targets.assignTargets(pons, knownAsteroids, managedTurrets)

            assert.is_nil(turret1.shooting_target)
            assert.are.equal(asteroid2, turret2.shooting_target)
            assert.spy(script.raise_event).was_called_with(on_target_assigned_event, {
                reason = 'assign', tun = 2, target = 4712
            })
            assert.are.same({
                filters = {
                    {
                        min = 1,
                        value = {
                            name = "copper-ore",
                            quality = "normal",
                            type = "item"
                        }
                    },
                }
            }, lls)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("prefers priority targets when priority targets are configured and non-priority targets are allowed", function()
            local lls = {
                filters = {}
            }

            local fcc = {
                unit_number = 1000,
                control_behavior = {
                    get_section = function(_)
                        return lls
                    end
                },
                valid = true
            }

            local pons = {
                platform = {
                    name = "test"
                },
                fccsOnPlatform = {
                    [1000] = fcc
                }
            }

            local asteroidPrototype = createMockedPrototype("metallic")
            local asteroid1 = createMockedAsteroid("metallic", 10)
            local asteroid2 = createMockedAsteroid("oxide", 11)
            local asteroid3 = createMockedAsteroid("metallic", 12)

            local knownAsteroids = {
                [10] = {
                    entity = asteroid1
                },
                [11] = {
                    entity = asteroid2
                },
                [12] = {
                    entity = asteroid3
                }
            }

            local turret = {
                unit_number = 100,
                targets_of_turret = {},
                priority_targets = {
                    [1] = asteroidPrototype
                },
                ignore_unprioritised_targets = false,
                valid = true
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
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
                        [asteroidPrototype.name] = true
                    }
                },
            }

            processing_targets.assignTargets(pons, knownAsteroids, managedTurrets)

            assert.are.equal(asteroid3, turret.shooting_target)
            assert.spy(script.raise_event).was_called_with(on_target_assigned_event, {
                reason = 'assign', tun = 100, target = 12
            })
            assert.are.same({
                filters = {
                    {
                        min = 1,
                        value = {
                            name = "iron-ore",
                            quality = "normal",
                            type = "item"
                        }
                    }
                }
            }, lls)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("assigns the nearest priority target when non-priority targets are ignored", function()
            local lls = {
                filters = {}
            }

            local fcc = {
                unit_number = 1000,
                control_behavior = {
                    get_section = function(_)
                        return lls
                    end
                },
                valid = true
            }

            local pons = {
                platform = {
                    name = "test"
                },
                fccsOnPlatform = {
                    [1000] = fcc
                }
            }

            local asteroidPrototype = createMockedPrototype("metallic")
            local asteroid1 = createMockedAsteroid("metallic", 10)
            local asteroid2 = createMockedAsteroid("metallic", 11)

            local knownAsteroids = {
                [10] = {
                    entity = asteroid1
                },
                [11] = {
                    entity = asteroid2
                }
            }

            local turret = {
                unit_number = 100,
                targets_of_turret = {},
                priority_targets = {
                    [1] = asteroidPrototype
                },
                ignore_unprioritised_targets = true,
                valid = true
            }

            local managedTurrets = {
                [1] = {
                    turret = turret,
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
                        [asteroidPrototype.name] = true
                    }
                },
            }

            processing_targets.assignTargets(pons, knownAsteroids, managedTurrets)

            assert.are.equal(asteroid2, turret.shooting_target)
            assert.spy(script.raise_event).was_called_with(on_target_assigned_event, {
                reason = 'assign', tun = 100, target = 11
            })

            assert.are.same({
                filters = {
                    {
                        min = 1,
                        value = {
                            name = "iron-ore",
                            quality = "normal",
                            type = "item"
                        }
                    }
                }
            }, lls)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("sorts candidate targets by distance", function()
            local turret = {
                unit_number = 1,
                position = {
                    x = 0,
                    y = 0
                },
                valid = true
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
                },
                valid = true
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

            local asteroid1 = {
                unit_number = 4711,
                name = "asteroid1",
                valid = true
            }
            local asteroid2 = {
                unit_number = 4712,
                name = "asteroid2",
                valid = true
            }
            local asteroid3 = {
                unit_number = 4713,
                name = "asteroid3",
                valid = true
            }

            local knownAsteroids = {
                [4711] = {
                    entity = asteroid1
                },
                [4712] = {
                    entity = asteroid2
                },
                [4713] = {
                    entity = asteroid3
                }
            }

            local pons = {
                fccsOnPlatform = {
                    [10] = fcc
                }
            }

            processing_targets.assignTargets(pons, knownAsteroids, managedTurrets)

            assert.are.equal(asteroid2, turret.shooting_target)
            assert.are.same({
                filters = {
                    {
                        min = 1,
                        value = {
                            name = "iron-ore",
                            quality = "normal",
                            type = "item"
                        }
                    }
                }
            }, lls)
        end)
    end)
end)
