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
local Hub = require("scripts.Hub")
local messaging = require("scripts.messaging")
local ammoTurretMapping = require("scripts.ammoTurretMapping")

-- Type definitions for this file

--- @class TurretOnPlatform a turret on a platform
--- @field turret LuaEntity the turret
--- @field control_behavior LuaTurretControlBehavior of the turret
--- @field range float range of the turret

--- @class AmmoWarningThreshold threshold for warning of ammo shortage of a certain ammo type
--- @field type string ammo type
--- @field enabled boolean flag whether warning (for a certain ammo type) is active
--- @field threshold uint threshold value for warning for low ammo

--- @class AmmoWarningThresholdAndStock threshold for warning of ammo shortage of a certain ammo type + stock in hub
--- @field threshold AmmoWarningThreshold
--- @field stockInHub uint stock in hub for this ammo type

--- @class AmmoWarning settings for warning of ammo shortage for a fcc
--- @field autoValues boolean flag if thresholds have been initially set, but may (probably) need updates in gui
--- @field turret_types table<string> List of turret-types connected to a fcc
--- @field thresholds table<string, AmmoWarningThreshold> thresholds for warning for low ammo (indexed by ammo type)

--- @class FccOnPlatform a dart-fcc on a platform
--- @field fcc LuaEntity dart-fcc
--- @field control_behavior LuaConstantCombinatorControlBehavior of fcc
--- @field fcc_un uint64 unit_number of dart-fcc
--- @field ammo_warning AmmoWarning

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
--- @field fccsOnPlatform table<uint, FccOnPlatform> array of D.A.R.T. fcc entities located on the platform, indexed by un of fcc
--- @field radarsOnPlatform RadarOnPlatform[] array of D.A.R.T. radar entities located on the platform
--- @field knownAsteroids KnownAsteroid[] array of asteroids currently known and in detection range
--- @field ammoInStockPerType table<string, uint> array with stock in hub per ammo type

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
            Log.logMsg(function(m)log(m)end, Log.FINER, "setting shooting_target=%s for turret=%s",
                       prios[1] or "<NIL>", turret.unit_number or "<NIL>")
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
                Log.logMsg(function(m)log(m)end, Log.WARN, "ignored turret with invalid CircuitCondition=%s", turret.unit_number or "<NIL>")
            end
        else
            -- set no filter => disable turret using circuit network
            Log.logMsg(function(m)log(m)end, Log.FINER, "try to disable turret=%s", turret.unit_number or "<NIL>")
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
--- @param lvl MessageLevel
--- @param pons Pons
--- @param num number|nil number of asteroids hitting or grazing or ...
local function messageConcerningAsteroids(ls, lvl, pons, num)
    if pons.platform.valid then
        if not num then
            messaging.printmsg({ ls, platform2richText(pons) }, lvl, pons.platform.force)
        elseif (num > 0) then
            messaging.printmsg({ ls, num, platform2richText(pons) }, lvl, pons.platform.force)
        end
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- determines which types of turrets are connected to fcc and initializes settings per ammo-type if needed
--- @param pons Pons
--- @param managedTurrets ManagedTurret[]
local function updateTurretTypes(pons, managedTurrets)
    if table_size(pons.fccsOnPlatform) > 0 then
        -- only platforms with a fcc
        for _, mt in pairs(managedTurrets) do
            local fcc = mt.fcc -- fcc managing the turret
            local fop = pons.fccsOnPlatform[fcc.unit_number]

            if not fop.ammo_warning then
                -- this fcc is uninitialized (for ammo warnings)

                Log.logMsg(function(m)log(m)end, Log.FINE, "initializing fcc for ammo warning fcc=%s", fcc.unit_number)
                fop.ammo_warning = {
                    autoValues = true,
                    turret_types = {},
                    thresholds = {},
                }
            end

            --- @type AmmoWarning
            local awa = fop.ammo_warning
            local turret = mt.turret
            awa.turret_types[turret.name] = true
        end

        local atms = ammoTurretMapping.getAmmoTurretMapping()
        Log.logBlock(atms, function(m)log(m)end, Log.FINER)

        for _, fop in pairs(pons.fccsOnPlatform) do
            local awa = fop.ammo_warning
            -- now look for the needed ammos
            for tt, _ in pairs(awa.turret_types) do
                Log.logBlock(tt, function(m)log(m)end, Log.FINER)

                local atm = atms[tt]

                if atm then
                    Log.logBlock(atm, function(m)log(m)end, Log.FINER)
                    for _, ammo_cat in pairs(atm) do
                        Log.logBlock(ammo_cat, function(m)log(m)end, Log.FINER)
                        for _, ammo in pairs(ammo_cat) do
                            Log.logBlock(ammo, function(m)log(m)end, Log.FINER)
                            local threshold = awa.thresholds[ammo]
                            if not threshold then
                                -- yet unknown ammo type for this fcc
                                local first = table_size(awa.thresholds) == 0 -- check if it's the first one
                                Log.logMsg(function(m)log(m)end, Log.FINE, "setting initial values for ammo warning fcc=%s ammo=%s", fop.fcc.unit_number, ammo)
                                awa.thresholds[ammo] = {
                                    type = ammo,
                                    enabled = first, -- for the first new ammo warning is enabled
                                    threshold = settings.global["dart-low-ammo-warning-threshold-default"].value
                                }
                            end
                        end
                    end
                else
                    Log.logMsg(function(m)log(m)end, Log.WARN, "unmapped turret_type=%s", tt)
                end
            end
        end

        Log.logBlock(pons, function(m)log(m)end, Log.FINEST)
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- performs decision which asteroid should be targeted
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

        updateTurretTypes(pons, managedTurrets)

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

    end
    Log.log("leave BL", function(m)log(m)end, Log.FINER)
