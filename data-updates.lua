---
--- Created by xyzzycgn.
--- DateTime: 29.07.25 18:01
---
local Log = require("__log4factorio__.Log")
Log.setSeverity(Log.CONFIG)

local function createVariation(num, x, y)
    return { variation = num, main_offset = util.by_pixel(x, y), shadow_offset = util.by_pixel(0, 0), show_shadow = false }
end

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

    local turret = data.raw["ammo-turret"]["vtk-cannon-turret"]
    turret.circuit_connector = circuit_connector_definitions["dart-turret-vtk"]
    turret.circuit_wire_max_distance = default_circuit_wire_max_distance

    local hturret = data.raw["ammo-turret"]["vtk-cannon-turret-heavy"]
    hturret.circuit_connector = circuit_connector_definitions["dart-turret-heavy-vtk"]
    hturret.circuit_wire_max_distance = default_circuit_wire_max_distance
end


