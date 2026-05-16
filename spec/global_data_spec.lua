---
--- Created by xyzzycgn.
---
local Require = require("test.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)

require("spec.common")

describe("GlobalData", function()
    local globalData

    setup(function()
        globalData = require("scripts.global_data")
    end)

    before_each(function()
        _G.storage = {
            forces = {},
            players = {}
        }
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("init", function()
        it("initializes player and platform storage", function()
            globalData.init()

            assert.are.same(storage, {
                players = {},
                platforms = {},
                queued = {},
                registeredEntities = {},
                forces = {},
            })
        end)
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("player data", function()
        it("adds simple player data by player index", function()
            local player = {
                index = 17
            }
            local playerData = { bla = "blub"}

            assert.is_not_nil(playerData)

            globalData.addPlayer_data(player, playerData)

            assert.are.same(playerData, storage.players[player.index])
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("retrieves initialized player data", function()
            local player = {
                index = 17
            }
            local playerData = { bla = "blub2"}
            storage.players[player.index] = playerData

            local fromGlobalData = globalData.getPlayer_data(player.index)
            assert.are.same(playerData, fromGlobalData)
        end)
    end)
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("force data", function()
        it("adds force data by force object or by force index", function()
            local force = {
                index = 2
            }
            local forceData = { force = "may be the force with you" }

            globalData.addForce_data(force, forceData)

            assert.are.same(forceData, storage.forces[2])
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("retrieves force data by index", function()
            local forceData = { force = "the force is strong with this one" }
            storage.forces[2] = forceData

            assert.are.equal(forceData, globalData.getForce_data(2))
        end)
        -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("deletes force data by index", function()
            local forceData1 = { force = "the force is strong in my family" }
            local forceData2 = { force = "trust the force" }

            _G.storage = {
                forces = {
                    [1] = forceData1,
                    [2] = forceData2,
                }
            }
            globalData.deleteForce_data(1)
            assert.is.same(storage, {
                forces = {
                    [2] = forceData2,
                }
            })
        end)
    end)
end)