---
--- Created by xyzzycgn.
--- DateTime: 29.07.25 18:01
---
local Log = require("__log4factorio__.Log")
Log.setSeverity(Log.CONFIG)

local function createVariation(variation, x, y)
    return { variation = variation, main_offset = util.by_pixel(x, y), shadow_offset = util.by_pixel(0, 0), show_shadow = false }
end

local function addCircuitConnector(turret_name, ccd_name)
    local turret = data.raw["ammo-turret"][turret_name]
    turret.circuit_connector = circuit_connector_definitions[ccd_name]
    turret.circuit_wire_max_distance = default_circuit_wire_max_distance
end

local function createVariationsAndAddCircuitConnector(ccd_name, listOfVariations, turret_name)
    circuit_connector_definitions[ccd_name] = circuit_connector_definitions.create_vector(universal_connector_template, listOfVariations)
    addCircuitConnector(turret_name, ccd_name)
end
-- ###############################################################

if mods['vtk-cannon-turret'] then
    Log.log("mod vtk-cannon-turret detected", function(m)log(m)end, Log.CONFIG)

    createVariationsAndAddCircuitConnector("dart-turret-vtk", {
        createVariation(17, -20, 15),
        createVariation(17, -20, 15),
        createVariation(17, -20, 15),
        createVariation(17, -20, 15),
    }, "vtk-cannon-turret")

    createVariationsAndAddCircuitConnector("dart-turret-heavy-vtk", {
        createVariation(17,   -31,  21),
        createVariation(17,   -31,  21),
        createVariation(17,   -31,  21),
        createVariation(17,   -31,  21),
    }, "vtk-cannon-turret-heavy")
end
-- ###############################################################

if mods['RampantArsenalFork'] then
    Log.log("mod RampantArsenalFork detected", function(m)log(m)end, Log.CONFIG)

    local function rampant_name(name)
        return name .. "-ammo-turret-rampant-arsenal"
    end

    createVariationsAndAddCircuitConnector("dart-cannon-rampant", {
        createVariation(17,   -41.5,  24),
        createVariation(17,   -41.5,  24),
        createVariation(17,   -41.5,  24),
        createVariation(17,   -41.5,  24),
    }, rampant_name("cannon"))

    createVariationsAndAddCircuitConnector("dart-rapid-cannon-rampant", {
        createVariation(26,   0,  28),
        createVariation(26,   0,  28),
        createVariation(26,   0,  28),
        createVariation(26,   0,  28),
    }, rampant_name("rapid-cannon"))

    createVariationsAndAddCircuitConnector("dart-rocket-rampant", {
        createVariation(31, 21, 24),
        createVariation(31, 21, 24),
        createVariation(31, 21, 24),
        createVariation(31, 21, 24),
    }, rampant_name("rocket"))

    createVariationsAndAddCircuitConnector("dart-rapid-rocket-rampant", {
        createVariation(0, 6, 24),
        createVariation(0, 6, 24),
        createVariation(0, 6, 24),
        createVariation(0, 6, 24),
    }, rampant_name("rapid-rocket"))

    createVariationsAndAddCircuitConnector("dart-gun-rampant", {
        createVariation(33, 15, 21),
    }, rampant_name("gun"))
end

