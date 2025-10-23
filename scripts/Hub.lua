---
--- Created by xyzzycgn.
---
local Log = require("__log4factorio__.Log")
local messaging = require("scripts.messaging")

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
    if not hub then
        Log.log("disfunctional platform without hub detected", function(m)log(m)end, Log.WARN)
        messaging.printmsg({ "dart-message.dart-dysfunctional-platform", messaging.platform2richText(platform) }, messaging.level.WARNING, platform.force)
        return {}
    end
    --- @type LuaInventory
    local inv = hub.get_inventory(defines.inventory.hub_main)
    if inv then
        return amountsOfItems(inv.get_contents())
    else
        Log.log("hub without hub_main inventory", function(m)log(m)end, Log.WARN)
        return {}
    end
end
-- ###############################################################

--- update ammo stock for a platform
--- @param pons Pons
function Hub.updateAmmoInStock(pons)
    local ammoInStockPerType =  {}
    -- get inventory of hub of platform
    local inv = Hub.getInventoryContent(pons)
    for _, fop in pairs(pons.fccsOnPlatform) do
        -- check each ammo type used by turrets conected to FCC
        for type, awt in pairs(fop.ammo_warning.thresholds) do
            ammoInStockPerType[type] = ammoInStockPerType[type] or inv[type] or 0
        end
    end
    pons.ammoInStockPerType = ammoInStockPerType
    Log.logBlock({platform=pons.platform.name, ammoInStockPerType=ammoInStockPerType}, function(m)log(m)end, Log.FINER)
end
-- ###############################################################

--- check ammo stock for a platform
--- @param pons Pons
function Hub.checkLowAmmoInStock(pons)

    local lowAmmoInStock = { }
    local stocks = pons.ammoInStockPerType
    for _, fcc in pairs(pons.fccsOnPlatform) do
        for ammo_type, awt in pairs(fcc.ammo_warning.thresholds) do
            if awt.enabled and (stocks[ammo_type] < awt.threshold) then
                lowAmmoInStock[ammo_type] = stocks[ammo_type]
            end
        end
    end

    return lowAmmoInStock
end

return Hub