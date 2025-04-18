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
                  column_count = 1,
                  draw_horizontal_line_after_headers = true,
                  style = "dart_table_style",
                  name = "radars_table",
                  visible = true, -- TODO false
                  { type = "label", caption = { "gui.dart-radar-unit" }, style = "dart_stretchable_label_style", },
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

    return data.radar.unit_number, data.radar.position
end

--- @param v RadarOnPlatform
local function appendTableRow(table, v)
    local run, position = dataOfRow(v)
    flib_gui.add(table,  {
        { type = "minimap",
          style = "dart_minimap",
          position = position,
          zoom = 5,

          -- TODO camera shows nothing / isn't rendered properly
          --type = "camera",
          --position = position,
          --entity = v.radar,
          --surface_index = v.radar.surface_index,

          { type = "label", style = "dart_minimap_label", caption = run }
        },
    })
end

local function updateTableRow(table, v, at_row)
    local run, position = dataOfRow(v)
    local offset = at_row * 1 + 1
    local minimap = table.children[offset]
    minimap.children[1].caption = run
    -- workaround to prevent a race condition if radar has been deleted meanwhile before next update event occured
    if (position) then
        minimap.position = position
    else
        minimap.enabled = false
    end
end
-- ###############################################################

--- @param elems GuiAndElements
--- @param data RadarOnPlatform[]
function radars.update(elems, data)
    Log.logBlock(data, function(m)log(m)end, Log.FINE)

    components.updateVisualizedData(elems, data, getTableAndTab, appendTableRow, updateTableRow)
end


return radars