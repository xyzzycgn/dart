---
--- Created by xyzzycgn.
---
local Require = require("test.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)

require("spec.common")

describe("Force events", function()
    local force

    setup(function()
        force = require("scripts.events.force")
    end)

    before_each(function()
        -- Mock storage for tests.
        _G.storage = {}
        _G.storage.forces = {
            { techLevel = 0 },
            { techLevel = 1 }
        }
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("onForceCreated", function()
        it("adds initialized force data for the created force", function()
            -- Mock a force creation event.
            local mockEvent = {
                name = defines.events.on_force_created,
                force = {
                    name = "test-force",
                    index = 3,
                    valid = true
                },
                tick = 100
            }

            local expected = {
                { techLevel = 0 },
                { techLevel = 1 },
                { techLevel = 0 }
            }

            force.onForceCreated(mockEvent)

            assert.are.same(expected, storage.forces)
        end)
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("onForcesMerged", function()
        it("removes force data for the source force", function()
            -- Mock a forces merged event.
            local mockEvent = {
                name = defines.events.on_forces_merged,
                source = "source-force",
                source_index = 1,
                destination = {
                    name = "destination-force",
                    index = 2,
                    valid = true
                },
                tick = 200
            }

            local expected = {
                [2] = { techLevel = 1 },
            }

            force.onForcesMerged(mockEvent)

            assert.are.same(expected, storage.forces)
        end)
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("onForceReset", function()
        it("resets the tech level for an existing force", function()
            -- Mock a force reset event.
            local mockEvent = {
                name = defines.events.on_force_reset,
                force = {
                    name = "reset-force",
                    index = 2,
                    valid = true
                },
                tick = 300
            }

            local expected = {
                { techLevel = 0 },
                { techLevel = 0 }
            }

            force.onForceReset(mockEvent)

            assert.are.same(expected, storage.forces)
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("keeps force data unchanged when the force is unknown", function()
            -- Mock a force reset event for an unknown force.
            local mockEvent = {
                name = defines.events.on_force_reset,
                force = {
                    name = "reset-force",
                    index = 3,
                    valid = true
                },
                tick = 300
            }

            local expected = {
                { techLevel = 0 },
                { techLevel = 1 }
            }

            force.onForceReset(mockEvent)

            assert.are.same(expected, storage.forces)
        end)
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("module structure", function()
        it("exports the expected event handler functions", function()
            assert.are.equal("table", type(force))

            -- Check existence of functions.
            local expectedFunctions = {
                "onForceCreated",
                "onForcesMerged",
                "onForceReset"
            }

            for _, funcName in ipairs(expectedFunctions) do
                assert.is_not_nil(force[funcName], string.format("%s should exist", funcName))
                assert.are.equal("function", type(force[funcName]), string.format("%s should be a function", funcName))
            end
        end)
    end)
end)
