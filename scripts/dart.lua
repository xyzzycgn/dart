---
--- Created by xyzzycgn.
--- DateTime: 20.03.25 12:49
---
--- D.A.R.T.s business logic
local Log = require("__log4factorio__.Log")
local dump = require("scripts.dump")
local global_data = require("scripts.global_data")
local asyncHandler = require("scripts.asyncHandler")

-- Type definitions for this file

--- @class TurretOnPlatform a turret on a platform
--- @field turret LuaEntity the turret
--- @field control_behavior LuaTurretControlBehavior of the turret

--- @class DartOnPlatform a D.A.R.T on a platform
--- @field radar LuaEntity dart-radar
--- @field control_behavior LuaConstantCombinatorControlBehavior of radar
--- @field radar_un uint64 unit_number of dart-radar

--- @class KnownAsteroid any describes an asteroid tracked by D.A.R.T
--- @field position MapPosition
--- @field movement table { x, y }
--- @field size string
--- @field entity LuaEntity the asteroid itself

--- @class Pons: any administrative structure for a platform
--- @field surface LuaSurface surface containing the platform
--- @field platform LuaSpacePlatform the platform
--- @field turretsOnPlatform TurretOnPlatform[] array of turrets located on the platform
--- @field dartsOnPlatform DartOnPlatform[] array of D.A.R.T. entities located on the platform
--- @field knownAsteroids KnownAsteroid[] array of asteroids currently known and in detection range

--- @class CnOfDart circuit network belonging to a dart-radar
--- @field radar_un int unit_number of dart-radar
--- @field radar LuaEntity dart-radar
--- @field control_behavior LuaConstantCombinatorControlBehavior of radar

--- @class CnOfTurret circuit network belonging to a turret.
--- @field turret LuaEntity turret
--- @field circuit_condition CircuitConditionDefinition of the turret

--- @class ManagedTurret turret managed by a D.A.R.T.
--- @field radar LuaEntity dart-radar managing turret
--- @field control_behavior LuaConstantCombinatorControlBehavior of radar
--- @field turret LuaEntity turret
--- @field circuit_condition CircuitConditionDefinition of the turret
--- @field targets_of_turret LuaEntity[] the targets of the turret

-- end of Type definitions for this file
-- ###############################################################

--- handle for asynchronous call of fragments()
local asyncFragments

-- ###############################################################

-- dump utilities

local function dumpOneSurface(k, v)
    return k .. " -> " .. serpent.block(dump.dumpSurface(v))
end

local function dumpSurfaces(table, sev)
    Log.log("surfaces", function(m)log(m)end, sev)

    for k, v in pairs(table) do
        Log.log(dumpOneSurface(k, v), function(m)log(m)end, sev)
    end
end

local function dumpOnePrototype(k, surface)
    return k .. " -> " .. serpent.block(dump.dumpAsteroidPropertyPrototype(surface))
end

local function dumpPrototypes(sev)
    Log.log("###### prototypes.surface_property", function(m)log(m)end, sev)

    for k, v in pairs(prototypes.asteroid_chunk) do
        Log.log(dumpOnePrototype(k, v), function(m)log(m)end, sev)
    end
end
-- ###############################################################

--- Calculates whether an asteroid hits, grazes or passes the defended area.
--- Defended area is defined by a circle with radius r and centerpoint at <xc, xc>
--- equation (x - xc)² + (y - yc)² = r²
---
--- The course of the asteroid is defined as half-line starting at <x0, y0> with
--- a movement vector of <dx, dy>.
--- P(t) = <x0, y0> + t * <dx, dy>
---
--- Combining the two equations for the circle and the half-line yields a quadratic equation
--- (x0 + t dx - xc)² + (y0 + t dy - yc)² = r²
--- transformed to
--- A t² + B t + C = 0
--- with
--- A = dx² + dy²
--- B = 2 ((x0 - xc) dx + (y0 - yc) * dy)
--- C = (x0 - xc)² + (y0 - yc)² - r²
--- whose discriminant is D = B² - 4 A C
--- Decisions:
--- If D < 0: the half-line does not intersect the circle - asteroid passes
--- If D = 0: the half-line touches the circle (one intersection) - asteroid grazes
--- If D > 0: the half-line intersect the circle twice - asteroid hits.
---
--- assuming center of defended area = center of hub on platform simplifies with xc = yc = 0
-- TODO use position of a certain dart-radar instead of center of hub
local function targeting(platform, chunk)
    local x0 = chunk.position.x
    local y0 = chunk.position.y

    local dx = chunk.movement.x
    local dy = chunk.movement.y + platform.speed

    local A = dx * dx + dy * dy
    local B = 2 * (x0 * dx + y0 * dy)
    local C = x0 * x0 + y0 * y0 - 15 * 15

    return B * B - 4 * A * C
