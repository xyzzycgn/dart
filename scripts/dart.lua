---
--- Created by xyzzycgn.
--- DateTime: 20.03.25 12:49
---
--- D.A.R.T.s business logic
local Log = require("__log4factorio__.Log")
local dump = require("scripts.dump")
local global_data = require("scripts.global_data")
local player_data = require("scripts.player_data")
local asyncHandler = require("scripts.asyncHandler")
local constants = require("scripts.constants")
local utils = require("scripts.utils")
local messaging = require("scripts.messaging")
local ammoTurretMapping = require("scripts.ammoTurretMapping")

-- Type definitions for this file

--- @class TurretOnPlatform a turret on a platform
--- @field turret LuaEntity the turret
--- @field control_behavior LuaTurretControlBehavior of the turret
--- @field range float range of the turret

--- @class FccOnPlatform a dart-fcc on a platform
--- @field fcc LuaEntity dart-fcc
--- @field control_behavior LuaConstantCombinatorControlBehavior of fcc
--- @field fcc_un uint64 unit_number of dart-fcc
--- @field ammo_warning_threshold uint threshold for warning for low ammo

--- @class RadarOnPlatform a dart-radar on a platform
--- @field radar LuaEntity dart-radar
--- @field radar_un uint64 unit_number of dart-radar
--- @field detectionRange uint radius of detection around a dart-radar
--- @field defenseRange uint radius of defended area around a dart-radar

--- @class KnownAsteroid any describes an asteroid tracked by D.A.R.T
--- @field position MapPosition
--- @field movement table { x, y }
--- @field size string
--- @field entity LuaEntity the asteroid itself

--- @class Pons: any administrative structure for a platform
--- @field surface LuaSurface surface containing the platform
--- @field platform LuaSpacePlatform the platform
--- @field turretsOnPlatform TurretOnPlatform[] array of turrets located on the platform, indexed by unit_number
--- @field fccsOnPlatform FccOnPlatform[] array of D.A.R.T. fcc entities located on the platform
--- @field radarsOnPlatform RadarOnPlatform[] array of D.A.R.T. radar entities located on the platform
--- @field knownAsteroids KnownAsteroid[] array of asteroids currently known and in detection range

--- @class CnOfTurret circuit network belonging to a turret.
--- @field turret LuaEntity turret
--- @field circuit_condition CircuitConditionDefinition of the turret

--- @class ManagedTurret turret managed by a D.A.R.T.
--- @field fcc LuaEntity dart-fcc managing turret
--- @field control_behavior LuaConstantCombinatorControlBehavior of fcc
--- @field turret LuaEntity turret
--- @field circuit_condition CircuitConditionDefinition of the turret
--- @field targets_of_turret LuaEntity[] the targets of the turret
--- @field range float range of the turret

