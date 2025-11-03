---
--- Created by xyzzycgn.
--- DateTime: 03.11.25 10:43
---

local utils = require("scripts.utils")
local Log = require("__log4factorio__.Log")

local function distToTurret(target, turret)
    local dx = target.position.x - turret.position.x
    local dy = target.position.y - turret.position.y
    return math.sqrt(dx * dx + dy * dy)
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
--###############################################################

--- assign target to turrets depending on prio (nearest asteroid first)
--- @param pons Pons for which assignment of targets occurs
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

        -- and here occurs the miracle
        if (#prios > 0) then
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
            if utils.checkCircuitCondition(cc) then -- check if turret has a valid/useable CircuitCondition
                local filter = {
                    value = { type = cc.first_signal.type,
                              name = cc.first_signal.name,
                              quality = cc.first_signal.quality or 'normal',
                    },
                    min = 1,
                }
                filter_setting_by_un[#filter_setting_by_un + 1] = filter
                filter_settings[un] = filter_setting_by_un
                script.raise_event(on_target_assigned_event, { tun = turret.unit_number, target = prios[1], reason="assign"} )
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
    for ndx, fop in pairs(pons.fccsOnPlatform) do
        --- @type LuaLogisticSection
        local lls = fop.control_behavior.get_section(1)
        lls.filters = filter_settings[ndx] or {} -- if nothing is set => reset
    end
end
-- ###############################################################

local processing_targets = {
    targeting = targeting,
    calculatePrio = calculatePrio,
    assignTargets = assignTargets,
}

return processing_targets