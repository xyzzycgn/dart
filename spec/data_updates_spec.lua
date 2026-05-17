---
--- Created by xyzzycgn.
---
local Require = require("test.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)

require("spec.common")

describe("data-updates", function()
    local createdConnectors
    local logCalls

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

        _G.data = {
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
                    ["at-gatling-turret"] = atrGatlingTurret,
                    ["at_CR_b"] = atrCRb,
                    ["at_A1_b"] = atrA1b,
                    ["at_A2_b"] = atrA2b,
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
            atrGatlingTurret = atrGatlingTurret,
            atrCRb = atrCRb,
            atrA1b = atrA1b,
            atrA2b = atrA2b,
        }
    end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    local function makeCircuitConnectorDefinitions()
        local created = {}

        _G.circuit_connector_definitions = {
            create_vector = function(template, variations)
                local result = {
                    template = template,
                    variations = variations
                }
                table.insert(created, result)
                return result
            end
        }

        return created
    end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    local function mockGlobals()
        _G.util = {
            by_pixel = function(x, y)
                return { x = x, y = y }
            end
        }

        _G.universal_connector_template = { mocked = true }
        _G.default_circuit_wire_max_distance = 42

        _G.mods = {}

        return makeCircuitConnectorDefinitions()
    end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    local function reloadModule()
        package.loaded["data-updates"] = nil
        dofile("data-updates.lua")
    end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    local function assertVariation(v, expectedVariation, expectedX, expectedY)
        assert.are.equal(expectedVariation, v.variation)
        assert.are.same({ x = expectedX, y = expectedY }, v.main_offset)
        assert.are.same({ x = 0, y = 0 }, v.shadow_offset)
        assert.is_false(v.show_shadow)
    end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    local function assertRepeatedVariation(v, expectedVariation, expectedX, expectedY, count)
        for i = 1, count do
            assertVariation(v.variations[i], expectedVariation, expectedX, expectedY)
        end
    end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    before_each(function()
        createdConnectors = mockGlobals()

        logCalls = 0
        log = function()
            logCalls = logCalls + 1
        end
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("without optional mods", function()
        it("does nothing", function()
            reloadModule()

            assert.are.equal(0, logCalls)
            assert.are.equal(0, #createdConnectors)
        end)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("with vtk-cannon-turret", function()
        it("creates the expected connectors", function()
            mods["vtk-cannon-turret"] = true

            local mocked = makeData()
            reloadModule()

            assert.are.equal(2, #createdConnectors)

            assert.is_not_nil(mocked.vtkTurret.circuit_connector)
            assert.is_not_nil(mocked.vtkHeavyTurret.circuit_connector)
            assert.are.equal(42, mocked.vtkTurret.circuit_wire_max_distance)
            assert.are.equal(42, mocked.vtkHeavyTurret.circuit_wire_max_distance)

            assert.are.equal(createdConnectors[1], mocked.vtkTurret.circuit_connector)
            assert.are.equal(createdConnectors[2], mocked.vtkHeavyTurret.circuit_connector)

            assert.are.equal(universal_connector_template, createdConnectors[1].template)
            assert.are.equal(universal_connector_template, createdConnectors[2].template)

            assert.are.equal(4, #createdConnectors[1].variations)
            assert.are.equal(4, #createdConnectors[2].variations)

            assertRepeatedVariation(createdConnectors[1], 17, -20, 15, 4)
            assertRepeatedVariation(createdConnectors[2], 17, -31, 21, 4)
        end)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("with Rampant Arsenal Fork", function()
        it("creates the expected connectors", function()
            mods["RampantArsenalFork"] = true

            local mocked = makeData()
            reloadModule()

            assert.are.equal(5, #createdConnectors)

            assert.are.equal(createdConnectors[1], mocked.rampantCannonTurret.circuit_connector)
            assert.are.equal(createdConnectors[2], mocked.rampantRapidCannonTurret.circuit_connector)
            assert.are.equal(createdConnectors[3], mocked.rampantRocketTurret.circuit_connector)
            assert.are.equal(createdConnectors[4], mocked.rampantRapidRocketTurret.circuit_connector)
            assert.are.equal(createdConnectors[5], mocked.rampantGunTurret.circuit_connector)

            assert.are.equal(42, mocked.rampantCannonTurret.circuit_wire_max_distance)
            assert.are.equal(42, mocked.rampantRapidCannonTurret.circuit_wire_max_distance)
            assert.are.equal(42, mocked.rampantRocketTurret.circuit_wire_max_distance)
            assert.are.equal(42, mocked.rampantRapidRocketTurret.circuit_wire_max_distance)
            assert.are.equal(42, mocked.rampantGunTurret.circuit_wire_max_distance)

            assert.are.equal(4, #createdConnectors[1].variations)
            assert.are.equal(4, #createdConnectors[2].variations)
            assert.are.equal(4, #createdConnectors[3].variations)
            assert.are.equal(4, #createdConnectors[4].variations)
            assert.are.equal(1, #createdConnectors[5].variations)

            assertRepeatedVariation(createdConnectors[1], 17, -41.5, 24, 4)
            assertRepeatedVariation(createdConnectors[2], 26, 0, 28, 4)
            assertRepeatedVariation(createdConnectors[3], 31, 21, 24, 4)
            assertRepeatedVariation(createdConnectors[4], 0, 6, 24, 4)
            assertVariation(createdConnectors[5].variations[1], 33, 15, 21)
        end)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("with Additional Turret revived", function()
        it("creates the expected connectors", function()
            mods["Additional-Turret-revived"] = true

            local mocked = makeData()
            reloadModule()

            assert.are.equal(8, #createdConnectors)

            assert.are.equal(createdConnectors[1], mocked.atrCannonTurretMk1.circuit_connector)
            assert.are.equal(createdConnectors[2], mocked.atrRocketTurretMk1.circuit_connector)
            assert.are.equal(createdConnectors[3], mocked.atrCannonTurretMk2.circuit_connector)
            assert.are.equal(createdConnectors[4], mocked.atrRocketTurretMk2.circuit_connector)
            assert.are.equal(createdConnectors[5], mocked.atrGatlingTurret.circuit_connector)
            assert.are.equal(createdConnectors[6], mocked.atrCRb.circuit_connector)
            assert.are.equal(createdConnectors[7], mocked.atrA1b.circuit_connector)
            assert.are.equal(createdConnectors[8], mocked.atrA2b.circuit_connector)

            assert.are.equal(42, mocked.atrCannonTurretMk1.circuit_wire_max_distance)
            assert.are.equal(42, mocked.atrRocketTurretMk1.circuit_wire_max_distance)
            assert.are.equal(42, mocked.atrCannonTurretMk2.circuit_wire_max_distance)
            assert.are.equal(42, mocked.atrRocketTurretMk2.circuit_wire_max_distance)
            assert.are.equal(42, mocked.atrGatlingTurret.circuit_wire_max_distance)
            assert.are.equal(42, mocked.atrCRb.circuit_wire_max_distance)
            assert.are.equal(42, mocked.atrA1b.circuit_wire_max_distance)
            assert.are.equal(42, mocked.atrA2b.circuit_wire_max_distance)

            assert.are.equal(1, #createdConnectors[1].variations)
            assert.are.equal(1, #createdConnectors[2].variations)
            assert.are.equal(1, #createdConnectors[3].variations)
            assert.are.equal(4, #createdConnectors[4].variations)
            assert.are.equal(1, #createdConnectors[5].variations)
            assert.are.equal(1, #createdConnectors[6].variations)
            assert.are.equal(1, #createdConnectors[7].variations)
            assert.are.equal(1, #createdConnectors[8].variations)

            assertRepeatedVariation(createdConnectors[1], 17, -18, 7, 1)
            assertRepeatedVariation(createdConnectors[2], 26, 14, 17, 1)
            assertRepeatedVariation(createdConnectors[3], 24, -25, 5, 1)
            assertRepeatedVariation(createdConnectors[4], 12, 27, 14, 4)

            assertVariation(createdConnectors[5].variations[1], 27, 28, 19)
            assertVariation(createdConnectors[6].variations[1], 26, 0, 36)
            assertVariation(createdConnectors[7].variations[1], 18, -2, 40)
            assertVariation(createdConnectors[8].variations[1], 18, -2, 40)
        end)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("with all supported optional mods", function()
        it("creates all expected connectors", function()
            mods["vtk-cannon-turret"] = true
            mods["RampantArsenalFork"] = true
            mods["Additional-Turret-revived"] = true

            local mocked = makeData()
            reloadModule()

            assert.are.equal(15, #createdConnectors)

            assert.are.equal(createdConnectors[1], mocked.vtkTurret.circuit_connector)
            assert.are.equal(createdConnectors[2], mocked.vtkHeavyTurret.circuit_connector)

            assert.are.equal(createdConnectors[3], mocked.rampantCannonTurret.circuit_connector)
            assert.are.equal(createdConnectors[4], mocked.rampantRapidCannonTurret.circuit_connector)
            assert.are.equal(createdConnectors[5], mocked.rampantRocketTurret.circuit_connector)
            assert.are.equal(createdConnectors[6], mocked.rampantRapidRocketTurret.circuit_connector)
            assert.are.equal(createdConnectors[7], mocked.rampantGunTurret.circuit_connector)

            assert.are.equal(createdConnectors[8], mocked.atrCannonTurretMk1.circuit_connector)
            assert.are.equal(createdConnectors[9], mocked.atrRocketTurretMk1.circuit_connector)
            assert.are.equal(createdConnectors[10], mocked.atrCannonTurretMk2.circuit_connector)
            assert.are.equal(createdConnectors[11], mocked.atrRocketTurretMk2.circuit_connector)
            assert.are.equal(createdConnectors[12], mocked.atrGatlingTurret.circuit_connector)
            assert.are.equal(createdConnectors[13], mocked.atrCRb.circuit_connector)
            assert.are.equal(createdConnectors[14], mocked.atrA1b.circuit_connector)
            assert.are.equal(createdConnectors[15], mocked.atrA2b.circuit_connector)
        end)
    end)
end)
