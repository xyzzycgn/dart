---
--- Created by xyzzycgn.
---
local Require = require("test.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)
_G.serpent = require("serpent") -- must be global

require("spec.common")
describe("ConfigureTurrets", function()
    local configureTurrets
    local utils

    setup(function()
        configureTurrets = require("scripts.ConfigureTurrets")
        utils = require("scripts.utils")


        -- Mock log function.
        _G.log = function(msg) end

        -- Mock prototypes.
        _G.prototypes = {
            virtual_signal = {
                ["signal-A"] = { valid = true, special = false, name = "signal-A" },
                ["signal-B"] = { valid = true, special = false, name = "signal-B" },
                ["signal-each"] = { valid = true, special = true, name = "signal-each" },
                ["signal-everything"] = { valid = true, special = true, name = "signal-everything" },
                ["invalid-signal"] = { valid = false, special = false, name = "invalid-signal" }
            }
        }

        -- Mock table_size function.
        _G.table_size = function(t)
            local count = 0
            for _ in pairs(t) do
                count = count + 1
            end
            return count
        end

        -- needed by ConfigureTurrets
        _G.defines.wire_connector_id = {
            circuit_green = 1,
            circuit_red = 0,
            combinator_input_green = 3,
            combinator_input_red = 2,
            combinator_output_green = 5,
            combinator_output_red = 4,
            pole_copper = 6,
            power_switch_left_copper = 7,
            power_switch_right_copper = 8,
        }
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("states", function()
        it("defines the extended state constants", function()
            local states = configureTurrets.states

            assert.are.equal(11, states.notConnected)
            assert.are.equal(12, states.connectedTwice)
            assert.are.equal(13, states.connectedToMultipleFccs)
            assert.are.equal(14, states.circuitNetworkDisabledInTurret)
            assert.are.equal(99, states.unknown)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("includes the inherited circuit condition states", function()
            local states = configureTurrets.states

            assert.is_not_nil(states.ok)
            assert.is_not_nil(states.firstSignalEmpty)
            assert.is_not_nil(states.secondSignalNotSupported)
            assert.is_not_nil(states.invalidComparator)
            assert.is_not_nil(states.noFalse)
            assert.is_not_nil(states.noTrue)
        end)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("checkNetworkCondition", function()
        it("returns notConnected when the turret has no circuit connection", function()
            local tc = {
                num_connections = 0,
                managedBy = {},
                circuit_enable_disable = true
            }

            local result = configureTurrets.checkNetworkCondition(tc)

            assert.are.equal(configureTurrets.states.notConnected, result)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns connectedTwice when the turret has two circuit connections", function()
            local tc = {
                num_connections = 2,
                managedBy = { fcc1 = true },
                circuit_enable_disable = true
            }

            local result = configureTurrets.checkNetworkCondition(tc)

            assert.are.equal(configureTurrets.states.connectedTwice, result)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns connectedToMultipleFccs when the turret is managed by multiple FCCs", function()
            local tc = {
                num_connections = 1,
                managedBy = { fcc1 = true, fcc2 = true },
                circuit_enable_disable = true
            }

            local result = configureTurrets.checkNetworkCondition(tc)

            assert.are.equal(configureTurrets.states.connectedToMultipleFccs, result)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns circuitNetworkDisabledInTurret when circuit enable/disable is disabled", function()
            local tc = {
                num_connections = 1,
                managedBy = { fcc1 = true },
                circuit_enable_disable = false
            }

            local result = configureTurrets.checkNetworkCondition(tc)

            assert.are.equal(configureTurrets.states.circuitNetworkDisabledInTurret, result)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns ok for a valid circuit configuration", function()
            local tc = {
                num_connections = 1,
                managedBy = { fcc1 = true },
                circuit_enable_disable = true,
                cc = {
                    first_signal = { type = "virtual", name = "signal-A" },
                    comparator = ">",
                    constant = 0
                }
            }

            local result = configureTurrets.checkNetworkCondition(tc)

            assert.are.equal(configureTurrets.states.ok, result)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns firstSignalEmpty for a missing first signal", function()
            local tc = {
                num_connections = 1,
                managedBy = { fcc1 = true },
                circuit_enable_disable = true,
                cc = { first_signal = nil }
            }

            local result = configureTurrets.checkNetworkCondition(tc)

            assert.are.equal(configureTurrets.states.firstSignalEmpty, result)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns secondSignalNotSupported when a second signal is configured", function()
            local tc = {
                num_connections = 1,
                managedBy = { fcc1 = true },
                circuit_enable_disable = true,
                cc = {
                    first_signal = { type = "virtual", name = "signal-A" },
                    comparator = ">",
                    second_signal = { type = "virtual", name = "signal-B" }
                }
            }

            local result = configureTurrets.checkNetworkCondition(tc)

            assert.are.equal(configureTurrets.states.secondSignalNotSupported, result)
        end)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("autoConfigure", function()
        it("enables circuit enable/disable when it is disabled in the turret", function()
            local mockControlBehavior = {
                valid = true,
                circuit_enable_disable = false,
                circuit_condition = {
                    first_signal = { type = "virtual", name = "signal-A" },
                    comparator = ">",
                    constant = 0
                }
            }

            local mockTurret = {
                valid = true,
                unit_number = 123,
                get_control_behavior = function()
                    return mockControlBehavior
                end
            }

            local tc = {
                turret = mockTurret,
                num_connections = 1,
                managedBy = { fcc1 = true },
                circuit_enable_disable = false,
                stateConfiguration = configureTurrets.states.circuitNetworkDisabledInTurret
            }

            configureTurrets.autoConfigure({ tc }, {})

            assert.is_true(mockControlBehavior.circuit_enable_disable)
            assert.is_true(tc.circuit_enable_disable)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("sets an available first signal when the first signal is missing", function()
            local mockControlBehavior = {
                valid = true,
                circuit_enable_disable = true,
                circuit_condition = {
                    first_signal = nil,
                    comparator = ">",
                    constant = 0
                },
                get_circuit_network = function(wc)
                    return (wc == defines.wire_connector_id.circuit_green) and 1
                end
            }

            local mockTurret = {
                valid = true,
                unit_number = 123,
                get_control_behavior = function()
                    return mockControlBehavior
                end
            }

            local tc = {
                turret = mockTurret,
                num_connections = 1,
                managedBy = { fcc1 = true },
                circuit_enable_disable = true,
                stateConfiguration = configureTurrets.states.firstSignalEmpty,
                cc = mockControlBehavior.circuit_condition
            }

            local pons = {
                turretsOnPlatform = {
                    [123] = {
                        control_behavior = mockControlBehavior
                    },
                    [456] = {
                        control_behavior = {
                            valid = true,
                            get_circuit_network = function(wc)
                                return {
                                    -- Mock network.
                                }
                            end,
                            circuit_condition = {
                                first_signal = { type = "virtual", name = "signal-B" }
                            }
                        }
                    }
                }
            }

            configureTurrets.autoConfigure({ tc }, pons)

            assert.is_not_nil(mockControlBehavior.circuit_condition.first_signal)
            assert.are.equal("virtual", mockControlBehavior.circuit_condition.first_signal.type)
            assert.are.equal("signal-A", mockControlBehavior.circuit_condition.first_signal.name)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("repairs an invalid comparator circuit condition", function()
            local mockControlBehavior = {
                valid = true,
                circuit_enable_disable = true,
                circuit_condition = {
                    first_signal = { type = "virtual", name = "signal-A" },
                    comparator = "=",
                    constant = 5
                }
            }

            local mockTurret = {
                valid = true,
                unit_number = 123,
                get_control_behavior = function()
                    return mockControlBehavior
                end
            }

            local tc = {
                turret = mockTurret,
                num_connections = 1,
                managedBy = { fcc1 = true },
                circuit_enable_disable = true,
                stateConfiguration = configureTurrets.states.invalidComparator,
                cc = mockControlBehavior.circuit_condition
            }

            configureTurrets.autoConfigure({ tc }, {})

            assert.are.equal(">", mockControlBehavior.circuit_condition.comparator)
            assert.are.equal(0, mockControlBehavior.circuit_condition.constant)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("repairs a circuit condition that contains a second signal", function()
            local mockControlBehavior = {
                valid = true,
                circuit_enable_disable = true,
                circuit_condition = {
                    first_signal = { type = "virtual", name = "signal-A" },
                    comparator = "=",
                    second_signal = { type = "virtual", name = "signal-B" }
                }
            }

            local mockTurret = {
                valid = true,
                unit_number = 123,
                get_control_behavior = function()
                    return mockControlBehavior
                end
            }

            local tc = {
                turret = mockTurret,
                num_connections = 1,
                managedBy = { fcc1 = true },
                circuit_enable_disable = true,
                stateConfiguration = configureTurrets.states.secondSignalNotSupported,
                cc = mockControlBehavior.circuit_condition
            }

            configureTurrets.autoConfigure({ tc }, {})

            assert.are.equal(">", mockControlBehavior.circuit_condition.comparator)
            assert.are.equal(0, mockControlBehavior.circuit_condition.constant)
            assert.is_nil(mockControlBehavior.circuit_condition.second_signal)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("repairs multiple configuration issues in one run", function()
            local mockControlBehavior = {
                valid = true,
                circuit_enable_disable = false,
                circuit_condition = {
                    first_signal = nil,
                    comparator = "=",
                    constant = 5
                },
                get_circuit_network = function(wc)
                    return {
                        -- Mock network.
                    }
                end,
            }

            local mockTurret = {
                valid = true,
                unit_number = 123,
                get_control_behavior = function()
                    return mockControlBehavior
                end
            }

            local tc = {
                turret = mockTurret,
                num_connections = 1,
                managedBy = { fcc1 = true },
                circuit_enable_disable = false,
                stateConfiguration = configureTurrets.states.circuitNetworkDisabledInTurret,
                cc = mockControlBehavior.circuit_condition
            }

            local pons = {
                turretsOnPlatform = {
                    [123] = {
                        control_behavior = mockControlBehavior
                    }
                }
            }

            configureTurrets.autoConfigure({ tc }, pons)

            assert.is_true(mockControlBehavior.circuit_enable_disable)
            assert.is_not_nil(mockControlBehavior.circuit_condition.first_signal)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("does not enter an infinite loop when the requested repair cannot change the condition", function()
            local mockControlBehavior = {
                valid = true,
                circuit_enable_disable = true,
                circuit_condition = {
                    first_signal = { type = "virtual", name = "signal-A" },
                    comparator = ">",
                    constant = 0
                }
            }

            local mockTurret = {
                valid = true,
                unit_number = 123,
                get_control_behavior = function()
                    return mockControlBehavior
                end
            }

            local tc = {
                turret = mockTurret,
                num_connections = 1,
                managedBy = { fcc1 = true },
                circuit_enable_disable = true,
                stateConfiguration = configureTurrets.states.firstSignalEmpty,
                cc = mockControlBehavior.circuit_condition
            }

            configureTurrets.autoConfigure({ tc }, { turretsOnPlatform = {} })

            assert.is_true(true)
        end)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("edge cases", function()
        it("does not fail for an invalid turret", function()
            local mockTurret = {
                valid = false,
                unit_number = 123
            }

            local tc = {
                turret = mockTurret,
                managedBy = { fcc1 = true },
                circuit_enable_disable = true,
                stateConfiguration = configureTurrets.states.circuitNetworkDisabledInTurret
            }

            configureTurrets.autoConfigure({ tc })

            assert.is_true(true)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("does not fail for an invalid control behavior", function()
            local mockTurret = {
                valid = true,
                unit_number = 123,
                get_control_behavior = function()
                    return { valid = false }
                end
            }

            local pons = {
                turretsOnPlatform = {
                    [456] = {
                        control_behavior = {
                            valid = false,
                        }
                    },
                }
            }

            local tc = {
                turret = mockTurret,
                managedBy = { fcc1 = true },
                circuit_enable_disable = true,
                stateConfiguration = configureTurrets.states.firstSignalEmpty
            }

            configureTurrets.autoConfigure({ tc }, pons)

            assert.is_true(true)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("does not fail when no unused signal is available", function()
            local mockControlBehavior = {
                valid = true,
                circuit_condition = {
                    first_signal = nil,
                    comparator = ">",
                    constant = 0
                }
            }

            local mockTurret = {
                valid = true,
                unit_number = 123,
                get_control_behavior = function()
                    return mockControlBehavior
                end
            }

            local tc = {
                turret = mockTurret,
                num_connections = 1,
                managedBy = { fcc1 = true },
                circuit_enable_disable = true,
                stateConfiguration = configureTurrets.states.firstSignalEmpty
            }

            local pons = {
                turretsOnPlatform = {
                    [456] = {
                        control_behavior = {
                            valid = true,
                            get_circuit_network = function(wc)
                                return {
                                    -- Mock network.
                                }
                            end,
                            circuit_condition = {
                                first_signal = { type = "virtual", name = "signal-A" }
                            }
                        }
                    },
                    [789] = {
                        control_behavior = {
                            valid = true,
                            get_circuit_network = function(wc)
                                return {
                                    -- Mock network.
                                }
                            end,
                            circuit_condition = {
                                first_signal = { type = "virtual", name = "signal-B" }
                            }
                        }
                    }
                }
            }

            configureTurrets.autoConfigure({ tc }, pons)

            assert.is_true(true)
        end)
    end)
end)
