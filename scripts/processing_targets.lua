---
--- Created by xyzzycgn.
--- DateTime: 03.11.25 10:43
---

local utils = require("scripts.utils")
local Log = require("__log4factorio__.Log")

local dart_release_control = settings.startup["dart-release-control"].value

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

--- assign asteroid if hitting and not ignored by priority settings in turret
--- @param managedTurrets ManagedTurret[]
--- @param target LuaEntity asteroid which should be targeted
--- @param D float discriminant (@see targeting())
local function addToTargetList(managedTurrets, target, D)
    local tun = target.unit_number
    local target_prototype_name = target.prototype.name
    Log.logBlock(target_prototype_name, function(m)log(m)end, Log.FINER)
    for _, mt in pairs(managedTurrets) do
        Log.logBlock(tun, function(m)log(m)end, Log.FINER)
        local turret = mt.turret
        local targeted = false
        -- wanna have true or false - not nil!
        local on_priority_list_of_turret = mt.priority_targets_list[target_prototype_name] or false
        if D >= 0 and (not turret.ignore_unprioritised_targets or on_priority_list_of_turret) then
            -- target enters or touches protected area and is - if unprioritised targets should be ignored -
            -- in priority list of turret.
            local dist = utils.distFromTurret(target, turret)
            -- remember distance for each turret to target if in range
            if (mt.min_range <= dist) and (dist <= mt.range) then -- fix for #65 - check min_range too
                Log.logBlock(target, function(m)log(m)end, Log.FINER)
                mt.targets_of_turret[tun] = {
                    distance = dist,
                    is_priority_target = on_priority_list_of_turret
                }
                targeted = true
            end
        end
        if not targeted then
            -- no longer or not in range / not hitting / filtered by priority list
            Log.logBlock(target, function(m)log(m)end, Log.FINER)
            mt.targets_of_turret[tun] = nil
        end
    end
end
--###############################################################

--- @param managedTurret ManagedTurret
--- @param filter_settings any
--- @param assigned number? unit_number of asteroid to be assigned
--- @param knownAsteroids LuaEntity[]?
local function prepareCircuitCondition(managedTurret, filter_settings, assigned, knownAsteroids)
    local turret = managedTurret.turret
    -- unit number of dart-fcc managing this turret
    local un = managedTurret.fcc.unit_number
    -- filter_settings for this dart-fcc
    local filter_setting_by_un = filter_settings[un] or {}

    local newTarget = false
    local old = turret.shooting_target

    if assigned and knownAsteroids then
        local asteroid = knownAsteroids[assigned].entity
        Log.logBlock(asteroid, function(m)log(m)end, Log.FINER)
        if (not old or (old.unit_number ~= asteroid.unit_number)) then
            -- only assign if new target
            turret.shooting_target = asteroid
            newTarget = true
        end
    else
        -- control released by FCC
        turret.shooting_target = nil
        Log.logLine({assigned = assigned, knownAsteroids = knownAsteroids}, function(m)log(m)end, Log.FINE)
        script.raise_event(on_target_unassigned_event, { tun = turret.unit_number, reason="unassign", target = old and old.unit_number } )
    end

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
        if newTarget then
            script.raise_event(on_target_assigned_event,
                    { tun = turret.unit_number, target = assigned, reason=old and "reassign" or "assign", old = old and old.unit_number})
        end
    else
        Log.logMsg(function(m)log(m)end, Log.WARN, "ignored turret with invalid CircuitCondition=%s", turret.unit_number or "<NIL>")
    end
end
-- ###############################################################

--- @param managedTurret ManagedTurret
local function simpleSortByDistance(managedTurret, i, j)
    return managedTurret.targets_of_turret[i].distance < managedTurret.targets_of_turret[j].distance
end

--- @param managedTurret ManagedTurret
local function complexSortByPriorityListAndDistance(managedTurret, i, j)
    local mti = managedTurret.targets_of_turret[i]
    local mtj = managedTurret.targets_of_turret[j]

    -- true if mti has prio, but mtj not
    --      if both have same priority, use distance
    return (mti.is_priority_target and not mtj.is_priority_target) or
           (mti.is_priority_target == mtj.is_priority_target) and
           (mti.distance < mtj.distance)
