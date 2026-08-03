---
--- Created by Junie.
---
local Require = require("spec.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)

require("spec.common")

describe("Player events", function()
    local player_events
    local global_data

    setup(function()
        player_events = require("scripts.events.player")
        global_data = require("scripts.global_data")
    end)

    before_each(function()
        _G.storage = {
            players = {}
        }
    end)

    describe("playerRemoved", function()
        it("removes player data from storage when player is removed", function()
            local player_index = 1
            storage.players[player_index] = { name = "testplayer" }
            
            local event = {
                player_index = player_index
            }
            
            player_events.playerRemoved(event)
            
            assert.is_nil(storage.players[player_index])
        end)

        it("does nothing when player index is not in storage", function()
            storage.players[1] = { name = "testplayer" }
            
            local event = {
                player_index = 2
            }
            
            player_events.playerRemoved(event)
            
            assert.is_not_nil(storage.players[1])
            assert.is_nil(storage.players[2])
        end)
    end)

    describe("playerJoinedOrCreated", function()
        it("initializes player data when a player joins", function()
            local player_index = 10
            local mock_player = {
                index = player_index,
                name = "new_player"
            }
            
            -- Mock game.get_player
            _G.game = {
                get_player = function(index)
                    if index == player_index then
                        return mock_player
                    end
                end
            }
            
            local event = {
                player_index = player_index
            }
            
            player_events.playerJoinedOrCreated(event)
            
            assert.is_not_nil(storage.players[player_index])
            assert.equal(mock_player, storage.players[player_index].player)
        end)

        it("does not re-initialize if player data already exists", function()
            local player_index = 10
            local existing_data = { already = "here" }
            storage.players[player_index] = existing_data
            
            local event = {
                player_index = player_index
            }
            
            player_events.playerJoinedOrCreated(event)
            
            assert.equal(existing_data, storage.players[player_index])
        end)
    end)

    describe("playerChangedSurface", function()
        it("closes open GUI when player changes surface", function()
            local player_index = 5

            local gui = {
                valid = true,
                destroy = stub()
            }
            storage.players[player_index] = {
                guis = {
                    open = { gui = gui }
                }
            }
            
            local event = {
                player_index = player_index
            }
            
            player_events.playerChangedSurface(event)
            
            assert.stub(gui.destroy).was_called()
            assert.is_nil(storage.players[player_index].guis.open)
        end)

        it("does nothing if no GUI is open", function()
            local player_index = 5
            storage.players[player_index] = {
                guis = {}
            }
            
            local event = {
                player_index = player_index
            }
            
            player_events.playerChangedSurface(event)
            
            assert.is_nil(storage.players[player_index].guis.open)
        end)
    end)
end)
