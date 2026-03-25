---
--- Created by xyzzycgn.
--- DateTime: 24.03.26 12:19
---
---
--- Created by xyzzycgn.
---
require('test.BaseTest')
local lu = require('luaunit')

TestDataUpdates = {}

local function makeData()
    local vtkTurret = {}
    local vtkHeavyTurret = {}

    local rampantCannonTurret = {}
    local rampantRapidCannonTurret = {}
    local rampantRocketTurret = {}
    local rampantRapidRocketTurret = {}
    local rampantGunTurret = {}

    local atrCannonTurretMk1 = {}
    local atrRocketTurretMk1 = {}
    local atrCannonTurretMk2 = {}
    local atrRocketTurretMk2 = {}
    local atrGatlingTurret = {}
    local atrCRb = {}
    local atrA1b = {}
    local atrA2b = {}

    data = {
        raw = {
            ["ammo-turret"] = {
                ["vtk-cannon-turret"] = vtkTurret,
                ["vtk-cannon-turret-heavy"] = vtkHeavyTurret,

                ["cannon-ammo-turret-rampant-arsenal"] = rampantCannonTurret,
                ["rapid-cannon-ammo-turret-rampant-arsenal"] = rampantRapidCannonTurret,
                ["rocket-ammo-turret-rampant-arsenal"] = rampantRocketTurret,
                ["rapid-rocket-ammo-turret-rampant-arsenal"] = rampantRapidRocketTurret,
                ["gun-ammo-turret-rampant-arsenal"] = rampantGunTurret,

                ["at-cannon-turret-mk1"] = atrCannonTurretMk1,
                ["at-rocket-turret-mk1"] = atrRocketTurretMk1,
                ["at-cannon-turret-mk2"] = atrCannonTurretMk2,
                ["at-rocket-turret-mk2"] = atrRocketTurretMk2,
                ["at-gatling-turret"]    = atrGatlingTurret,
                ["at_CR_b"]              = atrCRb,
                ["at_A1_b"]              = atrA1b,
                ["at_A2_b"]              = atrA2b,
            }
        }
    }

    return {
        vtkTurret = vtkTurret,
        vtkHeavyTurret = vtkHeavyTurret,

        rampantCannonTurret = rampantCannonTurret,
        rampantRapidCannonTurret = rampantRapidCannonTurret,
        rampantRocketTurret = rampantRocketTurret,
        rampantRapidRocketTurret = rampantRapidRocketTurret,
        rampantGunTurret = rampantGunTurret,

        atrCannonTurretMk1 = atrCannonTurretMk1,
        atrRocketTurretMk1 = atrRocketTurretMk1,
        atrCannonTurretMk2 = atrCannonTurretMk2,
        atrRocketTurretMk2 = atrRocketTurretMk2,
        atrGatlingTurret   = atrGatlingTurret,
        atrCRb             = atrCRb,
        atrA1b             = atrA1b,
        atrA2b             = atrA2b,
    }
end

local function makeCircuitConnectorDefinitions()
    local created = {}

    circuit_connector_definitions = {
        create_vector = function(template, variations)
            local erg = {
                template = template,
                variations = variations
            }
            table.insert(created, erg)
            return erg
        end
    }

    return created
end

local function mockGlobals()
    util = {
        by_pixel = function(x, y)
            return { x = x, y = y }
        end
    }

    universal_connector_template = { mocked = true }
    default_circuit_wire_max_distance = 42

    local created = makeCircuitConnectorDefinitions()

    mods = {}
    return created
end

local function reloadModule()
    package.loaded["data-updates"] = nil
    dofile("data-updates.lua")
end

local function assertVariation(v, expectedVariation, expectedX, expectedY)
    lu.assertEquals(v.variation, expectedVariation)
    lu.assertEquals(v.main_offset, { x = expectedX, y = expectedY })
    lu.assertEquals(v.shadow_offset, { x = 0, y = 0 })
    lu.assertFalse(v.show_shadow)
end

local function assertRepeatedVariation(v, expectedVariation, expectedX, expectedY, cnt)
    for i = 1, cnt do
        assertVariation(v.variations[i], expectedVariation, expectedX, expectedY)
    end
end


function TestDataUpdates:setUp()
    local created = mockGlobals()
    self.createdConnectors = created

    local logCalls = 0
    log = function()
        logCalls = logCalls + 1
    end
    self.logCalls = function()
        return logCalls
    end
end
-- ###############################################################

