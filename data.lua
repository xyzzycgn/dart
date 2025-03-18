---
--- Created by xyzzycgn.
--- DateTime: 03.03.25 20:51
---
local Log = require("__log4factorio__.Log")
Log.setSeverity(Log.FINE)
local data_util = require('__flib__.data-util')

Log.logBlock(mods, function(m)log(m)end, Log.CONFIG)
Log.logBlock(data.raw["technology"], function(m)log(m)end, Log.FINER)

    local dart_radar_recipe = data_util.copy_prototype(data.raw["recipe"]["radar"], "dart-radar")
    dart_radar_recipe.ingredients = {
        { type = "item", name = "radar", amount = 1 },
        { type = "item", name = "electronic-circuit", amount = 4 },
        { type = "item", name = "advanced-circuit", amount = 2 },
    }


    local dartio = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
    dartio.name = 'dart-io'
    dartio.minable = nil
    dartio.item_slot_count = 300
    dartio.draw_cargo = false
    dartio.draw_circuit_wires = false
    dartio.selection_box = { { -0.0, -0.0 }, { 0.0, 0.0 } }
    dartio.collision_box = { { -0.0, -0.0 }, { 0.0, 0.0 } }
    dartio.collision_mask = { layers = {} }
    dartio.flags = { "placeable-off-grid", "not-on-map", "not-blueprintable", "hide-alt-info" }
    dartio.sprites = empty4
    dartio.activity_led_sprites = empty4

    local dart_radar_entity = data_util.copy_prototype(data.raw["radar"]["radar"], "dart-radar")
    dart_radar_entity.icon = "__base__/graphics/icons/radar.png" -- TODO
    dart_radar_entity.icon_size = 64
    dart_radar_entity.icon_mipmaps = 4
    dart_radar_entity.next_upgrade = nil
    --dart_hub.selection_box = {{-0.6, -0.6}, {0.6, 0.6}}
    dart_radar_entity.sprites = make_4way_animation_from_spritesheet({
        layers = {
            {
                scale = 0.5,
                filename = "__base__/graphics/entity/radar/radar.png",
                width = 196,
                height = 254,
                width_in_frames = 8,
                height_in_frames = 8,
                frame_count = 64,
                --shift = util.by_pixel(0, 5),
            },
            {
                scale = 0.5,
                filename = "__base__/graphics/entity/radar/radar-shadow.png",
                width = 196,
                height = 254,
                width_in_frames = 8,
                height_in_frames = 8,
                frame_count = 64,
                --shift = util.by_pixel(8.5, 5.5),
                draw_as_shadow = true,
            },
        },
    })

    local dart_radar_item = data_util.copy_prototype(data.raw["item"]["radar"], "dart-radar")
    dart_radar_item.icon = "__base__/graphics/entity/radar/radar.png" -- TODO
    dart_radar_item.icon_size = 64
    dart_radar_item.icon_mipmaps = 4
    dart_radar_item.order = (dart_radar_item.order or "dart") .. "-c"

    local dart_tech = {
        name = 'dart-radar',
        type = 'technology',

        -- Technology icons are quite large, so it is important
        -- to specify the size. As all icons are squares this is only one number.
        icon = "__base__/graphics/technology/radar.png", -- TODO
        icon_size = 128, -- TODO

        prerequisites = { "circuit-network", "radar", "space-platform" },

        effects = {
            { type = 'unlock-recipe',
              recipe = 'dart-radar'
            },
        },

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


data:extend({
    dart_radar_item,
    dartio,
    dart_radar_entity,
    dart_radar_recipe,
    dart_tech,
})
