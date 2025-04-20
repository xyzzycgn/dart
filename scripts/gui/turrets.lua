---
--- Created by xyzzycgn.
--- DateTime: 13.04.25 21:06
---
local Log = require("__log4factorio__.Log")
local components = require("scripts/gui/components")
local flib_gui = require("__flib__.gui")

local turrets = {}

function turrets.build()
    return {
        tab = {
            { type = "tab",
              caption = { "gui.dart-turrets" },
              name = "turrets_tab",
            }
        },
        content = {
            type = "frame", direction = "vertical",
            style = "dart_deep_frame",
            name = "turrets_tab_content",
            {
                type = "scroll-pane",
                { type = "table",
                  column_count = 1,
                  draw_horizontal_line_after_headers = true,
                  style = "dart_table_style",
                  name = "turrets_table",
                  visible = false,
                  { type = "label", caption = { "gui.dart-turret-unit" }, style = "dart_stretchable_label_style", },
                  --{ type = "label", caption = { "gui.dart-radar-detect" }, style = "dart_stretchable_label_style", },
                  --{ type = "label", caption = { "gui.dart-radar-defense" }, style = "dart_stretchable_label_style", },
                }
            },
        }
    }
end

--- @param elems table<string, LuaGuiElement>
local function getTableAndTab(elems)
    return elems.turrets_table, elems.turrets_tab
end
-- ###############################################################

--- @param data TurretOnPlatform
local function dataOfRow(data)
    Log.logBlock(data, function(m)log(m)end, Log.FINER)

    return data.turret.position, data.turret.surface_index
end

--- @param v TurretOnPlatform
local function appendTableRow(table, v)
    local position, surface_index  = dataOfRow(v)
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
        },
        --{ type = "label", style = "dart_stretchable_label_style", caption = detect },
        --{ type = "label", style = "dart_stretchable_label_style", caption = defense },
    })

    camera.children[1].entity = v.turret
end

--- @param v TurretOnPlatform
local function updateTableRow(table, v, at_row)
    local position, surface_index  = dataOfRow(v)
    local offset = at_row * 1 + 1
    local cframe = table.children[offset]
    local camera = cframe.children[1]
    camera.position = position
    camera.surface_index = surface_index
    -- workaround to prevent a race condition if turret has been deleted meanwhile before next update event occured
    if (position) then
        camera.position = position
    else
        camera.enabled = false
    end
end
-- ###############################################################

--- @param elems GuiAndElements
--- @param data TurretOnPlatform[]
function turrets.update(elems, data)
    Log.logBlock(data, function(m)log(m)end, Log.FINE)

    components.updateVisualizedData(elems, data, getTableAndTab, appendTableRow, updateTableRow)
end

return turrets