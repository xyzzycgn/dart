---
--- Created by xyzzycgn.
--- support for mods offering ammo-turrets without circuit_connector
---
local Log = require("__log4factorio__.Log")
Log.setSeverity(Log.CONFIG)

--- @param variation number
--- @param x number
--- @param y number
--- @param asArray boolean
local function createVariation(variation, x, y, asArray)
    local var = { variation = variation, main_offset = util.by_pixel(x, y), shadow_offset = util.by_pixel(0, 0), show_shadow = false }
    return asArray and { var } or var
end

local function repeatCreateVariation(variation, x, y, cnt)
    local listOfVariations = {}
    for i = 1, cnt do
        listOfVariations[#listOfVariations + 1] = createVariation(variation, x, y)
    end

    return listOfVariations
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function addCircuitConnector(turret_name, ccd_name)
    local turret = data.raw["ammo-turret"][turret_name]
    turret.circuit_connector = circuit_connector_definitions[ccd_name]
    turret.circuit_wire_max_distance = default_circuit_wire_max_distance
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function createVariationsAndAddCircuitConnector(ccd_name, listOfVariations, turret_name)
    circuit_connector_definitions[ccd_name] = circuit_connector_definitions.create_vector(universal_connector_template, listOfVariations)
    addCircuitConnector(turret_name, ccd_name)
end
-- ###############################################################

if mods['vtk-cannon-turret'] then
    Log.log("mod vtk-cannon-turret detected", function(m)log(m)end, Log.CONFIG)

    createVariationsAndAddCircuitConnector(
        "dart-turret-vtk",
        repeatCreateVariation(17, -20, 15, 4),
        "vtk-cannon-turret"
    )

    createVariationsAndAddCircuitConnector(
        "dart-turret-heavy-vtk",
        repeatCreateVariation(17, -31,  21, 4),
        "vtk-cannon-turret-heavy"
    )
end
-- ###############################################################

if mods['RampantArsenalFork'] then
    Log.log("mod RampantArsenalFork detected", function(m)log(m)end, Log.CONFIG)

    local function rampant_name(name)
        return name .. "-ammo-turret-rampant-arsenal"
    end

    createVariationsAndAddCircuitConnector("dart-cannon-rampant",
        repeatCreateVariation(17, -41.5, 24, 4),
        rampant_name("cannon")
    )

    createVariationsAndAddCircuitConnector("dart-rapid-cannon-rampant",
        repeatCreateVariation(26, 0, 28, 4),
        rampant_name("rapid-cannon")
    )

    createVariationsAndAddCircuitConnector("dart-rocket-rampant",
        repeatCreateVariation(31, 21, 24, 4),
        rampant_name("rocket")
    )

    createVariationsAndAddCircuitConnector("dart-rapid-rocket-rampant",
        repeatCreateVariation(0, 6, 24, 4),
        rampant_name("rapid-rocket")
    )

    createVariationsAndAddCircuitConnector("dart-gun-rampant",
        createVariation(33, 15, 21, true),
        rampant_name("gun"))
end
-- ###############################################################

if mods["Additional-Turret-revived"] then
    Log.log("mod Additional-Turret-revived detected", function(m)log(m)end, Log.CONFIG)

    -- MK1
    createVariationsAndAddCircuitConnector(
        "dart-cannon-turret-mk1-at",
        createVariation(17, -18, 7, true),
        "at-cannon-turret-mk1"
    )

    --data.raw["ammo-turret"]["at-rocket-turret-mk1"].turret_base_has_direction = true
    createVariationsAndAddCircuitConnector(
        "dart-rocket-turret-mk1-at",
        createVariation(26, 14, 17, true),
        "at-rocket-turret-mk1"
    )

    -- MK2
    createVariationsAndAddCircuitConnector(
            "dart-cannon-turret-mk2-at",
            createVariation(24, -25, 5, true),
            "at-cannon-turret-mk2"
    )

    createVariationsAndAddCircuitConnector(
            "dart-rocket-turret-mk2-at",
            repeatCreateVariation(12, 27, 14, 4),
            "at-rocket-turret-mk2"
    )

    --
    createVariationsAndAddCircuitConnector(
            "dart-gatling-turret-at",
            createVariation(27, 28, 19, true),
            "at-gatling-turret"
    )


    createVariationsAndAddCircuitConnector(
            "dart-CR_b-at",
            createVariation(26, 0, 36, true),
            "at_CR_b"
    )

    createVariationsAndAddCircuitConnector(
            "dart-A1_b-at",
            createVariation(18, -2, 40, true),
            "at_A1_b"
    )

    createVariationsAndAddCircuitConnector(
            "dart-A2_b-at",
            createVariation(18, -2, 40, true),
            "at_A2_b"
    )

end