end
-- ###############################################################

local function updateAmmoInStock()
    for _, pons in pairs(global_data.getPlatforms()) do
        Hub.updateAmmoInStock(pons)
        local low = Hub.checkLowAmmoInStock(pons)
        local force = pons.platform.force
        local hub = pons.platform.hub

        local append = false
        local items

        for ammo_type, stock in pairs(low) do
            if append then
                items = items .. ", [img=item."..ammo_type.."]"
            else
                append = true
                items = "[img=item."..ammo_type.."]"
            end
        end

        -- if append == true then at least one item has low stock => send message if it's enabled
        if append and settings.global["dart-low-ammo-warning"].value then
            messaging.printmsg({ "dart-message.dart-low-ammo", items, platform2richText(pons) },
                                messaging.level.WARNING, pons.platform.force)
        end
    end
    script.raise_event(on_dart_ammo_in_stock_updated_event, {} )
end
-- ###############################################################

local function space_platform_changed_state(event)
    Log.logLine({ event = dump.dumpEvent(event), speed=event.platform.speed}, function(m)log(m)end, Log.FINER)
end
-- ###############################################################

--- @param event EventData
local function playerChangedSurface(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.FINER)
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
        Log.logMsg(function(m)log(m)end, Log.WARN, "asteroid_died - unknown pons for surface=%s", entity.surface.index)
    end
end

local function hub_died(entity)
    -- remove references to platform or objects on it
    local sid = entity.surface.index
    local pons = global_data.getPlatforms()[sid]
    if pons then
        Log.logMsg(function(m)log(m)end, Log.INFO, "removing all D.A.R.T. installations on platform=%s", pons.platform.name)
        global_data.getPlatforms()[sid] = nil
        -- remove references to platform in player_data
        local platform = pons.platform
        if platform.valid then
            for _, player in pairs(platform.force.players) do
                local pd = global_data.getPlayer_data(player.index)
                pd.pons[platform.index] = nil
            end
        else
            Log.logMsg(function(m)log(m)end, Log.WARN, "platform already invalid - surfaceid = %s", event.surface_index)
        end
    else
        Log.logMsg(function(m)log(m)end, Log.WARN, "hub_died - unknown pons for surface=%s", sid)
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
--- @param event EventData
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
                Log.log("raising on_dart_gui_close_event", function(m)log(m)end, Log.FINE)
                script.raise_event(on_dart_gui_close_event, event)
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
    Log.logMsg(function(m)log(m)end, Log.INFO, "detected new surface with platform - index=%s", surface.index)
    return { surface = surface, platform = surface.platform, turretsOnPlatform = {},
             fccsOnPlatform = {}, radarsOnPlatform = {}, knownAsteroids = {} }
end
-- ###############################################################

--- creates the administrative structure for a new platform and stores it in
--- global_data resp. PlayerData of the owner
--- @param surface LuaSurface
local function createPonsAndAddToGDAndPD(surface)
    local platform = surface.platform

    if platform then
        local sid = surface.index
        Log.logMsg(function(m)log(m)end, Log.INFO, "add new platform on surface index=%s", sid)

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

