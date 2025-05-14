---
--- Created by xyzzycgn.
--- DateTime: 04.03.25 21:27
---
--- Build the D.A.R.T Main UI window

local Log = require("__log4factorio__.Log")
local dump = require("scripts.dump")
local global_data = require("scripts.global_data")
local components = require("scripts.gui.components")
local eventHandler = require("scripts.gui.eventHandler")
local radars = require("scripts.gui.radars")
local turrets = require("scripts.gui.turrets")

local flib_gui = require("__flib__.gui")
local flib_format = require("__flib__.format")

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
    turrets.update(elems, pons.turretsOnPlatform, pd)
end

local switch = {
    [1] = update_radars,
    [2] = update_turrets,
}

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

    if ponsOfEntity then
        -- show the numbers of known radars and turrets
        opengui.elems.radars_tab.badge_text = flib_format.number(table_size(ponsOfEntity.radarsOnPlatform))
        opengui.elems.turrets_tab.badge_text = flib_format.number(table_size(ponsOfEntity.turretsOnPlatform))

        local func = switch[opengui.activeTab]
        if (func) then
            func(opengui, ponsOfEntity, pd)
        else
            Log.log("no func for ndx=" .. opengui.activeTab, function(m)log(m)end, Log.WARN)
        end
    else
        Log.log("no valid pons for entity=" .. entity.unit_number, function(m)log(m)end, Log.WARN)
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function update_gui(event)
    Log.logLine(event, function(m)log(m)end, Log.FINER)

    local pd = global_data.getPlayer_data(event.player_index)
    if pd then
        -- the actual opened gui
        local opengui = pd.guis.open
        if opengui then
            Log.logBlock(opengui, function(m)log(m)end, Log.FINE)

            -- distinguish the different (sub-)guis
            if opengui.dart_gui_type == components.dart_guis.main_gui then
                update_main(pd, opengui, event)
            else
                -- currently only "dart_radar_gui"
                Log.log("update dart-radar NYI", function(m)log(m)end, Log.FINE)
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
    event.entity = gae.entity -- pimp the event ;-)
    script.raise_event(on_dart_gui_needs_update, event)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- local event handlers
local handlers = {
    change_tab = change_tab,
}

-- register local handlers in flib
flib_gui.add_handlers(handlers, function(e, handler)
    local guiAndElements = global_data.getPlayer_data(e.player_index).guis.open
    if guiAndElements then
        handler(guiAndElements, e)
    end
end)
-- ###############################################################

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
            style = "dart_top_frame",
            {
                type = "flow",
                direction = "horizontal",
                name = "titlebar",
                {
                    type = "label",
                    style = "frame_title",
                    caption = { "mod-name.dart" },
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
                  style = "entity_button_frame",
                  {
                      type = "entity-preview",
                      style = "wide_entity_button",
                      position = entity.position,
                      name = "fcc_view",
                  },
              },
              {
                  type = "tabbed-pane",
                  style = "dart_tabbed_pane",
                  handler = { [defines.events.on_gui_selected_tab_changed] = handlers.change_tab },
                  radars.build(),
                  turrets.build(),
              },
            }
        }
    })

    elems.titlebar.drag_target = gui

    return elems, gui
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function gui_open(event)
    local entity = event.entity
    Log.logBlock(dump.dumpEvent(event), function(m)log(m)end, Log.FINE)
    if event.gui_type == defines.gui_type.entity and entity.type == "constant-combinator" and entity.name == "dart-fcc" then

        local player = game.get_player(event.player_index)
        local elems, gui = build(player, entity)

        local pd = components.openNewGui(event.player_index, gui, elems, entity)
        elems.fcc_view.entity = entity
        pd.guis.open.activeTab = 1
        pd.guis.open.dart_gui_type = components.dart_guis.main_gui

        -- prepare sorting
        local allSortings = pd.guis.open.sortings or {}
        allSortings[1] = allSortings[1] or radars.sortings()
        allSortings[2] = allSortings[2] or turrets.sortings()
        pd.guis.open.sortings = allSortings

        script.raise_event(on_dart_gui_needs_update, event)
    elseif event.gui_type == defines.gui_type.custom then
        local pd = global_data.getPlayer_data(event.player_index)
        local entity = pd.guis.open.entity
        Log.logBlock(entity, function(m)log(m)end, Log.FINE)
        if entity and entity.name == "dart-radar" then
            event.entity = entity -- pimp the event ;-)
            script.raise_event(on_dart_gui_needs_update, event)
        end
    end
end
-- ###############################################################

local function standard_gui_closed(event) -- TODO better name for function
    Log.logBlock(dump.dumpEvent(event), function(m)log(m)end, Log.FINE)
    local pd = global_data.getPlayer_data(event.player_index)
    --- @type LuaEntity
    local entity = event.entity
    if entity then
        if (entity.type == 'ammo-turret') then
            local platform = entity.surface.platform

            if platform then
                Log.log("turret on platform", function(m)log(m)end, Log.FINE)
                local pons = pd.pons[platform.index]

                for _, top in pairs(pons.turretsOnPlatform) do
                    if top.turret == entity then
                        local gae = pd.guis.open
                        Log.log("closed turret on platform", function(m)log(m)end, Log.FINE)
                        if gae then -- chained?
                            eventHandler.close(gae, event) -- yes -- TODO better solution than calling eventHandler.close
                        end
                        break
                    end
                end
            end
        elseif entity.name == "dart-fcc" then
            Log.log("close fcc", function(m)log(m)end, Log.FINE)
            local gae = pd.guis.open
            local fcc_gui = gae and gae.gui
            if (fcc_gui.valid) then
                Log.log("omit close(gae, event))", function(m)log(m)end, Log.FINE)
                --close(gae, event)
            end
        end
    end
end
-- ###############################################################

-- GUI events - TODO TBC
local dart_gui = {}

dart_gui.events = {
    [defines.events.on_gui_opened] = gui_open,
    [defines.events.on_gui_closed] = standard_gui_closed,

    -- defined in internalEvents.lua
    [on_dart_component_build_event] = update_gui,
    [on_dart_component_removed_event] = update_gui,
    [on_dart_gui_needs_update] = update_gui,
}

return dart_gui