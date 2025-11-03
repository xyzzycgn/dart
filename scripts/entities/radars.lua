---
--- Created by xyzzycgn.
--- DateTime: 28.10.25 10:37
---

local constants = require("scripts.constants")

--- @param lvl number level for which the bonus should be calculated
local function calculateRangeBonus(lvl)
    local bonus = 1

    for i = 1, lvl do
        local nextbonus = 1 + constants.range_bonus[i <= 3 and i or 3] -- if level > 3 use bonus from level 3
        bonus = bonus * nextbonus
    end

    return bonus
end
-- ###############################################################

--- calculates increased value (based on quality)
--- @param rop RadarOnPlatform
--- @param base number base value
local function addIncreaseBasedOnQuality(rop, base)
    local entity = rop.radar
    local quality_level = (entity.valid and entity.quality.level) or 0

    -- yields differences of 8, 6, 4, 2 for the next higher level
    -- higher level gain 1 per level
    return base + ((quality_level < 5) and (9 - quality_level) * (quality_level) or (16 + quality_level))
end
-- ###############################################################

local radars = {
    calculateRangeBonus = calculateRangeBonus,
    addIncreaseBasedOnQuality = addIncreaseBasedOnQuality,
}

return radars