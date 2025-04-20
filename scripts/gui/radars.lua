---
--- Created by xyzzycgn.
--- DateTime: 13.04.25 21:05
---
local Log = require("__log4factorio__.Log")
local components = require("scripts/gui/components")
local flib_gui = require("__flib__.gui")

local radars = {}

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
                  { type = "label", caption = { "gui.dart-radar-unit" }, style = "dart_stretchable_label_style", },
                  { type = "label", caption = { "gui.dart-radar-detect" }, style = "dart_stretchable_label_style", },
                  { type = "label", caption = { "gui.dart-radar-defense" }, style = "dart_stretchable_label_style", },
                }
            },
        }
    }
end

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

--- @param elems GuiAndElements
--- @param data RadarOnPlatform[]
function radars.update(elems, data)
    Log.logBlock(data, function(m)log(m)end, Log.FINE)

    components.updateVisualizedData(elems, data, getTableAndTab, appendTableRow, updateTableRow)
end


return radars