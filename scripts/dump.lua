---
--- Created by xyzzycgn.
--- DateTime: 20.03.25 13:21
---
--- Utility functions for dumping several game objects in more detail

local dump = {}

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
-- ###############################################################

function dump.dumpSurface(surface)
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
-- ###############################################################

local function dumpGroupCommon(group)
    local dg = {
        name = group.name,
        type = group.type,
        object_name = group.object_name,
    }

    return dg
end

local function dumpGroup(group)
    local dg = dumpGroupCommon(group)

    dg.subgroups = group.subgroups

    return dg
end

function dump.dumpAsteroidPropertyPrototype(prototype)
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
-- ###############################################################

function dump.dumpEntity(entity, is_turret)
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
-- ###############################################################

function dump.dumpControlBehavior(cb)

    local cn = cb.get_circuit_network(defines.wire_connector_id.circuit_red)

    local dcb = {
        circuit_condition = cb.circuit_condition,
        circuit_network = cn,
        disabled = cb.disabled,
        type = cb.type,
    }

    return dcb
end


return dump