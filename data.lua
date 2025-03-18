---
--- Created by xyzzycgn.
--- DateTime: 03.03.25 20:51
---
local Log = require("__log4factorio__.Log")
Log.setSeverity(Log.FINE)
local data_util = require('__flib__.data-util')

Log.logBlock(mods, function(m)log(m)end, Log.CONFIG)
Log.logBlock(data.raw["technology"], function(m)log(m)end, Log.FINER)

local function recipes()
    --local dart_radar = data_util.copy_prototype(data.raw["recipe"]["radar"], "dart-radar")
    local dart_radar = table.deepcopy(data.raw["recipe"]["radar"])
    dart_radar.name = "dart-radar"
    dart_radar.ingredients = {
        { type = "item", name = "radar", amount = 1 },
        { type = "item", name = "electronic-circuit", amount = 4 },
        { type = "item", name = "advanced-circuit", amount = 2 },
    }
    dart_radar.results = {{ type = "item", name = 'dart-radar', amount = 1 }}
    dart_radar.enabled = true -- TODO tech

    --local dart_radar_recycle = {
    --    allow_decomposition = false,
    --    category = "recycling",
    --    crafting_machine_tint = {
    --        primary =    { 0.5, 0.5, 0.5, 0.5 },
    --        secondary =  { 0.5, 0.5, 0.5, 0.5 },
    --        tertiary =   { 0.5, 0.5, 0.5, 0.5 },
    --        quaternary = { 0.5, 0.5, 0.5, 0.5 },
    --    },
    --    energy_required = 0.0625,
    --    hidden = true,
    --    icons = {
    --        { icon = "__quality__/graphics/icons/recycling.png" },
    --        { icon = "__base__/graphics/icons/radar.png", scale = 0.4 },
    --        { icon = "__quality__/graphics/icons/recycling-top.png" }
    --    },
    --    ingredients = {
    --        { name = "dart-radar", type = "item", amount = 1, }
    --    },
    --    localised_name = { "recipe-name.recycling", { "entity-name.dart-radar" } },
    --    name = "dart-radar-recycling",
    --    results = {
    --        { name = "electronic-circuit", type = "item", amount = 1.25, extra_count_fraction = 0.25, },
    --        { name = "advanced-circuit",   type = "item", amount = 0.75, extra_count_fraction = 0.25, },
    --        { name = "radar",              type = "item", amount = 0.5,  extra_count_fraction = 0.5, }
    --    },
    --    subgroup = "other",
    --    type = "recipe",
    --    unlock_results = false
    --}
    --return dart_radar, dart_radar_recycle

    return dart_radar
end

local function entities()
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

    local dart_radar = data_util.copy_prototype(data.raw["radar"]["radar"], "dart-radar")
    dart_radar.icon = "__base__/graphics/icons/radar.png" -- TODO
    dart_radar.icon_size = 64
    dart_radar.icon_mipmaps = 4
    dart_radar.next_upgrade = nil
    --dart_hub.selection_box = {{-0.6, -0.6}, {0.6, 0.6}}
    dart_radar.sprites = make_4way_animation_from_spritesheet({
        layers = {
            {
                scale = 0.333,
                filename = "__base__/graphics/entity/radar/radar.png",
                width = 196,
                height = 254,
                width_in_frames = 8,
                height_in_frames = 8,
                frame_count = 64,
                --shift = util.by_pixel(0, 5),
            },
            {
                scale = 0.333,
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

    return dartio, dart_radar
end

local function item()
    --local dart_radar = data_util.copy_prototype(data.raw["item"]["radar"], "dart-radar")
    local dart_radar = table.deepcopy(data.raw["item"]["radar"])
    dart_radar.name = "dart-radar"
    --dart_radar.place_result = "dart-radar"
    dart_radar.icon = "__base__/graphics/entity/radar/radar.png" -- TODO
    dart_radar.icon_size = 64
    dart_radar.icon_mipmaps = 4
    dart_radar.order = (dart_radar.order or "dart") .. "-c"

    return dart_radar
end

data:extend({
    item(),
    entities(),
    recipes(),
})
