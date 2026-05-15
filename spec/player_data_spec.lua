---
--- Created by xyzzycgn.
---
local Require = require("test.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)

require("spec.common")
serpent = require("serpent") -- must be global

describe("PlayerData", function()
    local PlayerData

    setup(function()
        PlayerData = require("scripts.player_data")
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("init_player_data", function()
        it("initializes player data with GUI data and the given player", function()
            -- Mock the player.
            local player = {
                index = 4711
            }

            local playerData = PlayerData.init_player_data(player)

            assert.are.same(playerData, {
                guis = {},
                player = player,
                pons = {}
            })
        end)
    end)
end)