end

local sort_funcs = {
    [true] = simpleSortByDistance,
    [false] = complexSortByPriorityListAndDistance,
}

--- calculate prio (based on distance to turrets) for an asteroid if within range (and harmful)
--- assign target to turrets depending on prio (nearest asteroid first)
--- @param pons Pons for which assignment of targets occurs
--- @param knownAsteroids LuaEntity[]
--- @param managedTurrets ManagedTurret[]
--- @return any resulting filter setting (for all darts of a platform)
local function assignTargets(pons, knownAsteroids, managedTurrets)
    Log.log("assignTargets", function(m)log(m)end, Log.FINER)
    local filter_settings = {}

    -- reorganize prio
    for _, managedTurret in pairs(managedTurrets) do
        local turret = managedTurret.turret

        local prios = {}
        -- create array with unit_numbers of targets
        for tun, _ in pairs(managedTurret.targets_of_turret) do
            prios[#prios + 1] = tun
        end

        -- at this point we have 3 possibilities
        -- - the turret has no priority_targets => sort by distance
        -- - the turret has priority_targets AND ignore_unprioritised_targets is set => sort by distance (list contains
        --   only targets matching the priority_targets list)
        -- - else sort with these 2 criteria
        --   1st target is in priority_targets list
        --   2nd distance
        local simple = (not turret.priority_targets or (table_size(turret.priority_targets) == 0))
                       or turret.ignore_unprioritised_targets

        -- sort it (is a bit tricky - sorting prios by content from managedTurret)
        table.sort(prios, function(i, j)
            return sort_funcs[simple](managedTurret, i, j)
        end)

        -- check whether control over turret has to be released
        local release_control = false
        if dart_release_control then
            local fop = pons.fccsOnPlatform[managedTurret.fcc.unit_number]
            local tc = fop.turretControl

            if tc then -- no turretControl means default behaviour
                if tc.mode == "left" then
                    -- no more control requested by setting
                    release_control = true
                elseif tc.mode == "none" then
                    -- automatic release of control requested
                    release_control = tc.threshold < #prios
                end
                Log.logLine({ prios = prios, rc = release_control }, function(m)log(m)end, release_control and Log.FINE or Log.FINER)
            end
        end

        -- and here occurs the miracle
        if release_control then
            -- no preset target
            prepareCircuitCondition(managedTurret, filter_settings)
        else
            -- default behaviour == turret under control of fcc
            if (#prios > 0) then
                -- enable turret using circuit network
                Log.logMsg(function(m)log(m)end, Log.FINER, "setting shooting_target=%s for turret=%s",
                        prios[1] or "<NIL>", turret.unit_number or "<NIL>")
               prepareCircuitCondition(managedTurret, filter_settings, prios[1], knownAsteroids)
             else
                -- set no filter => disable turret using circuit network
                if (turret.shooting_target) then -- only if there is an assigned target
                    local old = turret.shooting_target
                    turret.shooting_target = nil
                    script.raise_event(on_target_unassigned_event, { tun = turret.unit_number, reason="unassign", target = old.unit_number } )
                end
            end
        end
    end

    Log.logBlock(filter_settings, function(m)log(m)end, Log.FINER)

    -- now set the CircuitConditions from the filter_settings
    -- @wube why simple if it could be complicated - part 2 ;-)
    for ndx, fop in pairs(pons.fccsOnPlatform) do
        --- @type LuaLogisticSection
        local lls = fop.control_behavior.get_section(1)
        lls.filters = filter_settings[ndx] or {} -- if nothing is set => reset
        Log.logLine(lls.filters, function(m)log(m)end, Log.FINER)
    end
end
-- ###############################################################

local processing_targets = {
    targeting = targeting,
    addToTargetList = addToTargetList,
    assignTargets = assignTargets,
}

return processing_targets