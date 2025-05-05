---
--- Created by xyzzycgn.
--- DateTime: 13.04.25 21:06
---
local flib_gui = require("__flib__.gui")
local Log = require("__log4factorio__.Log")
local components = require("scripts/gui/components")
local utils = require("scripts/utils")
local eventHandler = require("scripts/gui/eventHandler")

local turrets = {}
local redAndGreenWC = { defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green }

local sortFields = {
    unit = "turret-unit",
    cn = "turret-cn",
    cond = "turret-cond",
}
-- ###############################################################

--- @class Network a certain circuit network (either green or red) and its CircuitCondition of a turret
--- @field network_id number the unique ID of the network
--- @field circuit_condition CircuitConditionDefinition

--- @param top TurretOnPlatform
--- @return Network[] indexed by connector (circuit_red/circuit_green)
local function getNetworksOfTurretOnPlatform(top)
    local networks = {}
    local cb = top.control_behavior

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

    return networks
end
-- ###############################################################

--- @param data1 TurretConnection
--- @param data2 TurretConnection
--- @return true if data1 < data2
local function cmpPos(data1, data2)
    local pos1 = data1.turret.position
    local pos2 = data2.turret.position

    return (pos1.x < pos2.x) or ((pos1.x == pos2.x) and (pos1.y < pos2.y))
end
-- ###############################################################

--- @param data1 TurretConnection
--- @param data2 TurretConnection
--- @return true if network_id of data1 < network_id of data2
local function cmpNet(data1, data2)
    local n1 = data1.num_connections
    local n2 = data2.num_connections

    if (n1 == 1) and (n2 == 1) then
        -- both connected to one network => compare network-ids
        return (data1.network_id < data2.network_id)
    elseif n1 == 1 then
        -- only 1st connected to one network => treat it as smaller
        return true
    elseif n2 == 1 then
        -- only 2nd connected to one network => treat it as smaller
        return false
    else
        -- both are either not connected or connected twice => treat not connected as smaller
        return n1 > n2
    end
end
-- ###############################################################

--- @param data1 TurretConnection
--- @param data2 TurretConnection
--- @return true if circuit condition of data1 < circuit condition of data2
local function cmpCond(data1, data2)
    local n1 = data1.num_connections
    local n2 = data2.num_connections
    local cc1 = data1.cc
    local cc2 = data2.cc

    if (n1 == 1) and (n2 == 1) then
        -- both connected to one network => compare circuit conditions (name of 1st signal)
        return (cc1.first_signal.name < cc2.first_signal.name)
    elseif n1 == 1 then
        -- only 1st connected to one network => treat it as smaller
        return true
    elseif n2 == 1 then
        -- only 2nd connected to one network => treat it as smaller
        return false
    else
        -- both are either not connected or connected twice => treat not connected as smaller
        return n1 > n2
    end
end
-- ###############################################################

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
-- ###############################################################

local col_style = {
     [defines.wire_connector_id.circuit_red] =  "red_label",
     [defines.wire_connector_id.circuit_green] =  "green_label",
}

--- @param tc TurretConnection
local function networkCondition(tc)
    local lblcaption, lblstyle, cc
    if tc.num_connections == 1 then
        -- connected once
        lblcaption = tc.network_id
        lblstyle = col_style[tc.connector]
        cc = tc.cc
    elseif tc.num_connections == 0 then
        -- not connected
        lblcaption = { "gui.dart-turret-offline" }
        lblstyle = "bold_red_label"
    else
        -- connected twice
        lblcaption = { "gui.dart-turret-connected-twice" }
        lblstyle = "bold_orange_label"
    end

    return lblcaption, lblstyle, cc
end
-- ###############################################################

local function names(ndx)
    local prefix = "tur_cc_" .. ndx
    local camera = prefix .. "_camera"
    local lbl = prefix .. "_lbl"
    local ceb = prefix .. "_ceb"
    local ddb = prefix .. "_ddb"
    local sig2 = prefix .. "_2ndsig"

    return camera, lbl, ceb, ddb, sig2
end
-- ###############################################################

