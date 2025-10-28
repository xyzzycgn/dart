---
--- Created by xyzzycgn.
--- DateTime: 28.10.25 09:19
---
--- handles (most of) game events related to players
local global_data = require("scripts.global_data")
local player_data = require("scripts.player_data")
local Log = require("__log4factorio__.Log")

--###############################################################

--- creates the PlayerData if needed and stores them in global storage
--- @param player_index uint
local function init_player_data(player_index)
    local pd = global_data.getPlayer_data(player_index)
    if (pd == nil) then
        local player = game.get_player(player_index)
        pd = player_data.init_player_data(player)
        global_data.addPlayer_data(player, pd)
    end
end

--- @param event EventData
local function playerJoinedOrCreated(event)
    Log.logEvent(event, function(m)log(m)end)
    init_player_data(event.player_index)
end
-- ###############################################################

--- @param event EventData
local function playerChangedSurface(event)
    Log.logEvent(event, function(m)log(m)end, Log.FINER)
    local pd = global_data.getPlayer_data(event.player_index)
    local guis = pd and pd.guis

    if guis and guis.open then
        Log.log("close gui", function(m)log(m)end, Log.FINER)
        if guis.open.gui and guis.open.gui.valid then
            guis.open.gui.destroy()
            guis.open = {}
        end
    end
end
-- ###############################################################

local function toggleMapEditor(event)
    Log.logEvent(event, function(m)log(m)end, Log.FINE)
    local pd = global_data.getPlayer_data(event.player_index)
    if pd then
        local editorMode = pd.editorMode
        if editorMode then
            editorMode = false
        else
            editorMode = true
        end

        pd.editorMode = editorMode
        Log.logLine({ player_index = event.player_index, editorMode = editorMode }, function(m)log(m)end, Log.INFO)
    end
end
--###############################################################

--- @param event EventData
local function tbd(event)
    Log.logEvent(event, function(m)log(m)end, Log.FINER)
end

local Player = {
    playerJoinedOrCreated = playerJoinedOrCreated,
    playerChangedSurface = playerChangedSurface,
    toggleMapEditor = toggleMapEditor,
    playerLeftGame = tbd,
    playerRemoved = tbd,
}

return Player