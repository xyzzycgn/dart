---
--- Created by xyzzycgn.
--- DateTime: 04.03.25 21:27
---
--- Build the D.A.R.T Main UI window
--- @param player LuaPlayer @ Player object that is opening the combinator
--- @return GuiElemDef
---@diagnostic disable:missing-fields

local Log = require("__log4factorio__.Log")
local global_data = require("scripts.global_data")
local PlayerData = require("scripts.player_data")
local radars = require("scripts.gui.radars")
local turrets = require("scripts.gui.turrets")

local flib_gui = require("__flib__.gui")
local flib_format = require("__flib__.format")

local function close(gui, event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
    Log.logBlock(gui, function(m)log(m)end, Log.FINE)
    local pd = global_data.getPlayer_data(event.player_index)

    pd.guis.recentlyopen = pd.guis.recentlyopen or {}
    local ropen= pd.guis.recentlyopen[#pd.guis.recentlyopen]

    -- close actual gui and destroy it
    gui.visible = false
    gui.destroy()

    -- former gui present?
    if ropen then
        pd.guis.recentlyopen[#pd.guis.recentlyopen] = nil
        -- make former gui visible again
        ropen.gui.visible = true
    end
    pd.guis.open = ropen
end

local handlers = {
    close_gui = close
}

flib_gui.add_handlers(handlers, function(e, handler)
    local self = global_data.getPlayer_data(e.player_index).guis.open.gui
    if self then
        handler(self, e)
    end
end)


-- ###############################################################

--- creates the custom gui
--- @param player LuaPlayer who opens the entity
--- @param entity Entity to be shown in the GUI
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
              { -- TODO löschen
                  type = "label",
                  caption = "Huhu GUI",
                  name = "main_label_TBDel"
              },
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

local function open(player_index, gui, elems)
    local pd = global_data.getPlayer_data(player_index)
    local player = game.get_player(player_index)
    if (pd == nil) then
        pd = PlayerData.init_player_data(player)
        global_data.addPlayer_data(player, pd)
    end
    player.opened = gui
    -- store reference to gui in storage
    local nextgui =  {
        gui = gui,
        elems = elems,
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
end
-- ###############################################################

local function gui_open(event)
    local entity = event.entity
    if event.gui_type == defines.gui_type.entity and entity.type == "constant-combinator" and entity.name == "dart-fcc" then
        Log.logBlock(event, function(m)log(m)end, Log.FINE)
        Log.logBlock(defines.gui_type, function(m)log(m)end, Log.FINEST)

        local player = game.get_player(event.player_index)
        local elems, gui = build(player, entity)
        Log.logBlock( { gui = gui, elems = elems }, function(m)log(m)end, Log.FINE)

        open(event.player_index, gui, elems, "main")

        Log.logLine(entity, function(m)log(m)end, Log.FINE)

        elems.fcc_view.entity = entity
        elems.fcc_view.visible = true
    end
end
-- ###############################################################

local function gui_click(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
end

-- TODO temporary - tbd
local cnt = 0

local function tabChanged(event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
    -- TODO ??
    cnt = cnt + 1
    Log.log(cnt, function(m)log(m)end, Log.FINE)
end

--###############################################################


local function update_gui(event)
    Log.logLine(event, function(m)log(m)end, Log.FINE)

    --local pd = global_data.getPlayer_data(event.player_index)
    local pd = global_data.getPlayer_data(1) -- TODO
    Log.logBlock(pd, function(m)log(m)end, Log.FINER)

    if (pd ~= nil) then
        local open = pd.guis.open
        if open then
            open.elems.radars_tab.badge_text = flib_format.number(cnt)
        end
    end
end


-- GUI events - TBC
local dart_gui = {}

dart_gui.events = {
    [defines.events.on_gui_opened] = gui_open,
    [defines.events.on_gui_click] =  gui_click,
    [defines.events.on_gui_click] =  tabChanged,
}

-- handling of GUI updates (every second - easy way but not very efficient, TODO update only if necessary)
dart_gui.on_nth_tick = {
    [60] = update_gui
}


return dart_gui