--- @param table LuaGuiElement table to add row
--- @param v TurretConnection
--- @param at_row number of row
local function appendTableRow(table, v, at_row)
    local lblcaption, lblstyle, cc = networkCondition(v)
    local camera, lbl, ceb, ddb, sig2 = names(at_row)

    local elems, camera_elem = flib_gui.add(table, {
        { type = "camera",
          position = v.turret.position,
          style = "dart_camera",
          zoom = 0.6,
          surface_index = v.turret.surface_index,
          name = camera,
          raise_hover_events = true,
          handler = {
              [defines.events.on_gui_hover] = eventHandler.handlers.camera_hovered,
              [defines.events.on_gui_leave] = eventHandler.handlers.camera_leave,
              [defines.events.on_gui_click] = eventHandler.handlers.clicked,
          }
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
    camera_elem.entity = v.turret
    -- set the values for the choose-elem-button, ...
    if cc then
        local elem = elems[ceb]
        elem.elem_value = cc.first_signal
        elem.locked = true

        elems[ddb].caption = cc.comparator
        elems[sig2].caption = cc.constant -- TODO or second_signal
    end
end
-- ###############################################################

--- @param table LuaGuiElement table for update of row
--- @param v TurretConnection
--- @param at_row number of row
local function updateTableRow(table, v, at_row)
    local lblcaption, lblstyle, cc = networkCondition(v)
    local camera, lbl, ceb, ddb, sig2 = names(at_row)
    local offset = at_row * 3

    local camElem = table[camera]
    if (v.turret.position) then
        camElem.position = v.turret.position
        camElem.surface_index = v.turret.surface_index
        camElem.entity = v.turret
        camElem.enabled = true
    else
        camElem.enabled = false
    end

    table[lbl].caption = lblcaption
    table[lbl].style = lblstyle

    local ccflow = table.children[offset + 3]
    if cc then
        local cebelem = ccflow[ceb]
        cebelem.visible = true
        cebelem.elem_value = cc.first_signal
        cebelem.locked = true

        local ddbelem = ccflow[ddb]
        ddbelem.visible = true
        ddbelem.caption = cc.comparator

        local sig2elem = ccflow[sig2]
        sig2elem.visible = true
        sig2elem.caption = cc.constant -- TODO or second_signal
    else
        ccflow[ceb].visible = false
        ccflow[ddb].visible = false
        ccflow[sig2].visible = false
    end
end
-- ###############################################################

--- @class TurretConnection
--- @field turret LuaEntity
--- @field network_id uint ID of circuit network
--- @field num_connections number of connections to fcc 0 - 2
--- @field cc CircuitCondition
--- @field connector uint defines.wire_connector_id.circuit_red or defines.wire_connector_id.circuit_green

--- @param data TurretOnPlatform[]
--- @param nwOfFcc uint[] IDs of the circuit networks of fcc shown in gui
--- @return TurretConnection[]
local function extractDataForPresentation(data, nwOfFcc)
    local pdata = {}

    for _, top in pairs(data) do
        -- all networks of turret
        local networks = getNetworksOfTurretOnPlatform(top)

        local num_connections = 0 -- how often is the turret connected to fcc
        local nwid, cc, conn

        for connector, nw in pairs(networks) do
            if (nwOfFcc[nw.network_id]) then
                if num_connections > 0 then
                    -- 2nd connection :-/
                    num_connections = 2
                    break
                end
                -- network of turret is connected to fcc managed in gui
                nwid = nw.network_id
                cc = nw.circuit_condition
                conn = connector
                num_connections = 1
            end
        end

        pdata[#pdata + 1] = {
            turret = top.turret,
            network_id = nwid,
            connector = conn,
            cc = cc,
            num_connections = num_connections,
        }
    end

    return pdata
end
-- ###############################################################

local function sort_checkbox(name)
    return components.sort_checkbox( name, nil, false, false, eventHandler.handlers.sort_clicked)
end
-- ###############################################################

local comparators = {
    [sortFields.unit] = cmpPos,
    [sortFields.cn] = cmpNet,
    [sortFields.cond] = cmpCond,
}

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

    local pdata = extractDataForPresentation(data, nwOfFcc)

    -- sort data
    local sorteddata = pdata
    local gae = pd.guis.open

    local sortings = gae.sortings[gae.activeTab] -- turrets are on 2nd tab
    local active = sortings.active
    if (active ~= "") then
        sorteddata = utils.sort(pdata, sortings.sorting[active], comparators[active])
    end

    components.updateVisualizedData(elems, sorteddata, getTableAndTab, appendTableRow, updateTableRow)
end
-- ###############################################################

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
                  sort_checkbox(sortFields.unit),
                  sort_checkbox(sortFields.cn),
                  sort_checkbox(sortFields.cond),
                }
            },
        }
    }
end
-- ###############################################################

return turrets