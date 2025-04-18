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

local function getTableAndTab(refs)
    return refs[radars_table], refs[radars_tab]
end
-- ###############################################################

local function dataOfRow(data)
    Log.logBlock(data, function(m)log(m)end, Log.FINER)
    local train_id = data.id
    local position = loco and loco.position

    return train_id, position
end

local function appendTableRow(table, v)
    local train_id, position = dataOfRow(v)
    flib_gui.add(table,  {
        { type = "minimap",
          style = "dart_train_minimap",
          position = position,
          { type = "label", style = "dart_train_minimap_label", caption = train_id }
        },
    })
end

local function updateTableRow(table, v, at_row)
    local train_id, position = dataOfRow(v)
    local offset = at_row * 1 + 1
    local minimap = table.children[offset]
    minimap.children[1].caption = train_id
    -- workaround to prevent a race condition if radar has been deleted meanwhile before next update event occured
    if (position) then
        minimap.position = position
    else
        minimap.enabled = false
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function getModel(player_model)
    return player_model.trains -- TODO
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function setModel(player_model, val)
    player_model.trains = val -- TODO
end
-- ###############################################################

function radars.update(refs, data, gui_model, player_index)
    Log.logBlock(data[player_index], function(m)log(m)end, Log.FINE)

    components.updateVisualizedData(refs, data[player_index], gui_model, player_index,
            getTableAndTab, getModel, setModel,
            appendTableRow, updateTableRow)
end


return radars