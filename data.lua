---
--- Created by xyzzycgn.
--- DateTime: 03.03.25 20:51
---
local Log = require("__log4factorio__.Log")
Log.setSeverity(Log.FINE)
local data_util = require('__flib__.data-util')
local meld = require('meld') -- from lualib

-- fields for scaling
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
        -- must be shift
        object[1] = object[1] * factor
        object[2] = object[2] * factor

        return object
    end
end

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

local dart_radar_recipe = data_util.copy_prototype(data.raw["recipe"]["radar"], "dart-radar")
dart_radar_recipe.ingredients = {
    { type = "item", name = "radar", amount = 1 },
    { type = "item", name = "electronic-circuit", amount = 4 },
    { type = "item", name = "advanced-circuit", amount = 2 },
}
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


---@type data.ConstantCombinatorPrototype
local dart_out = data_util.copy_prototype(data.raw['constant-combinator']['constant-combinator'], 'dart-output')

local dart_out_update = {
    icon = '__core__/graphics/empty.png',
    icon_size = 64,
    next_upgrade = meld.delete(),
    minable = meld.delete(),
    selection_box = { { -0.6, -0.6 }, { 0.6, 0.6 } },
    selection_priority = (dart_out.selection_priority or 50) + 10, -- increase priority to default + 10
    collision_box = { { 0, 0 }, { 0, 0 } },
    --collision_mask = { layers = { rail = true } },                     -- collide only with rail entities
    hidden_in_factoriopedia = true,
    -----@diagnostic disable-next-line: undefined-global
    --sprites = make_4way_animation_from_spritesheet {
    --    layers = {
    --        {
    --            scale = 0.5,
    --            filename = '__LogisticTrainNetwork__/graphics/entity/output.png',
    --            width = 114,
    --            height = 102,
    --            frame_count = 1,
    --            shift = util.by_pixel(0, 5),
    --        },
    --        {
    --            scale = 0.5,
    --            filename = '__base__/graphics/entity/combinator/constant-combinator-shadow.png',
    --            width = 98,
    --            height = 66,
    --            frame_count = 1,
    --            shift = util.by_pixel(8.5, 5.5),
    --            draw_as_shadow = true,
    --        },
    --    },
    --},
}

dart_out = meld(dart_out, dart_out_update)




--local dartio = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
--dartio.name = 'dart-io'
--dartio.minable = nil
--dartio.item_slot_count = 300
--dartio.draw_cargo = false
--dartio.draw_circuit_wires = false
--dartio.selection_box = { { -0.0, -0.0 }, { 0.0, 0.0 } }
--dartio.collision_box = { { -0.0, -0.0 }, { 0.0, 0.0 } }
--dartio.collision_mask = { layers = {} }
--dartio.flags = { "placeable-off-grid", "not-on-map", "not-blueprintable", "hide-alt-info" }
--dartio.sprites = empty4
--dartio.activity_led_sprites = empty4

local dart_radar_entity = data_util.copy_prototype(data.raw["radar"]["radar"], "dart-radar")

Log.logBlock(dart_radar_entity, function(m)log(m)end, Log.FINE)

dart_radar_entity.icon = "__base__/graphics/icons/radar.png" -- TODO
dart_radar_entity.icon_size = 64
dart_radar_entity.icon_mipmaps = 4
dart_radar_entity.next_upgrade = nil
dart_radar_entity.rotation_speed = 0.02
dart_radar_entity.energy_usage = "100kW"

rescale_entity(dart_radar_entity, 1 / 3)

--dart_radar_entity.selection_box = {{ -0.6, -0.6 }, { 0.6, 0.6 }}
dart_radar_entity.selection_box = {{ 0, 0 }, { 0, 0 }}
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

Log.logBlock(dart_radar_entity, function(m)log(m)end, Log.FINE)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local dart_radar_item = data_util.copy_prototype(data.raw["item"]["radar"], "dart-radar")
dart_radar_item.icon = "__base__/graphics/icons/radar.png" -- TODO
dart_radar_item.icon_size = 64
dart_radar_item.icon_mipmaps = 4
dart_radar_item.order = (dart_radar_item.order or "dart") .. "-c"

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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

data:extend({
    dart_radar_item,
    dart_out,
    dart_radar_entity,
    dart_radar_recipe,
    dart_tech,
})
