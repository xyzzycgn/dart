
---
--- Created by xyzzycgn.
--- DateTime: 11.10.25 15:30
---
require('test.BaseTest')
local lu = require('lib.luaunit')

require('factorio_def')
local configureTurrets = require('scripts.ConfigureTurrets')
local utils = require('scripts.utils')
local serpent = require('lib.serpent')

TestConfigureTurrets = {}

function TestConfigureTurrets:setUp()
    -- Mock Log
    Log = {
        FINE = "FINE",
        FINER = "FINER",
        WARN = "WARN",
        logLine = function(msg, callback, level) end,
        logBlock = function(msg, callback, level) end,
        logMsg = function(callback, level, format, ...) end,
        log = function(msg, callback, level) end
    }

    -- Mock log function
    log = function(msg) end

    -- Mock defines
    defines = {
        wire_connector_id = {
            circuit_red = "red",
            circuit_green = "green"
        }
    }

    -- Mock prototypes
    prototypes = {
        virtual_signal = {
            ["signal-A"] = { valid = true, special = false, name = "signal-A" },
            ["signal-B"] = { valid = true, special = false, name = "signal-B" },
            ["signal-each"] = { valid = true, special = true, name = "signal-each" },
            ["signal-everything"] = { valid = true, special = true, name = "signal-everything" },
            ["invalid-signal"] = { valid = false, special = false, name = "invalid-signal" }
        }
    }

    -- Mock table_size function
    table_size = function(t)
        local count = 0
        for _ in pairs(t) do
            count = count + 1
        end
        return count
    end
end

-- ###############################################################
-- Tests für states Konstanten
-- ###############################################################

function TestConfigureTurrets:test_states_constants()
    local states = configureTurrets.states
    
    -- Test erweiterte states
    lu.assertEquals(states.notConnected, 11)
    lu.assertEquals(states.connectedTwice, 12)
    lu.assertEquals(states.connectedToMultipleFccs, 13)
    lu.assertEquals(states.circuitNetworkDisabledInTurret, 14)
    lu.assertEquals(states.unknown, 99)
    
    -- Test vererbte states von utils.CircuitConditionChecks
    lu.assertNotNil(states.ok)
    lu.assertNotNil(states.firstSignalEmpty)
    lu.assertNotNil(states.secondSignalNotSupported)
    lu.assertNotNil(states.invalidComparator)
    lu.assertNotNil(states.noFalse)
    lu.assertNotNil(states.noTrue)
end
-- ###############################################################

-- ###############################################################
-- Tests für checkNetworkCondition
-- ###############################################################

function TestConfigureTurrets:test_checkNetworkCondition_notConnected()
    local tc = {
        num_connections = 0,
        managedBy = {},
        circuit_enable_disable = true
    }

    local result = configureTurrets.checkNetworkCondition(tc)
    lu.assertEquals(result, configureTurrets.states.notConnected)
end
-- ###############################################################

function TestConfigureTurrets:test_checkNetworkCondition_connectedTwice()
    local tc = {
        num_connections = 2,
        managedBy = { fcc1 = true },
        circuit_enable_disable = true
    }

    local result = configureTurrets.checkNetworkCondition(tc)
    lu.assertEquals(result, configureTurrets.states.connectedTwice)
end
-- ###############################################################

function TestConfigureTurrets:test_checkNetworkCondition_connectedToMultipleFccs()
    local tc = {
        num_connections = 1,
        managedBy = { fcc1 = true, fcc2 = true },
        circuit_enable_disable = true
    }

    local result = configureTurrets.checkNetworkCondition(tc)
    lu.assertEquals(result, configureTurrets.states.connectedToMultipleFccs)
end
-- ###############################################################

