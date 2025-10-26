---
--- Created by xyzzycgn.
--- DateTime: 03.03.25 20:51
---
local Log = require("__log4factorio__.Log")
Log.setSeverity(Log.INFO)
local data_util = require('__flib__.data-util')
local meld = require('meld') -- from lualib

require("scripts.gui.styles") -- introduces styles specific for D.A.R.T
-- introduces the D.A.R.T. technologies - see #61
local technologies = require("scripts.technologies")

-- fields for scaling (as long as we have only 2 possibilities the neat trick in scale() works)
local fields = {
    shift = true,
    scale = true,
}

-- fields to ignore for scaling
local ignored_fields = {
    working_sound = true,
}

-- Scales values within object
local function scale(object, factor)
    -- Check if we have a number (i.e. it's scale)
    if type(object) == "number" then
        return object * factor
    else
        -- must be shift - neat trick as we have only 2 possibilities ;)
        object[1] = object[1] * factor
        object[2] = object[2] * factor

        return object
    end
end

-- used for shrinking the radar entity
local function rescale_entity(entity, factor)
    if not entity then
        return
    end

    for key, value in pairs(entity) do
        -- Check to see if we need to scale this key's value
        if fields[key] then
            entity[key] = scale(value, factor)
            -- Check to see if we need to ignore this key
        elseif ignored_fields[key] then
            -- nothing to do
        elseif (type(value) == "table") then
            rescale_entity(value, factor)
        end
    end

    return entity
end
-- ###############################################################

-- dart-radar/-fcc should only be build on platforms
local function surface_conditions()
    return {
        { property = "gravity", min = 0, max = 0 },
        { property = "pressure", min = 0, max = 0 },
    }
end


--- create the D.A.R.T-radar and -fcc recipe
local dart_radar_recipe = data_util.copy_prototype(data.raw["recipe"]["radar"], "dart-radar")
dart_radar_recipe.ingredients = {
    { type = "item", name = "radar", amount = 1 },
    { type = "item", name = "electronic-circuit", amount = 4 },
    { type = "item", name = "advanced-circuit", amount = 2 },
    { type = "item", name = "processing-unit", amount = 1 },
}
local dart_fcc_recipe = data_util.copy_prototype(data.raw["recipe"]["constant-combinator"], "dart-fcc")
dart_fcc_recipe.ingredients = {
    { type = "item", name = "electronic-circuit", amount = 40 },
    { type = "item", name = "advanced-circuit", amount = 10 },
    { type = "item", name = "processing-unit", amount = 5 },
}
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- create the D.A.R.T-fcc entity
local dart_fcc_entity = data_util.copy_prototype(data.raw['constant-combinator']['constant-combinator'], "dart-fcc")
dart_fcc_entity.icon = "__dart__/graphics/icons/fcc.png"
dart_fcc_entity.icon_size = 64
dart_fcc_entity.icon_mipmaps = 4
dart_fcc_entity.next_upgrade = nil
dart_fcc_entity.fast_replaceable_group = nil
dart_fcc_entity.surface_conditions = surface_conditions()
local image = "__dart__/graphics/entity/fcc.png"
local dart_fcc_entity_update = {
    sprites = {
        east = {},
        west = {},
        north = {},
        south = {},
    }
}
dart_fcc_entity_update.sprites.east.layers  = {{ filename  = image }}
dart_fcc_entity_update.sprites.west.layers  = {{ filename  = image }}
dart_fcc_entity_update.sprites.north.layers = {{ filename  = image }}
dart_fcc_entity_update.sprites.south.layers = {{ filename  = image }}

dart_fcc_entity = meld(dart_fcc_entity, dart_fcc_entity_update)

Log.logBlock(dart_fcc_entity, function(m)log(m)end, Log.FINER)

--- create the D.A.R.T-radar entity
local dart_radar_entity = data_util.copy_prototype(data.raw["radar"]["radar"], "dart-radar")
dart_radar_entity.icon = "__dart__/graphics/icons/radar.png"
dart_radar_entity.icon_size = 64
dart_radar_entity.icon_mipmaps = 4
dart_radar_entity.next_upgrade = nil
-- twice as fast and clockwise rotation - use of the neg. value is an undocumented feature, but works fine ;-)
dart_radar_entity.rotation_speed = -0.02
dart_radar_entity.energy_usage = "100kW"
dart_radar_entity.fast_replaceable_group = nil

local dart_radar_entity_update = {
    pictures = {
        layers = {{ filename  =  "__dart__/graphics/entity/radar.png"}}
    }
}
dart_radar_entity = meld(dart_radar_entity, dart_radar_entity_update)

rescale_entity(dart_radar_entity, 1 / 3)

dart_radar_entity.collision_box = {{ -0.4, -0.4 }, { 0.4, 0.4 }}
dart_radar_entity.selection_box = {{ -0.5, -0.5 }, { 0.5, 0.5 }}
dart_radar_entity.circuit_connector = {
    points = {
        shadow = {
            green = { -1.375 / 3, 0.203125 / 3 },
            red = { -1.09375 / 3, 0.203125 / 3 }
        },
        wire = {
            green = { -1.484375 / 3, 0.03125 / 3 },
            red = { -1.390625 / 3, -0.125 / 3 }
        }
    }
}
dart_radar_entity.surface_conditions = surface_conditions()

Log.logBlock(dart_radar_entity, function(m)log(m)end, Log.FINER)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--- create the D.A.R.T-radar item
local dart_radar_item = data_util.copy_prototype(data.raw["item"]["radar"], "dart-radar")
local order = dart_radar_item.order or "dart"
dart_radar_item.icon = "__dart__/graphics/icons/radar.png"
dart_radar_item.icon_size = 64
dart_radar_item.icon_mipmaps = 4
dart_radar_item.order = order .. "-a"

--- create the D.A.R.T-fcc item
local dart_fcc_item = data_util.copy_prototype(data.raw["item"]["constant-combinator"], "dart-fcc")
dart_fcc_item.icon = "__dart__/graphics/icons/fcc.png"
dart_fcc_item.icon_size = 64
dart_fcc_item.icon_mipmaps = 4
dart_fcc_item. fast_replaceable_group = nil
-- show both near to vanilla radar
dart_fcc_item.order = order .. "-b"
dart_fcc_item.subgroup = dart_radar_item.subgroup

Log.logBlock(dart_fcc_item, function(m)log(m)end, Log.FINER)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- make all usable
data:extend({
    dart_radar_item,
    dart_fcc_item,
    dart_radar_entity,
    dart_fcc_entity,
    dart_radar_recipe,
    dart_fcc_recipe,
    technologies.dart_tech,
    technologies.dart_tech_L1,
    technologies.dart_tech_L2,
    technologies.dart_tech_L3,
})

