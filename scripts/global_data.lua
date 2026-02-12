---
--- encapsulates the storage (formerly global) table
--- Created by xyzzycgn.
---

local Log = require("__log4factorio__.Log")

local global_data = {}

function global_data.init()
    Log.log('global_data.init', function(m)log(m)end, Log.FINER)
    storage.players = storage.players or {}
    storage.platforms = storage.platforms or {}
    storage.queued = storage.queued or {}
    storage.registeredEntities = storage.registeredEntities or {}
    storage.forces =  storage.forces or {}
end
-- ###############################################################

--- @param force number | LuaForce
--- @param forceData ForceData
function global_data.addForce_data(force, forceData)
    local fi = type(force) == "number" and force or force.index
    if (storage.forces[fi] == nil) then
        storage.forces[fi] = forceData
    else
        Log.log("force already known", function(m)log(m)end, Log.WARN)
    end
end

--- @param forceindex number
--- @return ForceData
function global_data.getForce_data(forceindex)
    return storage.forces[forceindex]
end

--- @param forceindex number
--- @return ForceData
function global_data.deleteForce_data(forceindex)
    Log.logMsg(function(m)log(m)end, Log.INFO, "force deleted - index=%d", forceindex)
    storage.forces[forceindex] = nil
end
-- ###############################################################

--- @param player LuaPlayer
--- @param pd PlayerData
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

--- returns RadarOnPlatform for a dart-radar
--- @param entity LuaEntity a dart-radar
--- @return RadarOnPlatform
function global_data.getRadarOnPlatform(entity)
    if (entity.name == "dart-radar") then
        return storage.platforms[entity.surface.index].radarsOnPlatform[entity.unit_number]
    end
end
-- ###############################################################

--- all fccs, radars and ammo-turrets (for usage in "remove all entities" in editor mode - see ticket #52)
--- @class RegisteredEntity any
--- @field useful_id number id of entity
--- @field referenceOnPlatform any reference to the according structure in pons
---
--- @return RegisteredEntity[] indexed by registrationNumber
function global_data.getRegisteredEntities()
    storage.registeredEntities = storage.registeredEntities or {}
    return storage.registeredEntities
end
-- ###############################################################

--- structure containing all data concerning queued async functions
function global_data.getQueued()
    return storage.queued
end

return global_data