--- @param event EventData
--- @return boolean returns true if player has entered editor mode
local function isInEditormode(event)
    local pd = global_data.getPlayer_data(event.player_index)
    return pd and pd.editorMode
end
-- ###############################################################

--- event handler for on_surface_created
--- @param event EventData
local function surfaceCreated(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.FINE)
    local surface = game.surfaces[event.surface_index]

    createPonsAndAddToGDAndPD(surface)
end
-- ###############################################################

--- event handler for on_surface_cleared
--- @param event EventData
local function onSurfaceCleared(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.INFO)
    local surface = game.surfaces[event.surface_index]
    --
    --createPonsAndAddToGDAndPD(surface)
end
-- ###############################################################

--- event handler for on_surface_deleted
--- @param event EventData
local function onSurfaceDeleted(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.INFO)
    local surface = game.surfaces[event.surface_index]
    --
    --createPonsAndAddToGDAndPD(surface)
end
-- ###############################################################

--- event handler for on_surface_imported
--- @param event EventData
local function onSurfaceImported(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.INFO)
    local surface = game.surfaces[event.surface_index]
end
-- ###############################################################

--- event handler for on_built_entity
--- if triggered in editor mode for dart-fcc, dart-radar and ammo-turret entities add new entity to internal data
--- @param event EventData
local function onBuiltEntity(event)
    if isInEditormode(event) then
        Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.INFO)
        -- if type == ammo-turret, check if it is on a platform
        local entity = event.entity
        if entity.type == "ammo-turret" then
            local surface = entity.surface
            if not (surface and surface.platform) then
                return -- not on platform => do nothing
            end
        end

        entityCreated(event)
    end
end
-- ###############################################################

--- event handler for on_entity_cloned
--- @param event EventData
local function onEntityCloned(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.INFO)
    local surface = game.surfaces[event.surface_index]
end
-- ###############################################################

--- event handler for on_player_mined_entity
--- if triggered in editor mode for dart-fcc, dart-radar and ammo-turret entities remove entity from internal data
--- @param event EventData
local function onPlayerMinedEntity(event)
    if isInEditormode(event) then
        Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.INFO)
        -- if type == ammo-turret, check if it is on a platform
        local entity = event.entity
        if entity.type == "ammo-turret" then
            local surface = entity.surface
            if not (surface and surface.platform) then
                return -- not on platform => do nothing
            end
        end

        entityRemoved(event)
    end
end
-- ###############################################################

