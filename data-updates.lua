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
-- ###############################################################

if mods['vtk-cannon-turret'] then
    Log.log("mod vtk-cannon-turret detected", function(m)log(m)end, Log.CONFIG)

    circuit_connector_definitions["dart-turret-vtk"] = circuit_connector_definitions.create_vector(universal_connector_template, {
        createVariation(17, -20, 15),
        createVariation(17, -20, 15),
        createVariation(17, -20, 15),
        createVariation(17, -20, 15),
    })

    circuit_connector_definitions["dart-turret-heavy-vtk"] = circuit_connector_definitions.create_vector(universal_connector_template, {
        createVariation(17,   -31,  21),
        createVariation(17,   -31,  21),
        createVariation(17,   -31,  21),
        createVariation(17,   -31,  21),
    })

    addCircuitConnector("vtk-cannon-turret", "dart-turret-vtk")
    addCircuitConnector("vtk-cannon-turret-heavy", "dart-turret-heavy-vtk")
end
-- ###############################################################

if mods['RampantArsenalFork'] then
    Log.log("mod RampantArsenalFork detected", function(m)log(m)end, Log.CONFIG)

    circuit_connector_definitions["dart-cannon-rampant"] = circuit_connector_definitions.create_vector(universal_connector_template, {
        createVariation(17,   -41.5,  24),
        createVariation(17,   -41.5,  24),
        createVariation(17,   -41.5,  24),
        createVariation(17,   -41.5,  24),
    })

    circuit_connector_definitions["dart-rapid-cannon-rampant"] = circuit_connector_definitions.create_vector(universal_connector_template, {
        createVariation(26,   0,  28),
        createVariation(26,   0,  28),
        createVariation(26,   0,  28),
        createVariation(26,   0,  28),
    })

    circuit_connector_definitions["dart-rocket-rampant"] = circuit_connector_definitions.create_vector(universal_connector_template, {
        createVariation(31, 21, 24),
        createVariation(31, 21, 24),
        createVariation(31, 21, 24),
        createVariation(31, 21, 24),
    })

    circuit_connector_definitions["dart-rapid-rocket-rampant"] = circuit_connector_definitions.create_vector(universal_connector_template, {
        createVariation(0, 6, 24),
        createVariation(0, 6, 24),
        createVariation(0, 6, 24),
        createVariation(0, 6, 24),
    })

    circuit_connector_definitions["dart-gun-rampant"] = circuit_connector_definitions.create_vector(universal_connector_template, {
        createVariation(33, 15, 21),
    })

    local function rampant_name(name)
        return name .. "-ammo-turret-rampant-arsenal"
    end

    addCircuitConnector(rampant_name("cannon"), "dart-cannon-rampant")
    addCircuitConnector(rampant_name("rapid-cannon"), "dart-rapid-cannon-rampant")

    addCircuitConnector(rampant_name("rocket"), "dart-rocket-rampant")
    addCircuitConnector(rampant_name("rapid-rocket"), "dart-rapid-rocket-rampant")

    addCircuitConnector(rampant_name("gun"), "dart-gun-rampant")
end

