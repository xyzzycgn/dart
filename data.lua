---
--- Created by xyzzycgn.
--- DateTime: 03.03.25 20:51
---
local Log = require("__log4factorio__.Log")
Log.setSeverity(Log.FINE)
local data_util = require('__flib__.data-util')

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

--- create the D.A.R.T-radar recipe
local dart_radar_recipe = data_util.copy_prototype(data.raw["recipe"]["radar"], "dart-radar")
dart_radar_recipe.ingredients = {
    { type = "item", name = "radar", amount = 1 },
    { type = "item", name = "electronic-circuit", amount = 4 },
    { type = "item", name = "advanced-circuit", amount = 2 },
    { type = "item", name = "processing-unit", amount = 1 },
}
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- create the INVISIBLE D.A.R.T-radar entity and shrink it to 1x1 tiles - the animated image of the radar is produced in control
local dart_radar_entity = data_util.copy_prototype(data.raw['constant-combinator']['constant-combinator'], "dart-radar")
dart_radar_entity.icon = "__base__/graphics/icons/radar.png" -- TODO
dart_radar_entity.icon_size = 64
dart_radar_entity.icon_mipmaps = 4
dart_radar_entity.next_upgrade = nil
dart_radar_entity.fast_replaceable_group = nil

-- at the moment there seems to be no solution for the problem that there is either a static image disturbing the animation
-- or no ghost / no image in gui. Obviously sprites is controlling both the static image and the ghost / image in gui, so
-- that it's not possible to have no static image but the ghost and image in gui

-- this has the flaw, that it shows no ghost and no image in gui (out of the box), but there is no static image
-- disturbing the animation
dart_radar_entity.sprites = nil

-- alternative solution which shows a ghost and an image in gui (out of the box), but a disturbing static image
-- together with the animation :(
-- dart_radar_entity.sprites = {
--   filename = "__base__/graphics/entity/radar/radar.png",
--   width = 196,
--   height = 254,
--   scale = 0.5,
--   flags = { "gui" }
--}
dart_radar_entity.activity_led_sprites = nil
dart_radar_entity.activity_led_light = nil
dart_radar_entity.working_sound = "__base__/sound/radar.ogg"

rescale_entity(dart_radar_entity, 1 / 3)

dart_radar_entity.selection_box = {{ -0.6, -0.6 }, { 0.6, 0.6 }}
dart_radar_entity.collision_box = {{ -0.4, -0.4 }, { 0.4, 0.4 }}
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
dart_radar_entity.surface_conditions = {  -- dart_radar should only be build on platforms
    { property = "gravity", min = 0, max = 0 },
    { property = "pressure", min = 0, max = 0 },
}

Log.logBlock(dart_radar_entity, function(m)log(m)end, Log.FINE)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- create the D.A.R.T-radar item
local dart_radar_item = data_util.copy_prototype(data.raw["item"]["radar"], "dart-radar")
dart_radar_item.icon = "__base__/graphics/icons/radar.png" -- TODO
dart_radar_item.icon_size = 64
dart_radar_item.icon_mipmaps = 4
dart_radar_item.order = (dart_radar_item.order or "dart") .. "-c"
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- create the D.A.R.T-radar technology
local dart_tech = {
    name = 'dart-radar',
    type = 'technology',
    icon = "__base__/graphics/technology/radar.png", -- TODO
    icon_size = 256,
    icon_mipmaps = 4,

    prerequisites = { "circuit-network", "radar", "space-platform" },
    effects = { { type = 'unlock-recipe', recipe = 'dart-radar' }, },

    unit = {
        count = 100,
        ingredients = {
            { "automation-science-pack", 2 },
            { "military-science-pack", 1 },
            { "space-science-pack", 1 },
        },
        time = 30,
    },

    order = "c-e-b2",
}
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- animation for the invisible dart_radar (as this is a constant combinator, it doesn't support animation itself
--- so this must be done in control (in the on_build_entity / on_space_platform_built_entity event)
local dart_radar_animation = {
    type = "animation",
    name = "dart-radar-animation",
    stripes = {
        { filename = "__base__/graphics/entity/radar/radar.png", width_in_frames = 8, height_in_frames = 8 },
    },
    animation_speed = 1.4,
    frame_count = 64,
    width = 196,
    height = 254,
    scale = 1 / 6,
    run_mode = "backward",
}

-- make all usable
data:extend({
    dart_radar_item,
    dart_radar_entity,
    dart_radar_recipe,
    dart_tech,
    dart_radar_animation,
})