-- part of initialization
local function searchPlatforms()
    for _, surface in pairs(game.surfaces) do
        createPonsAndAddToGDAndPD(surface)
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

    script.on_event(defines.events.on_space_platform_built_entity, entityCreated,       filters_dart_components)
    script.on_event(defines.events.on_space_platform_mined_entity, entityRemoved,       filters_dart_components)
    script.on_event(defines.events.on_built_entity,                onBuiltEntity,       filters_dart_components)
    script.on_event(defines.events.on_player_mined_entity,         onPlayerMinedEntity, filters_dart_components)
    script.on_event(defines.events.on_entity_died,                 entity_died,         filters_entity_died)

    asyncFragments = asyncHandler.registerAsync(fragments)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function initLogging()
    Log.setSeverityFromSettings("dart-logLevel")
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- check whether formerly used ammo-types have been removed (i.e. the defining mod has been removed)
local function checkRemovedAmmoTypes()
    local allpons = global_data.getPlatforms()
    local items = prototypes.item
    local removed = {}
    local keys = {}
    for _, pons in pairs(allpons) do
        for _, fcc in pairs(pons.fccsOnPlatform) do
            local thresholds = fcc.ammo_warning and fcc.ammo_warning.thresholds or {}
            for ammo, _ in pairs(thresholds) do
                local p = items[ammo]
                if not p then
                    -- no more present - remove it
                    thresholds[ammo] = nil
                    if not removed[ammo] then
                        -- 1st cleanup
                        removed[ammo] = true
                        keys[#keys + 1] = ammo
                    end
                end
            end
        end
    end

    if table_size(keys) > 0 then
        Log.logMsg(function(m)log(m)end, Log.INFO, "cleaned ammo types after removal = %s", serpent.line(keys))
    end
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
    checkRemovedAmmoTypes()
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

--- @param event EventData
local function ammo_in_stock_updated(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.FINER)

    for _, player in pairs(game.players) do
        local pd = global_data.getPlayer_data(player.index)
        local opengui = pd and pd.gui and pd.gui.open
        if opengui and opengui.entity then
            script.raise_event(on_dart_gui_needs_update_event, { entity = opengui.entity, player_index = player.index } )
        end
    end
end
--###############################################################

-- build (in entity mode)
-- *1  {consumed_items = "[LuaInventory: temp]", entity = "[LuaEntity: solar-panel at [gps=2.5,5.5,platform-1]]", name = "on_built_entity", player_index = 1, tick = 1754}
--   or (in None mode)
--     {name = "on_player_main_inventory_changed", player_index = 1, tick = 1754}
--     {name = "on_player_cursor_stack_changed", player_index = 1, tick = 1754}
--     {build_mode = 0, created_by_moving = false, direction = 0, flip_horizontal = false, flip_vertical = false, mirror = false, name = "on_pre_build", player_index = 1, position = {x = 6, y = -4}, tick = 1754}
-- *1  {consumed_items = "[LuaInventory: temp]", entity = "[LuaEntity: gun-turret at [gps=6.0,-4.0,platform-1]]", name = "on_built_entity", player_index = 1, tick = 1754}
--     {name = "on_player_cursor_stack_changed", player_index = 1, tick = 1754}
--
-- ctrl-C (only in None mode)
--     {name = "on_player_cursor_stack_changed", player_index = 1, tick = 1754}
--     {alt = true, area = {left_top = {x = 3.5703125, y = 5.625}, right_bottom = {x = 3.5703125, y = 5.625}}, item = "blueprint", mapping = "[LuaLazyLoadedValue]", name = "on_player_setup_blueprint", player_index = 1, quality = "normal", stack = "[LuaItemStack: 1x {blueprint, normal}]", surface = "[LuaSurface: platform-1]", tick = 1754}
--     {name = "on_player_cursor_stack_changed", player_index = 1, tick = 1754}
--
-- paste (only in None mode)
--     {build_mode = 0, created_by_moving = false, direction = 0, flip_horizontal = false, flip_vertical = false, mirror = false, name = "on_pre_build", player_index = 1, position = {x = 5.5390625, y = -0.1875}, tick = 1754}
-- *1  {consumed_items = "[LuaInventory: temp]", entity = "[LuaEntity: solar-panel at [gps=5.5,-0.5,platform-1]]", name = "on_built_entity", player_index = 1, tick = 1754}
--
-- moving an entity (ctrl-X, ctrl-V)  (only in None mode)
--     {name = "on_player_cursor_stack_changed", player_index = 1, tick = 1754}
--     {alt = true, area = {left_top = {x = 3.3203125, y = 5.3125}, right_bottom = {x = 3.3203125, y = 5.3125}}, item = "blueprint", mapping = "[LuaLazyLoadedValue]", name = "on_player_setup_blueprint", player_index = 1, quality = "normal", stack = "[LuaItemStack: 1x {blueprint, normal}]", surface = "[LuaSurface: platform-1]", tick = 1754}
-- *2  {entity = "[LuaEntity: solar-panel at [gps=3.5,5.5,platform-1]]", name = "script_raised_destroy", tick = 1754}
--     {name = "on_player_cursor_stack_changed", player_index = 1, tick = 1754}
--     {build_mode = 0, created_by_moving = false, direction = 0, flip_horizontal = false, flip_vertical = false, mirror = false, name = "on_pre_build", player_index = 1, position = {x = 5.5859375, y = 0.109375}, tick = 1754}
-- *1  {consumed_items = "[LuaInventory: temp]", entity = "[LuaEntity: solar-panel at [gps=5.5,0.5,platform-1]]", name = "on_built_entity", player_index = 1, tick = 1754}
--     {name = "on_player_cursor_stack_changed", player_index = 1, tick = 1754}
--
-- undo (only in None mode)
-- *2  {entity = "[LuaEntity: solar-panel at [gps=5.5,-0.5,platform-1]]", name = "script_raised_destroy", tick = 1754}
-- *1  {actions = {{surface_index = 3, target = {entity_number = 0, name = "solar-panel", position = {x = 5.5, y = -0.5}}, type = "built-entity"}}, name = "on_undo_applied", player_index = 1, tick = 1754}
--
-- delete with right mouse key (in entity mode)
-- *2  {entity = "[LuaEntity: gun-turret at [gps=-6.0,-6.0,platform-1]]", name = "script_raised_destroy", tick = 1754}
--   or (in None mode)
--     {entity = "[LuaEntity: solar-panel at [gps=2.5,5.5,platform-1]]", name = "on_pre_player_mined_item", player_index = 1, tick = 1754}
-- *3  {buffer = "[LuaInventory: temp]", entity = "[LuaEntity: solar-panel at [gps=2.5,5.5,platform-1]]", name = "on_player_mined_entity", player_index = 1, tick = 1754}
--     {item_stack = {count = 1, name = "solar-panel", quality = "normal"}, name = "on_player_mined_item", player_index = 1, tick = 1754}
--     {name = "on_player_main_inventory_changed", player_index = 1, tick = 1754}
--
-- clearing a surface ("remove all enties") in editor mode triggers nothing!!!!!!!!!!!!!
--
-- import save
--     {name = "on_pre_surface_cleared", surface_index = 3, tick = 1754}
-- *4  {name = "on_surface_cleared", surface_index = 3, tick = 1754}
-- *5  {name = "on_surface_imported", original_name = "platform-1", surface_index = 3, tick = 1754}
--    but doesn't import hub!!!!!!!!!!!!!!
--    needs manually adding a hub!!!!!!!!!!!!!!!
-- *1  {consumed_items = "[LuaInventory: temp]", entity = "[LuaEntity: space-platform-hub at [gps=0.0,0.0,platform-1]]", name = "on_built_entity", player_index = 1, tick = 1754}
--
-- deleting and recreating a surface in editor mode - same surface_index !!!!!!!
--     {name = "on_pre_surface_deleted", surface_index = 3, tick = 1754}
--     {name = "on_player_changed_position", player_index = 1, tick = 1754}
-- *6  {name = "on_surface_deleted", surface_index = 3, tick = 1754}
--     {name = "on_player_changed_surface", player_index = 1, tick = 1754}
-- *7  {name = "on_surface_created", surface_index = 3, tick = 1754}
--
-- creating a surface in editor mode
-- *7  {name = "on_surface_created", surface_index = 4, tick = 1754}
--
-- creating a platform in editor mode
-- *7  {name = "on_surface_created", surface_index = 2, tick = 1754}
--     {name = "on_player_controller_changed", old_type = 4, player_index = 1, tick = 1754}
--     {area = {left_top = {x = -32, y = -32}, right_bottom = {x = 0, y = 0}}, name = "on_chunk_generated", position = {x = -1, y = -1}, surface = "[LuaSurface: platform-1]", tick = 1754}
--        ...
--     {area = {left_top = {x = 64, y = 64}, right_bottom = {x = 96, y = 96}}, name = "on_chunk_generated", position = {x = 2, y = 2}, surface = "[LuaSurface: platform-1]", tick = 1754}
--     {name = "on_space_platform_changed_state", old_state = 0, platform = "[LuaSpacePlatform: index=2]", tick = 1754}

-- cloning
--   object
-- *8  {destination = "[LuaEntity: gun-turret at [gps=-6.0,6.0,platform-1]]", name = "on_entity_cloned", source = "[LuaEntity: gun-turret at [gps=0.0,-6.0,platform-1]]", tick = 1754}
--   area
-- *8  {destination = "[LuaEntity: gun-turret at [gps=0.0,-6.0,platform-1]]", name = "on_entity_cloned", source = "[LuaEntity: gun-turret at [gps=6.0,-4.0,platform-1]]", tick = 1754}
--     {clear_destination_decoratives = false, clear_destination_entities = false, clone_decoratives = false, clone_entities = true, clone_tiles = false, destination_area = {left_top = {x = -2, y = -8}, right_bottom = {x = 1, y = -5}}, destination_surface = "[LuaSurface: platform-1]", name = "on_area_cloned", source_area = {left_top = {x = 4, y = -6}, right_bottom = {x = 7, y = -3}}, source_surface = "[LuaSurface: platform-1]", tick = 1754}
--   brush
-- *8  {destination = "[LuaEntity: gun-turret at [gps=-1.3,-6.3,platform-1]]", name = "on_entity_cloned", source = "[LuaEntity: gun-turret at [gps=-6.3,5.7,platform-1]]", tick = 1754}
--     {clear_destination_decoratives = false, clear_destination_entities = false, clone_decoratives = false, clone_entities = true, clone_tiles = false, destination_offset = {x = -1, y = -7}, destination_surface = "[LuaSurface: platform-1]", name = "on_brush_cloned", source_offset = {x = -6, y = 5}, source_positions = {{x = -6, y = 5}, {x = -6, y = 6}, {x = -5, y = 5}, {x = -5, y = 6}}, source_surface = "[LuaSurface: platform-1]", tick = 1754}
--==============================================================================

-- new events *
-- old events called in new context +
-- *1   * on_built_entity
-- *2   + script_raised_destroy
-- *3   * on_player_mined_entity
-- *4   * on_surface_cleared
-- *5   * on_surface_imported
-- *6   * on_surface_deleted
-- *7   + on_surface_created
-- *8   + on_entity_cloned
--==============================================================================

local function updateDartInfrastructureAfterEditorMode()
    --
    ---- first scan for deleted platforms
    --local knownPlatforms = global_data.getPlatforms()
    --for sid, pons in pairs(knownPlatforms) do
    --    if not pons.surface.valid then
    --        Log.logMsg(function(m)log(m)end, Log.INFO, "detected deleted platform %d", sid)
    --
    --    end
    --end
    --
    ---- scan for new platforms
    --for _, surface in pairs(game.surfaces) do
    --    if surface.platform then
    --        -- surface is platform
    --        local sid = surface.index
    --        local pons = global_data.getPlatforms()[sid]
    --        if not pons then
    --            -- not known before
    --            createPonsAndAddToGDAndPD(surface)
    --        end
    --    end
    --end
    --
    ------ iterate platforms on surfaces
    --for _, pons in pairs(global_data.getPlatforms()) do
    --    searchTurrets(pons)
    --end
    --
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
        Log.logMsg(function(m)log(m)end, Log.CONFIG, 'setting %s changed to %s', which, new)
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
-- ###############################################################

local function toggleMapEditor(event)
    Log.logLine(dump.dumpEvent(event), function(m)log(m)end, Log.INFO)
    local pd = global_data.getPlayer_data(event.player_index)
    if pd then
        local editorMode = pd.editorMode
        if editorMode then
            editorMode = false
            -- TODO (re)scan all platforms to look for changed DART components
            -- searchDartInfrastructure() resets all former data - not suitable
            updateDartInfrastructureAfterEditorMode()
        else
            editorMode = true
        end

        pd.editorMode = editorMode
        Log.logLine({ player_index = event.player_index , editorMode = editorMode }, function(m)log(m)end, Log.INFO)

    end

end
--###############################################################

local dart = {}
local dart_update_stock_period = settings.startup["dart-update-stock-period"].value * 60

-- mod initialization
dart.on_init = dart_initializer
dart.on_load = dart_load
dart.on_configuration_changed = dart_config_changed

-- events without filters
dart.events = {
-- vvv mostly/only used in editor mode
    [defines.events.on_entity_cloned]                = onEntityCloned,
    [defines.events.on_surface_deleted]              = onSurfaceDeleted,
    [defines.events.on_surface_cleared]              = onSurfaceCleared,
    [defines.events.on_surface_imported]             = onSurfaceImported,
-- ^^^ mostly/only used in editor mode

    [defines.events.script_raised_destroy]           = entityRemoved,
    [defines.events.on_surface_created]              = surfaceCreated,
    [defines.events.on_space_platform_changed_state] = space_platform_changed_state,
    [defines.events.on_player_created]               = player_joined_or_created,
    [defines.events.on_player_joined_game]           = player_joined_or_created,
    [defines.events.on_player_left_game]             = tbd,
    [defines.events.on_player_removed]               = tbd,
    [defines.events.on_player_changed_surface]       = playerChangedSurface,
    [defines.events.on_runtime_mod_setting_changed]  = changeSettings,
    [defines.events.on_player_toggled_map_editor]    = toggleMapEditor,

    [defines.events.on_tick] = asyncHandler.dequeue,

    -- defined in internalEvents.lua
    [on_target_assigned_event] = tbda,
    [on_target_unassigned_event] = tbdu,
    [on_target_destroyed_event] = tbdd,
    [on_asteroid_detected_event] = tbdad,
    [on_asteroid_lost_event] = tbdal,
    [on_dart_ammo_in_stock_updated_event] = ammo_in_stock_updated,
}

-- handling of business logic
dart.on_nth_tick = {
    [60] = businessLogic,
    [dart_update_stock_period] = updateAmmoInStock
}

return dart
