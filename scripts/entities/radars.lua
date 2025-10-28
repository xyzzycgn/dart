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

local radars = {
    calculateRangeBonus = calculateRangeBonus,
}

return radars