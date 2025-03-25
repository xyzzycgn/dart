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

function global_data.getPlayer_data(playerindex)
    return storage.players[playerindex]
end
-- ###############################################################

--- create (or get) LuaConstantCombinatorControlBehavior from dart-output and
--- save it +  dart-radar + dart-output entities in storage as array
--- @param radar LuaEntity (dart-radar)
--- @param output LuaEntity (dart-output)
function global_data.setDart(radar, output)
    local run = radar.unit_number
    local oun = output.unit_number

    local dart = {
        radar_un = run,
        output_un = oun,
        output = output,
        control_behavior = output.get_or_create_control_behavior(),
    }

    -- save twice - with uns of dart-radar and dart-output
    storage.dart[run] = dart
    storage.dart[oun] = dart

    Log.logBlock(storage.dart, function(m)log(m)end, Log.FINE)
end

-- get dart array for unit_number
-- @param un unit_number of dart-radar/dart-output
function global_data.getDart(un)
    return storage.dart[un]
end

-- remove dart array for unit_number from storage
-- @param un unit_number of dart-radar
function global_data.clearDart(un)
    Log.logBlock(un, function(m)log(m)end, Log.FINE)
    storage.dart[un] = nil
end
-- ###############################################################

function global_data.getPlatforms()
    return storage.platforms
end

return global_data
