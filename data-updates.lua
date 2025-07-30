---
--- Created by xyzzycgn.
--- DateTime: 29.07.25 18:01
---
local Log = require("__log4factorio__.Log")
Log.setSeverity(Log.CONFIG)

local function createVariation(num, x, y)
    return { variation = num, main_offset = util.by_pixel(x, y), shadow_offset = util.by_pixel(0, 0), show_shadow = false }
end

Log.logBlock(circuit_connector_definitions, function(m)log(m)end, Log.CONFIG)

circuit_connector_definitions["dart-turret"] = circuit_connector_definitions.create_vector(universal_connector_template, {
    --createVariation(0,   6,  24),
    --createVariation(7, -20,  20),
    --createVariation(6, -34,   0),
    --createVariation(5, -37,  -8),
    --createVariation(4, -37,  -8),
    --createVariation(3,  34, -12),
    --createVariation(2,  37,  -8),
    --createVariation(1,  30,  16)

    createVariation(0,   0,  20),
    createVariation(6, -20,   0),
    createVariation(4,   0, -20),
    createVariation(2,  20,   0),
})

Log.logBlock(circuit_connector_definitions["dart-turret"], function(m)log(m)end, Log.CONFIG)

if mods['vtk-cannon-turret'] then
    Log.log("mod vtk-cannon-turret detected", function(m)log(m)end, Log.CONFIG)

  --table.insert(data.raw["ammo-turret"]["vtk-cannon-turret"], {
  --   circuit_connector = circuit_connector_definitions["dart-turret"],
  --   circuit_wire_max_distance = default_circuit_wire_max_distance,
  --})
    local turret = data.raw["ammo-turret"]["vtk-cannon-turret"]
    turret.circuit_connector = circuit_connector_definitions["dart-turret"]
    turret.circuit_wire_max_distance = default_circuit_wire_max_distance

    local hturret = data.raw["ammo-turret"]["vtk-cannon-turret-heavy"]
    hturret.circuit_connector = circuit_connector_definitions["dart-turret"]
    hturret.circuit_wire_max_distance = default_circuit_wire_max_distance

    Log.logBlock(data.raw["ammo-turret"]["vtk-cannon-turret"], function(m)log(m)end, Log.CONFIG)
    Log.logBlock(data.raw["ammo-turret"]["vtk-cannon-turret-heavy"], function(m)log(m)end, Log.CONFIG)
end


