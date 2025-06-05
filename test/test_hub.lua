---
--- Created by xyzzycgn.
--- DateTime: 28.12.24 10:31
---
require('test.BaseTest')
local lu = require('lib.luaunit')
local Hub = require('scripts.Hub')

local serpent = require("lib.serpent")

-- needed by Log.log() which is called by init()
function log()
end

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
        { count = 1, name = "dart-radar", quality = "normal" }
    }
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function mockedGet_inventory(which)
    return {
        get_contents = mockedGet_contents
    }
end

-- need an own function to determine size of table - as table_size (defined in BaseTest) is overridden by
-- test_dart and test_asyncHandler (by requiring factorio_def) and the execution sequence of the suites isn't predictable
-- (or doesn't matter)
local function tablelength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

TestHub = {}

function TestHub:setUp()
    -- mock global defines
    defines = defines or {}
    defines.inventory = {
        hub_main = 1
    }
end
-- ###############################################################

function TestHub:test_getInventoryOfHub()
    -- mock a pons
    local pons = {
        platform = {
            hub = {
                get_inventory = mockedGet_inventory
            }
        }
    }
    local erg = Hub.getInventoryContent(pons)

    lu.assertNotNil(erg)

    lu.assertEquals(tablelength(erg), 16)
    lu.assertEquals(erg["metallurgic-science-pack"], 497)
end
-- ###############################################################

BaseTest:hookTests()
