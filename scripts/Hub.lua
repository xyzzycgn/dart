---
--- Created by xyzzycgn.
---

local Hub = {}

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @class AmountsOfItems table<string, uint> Map of all items (ignoring quality) and their amounts
--- @param contents ItemWithQualityCounts[] @List of all items in the inventory of the Hub.
--- @return AmountsOfItems
local function amountsOfItems(contents)
    local erg = {}

    for _, iwqc in pairs(contents) do
        local name = iwqc.name
        -- ignore quality and sum
        erg[name] = (erg[name] or 0) + iwqc.count
    end

    return erg
end



--- @param pons Pons
--- @return ItemWithQualityCounts[] @List of all items in the inventory of the Hub.
function Hub.getInventoryContent(pons)
    local platform = pons.platform
    local hub = platform.hub
    --- @type LuaInventory
    local inv = hub.get_inventory(defines.inventory.hub_main)
    if inv then
        return amountsOfItems(inv.get_contents())
    else
        Log.log("hub without hub_main inventory", function(m)log(m)end, Log.WARN)
        return {}
    end
end

return Hub