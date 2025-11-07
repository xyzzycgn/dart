---
--- Created by xyzzycgn.
---

--- @class ForceData any  convenience class for handling data of a force
--- @field techLevel number the actual researched level of dart radar range

local ForceData = {}

--- @return ForceData
function ForceData.init_force_data()
    -- Force data used during game
    local fd = {
        techLevel = 0,
    }

    return fd
end

return ForceData