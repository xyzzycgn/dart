---
--- Created by xyzzycgn.
--- DateTime: 13.04.25 21:06
---
local flib_gui = require("__flib__.gui")
local Log = require("__log4factorio__.Log")
local dump = require("scripts/dump")
local components = require("scripts/gui/components")
local global_data = require("scripts/global_data")

local turrets = {}
local redAndGreenWC = { defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green }

-- ###############################################################

local function cmpPos(data1, data2)
    local pos1 = data1.turret.position
    local pos2 = data2.turret.position

    local x = (pos1.x < pos2.x) or ((pos1.x == pos2.x) and (pos1.y < pos2.y))
    Log.logBlock(x, function(m)log(m)end, Log.FINE)
    return x
end

-- table.sort doesn't work with these tables (not gapless)
-- because the size (# rows) of these tables shouldn't be large, a modified bubblesort should be fast enough
local function sort(data, ascending, func)
    local sortedData = {}

    local ndx = 0
    for _, row in pairs(data) do
        for i = 1, #sortedData do
            if (func(sortedData[i], row) ~= ascending) then
                table.insert(sortedData, i, row)
                goto continue
            end
        end

        sortedData[#sortedData + 1] = row

       ::continue::
    end

    return sortedData
end



local function sortByUnit(data, ascending)
    Log.logBlock(data, function(m)log(m)end, Log.FINE)

    local sortedData = sort(data, ascending, cmpPos)

    Log.logBlock(sortedData, function(m)log(m)end, Log.FINE)
    return sortedData
end

local function sortByNetwork(data, ascending)
    Log.log("sortByNetwork NYI", function(m)log(m)end, Log.WARN)
    return data
end

local function sortByCondition(data, ascending)
    Log.log("sortByCondition NYI", function(m)log(m)end, Log.WARN)
    return data
end

local sortFields = {
    unit = "turret-unit",
    cn = "turret-cn",
    cond = "turret-cond",
}


local sortFunction = {
    [sortFields.unit] = sortByUnit,
    [sortFields.cn] = sortByNetwork,
    [sortFields.cond] = sortByCondition,
}

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

---  @return Sortings defaults for the turret tab
function turrets.sortings()
    return {
        sorting = {
            [sortFields.unit] = false,
            [sortFields.cn] = false,
            [sortFields.cond] = false,
        },
        active = ""
    }
end
-- ###############################################################

--- @param elems table<string, LuaGuiElement>
local function getTableAndTab(elems)
    return elems.turrets_table, elems.turrets_tab
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- returns position of turret, surface_index of turret and an array with all circuit networks of turret
--- @param top TurretOnPlatform
local function dataOfRow(top)
    Log.logBlock(top, function(m)log(m)end, Log.FINER)

    local cb = top.control_behavior

    local networks = {}
    for connector, wc in pairs(redAndGreenWC) do
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

--- @param networks any array with all circuit networks of turret
--- @param nwOfFcc any array with the IDs of the circuitnetworks of the fcc managed in this gui
local function networkConditions(networks, prefix, nwOfFcc)
    local conditions = {}
    local add_params = {}
    local nw_numbers = {}

    for conn, nw in pairs(networks) do
        if (nwOfFcc[nw.network_id]) then
            -- network of turret is connected to fcc managed in gui
            nw_numbers[#nw_numbers + 1] =
                { type = "label", style = "dart_stretchable_label_style", caption = nw.network_id, style = col_style[conn] }

            ---@type CircuitCondition
            local cc = nw.circuit_condition
            Log.logBlock(cc.first_signal, function(m)log(m)end, Log.FINE)

            conditions[#conditions + 1] = {
                type = "flow",
                direction = "horizontal",
                { type = "choose-elem-button", elem_type = "signal", name = prefix .. #conditions,
                  ignored_by_interaction = true,
                },
                { type = "button",
                  style = "dropdown_button",
                  caption = cc.comparator,
                  ignored_by_interaction = true,
                  style_mods = { minimal_width = 28, top_margin = 6, vertical_align = "center", }
                },
                { type = "label",
                  style = "dart_stretchable_label_style",
                  caption = cc.constant, -- TODO or second_signal
                  style_mods = { top_margin = 10 }
                },
            }
            add_params[#add_params + 1] = cc.first_signal
        end
    end

    if #nw_numbers == 0 then
        -- not connected
        nw_numbers[1] = { type = "label", style = "dart_stretchable_label_style",
                          caption = { "gui.dart-turret-offline" }, style = "bold_orange_label" }
    end

    return {
        type = "flow",
        direction = "vertical",
        nw_numbers[1],
        nw_numbers[2],
    }, {
        type = "flow",
        direction = "vertical",
        conditions[1],
        conditions[2],
    },
    add_params
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param v TurretOnPlatform
--- @param nwOfFcc any array with the IDs of the circuitnetworks of the fcc managed in this gui
local function appendTableRow(table, v, nwOfFcc)
    local position, surface_index, networks  = dataOfRow(v)
    local prefix = "tur_cc_" .. v.turret.unit_number .. "_"
    local nwn, cc, add_params = networkConditions(networks, prefix, nwOfFcc)

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
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param v TurretOnPlatform
local function updateTableRow(table, v, at_row)
    local position, surface_index, networks  = dataOfRow(v)
    local offset = at_row * 3 + 1
    local cframe = table.children[offset]
    local camera = cframe.children[1]
    camera.position = position
    camera.surface_index = surface_index
    camera.entity = v.turret
    -- workaround to prevent a race condition if turret has been deleted meanwhile before next update event occured
    if (position) then
        camera.position = position
    else
        camera.enabled = false
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param elems GuiAndElements
--- @param data TurretOnPlatform[]
--- @param pd PlayerData
function turrets.update(elems, data, pd)
    -- fcc managed in gui
    local entity = elems.entity
    -- get the circuit networks of it
    local nwOfFcc = {}
    for _, wc in pairs(redAndGreenWC) do
        local cn = entity.get_circuit_network(wc)
        if cn then
            nwOfFcc[cn.network_id] = true
        end
    end

    local function localAppendTableRow(table, v)
        appendTableRow(table, v, nwOfFcc)
    end

    -- sort data
    local sorteddata = data

    local sortings = pd.guis.open.sortings[2] -- turrets are on 2nd tab
    local active = sortings.active
    if (active ~= "") then
        sorteddata = sortFunction[active](data, sortings.sorting[active])
    end

    components.updateVisualizedData(elems, sorteddata, getTableAndTab, localAppendTableRow, updateTableRow)
end
-- ###############################################################

local function sort_clicked_handler(gui, event)
    --- @type LuaGuiElement
    local element =  event.element
    Log.logBlock({ event = event, element = dump.dumpLuaGuiElement(element) }, function(m)log(m)end, Log.FINE)

    local column = element.name
    local gae = global_data.getPlayer_data(event.player_index).guis.open
    local sortings = gae.sortings[2] -- turrets are on 2nd tab

    Log.logBlock(sortings, function(m)log(m)end, Log.FINE)

    if (sortings.active == column) then
        -- toggled sort
        Log.log("toggled sort", function(m)log(m)end, Log.FINE)
        sortings.sorting[column] = element.state
    else
        Log.log("changed column", function(m)log(m)end, Log.FINE)
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


local handlers = {
   turret_sort_clicked = sort_clicked_handler
}

-- register local handlers in flib
flib_gui.add_handlers(handlers, function(e, handler)
    local self = global_data.getPlayer_data(e.player_index).guis.open.gui
    if self then
        handler(self, e)
    end
end)

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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
                    --{ type = "label", caption = { "gui.dart-turret-unit" }, style = "dart_stretchable_label_style", },
                    --{ type = "label", caption = { "gui.dart-turret-cn" }, style = "dart_stretchable_label_style", },
                    --{ type = "label", caption = { "gui.dart-turret-cond" }, style = "dart_stretchable_label_style", },
                  components.sort_checkbox( "turret-unit", nil, false, false, handlers.turret_sort_clicked),
                  components.sort_checkbox( "turret-cn", nil, false, false, handlers.turret_sort_clicked),
                  components.sort_checkbox( "turret-cond", nil, false, false, handlers.turret_sort_clicked),
                }
            },
        }
    }
end
-- ###############################################################

return turrets