function TestConfigureTurrets:test_checkNetworkCondition_circuitNetworkDisabledInTurret()
    local tc = {
        num_connections = 1,
        managedBy = { fcc1 = true },
        circuit_enable_disable = false
    }

    local result = configureTurrets.checkNetworkCondition(tc)
    lu.assertEquals(result, configureTurrets.states.circuitNetworkDisabledInTurret)
end
-- ###############################################################

function TestConfigureTurrets:test_checkNetworkCondition_valid_configuration()
    -- Mock utils.checkCircuitCondition to return valid
    utils.checkCircuitCondition = function(cc)
        return true, nil
    end

    local tc = {
        num_connections = 1,
        managedBy = { fcc1 = true },
        circuit_enable_disable = true,
        cc = { first_signal = { type = "virtual", name = "signal-A" } }
    }

    local result = configureTurrets.checkNetworkCondition(tc)
    lu.assertEquals(result, configureTurrets.states.ok)
end
-- ###############################################################

function TestConfigureTurrets:test_checkNetworkCondition_invalid_configuration()
    -- Mock utils.checkCircuitCondition to return invalid
    utils.checkCircuitCondition = function(cc)
        return false, configureTurrets.states.firstSignalEmpty
    end

    local tc = {
        num_connections = 1,
        managedBy = { fcc1 = true },
        circuit_enable_disable = true,
        cc = { first_signal = nil }
    }

    local result = configureTurrets.checkNetworkCondition(tc)
    lu.assertEquals(result, configureTurrets.states.firstSignalEmpty)
end
-- ###############################################################

function TestConfigureTurrets:test_checkNetworkCondition_unknown_error()
    -- Mock utils.checkCircuitCondition to return invalid without details
    utils.checkCircuitCondition = function(cc)
        return false, nil
    end

    local tc = {
        num_connections = 1,
        managedBy = { fcc1 = true },
        circuit_enable_disable = true,
        cc = {}
    }

    local result = configureTurrets.checkNetworkCondition(tc)
    lu.assertEquals(result, configureTurrets.states.unknown)
end
-- ###############################################################

-- ###############################################################
-- Tests für autoConfigure mit verschiedenen Szenarien
-- ###############################################################

function TestConfigureTurrets:test_autoConfigure_circuitNetworkDisabledInTurret()
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

    -- Mock utils.checkCircuitCondition für nach der Reparatur
    utils.checkCircuitCondition = function(cc)
        return true, nil
    end

    configureTurrets.autoConfigure({tc}, {})

    -- Überprüfe, dass circuit_enable_disable aktiviert wurde
    lu.assertTrue(mockControlBehavior.circuit_enable_disable)
    lu.assertTrue(tc.circuit_enable_disable)
end
-- ###############################################################

function TestConfigureTurrets:test_autoConfigure_firstSignalEmpty()
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
                            -- Mock network
                        }
                    end,
                    circuit_condition = {
                        first_signal = { type = "virtual", name = "signal-B" }
                    }
                }
            }
        }
    }

    -- Mock utils.checkCircuitCondition für nach der Reparatur
    utils.checkCircuitCondition = function(cc)
        return true, nil
    end

    configureTurrets.autoConfigure({tc}, pons)

    -- Überprüfe, dass ein Signal gesetzt wurde
    lu.assertNotNil(mockControlBehavior.circuit_condition.first_signal)
    lu.assertEquals(mockControlBehavior.circuit_condition.first_signal.type, "virtual")
    lu.assertEquals(mockControlBehavior.circuit_condition.first_signal.name, "signal-A")
end
-- ###############################################################

function TestConfigureTurrets:test_autoConfigure_repairCircuitCondition_invalidComparator()
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

    -- Mock utils.checkCircuitCondition für nach der Reparatur
    utils.checkCircuitCondition = function(cc)
        return true, nil
    end

    configureTurrets.autoConfigure({tc}, {})

    -- Überprüfe, dass die Werte korrigiert wurden
    lu.assertEquals(mockControlBehavior.circuit_condition.comparator, ">")
    lu.assertEquals(mockControlBehavior.circuit_condition.constant, 0)
