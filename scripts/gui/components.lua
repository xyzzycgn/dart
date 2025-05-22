---
--- Created by xyzzycgn.
--- DateTime: 18.01.25 09:27
local Log = require("__log4factorio__.Log")
local global_data = require("scripts.global_data")
local PlayerData = require("scripts.player_data")
local flib_gui = require("__flib__.gui")
local flib_format = require("__flib__.format")

local components =  {}

--- @class dart_guis
components.dart_guis =  {
    main_gui = 1,
    dart_radar_gui = 2,
}
-- ###############################################################

--- adds a slider
--- @param name string name for the slider widget
--- @param min uint min value for slider
--- @param max uint max value for slider
--- @param val uint actual value for slider
--- @param handler function event handler
local function sliderOnly(name, min, max, val, handler)
    return {
        type = "slider",
        minimum_value = min,
        maximum_value = max,
        value = val,
        style_mods = { top_margin = 10, horizontally_stretchable = true, maximal_width = 190, },
        name = name,
        handler = { [defines.events.on_gui_value_changed] = handler}
    }
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- adds a slider and a scale (if desired)
--- @param name string name for the slider widget
--- @param min uint min value for slider
--- @param max uint max value for slider
--- @param val uint actual value for slider
--- @param handler function event handler
--- @param omitScale boolean if true, only the slider is returned
local function sliderWithScale(name, min, max, val, handler, omitScale)
    if omitScale then
        return sliderOnly(name, min, max, val, handler)
    else
        return {
            type = "flow",
            direction = "vertical",
            style = "dart_stretchable_vertical_flow_style",
            {
                type = "flow",
                direction = "horizontal",
                style = "dart_stretchable_flow_style",
                {
                    type = "label",
                    style = "dart_stretchable_label_style",
                    style_mods = { horizontal_align = "left", },
                    caption = min,
                    natural_width = 38,
                },
                {
                    type = "flow",
                    direction = "horizontal",
                    style_mods = { natural_width = 155, maximal_width = 155, },
                },
                {
                    type = "label",
                    style = "dart_stretchable_label_style",
                    style_mods = { horizontal_align = "right", },
                    caption = max,
                    natural_width = 38,
                },
            },
            sliderOnly(name, min, max, val, handler),
        }
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- adds a slider + text
--- @param name string name for the slider widget
--- @param caption string short description
--- @param min uint min value for slider
--- @param max uint max value for slider
--- @param val uint actual value for slider
--- @param handler function event handler
--- @param omitScale boolean (opt.) flag if the scale shouldn't be shown
--- @return
function components.radar_slider(name, caption, min, max, val, handler, omitScale)
    return {
        type = "frame",
        style = "dart_content_frame_stretchable",
        style_mods = { width = 360, },
        direction = "horizontal",
        sliderWithScale(name, min, max, val, handler, omitScale),
        { type = "label",
          style = "dart_stretchable_label_style",
          style_mods = { top_margin = 10, left_margin = 8, },
          caption = caption,
        },
    }
end
-- ###############################################################

--- @param guiOrEntity LuaGuiElement|LuaEntity
--- @return true if guiOrEntity is a valid LuaGuiElement
function components.checkIfValidGuiElement(guiOrEntity)
    return guiOrEntity and guiOrEntity.valid and guiOrEntity.object_name == "LuaGuiElement"
end
-- ###############################################################

--- Creates a column header with a sort toggle.
--- @param name string used for name and (as base) for caption
--- @param tooltip string
--- @param sortByThis boolean true sort by this column
--- @param state boolean true = ascending
--- @param handler function eventHandler
function components.sort_checkbox(name, tooltip, sortByThis, state, handler)
    return {
        type = "checkbox",
        style = sortByThis and "dart_selected_sort_checkbox" or "dart_sort_checkbox",
        caption = { "gui.dart-" .. name },
        tooltip = tooltip,
        state = state,
        name = name,
        handler = { [defines.events.on_gui_checked_state_changed] = handler }
    }
end
-- ###############################################################

function components.slot_table(name, size)
    size = size or 4
    return {
        type = "frame",
        style = "rldman_small_slot_table_frame",
        {
            type = "flow",
            direction = "horizontal",
            style_mods = { width = 36 * size, height = 36, padding = 0 },
            name = name .. "_slot_table",
        }
    }
end
-- ###############################################################

local function indicator_color(color)
    return "flib_indicator_"..color
end

function components.status_indicator(color, center)
    return {
        type = "flow",
        style = "flib_indicator_flow",
        style_mods = { horizontal_align = center and "center" or nil },
        { type = "sprite", style = "flib_indicator", sprite = indicator_color(color) },
        { type = "label" },
    }
end
-- ###############################################################

function components.update_indicator(parent, color)
    parent.children[1].sprite = indicator_color(color)
end
-- ###############################################################

