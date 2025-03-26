---
--- Created by xyzzycgn.
--- DateTime: 20.03.25 12:49
---
--- D.A.R.T.s business logic
local Log = require("__log4factorio__.Log")
local dump = require("scripts.dump")
local global_data = require("scripts.global_data")

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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
-- TODO rewrite for use by a certain dart-radar
local function reorganizePrio(knownAsteroids, managedTurrets)
    -- reorganize prio
    for _, v in pairs(managedTurrets) do
        local turret = v.turret

        local prios = {}
        -- create array with unit_numbers of targets
        for tun, _ in pairs(v.targetsOfTurret) do
            prios[#prios + 1] = tun
        end

        -- sort it by distance (ascending)
        table.sort(prios, function(i, j)
            return v.targetsOfTurret[i] < v.targetsOfTurret[j]
        end)

        -- save new priorities
        v.prios = prios

        -- and here occurs the miracle
        if (#prios > 0) then
            Log.log("setting shooting_target=" .. (prios[1] or "<NIL>") ..
                    " for turret=" .. (turret.unit_number or "<NIL>"), function(m)log(m)end, Log.FINE)
            local entity = knownAsteroids[prios[1]].entity
            Log.logBlock(entity, function(m)log(m)end, Log.FINE)
            turret.shooting_target = entity
        else
            Log.log("try to disable turret=" .. (turret.unit_number or "<NIL>"), function(m)log(m)end, Log.FINE)
            -- TODO disable turret using circuit network
        end
    end

    Log.logBlock(managedTurrets, function(m)log(m)end, Log.FINE)
end
-- ###############################################################

--- calculate prio (based on distance) and (un)assign targets to turrets within range
local function assign(knownAsteroids, managedTurrets, target, D)
    if D >= 0 then
        -- target enters or touches protected area
        Log.logBlock(target.unit_number, function(m)log(m)end, Log.FINER)

        for _, v in pairs(managedTurrets) do
            local turret = v.turret
            local dist = distToTurret(target, turret)
            -- remember distance for each target in range of this turret
            if dist <= 18 then -- TODO quality
                Log.logBlock(target, function(m)log(m)end, Log.FINE)
                -- in range
                v.targetsOfTurret[target.unit_number] = dist
            else
                -- (no longer) in range
                Log.logBlock(target, function(m)log(m)end, Log.FINE)
                v.targetsOfTurret[target.unit_number] = nil
            end
        end

        reorganizePrio(knownAsteroids, managedTurrets)
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function getManagedTurrets(pons)
    return pons.turretsOnPlatform -- TODO not all of platform (assignment vi gui/circuit network)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- perforn decision which asteroid should be targeted
local function businessLogic()
    Log.log("enter BL", function(m)log(m)end, Log.FINER)
    Log.logBlock(global_data.getPlatforms, function(m)log(m)end, Log.FINEST)

    for index, pons in pairs(global_data.getPlatforms()) do
        Log.log(index, function(m)log(m)end, Log.FINEST)

        local surface = pons.surface
        local platform = pons.platform
        local managedTurrets = getManagedTurrets(pons)
        local knownAsteroids = pons.knownAsteroids

        local square = 35
        Log.log(platform.speed, function(m)log(m)end, Log.FINEST)
        local entities = surface.find_entities_filtered({ position = {0, 0}, radius = square, type ={ "asteroid" } })
        Log.log(#entities, function(m)log(m)end, Log.FINEST)

        for _, entity in pairs(entities) do
            if entity.force.name ~= "player" then
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

                    assign(knownAsteroids, managedTurrets, entity, D)
                else
                    -- new asteroid
                    Log.logBlock(dump.dumpEntity(entity), function(m)log(m)end, Log.FINEST)
                    local target = {
                        position = entity.position,
                        movement = {},
                        size = string.sub(entity.name, string.find(entity.name, "%a*")),
                        entity = entity,
                    }
                    knownAsteroids[unit_number] = target
                end

            end
        end
    end
    Log.log("leave BL", function(m)log(m)end, Log.FINER)
end
-- ###############################################################

local function space_platform_changed_state(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
    Log.logBlock(event.platform.speed, function(m)log(m)end, Log.FINER)
end
-- ###############################################################

--- called if an asteroid is destroyed
local function entity_died(event)
    local entity = event.entity
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
    Log.logBlock(dump.dumpEntity(entity), function(m)log(m)end, Log.FINER)

    local pons = global_data.getPlatforms()[entity.surface.index]
    local managedTurrets = getManagedTurrets(pons)
    local knownAsteroids = pons.knownAsteroids
    
    -- delete it from list of known targets (asteroids)
    knownAsteroids[entity.unit_number] = nil

    -- delete it from target list
    for _, v in pairs(managedTurrets) do
        v.targetsOfTurret[entity.unit_number] = nil
    end

    reorganizePrio(knownAsteroids, managedTurrets)
end
-- ###############################################################

--- new dart-radar created?
local function entityCreated(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)

    local entity = event.entity or event.destination
    if not entity or not entity.valid then return end

    if entity.name == "dart-radar" then
        -- yes - create also corresponding dart-output
        local output = entity.surface.create_entity {
            name = "dart-output",
            position = entity.position,
            force = entity.force,
            player = event.player_index
        }

        Log.logBlock(output, function(m)log(m)end, Log.FINE)

        local run = entity.unit_number
        local oun = output.unit_number
        -- the tuple of dart-radar and dart-output
        local dart = {
            radar_un = run,
            output_un = oun,
            output = output,
            control_behavior = output.get_or_create_control_behavior(),
        }
        -- save it in platform (twice, for dart-output too)
        local gdp = global_data.getPlatforms()[entity.surface.index].dartsOnPlatform
        gdp[run] = dart
        gdp[oun] = dart
    end
end
-- ###############################################################

local function entityRemoved(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)

    -- removed dart-radar
    local entity = event.entity
    local darts = global_data.getPlatforms()[entity.surface.index].dartsOnPlatform
    local run = entity.unit_number
    Log.logBlock(darts, function(m)log(m)end, Log.FINE)
    Log.logBlock(run, function(m)log(m)end, Log.FINE)

    local dart = darts[run]
    local oun = dart.output_un
    local output = dart and dart.output
    Log.logBlock(dart, function(m)log(m)end, Log.FINE)
    Log.logBlock(output, function(m)log(m)end, Log.FINE)
    if (output and output.valid) then
        -- if necessary destroy corresponding dart-output
        output.destroy()
    end
    -- clear both the data belonging to the dart-radar and dart-output
    darts[run] = nil
    darts[oun] = nil
end
-- ###############################################################

--- creates the administrative structure for a new platform.
--- @class Pons: any administrative structure for a platform
--- @field surface LuaSurface surface containing the platform
--- @field platform LuaSpacePlatform
--- @field turretsOnPlatform any array of turrets located on the platform
--- @field dartsOnPlatform any array of D.A.R.T. entities located on the platform
--- @field knownAsteroids any array of asteroids currently known and in detection range 
--- @param surface LuaSurface holding the new platform
--- @return Pons
local function newSurface(surface)
    return { surface = surface, platform = surface.platform, turretsOnPlatform = {}, dartsOnPlatform = {}, knownAsteroids = {} }
end
-- ###############################################################

local function surfaceCreated(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
    local surface = game.surfaces[event.surface_index]

    if (surface.platform) then
        Log.log("add new platform " .. event.surface_index, function(m)log(m)end, Log.FINE)

        global_data.getPlatforms()[event.surface_index] = newSurface(surface)
    end
end
-- ###############################################################

local function surfaceDeleted(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
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

local function searchTurrets(pons)
    Log.logBlock(pons, function(m)log(m)end, Log.FINE)

    local turretsOnPlatform = pons.turretsOnPlatform

    for _, turret in pairs(pons.surface.find_entities_filtered({ type = "ammo-turret" })) do
        Log.logBlock(turret, function(m)log(m)end, Log.FINE)
        turretsOnPlatform[turret.unit_number] = {
            turret = turret,
            targetsOfTurret = {},
            controlBehavior = turret.get_or_create_control_behavior(),
        }
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- searches D.A.R.T. components on existing platforms
--- as this is called from on_init, there can't be any dart-radar enties
--- that's why we only look for turrets on platforms
local function searchDartInfrastructure()
    Log.log("searchDartInfrastructure", function(m)log(m)end, Log.FINE)

    searchPlatforms()

    -- iterate platforms on surfaces
    for _, pons in pairs(global_data.getPlatforms()) do
        searchTurrets(pons)
    end

     Log.logBlock(global_data.getPlatforms, function(m)log(m)end, Log.FINE)
end
--###############################################################

--
-- Mod initialization
--
--- register complexer events with additional filters
local function registerEvents()
    local filters_on_built = { { filter = 'type', type = 'radar' } }
    local filters_on_mined = { { filter = 'type', type = 'radar' } }

    script.on_event(defines.events.on_space_platform_built_entity, entityCreated, filters_on_built)
    script.on_event(defines.events.on_space_platform_mined_entity, entityRemoved, filters_on_mined)
    ---- vvv TODO still needed later?
    --script.on_event(defines.events.on_built_entity, entityCreated, filters_on_built)
    --script.on_event(defines.events.on_robot_built_entity, entityCreated, filters_on_built)
    --script.on_event(defines.events.on_pre_player_mined_item, entityRemoved, filters_on_mined)
    --script.on_event(defines.events.on_robot_pre_mined, entityRemoved, filters_on_mined)
    ---- ^^^ TODO still needed later?

    script.on_event(defines.events.on_entity_died, entity_died, {{ filter = "type", type = "asteroid" }})

    -- TODO ??
    --script.on_event({ defines.events.on_pre_surface_deleted, defines.events.on_pre_surface_cleared }, OnSurfaceRemoved)
    --script.on_event(defines.events.on_runtime_mod_setting_changed, LtnSettings.on_config_changed)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function initLogging()
    --Log.setFromSettings("dart-logLevel")       -- TODO enable
    Log.setSeverity(Log.FINE)                    -- TODO delete
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
    searchDartInfrastructure() -- TODO delete - only for test
end
--###############################################################

local function tbd(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
end
--###############################################################

local dart = {}

-- mod initialization
dart.on_init = dart_initializer
dart.on_load = dart_load
dart.on_configuration_changed = dart_config_changed

-- event without filters
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
}

-- handling of business logic
dart.on_nth_tick = {
    [60] = businessLogic,
}

return dart