function TestDataUpdates:test_noMods_doesNothing()
    reloadModule()

    lu.assertEquals(self.logCalls(), 0)
    lu.assertEquals(#self.createdConnectors, 0)
end
-- ###############################################################

function TestDataUpdates:test_vtkMod_createsExpectedConnectors()
    mods["vtk-cannon-turret"] = true

    local mocked = makeData()
    reloadModule()

    lu.assertEquals(#self.createdConnectors, 2)

    lu.assertNotNil(mocked.vtkTurret.circuit_connector)
    lu.assertNotNil(mocked.vtkHeavyTurret.circuit_connector)
    lu.assertEquals(mocked.vtkTurret.circuit_wire_max_distance, 42)
    lu.assertEquals(mocked.vtkHeavyTurret.circuit_wire_max_distance, 42)

    lu.assertEquals(mocked.vtkTurret.circuit_connector, self.createdConnectors[1])
    lu.assertEquals(mocked.vtkHeavyTurret.circuit_connector, self.createdConnectors[2])

    lu.assertEquals(self.createdConnectors[1].template, universal_connector_template)
    lu.assertEquals(self.createdConnectors[2].template, universal_connector_template)

    lu.assertEquals(#self.createdConnectors[1].variations, 4)
    lu.assertEquals(#self.createdConnectors[2].variations, 4)

    assertRepeatedVariation(self.createdConnectors[1], 17, -20, 15, 4)
    assertRepeatedVariation(self.createdConnectors[2], 17, -31, 21, 4)
end
-- ###############################################################

function TestDataUpdates:test_rampantMod_createsExpectedConnectors()
    mods["RampantArsenalFork"] = true

    local mocked = makeData()
    reloadModule()

    lu.assertEquals(#self.createdConnectors, 5)

    lu.assertEquals(mocked.rampantCannonTurret.circuit_connector, self.createdConnectors[1])
    lu.assertEquals(mocked.rampantRapidCannonTurret.circuit_connector, self.createdConnectors[2])
    lu.assertEquals(mocked.rampantRocketTurret.circuit_connector, self.createdConnectors[3])
    lu.assertEquals(mocked.rampantRapidRocketTurret.circuit_connector, self.createdConnectors[4])
    lu.assertEquals(mocked.rampantGunTurret.circuit_connector, self.createdConnectors[5])

    lu.assertEquals(mocked.rampantCannonTurret.circuit_wire_max_distance, 42)
    lu.assertEquals(mocked.rampantGunTurret.circuit_wire_max_distance, 42)
    lu.assertEquals(mocked.rampantGunTurret.circuit_wire_max_distance, 42)
    lu.assertEquals(mocked.rampantGunTurret.circuit_wire_max_distance, 42)
    lu.assertEquals(mocked.rampantGunTurret.circuit_wire_max_distance, 42)

    lu.assertEquals(#self.createdConnectors[1].variations, 4)
    lu.assertEquals(#self.createdConnectors[2].variations, 4)
    lu.assertEquals(#self.createdConnectors[3].variations, 4)
    lu.assertEquals(#self.createdConnectors[4].variations, 4)
    lu.assertEquals(#self.createdConnectors[5].variations, 1)

    assertRepeatedVariation(self.createdConnectors[1], 17, -41.5, 24, 4)

    assertRepeatedVariation(self.createdConnectors[2],26, 0, 28, 4)

    assertRepeatedVariation(self.createdConnectors[3], 31, 21, 24, 4)

    assertRepeatedVariation(self.createdConnectors[4], 0, 6, 24, 4)

    assertVariation(self.createdConnectors[5].variations[1], 33, 15, 21)
end
-- ###############################################################

function TestDataUpdates:test_Additional_Turret_revived_createsExpectedConnectors()
    mods["Additional-Turret-revived"] = true

    local mocked = makeData()
    reloadModule()

    lu.assertEquals(#self.createdConnectors, 8)

    lu.assertEquals(mocked.atrCannonTurretMk1.circuit_connector, self.createdConnectors[1])
    lu.assertEquals(mocked.atrRocketTurretMk1.circuit_connector, self.createdConnectors[2])
    lu.assertEquals(mocked.atrCannonTurretMk2.circuit_connector, self.createdConnectors[3])
    lu.assertEquals(mocked.atrRocketTurretMk2.circuit_connector, self.createdConnectors[4])
    lu.assertEquals(mocked.atrGatlingTurret.circuit_connector, self.createdConnectors[5])
    lu.assertEquals(mocked.atrCRb.circuit_connector, self.createdConnectors[6])
    lu.assertEquals(mocked.atrA1b.circuit_connector, self.createdConnectors[7])
    lu.assertEquals(mocked.atrA2b.circuit_connector, self.createdConnectors[8])

    lu.assertEquals(mocked.atrCannonTurretMk1.circuit_wire_max_distance, 42)
    lu.assertEquals(mocked.atrRocketTurretMk1.circuit_wire_max_distance, 42)
    lu.assertEquals(mocked.atrCannonTurretMk2.circuit_wire_max_distance, 42)
    lu.assertEquals(mocked.atrRocketTurretMk2.circuit_wire_max_distance, 42)
    lu.assertEquals(mocked.atrGatlingTurret.circuit_wire_max_distance, 42)
    lu.assertEquals(mocked.atrCRb.circuit_wire_max_distance, 42)
    lu.assertEquals(mocked.atrA1b.circuit_wire_max_distance, 42)
    lu.assertEquals(mocked.atrA2b.circuit_wire_max_distance, 42)

    lu.assertEquals(#self.createdConnectors[1].variations, 1)
    lu.assertEquals(#self.createdConnectors[2].variations, 1)
    lu.assertEquals(#self.createdConnectors[3].variations, 1)
    lu.assertEquals(#self.createdConnectors[4].variations, 4)
    lu.assertEquals(#self.createdConnectors[5].variations, 1)
    lu.assertEquals(#self.createdConnectors[6].variations, 1)
    lu.assertEquals(#self.createdConnectors[7].variations, 1)
    lu.assertEquals(#self.createdConnectors[8].variations, 1)

    assertRepeatedVariation(self.createdConnectors[1], 17, -18, 7, 1)

    assertRepeatedVariation(self.createdConnectors[2], 26, 14, 17, 1)

    assertRepeatedVariation(self.createdConnectors[3], 24, -25, 5, 1)

    assertRepeatedVariation(self.createdConnectors[4], 12, 27, 14, 4)

    assertVariation(self.createdConnectors[5].variations[1], 27, 28, 19)
    assertVariation(self.createdConnectors[6].variations[1], 26, 0, 36)
    assertVariation(self.createdConnectors[7].variations[1], 18, -2, 40)
    assertVariation(self.createdConnectors[8].variations[1], 18, -2, 40)
end
-- ###############################################################

function TestDataUpdates:test_AllMods_createAllConnectors()
    mods["vtk-cannon-turret"] = true
    mods["RampantArsenalFork"] = true
    mods["Additional-Turret-revived"] = true

    local mocked = makeData()
    reloadModule()

    lu.assertEquals(#self.createdConnectors, 15)

    lu.assertEquals(mocked.vtkTurret.circuit_connector, self.createdConnectors[1])
    lu.assertEquals(mocked.vtkHeavyTurret.circuit_connector, self.createdConnectors[2])

    lu.assertEquals(mocked.rampantCannonTurret.circuit_connector, self.createdConnectors[3])
    lu.assertEquals(mocked.rampantRapidCannonTurret.circuit_connector, self.createdConnectors[4])
    lu.assertEquals(mocked.rampantRocketTurret.circuit_connector, self.createdConnectors[5])
    lu.assertEquals(mocked.rampantRapidRocketTurret.circuit_connector, self.createdConnectors[6])
    lu.assertEquals(mocked.rampantGunTurret.circuit_connector, self.createdConnectors[7])

    lu.assertEquals(mocked.atrCannonTurretMk1.circuit_connector, self.createdConnectors[8])
    lu.assertEquals(mocked.atrRocketTurretMk1.circuit_connector, self.createdConnectors[9])
    lu.assertEquals(mocked.atrCannonTurretMk2.circuit_connector, self.createdConnectors[10])
    lu.assertEquals(mocked.atrRocketTurretMk2.circuit_connector, self.createdConnectors[11])
    lu.assertEquals(mocked.atrGatlingTurret.circuit_connector, self.createdConnectors[12])
    lu.assertEquals(mocked.atrCRb.circuit_connector, self.createdConnectors[13])
    lu.assertEquals(mocked.atrA1b.circuit_connector, self.createdConnectors[14])
    lu.assertEquals(mocked.atrA2b.circuit_connector, self.createdConnectors[15])
end
-- ###############################################################

BaseTest:hookTests()