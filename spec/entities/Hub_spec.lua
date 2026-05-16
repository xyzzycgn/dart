---
--- Created by xyzzycgn.
---
local Require = require("test.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)

require("spec.common")
serpent=require('serpent') -- must be global
require("scripts.internalEvents")

local function mockedGet_contents()
    return {
        { count = 18, name = "transport-belt", quality = "normal" },
        { count = 2, name = "underground-belt", quality = "normal" },
        { count = 22, name = "inserter", quality = "normal" },
        { count = 5, name = "fast-inserter", quality = "normal" },
        { count = 1, name = "pipe-to-ground", quality = "normal" },
        { count = 33, name = "repair-pack", quality = "normal" },
        { count = 350, name = "iron-ore", quality = "normal" },
        { count = 240, name = "ice", quality = "normal" },
        { count = 400, name = "iron-plate", quality = "normal" },
        { count = 17, name = "plastic-bar", quality = "normal" },
        { count = 201, name = "carbon", quality = "normal" },
        { count = 491, name = "metallurgic-science-pack", quality = "normal" },
        { count = 6, name = "metallurgic-science-pack", quality = "rare" },
        { count = 1, name = "crusher", quality = "normal" },
        { count = 1, name = "carbonic-asteroid-chunk", quality = "normal" },
        { count = 700, name = "firearm-magazine", quality = "normal" },
        { count = 100, name = "uranium-rounds-magazine", quality = "normal" },
        { count = 1, name = "dart-radar", quality = "normal" }
    }
end

local function mockedGet_inventory()
    return {
        get_contents = mockedGet_contents
    }
end

-- Uses a local table size helper because the global table_size mock can be overridden by other tests.
local function tablelength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

describe("Hub", function()
    local Hub

    setup(function()
        Hub = require("scripts.entities.Hub")
    end)

    before_each(function()
        -- Mock global defines.
        defines.inventory = {
            hub_main = 1
        }
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("getInventoryContent", function()
        it("returns the aggregated inventory content of the hub", function()
            -- Mock a pons.
            local pons = {
                platform = {
                    hub = {
                        get_inventory = mockedGet_inventory
                    }
                }
            }

            local result = Hub.getInventoryContent(pons)

            assert.is_not_nil(result)
            assert.are.equal(17, tablelength(result))
            assert.are.equal(497, result["metallurgic-science-pack"])
        end)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("updateAmmoInStock", function()
        it("keeps ammo stock empty when no turrets are configured", function()
            -- Mock a pons.
            local pons = {
                platform = {
                    hub = {
                        get_inventory = mockedGet_inventory
                    },
                    name = "test platform",
                },
                fccsOnPlatform = {}
            }

            Hub.updateAmmoInStock(pons)

            local result = pons.ammoInStockPerType

            assert.is_not_nil(result)
            assert.are.equal(0, tablelength(result))
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("tracks only ammo types configured by turret warning thresholds", function()
            -- Mock a pons.
            local pons = {
                platform = {
                    hub = {
                        get_inventory = mockedGet_inventory
                    },
                    name = "test platform",
                },
                fccsOnPlatform = {
                    [4711] = {
                        fcc_un = 4711,
                        ammo_warning = {
                            thresholds = {
                                ["firearm-magazine"] = {
                                    type = "firearm-magazine",
                                    enabled = true,
                                    threshold = 400,
                                },
                                ["piercing-rounds-magazine"] = {
                                    type = "piercing-rounds-magazine",
                                    enabled = true,
                                    threshold = 400,
                                }
                            }
                        }
                    }
                }
            }

            Hub.updateAmmoInStock(pons)

            local result = pons.ammoInStockPerType

            -- firearm-magazine and piercing-rounds-magazine should be included, but not uranium-rounds-magazine,
            -- although it is present in the hub. This simulates matching ammo in stock, matching ammo not in stock,
            -- and non-matching ammo in stock.
            assert.are.same({
                ["firearm-magazine"] = 700,
                ["piercing-rounds-magazine"] = 0
            }, result)
        end)
    end)
end)
