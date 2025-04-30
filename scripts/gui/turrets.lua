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

-- table.sort doesn't work with these tables (not gapless)
-- because the size (# rows) of these tables shouldn't be large, a variant of bubblesort should be fast enough
-- although it's O(n²) ;-)
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
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param data1 TurretOnPlatform
--- @param data2 TurretOnPlatform
local function cmpPos(data1, data2)
    local pos1 = data1.turret.position
    local pos2 = data2.turret.position

    local x = (pos1.x < pos2.x) or ((pos1.x == pos2.x) and (pos1.y < pos2.y))
    return x
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param data1 TurretOnPlatform
--- @param data2 TurretOnPlatform
local function cmpNet(data1, data2)
    local pos1 = data1.turret.position
    local pos2 = data2.turret.position

    local x = (pos1.x < pos2.x) or ((pos1.x == pos2.x) and (pos1.y < pos2.y))
    return x
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


--- @param data TurretOnPlatform[]
local function sortByUnit(data, ascending)
    return sort(data, ascending, cmpPos)
end

--- @param data TurretOnPlatform[]
local function sortByNetwork(data, ascending)
    Log.log("sortByNetwork NYI", function(m)log(m)end, Log.WARN)
    return data
    --return sort(data, ascending, cmpNet)
end

--- @param data TurretOnPlatform[]
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
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param networks any array with all circuit networks of turret
--- @param nwOfFcc any array with the IDs of the circuitnetworks of the fcc managed in this gui
local function networkCondition(networks, nwOfFcc)
    local lblcaption, lblstyle, cc

    local connected_twice = false -- is the turret connected twice
    for conn, nw in pairs(networks) do
        if (nwOfFcc[nw.network_id]) then
            if lblcaption then -- ignore the 2nd connection
                connected_twice = true
                break
            end
            -- network of turret is connected to fcc managed in gui
            lblcaption = nw.network_id
            lblstyle = col_style[conn]


            ---@type CircuitCondition
            cc = nw.circuit_condition
            Log.logBlock(cc.first_signal, function(m)log(m)end, Log.FINER)
        end
    end

    if lblcaption then
        if connected_twice then
            lblcaption = { "gui.dart-turret-connected-twice" }
            lblstyle = "bold_orange_label"
            cc = nil
        end
    else
        -- not connected
        lblcaption = { "gui.dart-turret-offline" }
        lblstyle = "bold_red_label"
    end

    return lblcaption, lblstyle, cc
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function names(ndx)
    local prefix = "tur_cc_" .. ndx
    local camera = prefix .. "_camera"
    local lbl = prefix .. "_lbl"
    local ceb = prefix .. "_ceb"
    local ddb = prefix .. "_ddb"
    local sig2 = prefix .. "_2ndsig"

    return camera, lbl, ceb, ddb, sig2
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param table LuaGuiElement table to add row
--- @param v TurretOnPlatform
--- @param ndx number of row
--- @param nwOfFcc any array with the IDs of the circuitnetworks of the fcc managed in this gui
local function appendTableRow(table, v, ndx, nwOfFcc)
    local position, surface_index, networks  = dataOfRow(v)
    local lblcaption, lblstyle, cc = networkCondition(networks, nwOfFcc)
    local camera, lbl, ceb, ddb, sig2 = names(ndx)

    local elems, camera = flib_gui.add(table, {
        { type = "camera",
          position = position,
          style = "dart_camera",
          zoom = 0.6,
          surface_index = surface_index,
          name = camera
        },
        {
            type = "label", name = lbl, style = lblstyle, caption = lblcaption,
        },
        {
            type = "flow",
            direction = "horizontal",
            { type = "choose-elem-button",
              elem_type = "signal",
              ignored_by_interaction = true,
              name = ceb
            },
            { type = "button",
              style = "dropdown_button",
              ignored_by_interaction = true,
              style_mods = { minimal_width = 28, top_margin = 6, vertical_align = "center", },
              name = ddb
            },
            { type = "label",
              style = "dart_stretchable_label_style",
              style_mods = { top_margin = 10 },
              name = sig2
            },
        }
    })
    Log.logBlock(elems, function(m)log(m)end, Log.FINER)

    -- set the entity the camera should follow
    camera.entity = v.turret
    -- set the values for the choose-elem-button, ...
    if cc then
        local elem = elems[ceb]
        elem.elem_value = cc.first_signal
        elem.locked = true

        elems[ddb].caption = cc.comparator
        elems[sig2].caption = cc.constant -- TODO or second_signal
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param table LuaGuiElement
--- @param v TurretOnPlatform
local function updateTableRow(table, v, at_row, nwOfFcc)
    local position, surface_index, networks  = dataOfRow(v)
    local lblcaption, lblstyle, cc = networkCondition(networks, nwOfFcc)
    local camera, lbl, ceb, ddb, sig2 = names(at_row)
    local offset = at_row * 3

    local camElem = table[camera]
    if (position) then
        camElem.position = position
        camElem.surface_index = surface_index
        camElem.entity = v.turret
        camElem.enabled = true
    else
        camElem.enabled = false
    end

    table[lbl].caption = lblcaption
    table[lbl].style = lblstyle

    local ccflow = table.children[offset + 3]
    if cc then
        ccflow.visible = true
        ccflow[ceb].elem_value = cc.first_signal
        ccflow[ceb].locked = true

        ccflow[ddb].caption = cc.comparator
        ccflow[sig2].caption = cc.constant -- TODO or second_signal
    else
        ccflow.visible = false
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

    local function localAppendTableRow(table, v, ndx)
        appendTableRow(table, v, ndx, nwOfFcc)
    end

    local function localUpdateTableRow(table, v, ndx)
        updateTableRow(table, v, ndx, nwOfFcc)
    end

    -- sort data
    local sorteddata = data

    local sortings = pd.guis.open.sortings[2] -- turrets are on 2nd tab
    local active = sortings.active
    if (active ~= "") then
        sorteddata = sortFunction[active](data, sortings.sorting[active])
    end

    components.updateVisualizedData(elems, sorteddata, getTableAndTab, localAppendTableRow, localUpdateTableRow)
end
-- ###############################################################

local function sort_clicked_handler(gui, event)
    --- @type LuaGuiElement
    local element =  event.element
    Log.logBlock({ event = event, element = dump.dumpLuaGuiElement(element) }, function(m)log(m)end, Log.FINER)

    local column = element.name
    local gae = global_data.getPlayer_data(event.player_index).guis.open
    local sortings = gae.sortings[2] -- turrets are on 2nd tab

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