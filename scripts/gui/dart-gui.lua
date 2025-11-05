---
--- Created by xyzzycgn.
--- DateTime: 04.03.25 21:27
---
--- Build the D.A.R.T Main UI window

local Log = require("__log4factorio__.Log")
local global_data = require("scripts.global_data")
local components = require("scripts.gui.components")
local eventHandler = require("scripts.gui.eventHandler")
local radars = require("scripts.gui.radars")
local turrets = require("scripts.gui.turrets")
local ammos = require("scripts.gui.ammos")

local flib_gui = require("__flib__.gui")
local flib_format = require("__flib__.format")

local dart_release_control = settings.startup["dart-release-control"].value

-- return TurretControl of a FccOnPlatform
--- @param fop FccOnPlatform
--- @return TurretControl
local function determineTurretControl(fop)
    -- if not set, assume "always" and use default threshold (although this isn't relevant with mode always)
    return fop.turretControl or  {
        mode = "right", -- == always
        threshold = settings.startup["dart-release-control-threshold-default"].value
    }
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param elems GuiAndElements
--- @param pons Pons
--- @param pd PlayerData
local function update_radars(elems, pons, pd)
    radars.update(elems, pons.radarsOnPlatform, pd)
end

--- @param elems GuiAndElements
--- @param pons Pons
--- @param pd PlayerData
local function update_turrets(elems, pons, pd)
    turrets.update(elems, pons, pd)
end

--- @param elems GuiAndElements
--- @param pons Pons
--- @param pd PlayerData
local function update_ammos(elems, pons, pd)
    ammos.update(elems, pons, pd)
end

local update_functions = {
    [1] = update_radars,
    [2] = update_turrets,
    [3] = update_ammos,
}

--- @param pd PlayerData
--- @param opengui GuiAndElements
--- @param event EventData
local function update_main(pd, opengui, event)
    ---  @type LuaEntity
    local entity = event.entity

    -- search the platform in the list of pons owned by player
    --- @type Pons
    local ponsOfEntity
    for _, pons in pairs(pd.pons) do
        if pons.surface == entity.surface then
            ponsOfEntity = pons
        end
    end

    -- show the numbers of known radars, turrets, ammo types
    if ponsOfEntity then
        if dart_release_control then
            -- release control is shown
            for un, fop in pairs(ponsOfEntity.fccsOnPlatform) do
                if un == entity.unit_number then
                    -- this is the FCC shown
                    local tc = determineTurretControl(fop)
                    fop.turretControl = tc
                    local mode = tc.mode
                    local switch = opengui.elems["dart-release-control"]
                    switch.switch_state = mode
                    local middle = opengui.elems["dart-release-control-middle"]
                    middle.style = components.getStyle(mode)
                    local threshold = opengui.elems["dart-release-control-threshold"]
                    threshold.text = tostring(tc.threshold)
                    threshold.enabled = mode == "none"
                end
            end
        end

        opengui.elems.radars_tab.badge_text = flib_format.number(table_size(ponsOfEntity.radarsOnPlatform))
        -- turrets may be controlled by other FCC => don't use simply ponsOfEntity.turretsOnPlatform
        opengui.elems.turrets_tab.badge_text = flib_format.number(table_size(turrets.dataForPresentation(opengui, ponsOfEntity)))
        -- need to know the stock in hub
        opengui.elems.ammos_tab.badge_text = flib_format.number(table_size(ammos.dataForPresentation(opengui, ponsOfEntity)))

        local func = update_functions[opengui.activeTab]
        if (func) then
            func(opengui, ponsOfEntity, pd)
        else
            Log.logMsg(function(m)log(m)end, Log.WARN, "no func for ndx=%s", opengui.activeTab)
        end
        -- prevent input fields from being overiden on next update
        opengui.fields_initialized = true
    else
        Log.logMsg(function(m)log(m)end, Log.WARN, "no valid pons for entity=%s", entity.unit_number)
    end
end
-- ###############################################################

local function update_gui(event)
    Log.logEvent(event, function(m)log(m)end, Log.FINER)

    local pd = global_data.getPlayer_data(event.player_index)
    if pd then
        -- the actual opened gui
        local opengui = pd.guis.open
        Log.logLine(opengui, function(m)log(m)end, Log.FINER)
        -- fix for #28
        -- ignore events raised when no (D.A.R.T.) gui is open
        if opengui and opengui.elems then
            Log.logBlock(opengui, function(m)log(m)end, Log.FINER)

            -- distinguish the different (sub-)guis
            if opengui.dart_gui_type == components.dart_guis.main_gui then
                update_main(pd, opengui, event)
            else
                -- currently only "dart_radar_gui"
                opengui.elems.radar_view.entity = opengui.entity
            end
        end
    end
end
-- ###############################################################

--
-- local handlers for flib
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param gae GuiAndElements
local function change_tab(gae, event)
    local tab = event.element
    gae.activeTab = tab.selected_tab_index
    gae.fields_initialized = false  -- force all fields to be initialized
    event.entity = gae.entity -- pimp the event ;-)
    script.raise_event(on_dart_gui_needs_update_event, event)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function getFop(gae, event)
    local pd = global_data.getPlayer_data(event.player_index)
    local entity = gae.entity
    local platform = entity.surface.platform

    if platform then
        local pons = pd.pons[platform.index]
        return pons.fccsOnPlatform[entity.unit_number]
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function updateModeOfFop(gae, event)
    local fop = getFop(gae, event)
    if fop then
        local state = gae.elems["dart-release-control"].switch_state
        fop.turretControl.mode = state
        gae.elems["dart-release-control-threshold"].enabled = state == "none"
        Log.logLine(fop.turretControl.mode, function(m)log(m)end, Log.FINE)
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param gae GuiAndElements
--- @param event EventData
local function threshold_changed(gae, event)
    Log.logEvent(event, function(m)log(m)end, Log.FINE)
    local fop = getFop(gae, event)
    if fop then
        fop.turretControl.threshold = tonumber(gae.elems["dart-release-control-threshold"].text) or 0
        Log.logLine(fop.turretControl.threshold, function(m)log(m)end, Log.FINE)
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- handles GUI update of the tristate switch in case switch was clicked
--- @param gae GuiAndElements
--- @param event EventData
local function switch_state_changed(gae, event)
    Log.logEvent(event, function(m)log(m)end, Log.FINE)
    -- it's impossible to chain event handlers, so this needs to be done manually
    components.tristate_switch_state_changed(gae, event)
    updateModeOfFop(gae,event)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- handles GUI update of the tristate switch in case middle label was clicked
