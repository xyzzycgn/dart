---
--- Created by xyzzycgn.
--- DateTime: 26.02.25 09:58
---

local Log = require("__log4factorio__.Log")
Log.setFromSettings("dart-logLevel")

local dart_gui = require("scripts.dart-gui")
local dart_bl = require("scripts.dart")
local dump = require("scripts.dump")

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function dumpSurfaces(table, sev)
    Log.log("surfaces", function(m)log(m)end, sev)

    for k, v in pairs(table) do
        Log.log(k .. " -> " .. serpent.block(dump.dumpSurface(v)), function(m)log(m)end, sev)
    end
end

local function dumpPrototypes(sev)
    Log.log("###### prototypes.surface_property", function(m)log(m)end, sev)

    for k, v in pairs(prototypes.asteroid_chunk) do
        Log.log(k .. " -> " .. serpent.block(dump.dumpAsteroidPropertyPrototype(v)), function(m)log(m)end, sev)
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function OnEntityCreated(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)

    local entity = event.entity or event.destination
    if not entity or not entity.valid then return end

    if entity.name == "dart-radar" then
       local output = entity.surface.create_entity {
            name = "dart-output",
            position = entity.position,
            force = entity.force
        }

        Log.logBlock(output, function(m)log(m)end, Log.FINE)

        local un = entity.unit_number
        local dart = {
            radar = un,
            output = output
        }

        storage.dart[un] = dart
    end
end

local function OnEntityRemoved(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)

    local entity = event.entity
    local un = entity.unit_number

    local dart = storage.dart[un]
    local output = dart and dart.output
    if (output) then
        output.destroy()
    end
end

local function initDart()
    if not storage.dart then
        storage.dart = {}
    end
end

-- register events
local function registerEvents()
    local filters_on_built = { { filter = 'type', type = 'radar' } }
    local filters_on_mined = { { filter = 'type', type = 'radar' } }

    -- always track built/removed train stops for duplicate name list
    script.on_event(defines.events.on_built_entity, OnEntityCreated, filters_on_built)
    script.on_event(defines.events.on_robot_built_entity, OnEntityCreated, filters_on_built)
    script.on_event({ defines.events.script_raised_built, defines.events.script_raised_revive, defines.events.on_entity_cloned }, OnEntityCreated)

    script.on_event(defines.events.on_pre_player_mined_item, OnEntityRemoved, filters_on_mined)
    script.on_event(defines.events.on_robot_pre_mined, OnEntityRemoved, filters_on_mined)
    --script.on_event(defines.events.on_entity_died, function(event) OnEntityRemoved(event, true) end, filters_on_mined) -- TODO
    script.on_event(defines.events.script_raised_destroy, OnEntityRemoved)

    -- TODO ??
    --script.on_event({ defines.events.on_pre_surface_deleted, defines.events.on_pre_surface_cleared }, OnSurfaceRemoved)
    --script.on_event(defines.events.on_runtime_mod_setting_changed, LtnSettings.on_config_changed)
end

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- complete initialization of fast-nav for new map/save-file
local function dart_initializer()
    Log.setSeverity(Log.FINE)
    Log.log('D.A.R.T on_init', function(m)log(m)end)

    --LuaGameScript
    --        -> planets
    --        -> surfaces

    dumpSurfaces(game.surfaces, Log.FINER)
    dumpPrototypes(Log.FINER)
    initDart()
    registerEvents()
end

script.on_init(dart_initializer)
--###############################################################

-- initialization of dart for save-file which already contained this mod
local function dart_load()
    Log.log('D.A.R.T_load', function(m)log(m)end)

    registerEvents()
end

script.on_load(dart_load)
--###############################################################

local function dart_config_changed()
    Log.log('D.A.R.T config_changed', function(m)log(m)end)
    dumpSurfaces(game.surfaces, Log.FINER)
    dumpPrototypes(Log.FINER)

    initDart()
    registerEvents()
end

-- init fast-nav on every mod update or change
script.on_configuration_changed(dart_config_changed)
--###############################################################

script.on_nth_tick(60, dart_bl.doit)

script.on_event(defines.events.on_mod_item_opened, function(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
end)

script.on_event(defines.events.on_gui_opened, function(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
    Log.logBlock(defines.gui_type, function(m)log(m)end, Log.FINEST)

    local entity = event.entity
    if event.gui_type == defines.gui_type.entity and entity.type == "constant-combinator" and entity.name == "dart-output" then
        local player = game.get_player(event.player_index)
        Log.logBlock(player, function(m)log(m)end, Log.FINE)
        --local custom_frame = player.gui.screen.add{type="frame", caption="Custom Inserter Interface"}
        local elems, gui = dart_gui.build(player)
        Log.logBlock(gui, function(m)log(m)end, Log.FINE)
        Log.logBlock(elems, function(m)log(m)end, Log.FINE)
        player.opened = gui

        elems.titlebar.drag_target = gui
        gui.force_auto_center()
        gui.bring_to_front()
        gui.visible = true
    end
end)


