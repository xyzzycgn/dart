---
--- Created by xyzzycgn.
--- DateTime: 04.03.25 21:27
---
--- Build the D.A.R.T Main UI window

local Log = require("__log4factorio__.Log")
local global_data = require("scripts.global_data")
local PlayerData = require("scripts.player_data")
local radars = require("scripts.gui.radars")
local turrets = require("scripts.gui.turrets")

local flib_gui = require("__flib__.gui")
local flib_format = require("__flib__.format")

--- @param elems GuiAndElements
--- @param pons Pons
local function update_radars(elems, pons)
    radars.update(elems, pons.radarsOnPlatform)
end

--- @param elems GuiAndElements
--- @param pons Pons
local function update_turrets(elems, pons)
    turrets.update(elems, pons.turretsOnPlatform)
end

local switch = {
    [1] = update_radars,
    [2] = update_turrets,
}

local function update_gui(event)
    Log.logLine(event, function(m)log(m)end, Log.FINE)

    local pd = global_data.getPlayer_data(event.player_index)
    if pd then
        -- the actual opened gui
        local opengui = pd.guis.open
        if opengui then
            -- TODO later distinguish the different (sub-)guis

            ---  @type LuaEntity
            local entity = event.entity

            -- search the platform
            --- @type Pons
            local ponsOfEntity
            for _, pons in pairs(pd.pons) do
                if pons.surface == entity.surface then
                    ponsOfEntity = pons
                end
            end

            if ponsOfEntity then
                Log.logBlock(opengui.elems, function(m)log(m)end, Log.FINE)
                opengui.elems.radars_tab.badge_text = flib_format.number(table_size(ponsOfEntity.radarsOnPlatform))
                opengui.elems.turrets_tab.badge_text = flib_format.number(table_size(ponsOfEntity.turretsOnPlatform))

                local func = switch[opengui.activeTab]
                if (func) then
                    func(opengui, ponsOfEntity)
                else
                    Log.log("no func for ndx=" .. opengui.activeTab, function(m)log(m)end, Log.WARN)
                end
            else
                -- TODO better logging
                Log.log("no valid pons for entity=" .. entity.unit_number, function(m)log(m)end, Log.WARN)
            end
        end
    end
end
-- ###############################################################

--
-- local handlers for flib
---
local function close(gui, event)
    Log.logBlock(event, function(m)log(m)end, Log.FINER)
    local pd = global_data.getPlayer_data(event.player_index)

    pd.guis.recentlyopen = pd.guis.recentlyopen or {}
    local ropen= pd.guis.recentlyopen[#pd.guis.recentlyopen]

    -- close actual gui and destroy it
    gui.visible = false
    gui.destroy()

    -- former gui present?
    if ropen then
        -- remove closed gui from list
        pd.guis.recentlyopen[#pd.guis.recentlyopen] = nil
        -- make former gui visible again
        ropen.gui.visible = true
    end
    pd.guis.open = ropen
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function change_tab(gui, event)
    local tab = event.element
    Log.logBlock( { event, tab.selected_tab_index }, function(m)log(m)end, Log.FINE)
    local pd = global_data.getPlayer_data(event.player_index)
    if pd then
        pd.guis.open.activeTab = tab.selected_tab_index
        event.entity = pd.guis.open.entity -- pimp the event ;-)
        update_gui(event)
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local handlers = {
    close_gui = close,
    change_tab = change_tab,
}

-- register local handlers in flib
flib_gui.add_handlers(handlers, function(e, handler)
    local self = global_data.getPlayer_data(e.player_index).guis.open.gui
    if self then
        handler(self, e)
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
            handler = { [defines.events.on_gui_closed] = handlers.close_gui },
            --style = "rldman_top_frame",
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
                    handler = { [defines.events.on_gui_click] = handlers.close_gui },
                },
            },
            { type = "frame", name = "content_frame", direction = "vertical", -- style = "rldman_content_frame",
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
-- ###############################################################

--- open new gui
--- @return PlayerData
local function openNewGui(player_index, gui, elems, entity)
    local pd = global_data.getPlayer_data(player_index)
    local player = game.get_player(player_index)
    if (pd == nil) then
        pd = PlayerData.init_player_data(player)
        global_data.addPlayer_data(player, pd)
    end
    player.opened = gui
    -- store reference to gui in storage
    --- @type GuiAndElements
    local nextgui =  {
        gui = gui,
        elems = elems,
        entity = entity,
    }
    pd.guis.recentlyopen = pd.guis.recentlyopen or {}
    pd.guis.recentlyopen[#pd.guis.recentlyopen + 1] = pd.guis.open

    if pd.guis.open then
        -- hide former gui
        pd.guis.open.gui.visible = false
    end
    pd.guis.open = nextgui

    gui.force_auto_center()
    gui.bring_to_front()
    gui.visible = true

    return pd
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function gui_open(event)
    local entity = event.entity
    if event.gui_type == defines.gui_type.entity and entity.type == "constant-combinator" and entity.name == "dart-fcc" then
        Log.logBlock(event, function(m)log(m)end, Log.FINE)

        local player = game.get_player(event.player_index)
        local elems, gui = build(player, entity)
        Log.logBlock( { gui = gui, elems = elems }, function(m)log(m)end, Log.FINE)

        local pd = openNewGui(event.player_index, gui, elems, entity)
        elems.fcc_view.entity = entity
        pd.guis.open.activeTab = 1

        Log.logLine(gae, function(m)log(m)end, Log.FINE)
        update_gui(event)
    end
end

-- GUI events - TBC
local dart_gui = {}

dart_gui.events = {
    [defines.events.on_gui_opened] = gui_open,

    -- defined in internalEvents.lua
    [on_dart_component_build_event] = update_gui,
    [on_dart_component_removed_event] = update_gui,
}


return dart_gui