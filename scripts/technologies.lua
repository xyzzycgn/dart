---
--- Created by xyzzycgn.
--- DateTime: 26.10.25 10:32
---
--- technology tree for D.A.R.T.
---
local constants = require("scripts.constants")

local function bonus(lvl)
    return { 'effect-description.dart-radar-range-bonus', tostring(constants.range_bonus[lvl] * 100) }
end


local function techname(lvl)
    return constants.dart_technologies .. lvl
end

--- D.A.R.T-radar base technology
local dart_tech = {
    name = 'dart-radar',
    type = 'technology',
    icon = "__dart__/graphics/technology/radar.png",
    icon_size = 256,
    icon_mipmaps = 4,

    prerequisites = { "circuit-network", "radar", "space-platform" },
    effects = {
        { type = 'unlock-recipe', recipe = 'dart-radar' },
        { type = 'unlock-recipe', recipe = 'dart-fcc' },
    },

    unit = {
        count = 100,
        ingredients = {
            { "automation-science-pack", 2 },
            { "military-science-pack", 1 },
            { "space-science-pack", 1 },
        },
        time = 40,
    },

    order = "c-e-b2",
}

--- increase of D.A.R.T-radar range
local dart_tech_radar_range1 = {
    name = techname(1),
    type = 'technology',
    icon = "__dart__/graphics/technology/radar_range.png",
    icon_size = 256,
    icon_mipmaps = 4,

    prerequisites = { "dart-radar" },
    localised_description = bonus(1),
    effects = {
        { type = 'nothing', effect_description = bonus(1) }
    },

    unit = {
        count = 100,
        ingredients = {
            { "automation-science-pack", 4 },
            { "military-science-pack", 2 },
            { "space-science-pack", 3 },
            { "utility-science-pack", 2 },
        },
        time = 50,
    },

    order = "c-e-b3",
    upgrade = true,
}

local dart_tech_radar_range2 = {
    name = techname(2),
    type = 'technology',
    icon = "__dart__/graphics/technology/radar_range.png",
    icon_size = 256,
    icon_mipmaps = 4,

    prerequisites = { techname(1) },
    localised_description = bonus(2),
    effects = {
        { type = 'nothing', effect_description = bonus(2) }
    },

    unit = {
        count = 150,
        ingredients = {
            { "automation-science-pack", 5 },
            { "military-science-pack", 3 },
            { "space-science-pack", 3 },
            { "utility-science-pack", 4 },
            { "metallurgic-science-pack", 1 },
        },
        time = 60,
    },

    order = "c-e-b4",
    upgrade = true,
}

local dart_tech_radar_range3 = {
    name = techname(3),
    type = 'technology',
    icon = "__dart__/graphics/technology/radar_range.png",
    icon_size = 256,
    icon_mipmaps = 4,

    prerequisites = { techname(2) },
    localised_description = bonus(3),
    effects = {
        { type = 'nothing', effect_description = bonus(3) }
    },

    unit = {
        count_formula = "2^(L - 3) * 250",
        ingredients = {
            { "automation-science-pack", 8 },
            { "military-science-pack", 4 },
            { "space-science-pack", 6 },
            { "utility-science-pack", 4 },
            { "metallurgic-science-pack", 3 },
            { "electromagnetic-science-pack", 2 },
        },
        time = 60,
    },
    order = "c-e-b4",
    max_level = "infinite",
    upgrade = true,
}

local technologies = {
    dart_tech              = dart_tech,
    dart_tech_radar_range1 = dart_tech_radar_range1,
    dart_tech_radar_range2 = dart_tech_radar_range2,
    dart_tech_radar_range3 = dart_tech_radar_range3,
}

return technologies