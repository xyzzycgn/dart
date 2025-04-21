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
                  column_count = 3,
                  draw_horizontal_line_after_headers = true,
                  style = "dart_table_style",
                  name = "turrets_table",
                  visible = false,
                  { type = "label", caption = { "gui.dart-turret-unit" }, style = "dart_stretchable_label_style", },
                  { type = "label", caption = { "gui.dart-turret-cn" }, style = "dart_stretchable_label_style", },
                  { type = "label", caption = { "gui.dart-turret-cond" }, style = "dart_stretchable_label_style", },
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

--- @param top TurretOnPlatform
local function dataOfRow(top)
    Log.logBlock(top, function(m)log(m)end, Log.FINER)

    local cb = top.control_behavior

    local networks = {}
    for connector, wc in pairs({ defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green }) do
        ---  @type LuaCircuitNetwork
        local cn = cb.get_circuit_network(wc)

        if cn then
            --- @type CnOfTurret
            networks[connector] = {
                network_id = cn.network_id,
                circuit_condition = cb.circuit_condition,
            }
        end
    end

    return top.turret.position, top.turret.surface_index, networks
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local col_style = {
     [defines.wire_connector_id.circuit_red] =  "red_label",
     [defines.wire_connector_id.circuit_green] =  "green_label",
}

local function networkConditions(networks, prefix)
    local conditions = {}
    local add_params = {}
    local nw_numbers = {}

    for conn, nw in pairs(networks) do
        nw_numbers[#nw_numbers + 1] =
            { type = "label", style = "dart_stretchable_label_style", caption = nw.network_id, style = col_style[conn] }

        ---@type CircuitCondition
        local cc = nw.circuit_condition
        Log.logBlock(cc.first_signal, function(m)log(m)end, Log.FINE)

        conditions[#conditions + 1] = {
            type = "frame",
            direction = "horizontal",
            { type = "choose-elem-button", elem_type = "signal", name = prefix .. #conditions, },
            { type = "label", style = "dart_stretchable_label_style", caption = cc.comparator },
            { type = "label", style = "dart_stretchable_label_style", caption = cc.constant,  }, -- TODO or second_signal
        }
        add_params[#add_params + 1] = cc.first_signal
    end

    return {
        type = "frame",
        direction = "vertical",
        conditions[1],
        conditions[2],
    }, {
        type = "frame",
        direction = "vertical",
        nw_numbers[1],
        nw_numbers[2],
    },
    add_params
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param v TurretOnPlatform
local function appendTableRow(table, v)
    local position, surface_index, networks  = dataOfRow(v)
    local prefix = "tur_cc_" .. v.turret.unit_number .. "_"
    local cc, nwn, add_params = networkConditions(networks, prefix)

    Log.logBlock( { cc, add_params }, function(m)log(m)end, Log.FINE)

    local elems, cameraframe = flib_gui.add(table, {
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
        nwn,
        cc,
    })

    -- set the entity the camera should follow
    cameraframe.children[1].entity = v.turret
    -- set the values for the choose-elem-buttons
    local ndx = 1
    for _, elem in pairs(elems) do
        elem.elem_value = add_params[ndx]
        elem.locked = true
        ndx = ndx + 1
    end
end
-- ###############################################################

--- @param v TurretOnPlatform
local function updateTableRow(table, v, at_row)
    local position, surface_index, networks  = dataOfRow(v)
    local offset = at_row * 3 + 1
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