end
-- ###############################################################

function TestConfigureTurrets:test_autoConfigure_multiple_errors()
    local mockControlBehavior = {
        valid = true,
        circuit_enable_disable = false,
        circuit_condition = {
            first_signal = nil,
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

    local checkCount = 0
    -- Mock utils.checkCircuitCondition um mehrere Fehler zu simulieren
    utils.checkCircuitCondition = function(cc)
        checkCount = checkCount + 1
        if checkCount == 1 then
            -- Nach erstem Fix: noch firstSignalEmpty
            return false, configureTurrets.states.firstSignalEmpty
        else
            -- Nach zweitem Fix: ok
            return true, nil
        end
    end

    configureTurrets.autoConfigure({tc}, pons)

    -- Überprüfe, dass beide Fehler behoben wurden
    lu.assertTrue(mockControlBehavior.circuit_enable_disable)
    lu.assertNotNil(mockControlBehavior.circuit_condition.first_signal)
end
-- ###############################################################

function TestConfigureTurrets:test_autoConfigure_infinite_loop_protection()
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

    -- Mock utils.checkCircuitCondition um immer den gleichen Fehler zurückzugeben
    utils.checkCircuitCondition = function(cc)
        return false, configureTurrets.states.firstSignalEmpty
    end

    -- Das sollte nicht in einer Endlosschleife enden
    configureTurrets.autoConfigure({tc}, { turretsOnPlatform = {} })

    -- Test ist erfolgreich, wenn wir hier ankommen (keine Endlosschleife)
    lu.assertTrue(true)
end
-- ###############################################################

-- ###############################################################
-- Tests für Edge Cases
-- ###############################################################

function TestConfigureTurrets:test_autoConfigure_invalid_turret()
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

    -- Sollte nicht abstürzen, auch wenn Turret invalid ist
    configureTurrets.autoConfigure({ tc })

    lu.assertTrue(true) -- Test erfolgreich wenn kein Fehler auftritt
end
-- ###############################################################

function TestConfigureTurrets:test_autoConfigure_invalid_control_behavior()
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
                    --get_circuit_network = function(wc)
                    --    return {} -- Mock network
                    --end,
                    --circuit_condition = {
                    --    first_signal = { type = "virtual", name = "signal-A" }
                    --}
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

    -- Sollte nicht abstürzen, auch wenn ControlBehavior invalid ist
    configureTurrets.autoConfigure( { tc }, pons)

    lu.assertTrue(true) -- Test erfolgreich wenn kein Fehler auftritt
end
-- ###############################################################

function TestConfigureTurrets:test_autoConfigure_unsupported_case()
    local mockControlBehavior = {
        valid = true,
        circuit_condition = {}
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
        stateConfiguration = 999, -- Unsupported state
        cc = mockControlBehavior.circuit_condition
    }

    -- Mock utils.checkCircuitCondition
    utils.checkCircuitCondition = function(cc)
        return true, nil
    end

    -- Sollte nicht abstürzen bei unsupportetem Case
    configureTurrets.autoConfigure({tc}, {})

    lu.assertTrue(true) -- Test erfolgreich wenn kein Fehler auftritt
end
-- ###############################################################

function TestConfigureTurrets:test_firstSignalEmpty_no_available_signals()
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
                        return {} -- Mock network
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
                        return {} -- Mock network
                    end,
                    circuit_condition = {
                        first_signal = { type = "virtual", name = "signal-B" }
                    }
                }
            }
        }
    }

    -- Alle verfügbaren Signale sind bereits in Benutzung
    -- Die Funktion sollte trotzdem nicht abstürzen
    configureTurrets.autoConfigure({tc}, pons)

    lu.assertTrue(true) -- Test erfolgreich wenn kein Fehler auftritt
end
-- ###############################################################

BaseTest:hookTests()