--- @param gae GuiAndElements
--- @param event EventData
local function middle_clicked(gae, event)
    Log.logEvent(event, function(m)log(m)end, Log.FINE)
    -- it's impossible to chain event handlers, so this needs to be done manually
    components.middle_clicked(gae, event)
    updateModeOfFop(gae,event)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- local event handlers
local handlers = {
    change_tab = change_tab,
    threshold_changed = threshold_changed,
    switch_state_changed = switch_state_changed,
    middle_clicked = middle_clicked,
}

-- register local handlers in flib
flib_gui.add_handlers(handlers, function(e, handler)
    local guiAndElements = global_data.getPlayer_data(e.player_index).guis.open
    if guiAndElements then
        handler(guiAndElements, e)
    end
end)
-- ###############################################################

local function optionalReleaseControl()
    return {
        type = "flow",
        direction = "vertical",
        visible = dart_release_control,
        {
            type = "label",
            caption = { "gui.dart-release-control" },
            style = "squashable_label_with_left_padding",
        },
        {
            type = "flow",
            direction = "horizontal",
            -- horizontal filler
            {
                type = "flow",
                direction = "horizontal",
                style = "dart_centered_flow",
            },
            components.triStateSwitch("dart-release-control",
                                      handlers.switch_state_changed,
                                      handlers.middle_clicked),
            -- horizontal filler
            {
                type = "flow",
                direction = "horizontal",
                style = "dart_centered_flow",
            },
            -- threshold for release control
            {
                type = "textfield",
                numeric = true,
                style = "dart_controls_textfield",
                name = "dart-release-control-threshold",
                handler = { [defines.events.on_gui_text_changed] = handlers.threshold_changed, }
            },
        },
    }
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- creates the custom gui
--- @param player LuaPlayer who opens the entity
--- @param entity LuaEntity to be shown in the GUI
local function build(player, entity)
    local elems, gui = flib_gui.add(player.gui.screen, {
        {
            type = "frame",
            direction = "vertical",
            visible = false,
            handler = { [defines.events.on_gui_closed] = eventHandler.handlers.close_gui },
            -- outer frame higher if release control is enabled
            style = dart_release_control and "dart_top_frame_800" or "dart_top_frame",
            {
                type = "flow",
                direction = "horizontal",
                name = "titlebar",
                {
                    type = "label",
                    style = "frame_title",
                    caption = { "entity-name.dart-fcc" },
                    ignored_by_interaction = true,
                },
                { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
                {
                    type = "sprite-button",
                    name = "gui_close_button",
                    style = "close_button",
                    sprite = "utility/close",
                    hovered_sprite = "utility/close_black",
                    tooltip = { "gui.dart-close-button-tt" },
                    handler = { [defines.events.on_gui_click] = eventHandler.handlers.close_gui },
                },
            },
            { type = "frame", name = "content_frame", direction = "vertical", style = "dart_content_frame",
                {
                    type = "frame",
                    direction = "horizontal",
                    {
                        type = "frame",
                        style = "entity_button_frame",
                        {
                          type = "entity-preview",
                          style = "wide_entity_button",
                          position = entity.position,
                          name = "fcc_view",
                        },
                    },
                    optionalReleaseControl(),
                },
                {
                    type = "tabbed-pane",
                    style = "dart_tabbed_pane",
                    handler = { [defines.events.on_gui_selected_tab_changed] = handlers.change_tab },
                    radars.build(),
                    turrets.build(),
                    ammos.build(),
                },
            }
        }
    })

    Log.logBlock(elems["dart-release-control-middle"].tags, function(m)log(m)end, Log.FINEST)

    elems.titlebar.drag_target = gui

    return elems, gui
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function gui_opened(event)
    local entity = event.entity
    Log.logEvent(event, function(m)log(m)end, Log.FINER)
    if event.gui_type == defines.gui_type.entity and entity.type == "constant-combinator" and entity.name == "dart-fcc" then

        -- check whether there is an already open but hidden instance (see ticket #20)
        local guis = global_data.getPlayer_data(event.player_index).guis
        Log.logBlock(guis, function(m)log(m)end, Log.FINER)

        local hiddengui = false
        if guis and guis.open and guis.open.entity then
            -- same fcc already opened?
            hiddengui = guis.open.entity.unit_number == entity.unit_number
        end

        if hiddengui then
            Log.log("hidden gui already opened", function(m)log(m)end, Log.FINER)
            local player = game.get_player(event.player_index)
            player.opened = guis.open.gui
        else
            local player = game.get_player(event.player_index)
            local elems, gui = build(player, entity)
            Log.logLine(elems, function(m)log(m)end, Log.FINER)

            local pd = components.openNewGui(event.player_index, gui, elems, entity)
            elems.fcc_view.entity = entity
            local gae = pd.guis.open
            gae.activeTab = 1
            gae.dart_gui_type = components.dart_guis.main_gui
            gae.fields_initialized = false   -- force all fields to be initialized

            -- prepare sorting
            local allSortings = gae.sortings or {}
            allSortings[1] = allSortings[1] or radars.sortings()
            allSortings[2] = allSortings[2] or turrets.sortings()
            allSortings[3] = allSortings[3] or ammos.sortings()
            gae.sortings = allSortings
        end

        script.raise_event(on_dart_gui_needs_update_event, event)
    elseif event.gui_type == defines.gui_type.custom then
        local pd = global_data.getPlayer_data(event.player_index)
        entity = pd and pd.guis and pd.guis.open and pd.guis.open.entity
        Log.logBlock(entity, function(m)log(m)end, Log.FINER)
        if entity and entity.name == "dart-radar" then
            event.entity = entity -- pimp the event ;-)
            script.raise_event(on_dart_gui_needs_update_event, event)
        end
    end
end
-- ###############################################################

local function gui_closed(event)
    Log.logEvent(event, function(m)log(m)end, Log.FINEST)
    local pd = global_data.getPlayer_data(event.player_index)
    --- @type LuaEntity
    local entity = event.entity
    if entity then
        if (entity.type == 'ammo-turret') then
            local platform = entity.surface.platform

            if platform then
                Log.log("turret on platform", function(m)log(m)end, Log.FINER)
                local pons = pd.pons[platform.index]

                for _, top in pairs(pons.turretsOnPlatform) do
                    if top.turret == entity then
                        local gae = pd.guis.open
                        Log.log("closed turret on platform", function(m)log(m)end, Log.FINER)
                        if gae then -- chained?
                            eventHandler.close(gae, event) -- yes
                        end
                        break
                    end
                end
            end
        end
    end
end
-- ###############################################################

-- delegates the on_dart_gui_close event to the standard handler
local function handle_on_dart_gui_close(event)
    Log.logEvent(event, function(m)log(m)end, Log.FINER)
    eventHandler.close(event.gae, event)
end


-- GUI events
local dart_gui = {}

dart_gui.events = {
    [defines.events.on_gui_opened] = gui_opened,
    [defines.events.on_gui_closed] = gui_closed,

    -- defined in internalEvents.lua
    [on_dart_component_build_event] = update_gui,
    [on_dart_component_removed_event] = update_gui,
    [on_dart_gui_needs_update_event] = update_gui,

    [on_dart_gui_close_event] = handle_on_dart_gui_close
}

return dart_gui