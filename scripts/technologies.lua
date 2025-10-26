---
--- Created by xyzzycgn.
--- DateTime: 26.10.25 10:32
---
--- technology tree for D.A.R.T.
---


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
local dart_tech_L1 = {
    name = 'dart-radar-L-1',
    type = 'technology',
    icon = "__dart__/graphics/technology/radar.png",
    icon_size = 256,
    icon_mipmaps = 4,

    prerequisites = { "dart-radar" },
    effects = {
        {
            type = 'nothing',
            -- TODO effect_description = { 'effect-description.solar-productivity', str(SP.BONUS[1] * 100)}
            effect_description = 'erhöhe reichweite'
        }
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

    order = "c-e-b3",
    upgrade = true,
}

local dart_tech_L2 = {
    name = 'dart-radar-L-2',
    type = 'technology',
    icon = "__dart__/graphics/technology/radar.png",
    icon_size = 256,
    icon_mipmaps = 4,

    prerequisites = { "dart-radar-L-1" },
    effects = {
        {
            type = 'nothing',
            -- TODO effect_description = { 'effect-description.solar-productivity', str(SP.BONUS[1] * 100)}
            effect_description = 'erhöhe reichweite nochmal'
        }
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

    order = "c-e-b4",
    upgrade = true,
}

local dart_tech_L3 = {
    name = 'dart-radar-L-3',
    type = 'technology',
    icon = "__dart__/graphics/technology/radar.png",
    icon_size = 256,
    icon_mipmaps = 4,

    prerequisites = { "dart-radar-L-2" },
    effects = {
        {
            type = 'nothing',
            -- TODO effect_description = { 'effect-description.solar-productivity', str(SP.BONUS[1] * 100)}
            effect_description = 'erhöhe reichweite immer wieder '
        }
    },

    unit = {
        count_formula = "2^(L - 3) * 1000",
        ingredients = {
            { "automation-science-pack", 2 },
            { "military-science-pack", 1 },
            { "space-science-pack", 1 },
        },
        time = 40,
    },
    order = "c-e-b4",
    max_level = "infinite",
    upgrade = true,
}

local technologies = {
    dart_tech    = dart_tech,
    dart_tech_L1 = dart_tech_L1,
    dart_tech_L2 = dart_tech_L2,
    dart_tech_L3 = dart_tech_L3,
}

return technologies