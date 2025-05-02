---
--- Created by xyzzycgn.
--- DateTime: 13.04.25 21:05
---
local Log = require("__log4factorio__.Log")
local flib_gui = require("__flib__.gui")
local components = require("scripts/gui/components")
local utils = require("scripts/utils")
local eventHandler = require("scripts/gui/eventHandler")

local radars = {}

local sortFields = {
    unit = "radar-unit",
    detect = "radar-detect",
    defense = "radar-defense",
}


--- @param elems table<string, LuaGuiElement>
local function getTableAndTab(elems)
    return elems.radars_table, elems.radars_tab
end
-- ###############################################################

--- @param data RadarOnPlatform
local function dataOfRow(data)
    Log.logBlock(data, function(m)log(m)end, Log.FINER)

    return data.radar.position, data.radar.surface_index, data.radar.backer_name, data.detectionRange, data.defenseRange
end

--- @param v RadarOnPlatform
local function appendTableRow(table, v)
    local position, surface_index, name, detect, defense = dataOfRow(v)
    local _, camera = flib_gui.add(table, {
        {
            type = "frame",
            direction = "vertical",
            { type = "camera",
              position = position,
              style = "dart_camera",
              zoom = 0.6,
              surface_index = surface_index,
              raise_hover_events = true,
              handler = {
                  [defines.events.on_gui_hover] = eventHandler.handlers.camera_hovered,
                  [defines.events.on_gui_leave] = eventHandler.handlers.camera_leave,
              }
            },
            { type = "label", style = "dart_minimap_label", caption = name },
        },
        { type = "label", style = "dart_stretchable_label_style", caption = detect },
        { type = "label", style = "dart_stretchable_label_style", caption = defense },
    })

    camera.children[1].entity = v.radar
end

--- @param v RadarOnPlatform
local function updateTableRow(table, v, at_row)
    local position, surface_index, name, detect, defense = dataOfRow(v)
    local offset = at_row * 3 + 1
    local cframe = table.children[offset]
    local camera = cframe.children[1]
    camera.position = position
    camera.surface_index = surface_index
    cframe.children[2].caption = name
    -- workaround to prevent a race condition if radar has been deleted meanwhile before next update event occured
    if (position) then
        camera.position = position
    else
        camera.enabled = false
    end
    table.children[offset + 1].caption = detect
    table.children[offset + 2].caption = defense
end
-- ###############################################################

local function sort_checkbox(name)
    return components.sort_checkbox( name, nil, false, false, eventHandler.handlers.sort_clicked)
end
-- ###############################################################

--- @param data1 RadarOnPlatform
--- @param data2 RadarOnPlatform
--- @return true if backer_name of data1 < backer_name of data2
local function cmpUnit(data1, data2)
    return data1.radar.backer_name < data2.radar.backer_name
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param data1 RadarOnPlatform
--- @param data2 RadarOnPlatform
--- @return true if data1.detectionRange < data2.detectionRange
local function cmpDetect(data1, data2)
    return data1.detectionRange < data2.detectionRange
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param data1 RadarOnPlatform
--- @param data2 RadarOnPlatform
--- @return true if data1.defenseRange < data2.defenseRange
local function cmpDefense(data1, data2)
    return data1.defenseRange < data2.defenseRange
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local comparators = {
    [sortFields.unit] = cmpUnit,
    [sortFields.detect] = cmpDetect,
    [sortFields.defense] = cmpDefense,
}

--- @param elems GuiAndElements
--- @param data RadarOnPlatform[]
--- @param pd PlayerData
function radars.update(elems, data, pd)
    Log.logBlock(data, function(m)log(m)end, Log.FINE)

    -- sort data
    local sorteddata = data
    local gae = pd.guis.open

    local sortings = gae.sortings[gae.activeTab] -- radars are on 1st tab
    local active = sortings.active
    if (active ~= "") then
        sorteddata = utils.sort(data, sortings.sorting[active], comparators[active])
    end

    components.updateVisualizedData(elems, sorteddata, getTableAndTab, appendTableRow, updateTableRow)
end
-- ###############################################################

---  @return Sortings defaults for the turret tab
function radars.sortings()
    return {
        sorting = {
            [sortFields.unit] = false,
            [sortFields.detect] = false,
            [sortFields.defense] = false,
        },
        active = ""
    }
end
-- ###############################################################

--- @return any content for the radars tab
function radars.build()
    return {
        tab = {
            { type = "tab",
              caption = { "gui.dart-radars" },
              name = "radars_tab",
            }
        },
        content = {
            type = "frame", direction = "vertical",
            style = "dart_deep_frame",
            name = "radars_tab_content",
            {
                type = "scroll-pane",
                { type = "table",
                  column_count = 3,
                  draw_horizontal_line_after_headers = true,
                  style = "dart_table_style",
                  name = "radars_table",
                  visible = false,
                  --{ type = "label", caption = { "gui.dart-radar-unit" }, style = "dart_stretchable_label_style", },
                  --{ type = "label", caption = { "gui.dart-radar-detect" }, style = "dart_stretchable_label_style", },
                  --{ type = "label", caption = { "gui.dart-radar-defense" }, style = "dart_stretchable_label_style", },
                  sort_checkbox(sortFields.unit),
                  sort_checkbox(sortFields.detect),
                  sort_checkbox(sortFields.defense),
               }
            },
        }
    }
end
-- ###############################################################

return radars