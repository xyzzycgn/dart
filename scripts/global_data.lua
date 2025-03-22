---
--- Created by xyzzycgn.
--- DateTime: 22.12.24 13:32
---
--- encapsulates the storage (formerly global) table

local Log = require("__log4factorio__.Log")

local global_data = {}

function global_data.init()
    Log.log('global_data.init', function(m)log(m)end, Log.FINE)
    storage.players = storage.players or {}
    storage.dart = storage.dart or {}
end


function global_data.addPlayer_data(player, pd)
    local pi = player.index
    if (storage.players[pi] == nil) then
        storage.players[pi] = pd
    else
        Log.log("player already known", function(m)log(m)end, Log.WARN)
    end
end

function global_data.getPlayer_data(playerindex)
    return storage.players[playerindex]
end

return global_data