function components.addSprites2Slots(slot_table, data, func)
    Log.logBlock(data, function(m)log(m)end, Log.FINER)
    local children = slot_table.children

    local i = 0
    for k, v in pairs(data) do
        local sprite

        if (type(v) == "number") then
            sprite = string.gsub(k, "=", "/")
        elseif v.tnq then
            sprite = string.gsub(v.tnq, "=", "/")
        elseif v.type then
            sprite = v.type .. "/" .. v.name
        else
            sprite = string.gsub(k, "=", "/")
        end
        if helpers.is_valid_sprite_path(sprite) then
            i = i + 1
            local button = children[i]
            if not button then
                _, button = flib_gui.add(slot_table, {
                    type = "sprite-button",
                    style = "rldman_small_slot_button_default",
                })
            end

            button.sprite = sprite
            -- set number and/or other fields (e.g. tooltip)
            if (func) then
                func(button, v)
            end
        else
            Log.log("sprite-path not valid: '" .. sprite .. "'", function(m)log(m)end, Log.WARN)
        end
    end
    -- remove obsolete former entries
    for j = i + 1, #children do
        children[j].destroy()
    end
end
-- ###############################################################

function components.updateSpritesInSlots(slot_frame, data, func)
    components.addSprites2Slots(slot_frame.children[1], data, func)
end
-- ###############################################################

-- remove a row from table
function components.removeTableRow(table, at_row)
    local offset = at_row * table.column_count + 1

    -- remove the elements (in reverse order they've been created)
    for i = offset + table.column_count - 1, offset, -1  do
        table.children[i].destroy()
    end
end
-- ###############################################################

-- update of a complete table showing various data
--- @param gae GuiAndElements gui model
--- @param data any data to be shown
--- @param getTableAndTab function that returns the tab (from tabbed pane) and the table (from content)
--- @param appendTableRow function that returns appends a new row to the table
--- @param updateTableRow function that update a row of the table
--- @param funcRemoveTableRow function (optional) that removes a row from the table
function components.updateVisualizedData(gae, data,
                                         getTableAndTab, appendTableRow, updateTableRow, funcRemoveTableRow)
    funcRemoveTableRow = funcRemoveTableRow or components.removeTableRow
    Log.logBlock(data, function(m)log(m)end, Log.FINER)
    local table, tab = getTableAndTab(gae.elems)
    local new_number = table_size(data)
    local rows = gae.rowsShownLastInTab or {}
    local old_number = rows[gae.activeTab] or 0

    Log.log("oldn = " .. old_number .. ", newn=" .. new_number, function(m)log(m)end, Log.FINER)

    -- update tab-label with new count
    tab.badge_text = flib_format.number(new_number)

    local ndx = 1
    for _, v in pairs(data) do
        if (ndx <= new_number) and (ndx <= old_number) then
            -- update existing rows with new data
            Log.log("update entry@" .. ndx, function(m)log(m)end, Log.FINER)
            updateTableRow(table, v, ndx)
        else
            -- more active => add new entries at the end of table
            Log.log("add new entry at end", function(m)log(m)end, Log.FINER)
            appendTableRow(table, v, ndx)
        end
        ndx = ndx + 1
    end

    if (new_number < old_number) then
        -- less active => remove entries at the end of table
        local firstRow2remove = ndx
        while (ndx <= old_number) do
            Log.log("remove old entry@" .. ndx, function(m)log(m)end, Log.FINER)
            funcRemoveTableRow(table, firstRow2remove)
            ndx = ndx + 1
        end
    end

    table.visible = (new_number > 0)
    -- save model (number of shown rows)
    rows[gae.activeTab] = new_number
    gae.rowsShownLastInTab = rows
end
-- ###############################################################

--- open new gui and chain it with formerly opened
--- @param gui LuaGuiElement | LuaEntity new gui to open
--- @return PlayerData
function components.openNewGui(player_index, gui, elems, entity)
    Log.logBlock({player_index = player_index, gui = gui, elems = elems, entity = entity}, function(m)log(m)end, Log.FINE)

    local pd = global_data.getPlayer_data(player_index)
    local player = game.get_player(player_index)
    if (pd == nil) then
        pd = PlayerData.init_player_data(player)
        global_data.addPlayer_data(player, pd)
    end
    -- store reference to gui in storage
    --- @type GuiAndElements
    local nextgui =  {
        gui = gui,
        elems = elems,
        entity = entity,
    }
    pd.guis.recentlyopen = pd.guis.recentlyopen or {}
    pd.guis.recentlyopen[#pd.guis.recentlyopen + 1] = pd.guis.open

    Log.logBlock(pd.guis, function(m)log(m)end, Log.FINER)
    local open = pd.guis.open
    if open and components.checkIfValidGuiElement(open.gui) then
        -- hide former gui
        open.gui.visible = false
    end
    pd.guis.open = nextgui

    -- open new GUI
    player.opened = gui
    if components.checkIfValidGuiElement(gui) then
        gui.force_auto_center()
        gui.bring_to_front()
        gui.visible = true
    end

    return pd
end





return components