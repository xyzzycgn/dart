---
--- Created by xyzzycgn.
--- DateTime: 20.03.25 13:21
---
--- Utility functions for dumping several game objects in more detail

local dump = {}

local reverseTypes = {}

local function fillReverseTypes(types)
    local rtypes = {}
    for k,v in pairs(defines.events) do
        rtypes[v] = k
    end

    reverseTypes[types] = rtypes
end
-- ###############################################################

local function getTypeName(types, value)
    if value then
        if not reverseTypes[types] then
            fillReverseTypes(types)
        end

        return reverseTypes[types][value] or ("unknown-" .. types)
    end
    return nil
end
-- ###############################################################

--- @param surface LuaSurface
local function dumpPlatformOfSurface(surface)
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

--- @param surface LuaSurface
function dump.dumpSurface(surface)
    local ds = {}

    if surface then
        ds.name = surface.name
        ds.localised_name  = surface.localised_name
        ds.platform = dumpPlatformOfSurface(surface)
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

-- ###############################################################

function dump.dumpAsteroidPropertyPrototype(prototype)
    local dp = prototype and {
        name = prototype.name,
        object_name = prototype.object_name,
        type = prototype.type,
        order = prototype.order,
        hidden = prototype.hidden,
        localised_name = prototype.localised_name,
        group = dumpGroup(prototype.group),
    } or {}

    return dp
end
-- ###############################################################

--- @param entity LuaEntity
--- @param is_turret boolean
function dump.dumpEntity(entity, is_turret)
    if entity.valid then
        local de = {
            force = entity.force,
            force_index = entity.force_index,
            surface = entity.surface,
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
            get_radius = entity.get_radius(),
            unit_number = entity.unit_number,
        }

        if is_turret then
            de.shooting_target = entity.shooting_target
        end

        return de
    else
        return serpent.block(entity)
    end
end
-- ###############################################################

local function dumpCircuitNetwork(cn)
    local dcn = cn and {
        entity = cn.entity,
        network_id = cn.network_id,
        wire_type = cn.wire_type,
        signals = cn.signals,
        connected_circuit_count = cn.connected_circuit_count,
    } or {}

    return dcn
end

local function dumpCircuitNetworks(cb)
    local dcn = {}

    for cn in pairs {
        defines.wire_connector_id.circuit_red,
        defines.wire_connector_id.circuit_green,
        defines.wire_connector_id.combinator_input_red,
        defines.wire_connector_id.combinator_input_green,
        defines.wire_connector_id.combinator_output_red,
        defines.wire_connector_id.combinator_output_green,
    } do
        dcn[cn] = dumpCircuitNetwork(cb.get_circuit_network(cn))
    end

    return dcn
end
-- ###############################################################

local function turretOnly(cb, dcb)
    if cb and (cb.type == defines.control_behavior.type.turret) then
        dcb.circuit_condition = cb.circuit_condition
        dcb.disabled = cb.disabled
    end
end

function dump.dumpControlBehavior(cb)
    local dcb = cb and {
        circuit_networks = dumpCircuitNetworks(cb),
        type = cb.type,
    } or {}

    turretOnly(cb, dcb)

    return dcb
end
-- ###############################################################

--- @param lge LuaGuiElement
function dump.dumpLuaGuiElement(lge)
    local dlge = lge and {
        type = getTypeName("gui_type", lge.type),
        children_names = lge.children_names,
        enabled = lge.enabled,
        tags = lge.tags,
        caption = lge.caption,
        name = lge.name,
        index = lge.index,
        valid = lge.valid,
        visible = lge.visible,
    } or {}

    return dlge
end

local function tableCopy(obj)
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do
        res[tableCopy(k)] = tableCopy(v)
    end
    return res
end



--- @param event EventData
function dump.dumpEvent(event)
    local function f()
        local erg = tableCopy(event)
        erg.gui_type = getTypeName("gui_type", event.gui_type)
        erg.name = getTypeName("events", event.name)
        return erg
    end

    return event and f() or {}
end

return dump