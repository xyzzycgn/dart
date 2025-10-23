---
--- Common event handlers for the gui
---
local Log = require("__log4factorio__.Log")
local flib_gui = require("__flib__.gui")
local dump = require("__log4factorio__.dump")
local global_data = require("scripts.global_data")
local components = require("scripts.gui.components")

local eventHandler = {}
-- ###############################################################

--- @param gae GuiAndElements
--- @param event EventData
local function sort_clicked_handler(gae, event)
    --- @type LuaGuiElement
    local element =  event.element
    Log.logBlock({ event = dump.dumpEvent(event), element = dump.dumpLuaGuiElement(element) }, function(m)log(m)end, Log.FINEST)
    Log.logBlock({ active = gae.activeTab, sortings = gae.sortings}, function(m)log(m)end, Log.FINEST)

    local column = element.name
    local sortings = gae.sortings[gae.activeTab] -- turrets are on 2nd tab

    if (sortings.active == column) then
        -- toggled sort
        Log.log("toggled sort", function(m)log(m)end, Log.FINER)
        sortings.sorting[column] = element.state
    else
        Log.log("changed column", function(m)log(m)end, Log.FINER)
        -- changed sort column
        element.state = sortings.sorting[column]
        element.style = "dart_selected_sort_checkbox"

        if sortings.active ~= "" then
            local prev = gae.elems[sortings.active]
            prev.style = "dart_sort_checkbox"
        end

        sortings.active = column
    end

    script.raise_event(on_dart_gui_needs_update_event, { player_index = event.player_index, entity = gae.entity } )
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param gae GuiAndElements
--- @param event EventData
local function camera_hover(gae, event)
    ---@type LuaGuiElement
    local camera = event.element
    local entity = camera.entity

    -- highlight the entity in main window
    local highlight = entity.surface.create_entity({
        name = "highlight-box",
        position = entity.position,
        source = entity,
        box_type = "entity",
    })

    gae.highlight = highlight
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param gae GuiAndElements
--- @param event EventData
local function camera_leave(gae, event)
    if gae.highlight then
        gae.highlight.destroy()
        gae.highlight = nil
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param gae GuiAndElements
--- @param event EventData
local function clicked(gae, event)
    Log.logBlock({ gae = gae, event = dump.dumpEvent(event) }, function(m)log(m)end, Log.FINEST)
    local entity = event.element.entity
    Log.logEntity(entity, function(m)log(m)end, Log.FINEST)

    components.openNewGui(event.player_index, entity, nil, entity)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- common function to close gui
--- @param gae GuiAndElements
--- @param event EventData
function eventHandler.close(gae, event)
    Log.logEvent(event, function(m)log(m)end, Log.FINE)
    Log.logBlock(gae, function(m)log(m)end, Log.FINER)
    local guis = global_data.getPlayer_data(event.player_index).guis
    local guiToBeCLosed = gae.gui
    guis.recentlyopen = guis.recentlyopen or {}
    local ropen = guis.recentlyopen[#guis.recentlyopen]

    -- has an entity in main window been highlighted?
    local highlight = gae.highlight or (ropen and ropen.highlight)
    if (highlight and highlight.valid) then
        -- yes - destroy the highlight-box
        highlight.destroy()
        gae.highlight = nil
    end

    Log.logBlock(ropen, function(m)log(m)end, Log.FINER)
    Log.logLine((ropen and ropen.gui) == event.element, function(m)log(m)end, Log.FINER)

    -- 3 cases
    -- only fcc-gui open and close it                                 -- ropen == nil
    -- only turret open and close it                                  -- ropen == nil
    -- fcc-gui open and turret just opened -> close event for fcc-gui -- ropen != nil // handled not here????
    -- close chained turret                                           -- ropen != nil

    -- close or chaining gui?
    if ropen and ropen.gui then
        local rogui = ropen.gui
        Log.logLuaGuiElement(rogui, function(m)log(m)end, Log.FINER)
        -- chaining gui?
        if (rogui.valid and rogui == event.element) then
            -- chaining to turret gui
            rogui.visible = false
        else
            -- special handling for dart-radar
            if gae.dart_gui_type == components.dart_guis.dart_radar_gui then
                local entity = gae.entity
                local rop = global_data.getRadarOnPlatform(entity)
                rop.edited = false

                guiToBeCLosed.visible = false
                guiToBeCLosed.destroy()
            end
            -- remove closed gui from list
            guis.recentlyopen[#guis.recentlyopen] = nil
            -- make former gui visible again
            ropen.gui.visible = true
            guis.open = ropen
            Log.log("raise on_dart_gui_needs_update_event", function(m)log(m)end, Log.FINER)
            script.raise_event(on_dart_gui_needs_update_event, { player_index = event.player_index, entity = ropen.entity })
        end
    else
        -- close single gui - either fcc or turret
        if components.checkIfValidGuiElement(guiToBeCLosed) then
            -- must be fcc
            Log.log("destroy custom gui", function(m)log(m)end, Log.FINER)
            guiToBeCLosed.destroy()
            guis.open = nil
        end
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

eventHandler.handlers = {
    sort_clicked = sort_clicked_handler,
    camera_hovered = camera_hover,
    camera_left = camera_leave,
    clicked = clicked,
    close_gui = eventHandler.close,
}

-- register local handlers in flib
flib_gui.add_handlers(eventHandler.handlers, function(e, handler)
    local guiAndElements = global_data.getPlayer_data(e.player_index).guis.open
    if guiAndElements then
        handler(guiAndElements, e)
    end
end)

return eventHandler