end

local function distToTurret(target, turret)
    local dx = target.position.x - turret.position.x
    local dy = target.position.y - turret.position.y
    return math.sqrt(dx * dx + dy * dy)
end
--###############################################################

--- assign target to turrets depending on prio (nearest asteroid first)
--- @param pons Pons
--- @param knownAsteroids LuaEntity[]
--- @param managedTurrets ManagedTurret[]
--- @return any resulting filter setting (for all darts of a platform)
local function assignTargets(pons, knownAsteroids, managedTurrets)
    local filter_settings = {}

    -- reorganize prio
    for _, managedTurret in pairs(managedTurrets) do
        local turret = managedTurret.turret

        local prios = {}
        -- create array with unit_numbers of targets
        for tun, _ in pairs(managedTurret.targets_of_turret) do
            prios[#prios + 1] = tun
        end

        -- sort it by distance (ascending)
        table.sort(prios, function(i, j)
            return managedTurret.targets_of_turret[i] < managedTurret.targets_of_turret[j]
        end)

        -- save new priorities
        managedTurret.prios = prios

        -- and here occurs the miracle
        if (#prios > 0) then
            -- enable turret using circuit network
            script.raise_event(on_target_assigned_event, { tun = turret.unit_number, target = prios[1], reason="assign"} )

            Log.log("setting shooting_target=" .. (prios[1] or "<NIL>") ..
                    " for turret=" .. (turret.unit_number or "<NIL>"), function(m)log(m)end, Log.FINER)
            local asteroid = knownAsteroids[prios[1]].entity
            Log.logBlock(asteroid, function(m)log(m)end, Log.FINER)
            turret.shooting_target = asteroid
            -- unit number of dart-radar managing this turret
            local un = managedTurret.radar.unit_number
            -- filter_settings for this dart-radar
            local filter_setting_by_un = filter_settings[un] or {}

            -- now prepare to set the CircuitConditions
            -- @wube why simple if it could be complicated ;-)
            --- @type CircuitCondition
            Log.logBlock(managedTurret.circuit_condition, function(m)log(m)end, Log.FINER)
            local cc = managedTurret.circuit_condition
            local filter = {
                value = { type = cc.first_signal.type,
                          name = cc.first_signal.name,
                          quality = cc.first_signal.quality or 'normal',
                        },
                min = 1,
            }
            filter_setting_by_un[#filter_setting_by_un + 1] = filter
            filter_settings[un] = filter_setting_by_un
        else
            -- set no filter => disable turret using circuit network
            Log.log("try to disable turret=" .. (turret.unit_number or "<NIL>"), function(m)log(m)end, Log.FINER)
            turret.shooting_target = nil
            script.raise_event(on_target_unassigned_event, { tun = turret.unit_number, reason="unassign" } )
       end
    end

    Log.logBlock(filter_settings, function(m)log(m)end, Log.FINER)

    -- now set the CircuitConditions from the filter_settings
    -- @wube why simple if it could be complicated - part 2 ;-)
    for ndx, dart in pairs(pons.dartsOnPlatform) do
        local lls = dart.control_behavior.get_section(1)
        lls.filters = filter_settings[ndx] or {} -- if nothing is set => reset
    end
end
-- ###############################################################

--- calculate prio (based on distance to turrets) for an asteroid if within range (and harmful)
--- @param managedTurrets ManagedTurret[]
--- @param target LuaEntity asteroid which should be targeted
--- @param D float discriminant (@see targeting())
local function calculatePrio(managedTurrets, target, D)
    local tun = target.unit_number
    for _, v in pairs(managedTurrets) do
        -- target enters or touches protected area
        Log.logBlock(tun, function(m)log(m)end, Log.FINER)

        local inRange = false
        if D >= 0 then
            local dist = distToTurret(target, v.turret)
            -- remember distance for each turret to target if in range
            if dist <= 18 then -- TODO quality
                Log.logBlock(target, function(m)log(m)end, Log.FINER)
                v.targets_of_turret[tun] = dist
                inRange = true
            end
        end
        if not inRange then
            -- no longer or not in range / not hitting
            Log.logBlock(target, function(m)log(m)end, Log.FINER)
            v.targets_of_turret[tun] = nil
        end
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param pons Pons
local function circuitNetworkOfTurrets(pons)
    local turrets = pons.turretsOnPlatform

    -- determine circuit networks of turrets
    local cnOfTurrets = {}
    for tid, top in pairs(turrets) do
        local cb = top.control_behavior
        -- turrets only have simple green or red wire connectors
        for _, wc in pairs({ defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green }) do
            local network = cb.get_circuit_network(wc)

            if network then
                -- circuit_condition of turret
                local cot = cnOfTurrets[network.network_id] or {}
                cot[tid] = {
                    turret = top.turret,
                    circuit_condition = cb.circuit_condition,
                }
                cnOfTurrets[network.network_id] = cot
            end
        end
    end
    Log.logBlock(cnOfTurrets, function(m)log(m)end, Log.FINER)

    return cnOfTurrets
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- determine circuit networks of darts
--- @param pons Pons platform
--- @return CnOfDart[]
local function circuitNetworkOfDarts(pons)
    local darts = pons.dartsOnPlatform

    --- @type CnOfDart[]
    local cnOfDarts = {}
    for _, dart in pairs(darts) do
        local cb = dart.control_behavior
        -- darts only have simple green or red wire connectors
        for _, wc in pairs({ defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green }) do
            local network = cb.get_circuit_network(wc)

            if network then
                -- dart belonging to network
                cnOfDarts[network.network_id] = dart
            end
        end
    end
    Log.logBlock(cnOfDarts, function(m)log(m)end, Log.FINER)

    return cnOfDarts
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param pons Pons
--- @return ManagedTurret[]
local function getManagedTurrets(pons)
    --- @type CnOfDart[]
    local cnOfDarts = circuitNetworkOfDarts(pons)
    --- @type CnOfTurret[]
    local cnOfTurrets = circuitNetworkOfTurrets(pons)

    --- @type ManagedTurret[]
    local mts = {}
    -- iterate over all known circuit networks containing a dart
    for nwid, cnOfDart in pairs(cnOfDarts) do
        -- iterate over all known turrets in this circuit network
        for tid, cnOfTurret in pairs(cnOfTurrets[nwid]) do
            -- form ManagedTurret
            --- @type ManagedTurret
            local mt = {
                turret = cnOfTurret.turret,
                circuit_condition = cnOfTurret.circuit_condition,
                radar = cnOfDart.radar,
                control_behavior = cnOfDart.control_behavior,
                targets_of_turret = {},
            }
            mts[#mts + 1] = mt
        end
    end

    Log.logBlock(mts, function(m)log(m)end, Log.FINER)

    return mts
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param knownAsteroids KnownAsteroid[]
--- @param entity LuaEntity the new asteroid
local function newAsteroid(knownAsteroids, entity, fromEvent)
    -- new asteroid
    Log.logLine(dump.dumpEntity(entity), function(m)log(m)end, Log.FINEST)
    script.raise_event(on_asteroid_detected_event, {
        asteroid = entity, fromEvent = fromEvent, un = entity.unit_number, reason = "detected" })
    local target = {
        position = entity.position,
        movement = {},
        size = string.sub(entity.name, string.find(entity.name, "%a*")),
        entity = entity,
    }
    knownAsteroids[entity.unit_number] = target
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- perforn decision which asteroid should be targeted
local function businessLogic()
    Log.log("enter BL", function(m)log(m)end, Log.FINER)
    Log.logBlock(global_data.getPlatforms, function(m)log(m)end, Log.FINEST)

    for _, pons in pairs(global_data.getPlatforms()) do
        local surface = pons.surface
        local platform = pons.platform
        local managedTurrets = getManagedTurrets(pons)
        local knownAsteroids = pons.knownAsteroids

        local detectionRange = 35 -- TODO configurable or depending on quality?
        Log.log(platform.speed, function(m)log(m)end, Log.FINEST)
        -- detect all asteroids around platform - TODO do not use center of hub but position of dart
        local asteroids = surface.find_entities_filtered({ position = {0, 0}, radius = detectionRange, type ={ "asteroid" } })
        Log.log(#asteroids, function(m)log(m)end, Log.FINEST)

        local processed = {}
        for _, entity in pairs(asteroids) do
            local unit_number = entity.unit_number
            if (knownAsteroids[unit_number]) then
                -- well known asteroid
                local target = knownAsteroids[unit_number]

                target.movement.x = target.position.x - entity.position.x
                target.movement.y = target.position.y - entity.position.y
                target.position = entity.position

                local D = targeting(surface.platform, target)

                local color
                if (D < 0) then
                    color = { 0, 0.5, 0, 0.5 }
                elseif (D == 0) then
                    color = { 0.5, 0.5, 0, 0.5 }
                else
                    color = { 0.5, 0, 0, 0.5 }
                end

                -- TODO configure drawing
                rendering.draw_circle({
                    target = target.position,
                    color = color,
                    time_to_live = 55,
                    surface = surface,
                    radius = 0.8,
                })

                calculatePrio(managedTurrets, entity, D)
            else
                newAsteroid(knownAsteroids, entity)
            end
            processed[unit_number] = true
        end

        -- prevent memory leak - remove unprocessed asteroids (should be those which left detection range)
        for un, asteroid in pairs(knownAsteroids) do
            if not processed[un] then
                script.raise_event(on_asteroid_lost_event, { asteroid = asteroid.entity, un = un, reason="lost"} )
                knownAsteroids[un] = nil -- remove from knownAsteroids

                for _, v in pairs(managedTurrets) do
                    v.targets_of_turret[un] = nil -- remove from targets_of_turret
                end
            end
        end

        assignTargets(pons, knownAsteroids, managedTurrets)
    end
    Log.log("leave BL", function(m)log(m)end, Log.FINER)
end
-- ###############################################################

local function space_platform_changed_state(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINER)
    Log.logBlock(event.platform.speed, function(m)log(m)end, Log.FINER)
end
-- ###############################################################


--- add new asteroid fragments arising from the destroyed one
local function fragments(arg)
    local knownAsteroids = arg.knownAsteroids

    local cands = arg.surface.find_entities_filtered({ position = arg.position, radius = 2, type ={ "asteroid" } })
    Log.logLine(cands, function(m)log(m)end, Log.FINER)
    for _, cand in pairs(cands) do
        -- ignore the asteroid just destroyed (which may still exist in game), those already invalid or already known
        if cand.valid then
            local cun = cand.unit_number
            if (cun ~= arg.aun) and not knownAsteroids[cun] then
                Log.logBlock(function()dump.dumpEntity(cand)end, function(m)log(m)end, Log.FINEST)

                newAsteroid(knownAsteroids, cand, true)
            end
        end
    end
end
-- ###############################################################

--- called if an asteroid is destroyed
local function entity_died(event)
    --- @type LuaEntity
    local entity = event.entity
    Log.logBlock(event, function(m)log(m)end, Log.FINER)
    Log.logBlock(dump.dumpEntity(entity), function(m)log(m)end, Log.FINER)

    script.raise_event(on_target_destroyed_event, { entity=entity, un=entity.unit_number, reason="destroy" } )

    --- @type Pons
    local pons = global_data.getPlatforms()[entity.surface.index]
    local managedTurrets = getManagedTurrets(pons)
    local knownAsteroids = pons.knownAsteroids
    local aun = entity.unit_number
    local size = knownAsteroids[aun] and knownAsteroids[aun].size

    -- delete it from list of known asteroids
    knownAsteroids[aun] = nil

    -- delete it from target list
    for _, v in pairs(managedTurrets) do
        v.targets_of_turret[aun] = nil
    end

    -- if destroyed asteroid is not small (=> larger than small), start a search for the fragments
    if size and (size ~= "small") then
        -- execute fragments() in 2 ticks
        local deltatick = 2
        local nextPos = entity.position
        nextPos.y = nextPos.y + pons.platform.speed * deltatick / 60
        asyncHandler.enqueue(asyncFragments,
                { aun = aun, surface = entity.surface, position = nextPos, knownAsteroids = knownAsteroids },
                deltatick)
    end

    -- assign remaining asteroids to turrets
    assignTargets(pons, knownAsteroids, managedTurrets)
end
-- ###############################################################

--- new dart-radar created
local function entityCreated(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINER)

    local entity = event.entity or event.destination
    if not entity or not entity.valid then return end

    local dart_anim = rendering.draw_animation({
        animation = "dart-radar-animation",
        surface = entity.surface,
        target = entity,
        render_layer = "object"
    })
    Log.logBlock(dart_anim, function(m)log(m)end, Log.FINER)

    local run = entity.unit_number
    -- the tuple of dart-radar and its control_behavior
    local dart = {
        radar_un = run,
        radar = entity,
        control_behavior = entity.get_or_create_control_behavior(),
        animation = dart_anim,
    }
    -- save it in platform
    local gdp = global_data.getPlatforms()[entity.surface.index].dartsOnPlatform
    gdp[run] = dart
end
-- ###############################################################

local function entityRemoved(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINER)

    -- removed dart-radar
    local entity = event.entity
    local darts = global_data.getPlatforms()[entity.surface.index].dartsOnPlatform
    local run = entity.unit_number
    Log.logBlock(darts, function(m)log(m)end, Log.FINEST)
    Log.logBlock(run, function(m)log(m)end, Log.FINEST)

    -- clear the data belonging to the dart-radar
    darts[run] = nil
end
-- ###############################################################

--- creates the administrative structure for a new platform.
--- @param surface LuaSurface holding the new platform
--- @return Pons created from surface
local function newSurface(surface)
    return { surface = surface, platform = surface.platform, turretsOnPlatform = {}, dartsOnPlatform = {}, knownAsteroids = {} }
end
-- ###############################################################

local function surfaceCreated(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINER)
    local surface = game.surfaces[event.surface_index]

    if (surface.platform) then
        Log.log("add new platform " .. event.surface_index, function(m)log(m)end, Log.FINER)

        global_data.getPlatforms()[event.surface_index] = newSurface(surface)
    end
end
-- ###############################################################

local function surfaceDeleted(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINER)
    -- remove references to platform or objects on it
    global_data.getPlatforms()[event.surface_index] = nil
end
--###############################################################

local function searchPlatforms()
    local gdp = global_data.getPlatforms()

    for _, surface in pairs(game.surfaces) do
        if surface.platform then
            gdp[surface.index] = newSurface(surface)
        end
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param pons Pons
local function searchTurrets(pons)
    local turretsOnPlatform = pons.turretsOnPlatform

    for _, turret in pairs(pons.surface.find_entities_filtered({ type = "ammo-turret" })) do
        Log.logBlock(turret, function(m)log(m)end, Log.FINER)
        turretsOnPlatform[turret.unit_number] = {
            turret = turret,
            control_behavior = turret.get_or_create_control_behavior(),
        }
    end
    Log.logBlock(pons, function(m)log(m)end, Log.FINER)

end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- searches D.A.R.T. components on existing platforms
--- as this is called from on_init, there can't be any dart-radar enties
--- that's why we only look for turrets on platforms
local function searchDartInfrastructure()
    Log.log("searchDartInfrastructure", function(m)log(m)end, Log.FINER)

    searchPlatforms()

    -- iterate platforms on surfaces
    for _, pons in pairs(global_data.getPlatforms()) do
        searchTurrets(pons)
    end

     Log.logBlock(global_data.getPlatforms, function(m)log(m)end, Log.FINER)
end
--###############################################################

--
-- Mod initialization
--

--- register complexer events with additional filters
local function registerEvents()
    local filters_on_built    = {{ filter = 'name', name = 'dart-radar' }}
    local filters_on_mined    = {{ filter = 'name', name = 'dart-radar' }}
    local filters_entity_died = {{ filter = "type", type = "asteroid" }}

    script.on_event(defines.events.on_space_platform_built_entity, entityCreated, filters_on_built)
    script.on_event(defines.events.on_space_platform_mined_entity, entityRemoved, filters_on_mined)
    script.on_event(defines.events.on_entity_died, entity_died, filters_entity_died)

    asyncFragments = asyncHandler.registerAsync(fragments)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function initLogging()
    Log.setFromSettings("dart-logLevel")
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- complete initialization of D.A.R.T for new map/save-file
local function dart_initializer()
    initLogging()
    Log.log('D.A.R.T on_init', function(m)log(m)end)

    dumpSurfaces(game.surfaces, Log.FINEST)
    dumpPrototypes(Log.FINEST)

    global_data.init();
    searchDartInfrastructure()
    registerEvents()
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- initialization of D.A.R.T for save-file which already contained this mod
local function dart_load()
    initLogging()
    Log.log('D.A.R.T on_load', function(m)log(m)end)

    registerEvents()
end

--- init D.A.R.T on every mod update or change
local function dart_config_changed()
    Log.log('D.A.R.T config_changed', function(m)log(m)end)
    dumpSurfaces(game.surfaces, Log.FINEST)
    dumpPrototypes(Log.FINEST)

    global_data.init();
end
--###############################################################

local function tbd(event)
    Log.logLine(event, function(m)log(m)end, Log.FINER)
end
--###############################################################

local function tbda(event)
    Log.logLine(event, function(m)log(m)end, Log.FINER)
end
--###############################################################

local function tbdu(event)
    Log.logLine(event, function(m)log(m)end, Log.FINER)
end
--###############################################################

local function tbdd(event)
    Log.logLine(event, function(m)log(m)end, Log.FINER)
end
--###############################################################

local function tbdad(event)
    Log.logLine(event, function(m)log(m)end, Log.FINER)
end
--###############################################################

local function tbdal(event)
    Log.logLine(event, function(m)log(m)end, Log.FINER)
end
--###############################################################

local dart = {}

-- mod initialization
dart.on_init = dart_initializer
dart.on_load = dart_load
dart.on_configuration_changed = dart_config_changed

-- events without filters
dart.events = {
    [defines.events.on_entity_cloned]                = entityCreated, -- TODO delete?
    [defines.events.script_raised_destroy]           = entityRemoved,
    [defines.events.on_space_platform_pre_mined]     = tbd,
    [defines.events.on_surface_created]              = surfaceCreated,
    [defines.events.on_pre_surface_deleted]          = surfaceDeleted,
    [defines.events.on_space_platform_changed_state] = space_platform_changed_state,
    [defines.events.on_player_joined_game] = tbd,
    [defines.events.on_player_left_game] = tbd,
    [defines.events.on_player_removed] = tbd,

    [on_target_assigned_event] = tbda,
    [on_target_unassigned_event] = tbdu,
    [on_target_destroyed_event] = tbdd,
    [on_asteroid_detected_event] = tbdad,
    [on_asteroid_lost_event] = tbdal,

    [defines.events.on_tick] = asyncHandler.dequeue,
}

-- handling of business logic
dart.on_nth_tick = {
    [60] = businessLogic,
}

return dart
