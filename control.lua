---
--- Created by xyzzycgn.
--- DateTime: 26.02.25 09:58
---

local Log = require("__log4factorio__.Log")
Log.setFromSettings("dart-logLevel")

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function dumpPlatform(surface)
    local platform = surface.platform

    if platform then
        local dp = {}

        dp.name = platform.name
        dp.force = platform.force
        dp.state = platform.state
        dp.speed = platform.speed
        dp.space_location = platform.space_location
        dp.last_visited_space_location = platform.last_visited_space_location

        return dp
    end

    return nil
end

local function dumpSurface(surface)
    local ds = {}

    if surface then
        ds.name = surface.name
        ds.localised_name  = surface.localised_name
        ds.platform = dumpPlatform(surface)
        ds.planet = surface.planet
        --ds.map_gen_settings = surface.map_gen_settings
        ds.wind_speed = surface.wind_speed
        ds.wind_orientation = surface.wind_orientation
        ds.wind_orientation_change = surface.wind_orientation_change
        ds.has_global_electric_network = surface.has_global_electric_network
    end

    return ds
end

local function dumpSurfaces(table, sev)
    Log.log("surfaces", function(m)log(m)end, sev)
 
    for k, v in pairs(table) do
        Log.log(k .. " -> " .. serpent.block(dumpSurface(v)), function(m)log(m)end, sev)
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function dumpGroupCommon(group)
    local dg = {
        name = group.name,
        type = group.type,
        object_name = group.object_name,
    }

    return dg
end

local function dumpSubgroups(groups, func)
    local sub
    for k, sg in pairs(groups) do
        if not sub then
            sub = {}
        end
        sub[k] = dumpGroupCommon(sg)
    end

    return sub
end

local function dumpGroup(group)
    local dg = dumpGroupCommon(group)

    --dg.subgroups = dumpSubgroups(group.subgroups)
    dg.subgroups = group.subgroups

    return dg
end

local function dumpAsteroidPropertyPrototype(prototype)
    local dp = {
        name = prototype.name,
        object_name = prototype.object_name,
        type = prototype.type,
        order = prototype.order,
        hidden = prototype.hidden,
        localised_name = prototype.localised_name,
        group = dumpGroup(prototype.group),
    }

    return dp
end


local function dumpPrototypes(sev)
    Log.log("###### prototypes.surface_property", function(m)log(m)end, sev)

    for k, v in pairs(prototypes.asteroid_chunk) do
        Log.log(k .. " -> " .. serpent.block(dumpAsteroidPropertyPrototype(v)), function(m)log(m)end, sev)
    end
end

local function dumpEntity(entity, is_turret)
    local de = {
        force = entity.force,
        force_index = entity.force_index,
        status = entity.status,
        name = entity.name,
        type = entity.type,
        position = entity.position,
        prototype = entity.prototype,
        gps_tag = entity.gps_tag,
        destructible = entity.destructible,
        direction = entity.direction,
        speed = entity.speed,
        is_military_target = entity.is_military_target,
        --shooting_state = entity.shooting_state,
        get_radius = entity.get_radius(),
        unit_number = entity.unit_number,
    }

    if is_turret then
        de.shooting_target = entity.shooting_target
    end

    return de
end

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- complete initialization of fast-nav for new map/save-file
local function dart_initializer()
    Log.setSeverity(Log.FINE)
    Log.log('D.A.R.T on_init', function(m)log(m)end)

    --LuaGameScript
    --        -> planets
    --        -> surfaces

    dumpSurfaces(game.surfaces, Log.FINE)
    dumpPrototypes(Log.FINER)
end

script.on_init(dart_initializer)
--###############################################################

-- initialization of fast-nav for save-file which already contained this mod
local function dart_load()
    Log.log('D.A.R.T_load', function(m)log(m)end)

end

script.on_load(dart_load)
--###############################################################

local function dart_config_changed()
    Log.log('D.A.R.T config_changed', function(m)log(m)end)
    dumpSurfaces(game.surfaces, Log.FINE)
    dumpPrototypes(Log.FINE)
end

-- init fast-nav on every mod update or change
script.on_configuration_changed(dart_config_changed)
--###############################################################

--- A = dx² + dy²
--- B = 2 ((x0 - xc) dx + (y0 - yc) * dy)
--- C = (x0 - xc)² + (y0 - yc)² - r²
--
--5. Diskriminantenberechnung:
--D = B² - 4 A C
--- Wenn D < 0: Die Halbgerade schneidet den Kreis nicht.
--- Wenn D = 0: Die Halbgerade berührt den Kreis (ein Schnittpunkt).
--- Wenn D > 0: Die Halbgerade schneidet den Kreis an zwei Punkten.
---
--- xc = yc = 0
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

--###############################################################

script.on_event(defines.events.on_surface_created, function(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
end)

script.on_event(defines.events.on_surface_deleted, function(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
end)

script.on_event(defines.events.on_surface_renamed, function(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
end)

local show_turrets = true -- TODO später löschen

local targets = {}

local turrets = {}


script.on_nth_tick(60, function(event)
    local surface = game.get_surface("platform-2")
    Log.logBlock(surface, function(m)log(m)end, Log.FINER)

    local square = 35
    local area = {{ -square, -square }, { square, square }}

    local platform = surface and surface.platform

    if platform then
        if show_turrets then
            local turrets = surface.find_entities_filtered( { is_military_target = true })
            for _, turret in pairs(turrets) do
                Log.logBlock(dumpEntity(turret), function(m)log(m)end, Log.FINE)
                turrets[#turrets] = turret
            end

            show_turrets = false
        end

        Log.log(platform.speed, function(m)log(m)end, Log.FINE)
        local entities = surface.find_entities_filtered({ position = {0, 0}, radius = square, type ={ "asteroid" } })
        Log.log(#entities, function(m)log(m)end, Log.FINER)
        for _, entity in pairs(entities) do
            if entity.force.name ~= "player" then
                Log.logBlock(dumpEntity(entity), function(m)log(m)end, Log.FINE)

                local unit_number = entity.unit_number
                if (targets[unit_number]) then
                    -- well known asteroid
                    local target = targets[unit_number]

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

                    rendering.draw_circle({
                        target = target.position,
                        color = color,
                        time_to_live = 55,
                        surface = surface,
                        radius = 0.8,
                    })
                else
                    -- new asteroid
                    local target = {
                        position = entity.position,
                        movement = {},
                        size = string.sub(entity.name, string.find(entity.name, "%a*"))
                    }
                    targets[unit_number] = target
                end

            end
        end
    else
        Log.log("no surface / platform", function(m)log(m)end, Log.WARN)
    end

end)


script.on_event(defines.events.on_space_platform_changed_state, function(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
    Log.logBlock(event.platform.speed, function(m)log(m)end, Log.FINE)
end)

script.on_event(defines.events.on_entity_died, function(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
    Log.logBlock(dumpEntity(event.entity), function(m)log(m)end, Log.FINE)
end
, {{ filter = "type", type = "asteroid" }}
)

)
