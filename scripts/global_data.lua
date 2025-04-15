---
--- encapsulates the storage (formerly global) table
--- Created by xyzzycgn.
---

local Log = require("__log4factorio__.Log")

local global_data = {}

function global_data.init()
    Log.log('global_data.init', function(m)log(m)end, Log.FINE)
    storage.players = storage.players or {}
    storage.dart = storage.dart or {}
    storage.platforms = storage.platforms or {}
    storage.queued = storage.queued or {}
end
-- ###############################################################

function global_data.addPlayer_data(player, pd)
    local pi = player.index
    if (storage.players[pi] == nil) then
        storage.players[pi] = pd
    else
        Log.log("player already known", function(m)log(m)end, Log.WARN)
    end
end

--- @return PlayerData
function global_data.getPlayer_data(playerindex)
    return storage.players[playerindex]
end
-- ###############################################################

--- structure containing all data concerning the darts and turrets of all platforms
--- @return Pons[]
function global_data.getPlatforms()
    return storage.platforms
end

-- ###############################################################

--- structure containing all data concerning queued async functions
function global_data.getQueued()
    return storage.queued
end

return global_data
