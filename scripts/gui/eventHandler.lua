---
--- Created by xyzzycgn.
---
local Log = require("__log4factorio__.Log")
local flib_gui = require("__flib__.gui")
local dump = require("scripts.dump")
local global_data = require("scripts.global_data")

local eventHandlers = {}
-- ###############################################################

--- @param gae GuiAndElements
--- @param event EventData
local function sort_clicked_handler(gae, event)
    --- @type LuaGuiElement
    local element =  event.element
    Log.logBlock({ event = event, element = dump.dumpLuaGuiElement(element) }, function(m)log(m)end, Log.FINER)

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

    script.raise_event(on_dart_gui_needs_update, { player_index = event.player_index, entity = gae.entity } )
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param gae GuiAndElements
--- @param event EventData
local function turret_hover(gae, event)
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
local function turret_leave(gae, event)
    gae.highlight.destroy()
    gae.highlight = nil
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

eventHandlers.handlers = {
    turret_sort_clicked = sort_clicked_handler,
    turret_hover = turret_hover,
    turret_leave = turret_leave,
}

-- register local handlers in flib
flib_gui.add_handlers(eventHandlers.handlers, function(e, handler)
    local guiAndElements = global_data.getPlayer_data(e.player_index).guis.open
    if guiAndElements then
        handler(guiAndElements, e)
    end
end)

return eventHandlers