--- @class DestroyedTarget contains data of a destroyed asteroid which are used to find the fragments arising from it
--- @field aun uint unit_number of destroyed asteroid
--- @field position MapPosition  last known position of destroyed asteroid
--- @field surface LuaSurface where destruction of an asteroid happened
--- @field knownAsteroids KnownAsteroid[] list of actual known asteroids in this surface

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
--- If D > 0: the half-line intersects the circle twice - asteroid hits.
---
--- @param pons Pons the platform for that the targeting has to be done
--- @param asteroid LuaEntity asteroid to be checked
local function targeting(pons, asteroid)
    local platform = pons.platform

    -- check defenseRange of all dart-radars
    local D = -1
    for _, rop in pairs(pons.radarsOnPlatform) do
        local radar = rop.radar
        local pos = radar.position

        local x0_xc = asteroid.position.x - pos.x
        local y0_yc = asteroid.position.y - pos.y

        local dx = asteroid.movement.x
        local dy = asteroid.movement.y + platform.speed

        local A = dx * dx + dy * dy
        local B = 2 * (x0_xc * dx + y0_yc * dy)
        local C = x0_xc * x0_xc + y0_yc * y0_yc - rop.defenseRange * rop.defenseRange

        D = B * B - 4 * A * C

        if (D >= 0) then
            -- asteroid will hit or graze
            break
        end
    end

    return D
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
            script.raise_event(on_target_assigned_event, { tun = turret.unit_number, target = prios[1], reason="assign"} )

            -- enable turret using circuit network
            Log.log("setting shooting_target=" .. (prios[1] or "<NIL>") ..
                    " for turret=" .. (turret.unit_number or "<NIL>"), function(m)log(m)end, Log.FINER)
            local asteroid = knownAsteroids[prios[1]].entity
            Log.logBlock(asteroid, function(m)log(m)end, Log.FINER)
            turret.shooting_target = asteroid
            -- unit number of dart-fcc managing this turret
            local un = managedTurret.fcc.unit_number
            -- filter_settings for this dart-fcc
            local filter_setting_by_un = filter_settings[un] or {}

            -- now prepare to set the CircuitConditions
            -- @wube why simple if it could be complicated ;-)
            --- @type CircuitCondition
            Log.logBlock(managedTurret.circuit_condition, function(m)log(m)end, Log.FINER)
            local cc = managedTurret.circuit_condition
            if utils.checkCircuitCondition(cc) then
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
                Log.log("ignored turret with invalid CircuitCondition=" .. (turret.unit_number or "<NIL>"), function(m)log(m)end, Log.WARN)
            end
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
    for ndx, dart in pairs(pons.fccsOnPlatform) do
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
            if dist <= v.range then
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
--- @return CnOfTurret[][] indexed by network id, unit_number of turret
local function circuitNetworkOfTurrets(pons)
    local turrets = pons.turretsOnPlatform

    -- determine circuit networks of turrets
    local cnOfTurrets = {}
    for tid, top in pairs(turrets) do
        local cb = top.control_behavior
        -- turrets only have simple green or red wire connectors
        for _, wc in pairs({ defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green }) do
            local network = cb.valid and cb.get_circuit_network(wc)

            if network then
                --- @type CnOfTurret
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
--- @return FccOnPlatform[] indexed by network id
local function circuitNetworkOfDarts(pons)
    local darts = pons.fccsOnPlatform

    --- @type FccOnPlatform[]
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
    --- @type FccOnPlatform[]
    local cnOfDarts = circuitNetworkOfDarts(pons)
    --- @type CnOfTurret[][]
    local cnOfTurrets = circuitNetworkOfTurrets(pons)

    --- @type ManagedTurret[]
    local mts = {}
    -- iterate over all known circuit networks containing a dart
    for nwid, cnOfDart in pairs(cnOfDarts) do
        -- iterate over all known turrets in this circuit network
        local cnot = cnOfTurrets[nwid] or {}
        for _, cnOfTurret in pairs(cnot) do
            local turret = cnOfTurret.turret

            --- @type ManagedTurret
            local mt = {
                turret = turret,
                circuit_condition = cnOfTurret.circuit_condition,
                fcc = cnOfDart.fcc,
                control_behavior = cnOfDart.control_behavior,
                targets_of_turret = {},
                range = pons.turretsOnPlatform[turret.unit_number].range
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

--- all asteroids in detectionRange of at least one dart-radar
--- @param pons Pons
--- @return LuaEntity[] detected asteroids indexed by unit_number
local function detection(pons)
    local detectedAsteroids = {}
    local surface = pons.surface
    for _, rop in pairs(pons.radarsOnPlatform) do
        Log.logBlock(rop, function(m)log(m)end, Log.FINER)
        local pos = rop.radar.position
        local asteroids = surface.find_entities_filtered({ position = pos, radius = rop.detectionRange, type ={ "asteroid" } })
        for _, asteroid  in pairs(asteroids) do
            detectedAsteroids[asteroid.unit_number] = asteroid
        end
        local width = rop.edited and 3 or 1 -- thickness of drawn circle
        -- would be nice if only done when hovering over a dart-radar - unfortunately there seems to be no suitable event
        if settings.global["dart-show-detection-area"].value or rop.edited then
            rendering.draw_circle({
                target = pos,
                color = { 0, 0, 0.7, 1 },
                surface = surface,
                time_to_live = 55,
                radius = rop.detectionRange,
                width = width,
            })
        end
        if settings.global["dart-show-defended-area"].value or rop.edited then
            rendering.draw_circle({
                target = pos,
                color = { 0, 0.7, 0.7, 1 },
                surface = surface,
                time_to_live = 55,
                radius = rop.defenseRange,
                width = width,
            })
        end
    end

    Log.logBlock(detectedAsteroids, function(m)log(m)end, Log.FINER)

    return detectedAsteroids
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param pons Pons
local function platform2richText(pons)
    return string.format("[space-platform=%d]", pons.platform.index)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param ls LocalisedString
--- @param filter MessageFilter
--- @param pons Pons
--- @param num number|nil number of asteroids hitting or grazing or ...
local function messageConcerningAsteroids(ls, filter, pons, num)
    if pons.platform.valid then
        if not num then
            messaging.printmsg({ ls, platform2richText(pons) }, filter, pons.platform.force)
        elseif (num > 0) then
            messaging.printmsg({ ls, num, platform2richText(pons) }, filter, pons.platform.force)
        end
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param pons Pons
--- @param managedTurrets ManagedTurret[]
local function checkLowAmmo(pons, managedTurrets)
    Log.log("check low ammo", function(m)log(m)end, Log.FINER)

    local platform = pons.platform
    local hub = platform.hub
    --- @type LuaInventory
    local inv = hub.get_inventory(defines.inventory.hub_main)
    if inv then

        local contents = inv.get_contents()
        Log.logBlock({ platform = platform.name, inv=contents }, function(m)log(m)end, Log.FINEST)

        Log.logBlock(ammoTurretMapping.getAmmoTurretMapping, function(m)log(m)end, Log.FINE)
    else
        Log.log("hub without hub_main inventory", function(m)log(m)end, Log.WARN)
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- perform decision which asteroid should be targeted
local function businessLogic()
    Log.log("enter BL", function(m)log(m)end, Log.FINER)
    Log.logBlock(global_data.getPlatforms, function(m)log(m)end, Log.FINEST)

    local warnLowAmmo = settings.global["dart-low-ammo-warning"].value
    for _, pons in pairs(global_data.getPlatforms()) do
        local surface = pons.surface
        --- @type LuaSpacePlatform
        local platform = pons.platform
        local managedTurrets = getManagedTurrets(pons)
        local knownAsteroids = pons.knownAsteroids

        if platform.valid then
            Log.log(platform.speed, function(m)log(m)end, Log.FINEST)
            -- detect all asteroids around platform
            local processed = {}
            local hitting = 0
            local grazing = 0
            for aun, asteroid in pairs(detection(pons)) do
                if (knownAsteroids[aun]) then
                    -- well known asteroid
                    local target = knownAsteroids[aun]

                    target.movement.x = target.position.x - asteroid.position.x
                    target.movement.y = target.position.y - asteroid.position.y
                    target.position = asteroid.position

                    local D = targeting(pons, target)

                    local color
                    if (D < 0) then
                        color = { 0, 0.7, 0, 1 }
                    elseif (D == 0) then
                        color = { 0.7, 0.7, 0, 1 }
                        grazing = grazing + 1
                    else
                        color = { 0.7, 0, 0, 1 }
                        hitting = hitting + 1
                    end

                    if settings.global["dart-mark-targets"].value then
                        rendering.draw_circle({
                            target = target.position,
                            color = color,
                            time_to_live = 55,
                            surface = surface,
                            radius = 0.8,
                        })
                    end

                    calculatePrio(managedTurrets, asteroid, D)
                else
                    -- new asteroid
                    if table_size(knownAsteroids) == 0 then
                        messageConcerningAsteroids("dart-message.dart-asteroids-approaching", messaging.level.WARNING, pons)
                    end
                    newAsteroid(knownAsteroids, asteroid)
                end
                processed[aun] = true
            end

            -- messages if asteroid(s) on collision course/grazing
            messageConcerningAsteroids("dart-message.dart-asteroids-collision-course", messaging.level.ALERT, pons, hitting)
            messageConcerningAsteroids("dart-message.dart-asteroids-grazing", messaging.level.WARNING, pons, grazing)

            -- prevent memory leak - remove unprocessed asteroids (should be those which left detection range)
            local left = 0
            for un, asteroid in pairs(knownAsteroids) do
                if not processed[un] then
                    script.raise_event(on_asteroid_lost_event, { asteroid = asteroid.entity, un = un, reason="lost"} )
                    knownAsteroids[un] = nil -- remove from knownAsteroids

                    for _, v in pairs(managedTurrets) do
                        v.targets_of_turret[un] = nil -- remove from targets_of_turret
                    end
                    left = left + 1
                end
            end
            messageConcerningAsteroids("dart-message.dart-asteroids-left", messaging.level.INFO, pons, left)

            assignTargets(pons, knownAsteroids, managedTurrets)
        else
            Log.log("skipped invalid platform during processing", function(m)log(m)end, Log.WARN)
        end

        -- check low ammo if enabled, hub present and protected by D.A.R.T. (FCC built)
        if warnLowAmmo and platform.hub and pons.fccsOnPlatform and table_size(pons.fccsOnPlatform) > 0 then
            checkLowAmmo(pons, managedTurrets)
        end
    end
    Log.log("leave BL", function(m)log(m)end, Log.FINER)
end
-- ###############################################################

local function space_platform_changed_state(event)
    Log.logLine({ event = dump.dumpEvent(event), speed=event.platform.speed}, function(m)log(m)end, Log.FINER)
end
-- ###############################################################

--- @param event EventData
local function playerChangedSurface(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.FINE)
    local pd = global_data.getPlayer_data(event.player_index)
    local guis = pd and pd.guis

    if guis and guis.open then
        Log.log("close gui", function(m)log(m)end, Log.FINE)
        if guis.open.gui and guis.open.gui.valid then
            guis.open.gui.destroy()
            guis.open = {}
        end
    end
end
-- ###############################################################

--- add new asteroid fragments arising from the destroyed one (will be called asynchronusly after destruction of an asteroid)
--- @param dest_target DestroyedTarget
local function fragments(dest_target)
    local knownAsteroids = dest_target.knownAsteroids

    local cands = dest_target.surface.find_entities_filtered({ position = dest_target.position, radius = 2, type ={ "asteroid" } })
    Log.logLine(cands, function(m)log(m)end, Log.FINER)
    for _, cand in pairs(cands) do
        -- ignore the asteroid just destroyed (which may still exist in game), those already invalid or already known
        if cand.valid then
            local cun = cand.unit_number
            if (cun ~= dest_target.aun) and not knownAsteroids[cun] then
                Log.logBlock(function()dump.dumpEntity(cand)end, function(m)log(m)end, Log.FINEST)

                newAsteroid(knownAsteroids, cand, true)
            end
        end
    end
end
-- ###############################################################

local function asteroid_died(entity)
    script.raise_event(on_target_destroyed_event, { entity=entity, un=entity.unit_number, reason="destroy" } )

    --- @type Pons
    local pons = global_data.getPlatforms()[entity.surface.index]
    if pons then
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
    else
        Log.log("asteroid_died - unknown pons for surface=" .. entity.surface.index, function(m)log(m)end, Log.WARN)
    end
end

local function hub_died(entity)
    -- remove references to platform or objects on it
    local sid = entity.surface.index
    local pons = global_data.getPlatforms()[sid]
    if pons then
        Log.log("removing all D.A.R.T. installations on platform=" .. pons.platform.name, function(m)log(m)end, Log.INFO)
        global_data.getPlatforms()[sid] = nil
        -- remove references to platform in player_data
        local platform = pons.platform
        if platform.valid then
            for _, player in pairs(platform.force.players) do
                local pd = global_data.getPlayer_data(player.index)
                pd.pons[platform.index] = nil
            end
        else
            Log.log("platform already invalid - surfaceid = " .. event.surface_index, function(m)log(m)end, Log.WARN)
        end
    else
        Log.log("hub_died - unknown pons for surface=" .. sid, function(m)log(m)end, Log.WARN)
    end
end

local diedFuncs = {
    ["space-platform-hub"] = hub_died,
    asteroid = asteroid_died,
}

--- event handler called if an asteroid or a hub is destroyed
local function entity_died(event)
    --- @type LuaEntity
    local entity = event.entity

    local func = diedFuncs[entity.name] or diedFuncs[entity.type]
    _= func and func(entity, event)
end
-- ###############################################################

--- @param turretsOnPlatform TurretOnPlatform[]
--- @param turret LuaEntity
local function addTurretToPons(turretsOnPlatform, turret)
    local prot = prototypes.entity[turret.name]
    local ap = prot.attack_parameters

    turretsOnPlatform[turret.unit_number] = {
        turret = turret,
        control_behavior = turret.get_or_create_control_behavior(),
        range = ap.range
    }
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param eventnumber number generated by script.generate_event_name()
--- @see InternalEvents.lua
--- @param entity LuaEntity
local function raiseDartComponentEvent(eventnumber, entity)
    --- @type LuaForce
    local force = entity.force
    for _, player in pairs(force.players) do
        script.raise_event(eventnumber, { entity = entity, player_index = player.index } )
    end
end

--- @param entity LuaEntity
local function raiseDartComponentBuild(entity)
    raiseDartComponentEvent(on_dart_component_build_event, entity)
end


--- @param entity LuaEntity
local function newRadar(entity)
    local radar_un = entity.unit_number
    --- @type RadarOnPlatform
    local dart = {
        radar_un = radar_un,
        radar = entity,
        detectionRange = constants.default_detectionRange,
        defenseRange = constants.default_defenseRange,
    }
    -- save it in platform
    local gdp = global_data.getPlatforms()[entity.surface.index].radarsOnPlatform
    gdp[radar_un] = dart

    raiseDartComponentBuild(entity)

    Log.logBlock(dart, function(m)log(m)end, Log.FINER)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param entity LuaEntity
local function newFcc(entity)
    local fccun = entity.unit_number
    -- the tuple of dart-fcc and its control_behavior
    --- @type FccOnPlatform
    local dart = {
        fcc_un = fccun,
        fcc = entity,
        control_behavior = entity.get_or_create_control_behavior(),
        ammo_warning_threshold = settings.global["dart-low-ammo-warning-threshold-default"].value
    }
    -- save it in platform
    local gdp = global_data.getPlatforms()[entity.surface.index].fccsOnPlatform
    gdp[fccun] = dart
    Log.logBlock(dart, function(m)log(m)end, Log.FINE)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param entity LuaEntity
local function newTurret(entity)
    Log.log(entity.unit_number, function(m)log(m)end, Log.FINER)

    local pons = global_data.getPlatforms()[entity.surface.index]
    if pons then -- fix for #25
        addTurretToPons(pons.turretsOnPlatform, entity)
        raiseDartComponentBuild(entity)
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local createFuncs = {
    -- by name
    ["dart-fcc"] = newFcc,
    ["dart-radar"] = newRadar,

    -- by type
    ["ammo-turret"] = newTurret,
}

--- event handler called if a new dart-fcc/dart-radar or a turret is build on a platform
--- @param entity LuaEntity
local function entityCreated(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.FINE)

    local entity = event.entity or event.destination
    if not entity or not entity.valid then return end

    local func = createFuncs[entity.name] or createFuncs[entity.type]

    _= func and func(entity, event)
end
-- ###############################################################

--- @param entity LuaEntity
local function raiseDartComponentRemoved(entity)
    raiseDartComponentEvent(on_dart_component_removed_event, entity)
end

--- @param entity LuaEntity
local function removedRadar(entity, event)
    local darts = global_data.getPlatforms()[entity.surface.index].radarsOnPlatform
    local fccun = entity.unit_number
    Log.logBlock({ darts = darts, fccun = fccun }, function(m)log(m)end, Log.FINE)

    -- check if deleted radar is just show in a GUI -> close it (for all players of the force owning the entity)
    for _, player in pairs(entity.force.players) do
        local pd = global_data.getPlayer_data(player.index)
        if pd and pd.guis and pd.guis.open then
            -- there is an open GUI
            local opengui = pd.guis.open -- the actual opened gui
            Log.logBlock(opengui, function(m)log(m)end, Log.FINE)

            if opengui and opengui.entity and (opengui.entity.unit_number == entity.unit_number) then
                -- for the deleted dart-radar
                event.gae = opengui
                event.player_index = player.index
                -- close the opened gui for this dart-radar
                Log.log("raising on_dart_gui_close", function(m)log(m)end, Log.FINE)
                script.raise_event(on_dart_gui_close, event)
            end
        end
    end

    -- clear the data belonging to the dart-radar
    darts[fccun] = nil
    raiseDartComponentRemoved(entity)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param entity LuaEntity
local function removedFcc(entity)
    local darts = global_data.getPlatforms()[entity.surface.index].fccsOnPlatform
    local fccun = entity.unit_number
    Log.logBlock({ darts = darts, fccun = fccun }, function(m)log(m)end, Log.FINER)

    -- clear the data belonging to the dart-fcc
    darts[fccun] = nil
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param entity LuaEntity
local function removedTurret(entity)
    Log.log(entity.unit_number, function(m)log(m)end, Log.FINER)

    -- remove turret
    local pons = global_data.getPlatforms()[entity.surface.index]
    if pons then -- fix for #25
        local turretsOnPlatform = pons.turretsOnPlatform
        turretsOnPlatform[entity.unit_number] = nil
        raiseDartComponentRemoved(entity)
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local removedFuncs = {
    -- by name
    ["dart-fcc"] = removedFcc,
    ["dart-radar"] = removedRadar,

    -- by type
    ["ammo-turret"] = removedTurret,
}

--- event handler called if a dart-fcc/dart-radar or a turret is removed from platform
local function entityRemoved(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.FINE)
    local entity = event.entity
    local func = removedFuncs[entity.name] or removedFuncs[entity.type]

    _= func and func(entity, event)
end
-- ###############################################################

--- creates the administrative structure for a new platform.
--- @param surface LuaSurface holding the new platform
--- @return Pons created from surface
local function newSurface(surface)
    Log.log("detected new surface with platform - index=" .. surface.index, function(m)log(m)end, Log.INFO)
    return { surface = surface, platform = surface.platform, turretsOnPlatform = {},
             fccsOnPlatform = {}, radarsOnPlatform = {}, knownAsteroids = {} }
end
-- ###############################################################

--- creates the administrative structure for a new platform and stores it in
--- global_data resp. PlayerData of the owner
--- @param surface LuaSurface
local function createPonsAndAddToGDPAndPD(surface)
    local platform = surface.platform

    if platform then
        local sid = surface.index
        Log.log("add new platform on surface index=" .. sid, function(m)log(m)end, Log.INFO)

        local pons = newSurface(surface)
        global_data.getPlatforms()[sid] = pons

        for _, player in pairs(platform.force.players) do
            local pd = global_data.getPlayer_data(player.index)
            if not pd then
                pd = player_data.init_player_data(player)
                global_data.addPlayer_data(player, pd)
            end
            pd.pons[platform.index] = pons
        end
    end
end
-- ###############################################################

--- event handler for on_surface_created
--- @param event EventData
local function surfaceCreated(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.FINE)
    local surface = game.surfaces[event.surface_index]

    createPonsAndAddToGDPAndPD(surface)
end
-- ###############################################################

-- part of initialization
local function searchPlatforms()
    for _, surface in pairs(game.surfaces) do
        createPonsAndAddToGDPAndPD(surface)
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param pons Pons
local function searchTurrets(pons)
    local turretsOnPlatform = pons.turretsOnPlatform

    for _, turret in pairs(pons.surface.find_entities_filtered({ type = "ammo-turret" })) do
        addTurretToPons(turretsOnPlatform, turret)
    end
    Log.logBlock(pons, function(m)log(m)end, Log.FINER)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- searches turrets on existing platforms
--- as this is called from on_init, there can't be any dart-radar/dart-fcc enties
--- that's why we only look for turrets on platforms
local function searchDartInfrastructure()
    Log.log("searchDartInfrastructure", function(m)log(m)end, Log.INFO)

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

--- register complexer events, e.g. with additional filters
local function registerEvents()
    local filters_dart_components = { { filter = 'name', name = 'dart-radar' },
                                      { filter = 'name', name = 'dart-fcc' },
                                      { filter = 'type', type = 'ammo-turret' },
    }

    local filters_entity_died = {
        { filter = "type", type = "asteroid" },
        { filter = "type", type = "space-platform-hub" },
    }

    script.on_event(defines.events.on_space_platform_built_entity, entityCreated, filters_dart_components)
    script.on_event(defines.events.on_space_platform_mined_entity, entityRemoved, filters_dart_components)
    script.on_event(defines.events.on_entity_died, entity_died, filters_entity_died)

    asyncFragments = asyncHandler.registerAsync(fragments)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function initLogging()
    Log.setSeverityFromSettings("dart-logLevel")
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
local function player_joined_or_created(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end)
    init_player_data(event.player_index)
end
--###############################################################

--- @param event EventData
local function tbd(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end)
end
--###############################################################

--- @param event EventData
local function tbda(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.FINER)
end
--###############################################################

--- @param event EventData
local function tbdu(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.FINER)
end
--###############################################################

--- @param event EventData
local function tbdd(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.FINER)
end
--###############################################################

--- @param event EventData
local function tbdad(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.FINER)
end
--###############################################################

--- @param event EventData
local function tbdal(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.FINER)
end
--###############################################################

local function alterSetting(event, which, func)
    if event.setting == which then
        local new = settings.global[which].value
        if type(new) == "nil" then
            new = "<NIL>"
        elseif type(new) == "boolean" then
            new = new and "true" or "false"
        end
        Log.log('setting ' .. which .. ' changed to ' .. new, function(m)log(m)end, Log.CONFIG)
        if func then
            func(new)
        end
        return true
    end
    return false
end

local function changeSettings(e)
    -- local var to make lua happy
    local _ =
        alterSetting(e, "dart-logLevel", function(newval) Log.setSeverity(Log[newval]) end)
        or alterSetting(e, "dart-show-detection-area")
        or alterSetting(e, "dart-show-defended-area")
        or alterSetting(e, "dart-mark-targets")
        or alterSetting(e, "dart-msgLevel")
        or alterSetting(e, "dart-low-ammo-warning")
        or alterSetting(e, "dart-low-ammo-warning-threshold-default")
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
    [defines.events.on_surface_created]              = surfaceCreated,
    [defines.events.on_space_platform_changed_state] = space_platform_changed_state,
    [defines.events.on_player_created]               = player_joined_or_created,
    [defines.events.on_player_joined_game]           = player_joined_or_created,
    [defines.events.on_player_left_game] = tbd,
    [defines.events.on_player_removed] = tbd,
    [defines.events.on_player_changed_surface]       = playerChangedSurface,
    [defines.events.on_runtime_mod_setting_changed]  = changeSettings,

    [defines.events.on_tick] = asyncHandler.dequeue,

    -- defined in internalEvents.lua
    [on_target_assigned_event] = tbda,
    [on_target_unassigned_event] = tbdu,
    [on_target_destroyed_event] = tbdd,
    [on_asteroid_detected_event] = tbdad,
    [on_asteroid_lost_event] = tbdal,
}

-- handling of business logic
dart.on_nth_tick = {
    [60] = businessLogic,
}

return dart
