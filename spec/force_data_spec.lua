---
--- Created by xyzzycgn.
---
local Require = require("test.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)

require("spec.common")

describe("ForceData", function()
    local ForceData

    setup(function()
        ForceData = require("scripts.force_data")
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("init_force_data", function()
        it("initializes force data with the default tech level", function()
            local forceData = ForceData.init_force_data()

            assert.are.same(forceData, {
                techLevel = 0,
            })
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("creates a new table instance on each call", function()
            local forceData1 = ForceData.init_force_data()
            local forceData2 = ForceData.init_force_data()

            -- Each call should return a separate table instance.
            assert.is_false(forceData1 == forceData2)

            -- Both instances should have the same initial content.
            assert.are.same(forceData1.techLevel, forceData2.techLevel)
        end)
    end)
end)
