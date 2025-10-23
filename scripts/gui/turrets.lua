---
--- Created by xyzzycgn.
--- DateTime: 13.04.25 21:06
---
local flib_gui = require("__flib__.gui")
local Log = require("__log4factorio__.Log")
local dump = require("__log4factorio__.dump")
local global_data = require("scripts.global_data")
local components = require("scripts/gui/components")
local utils = require("scripts/utils")
local eventHandler = require("scripts/gui/eventHandler")
local configureTurrets = require("scripts/ConfigureTurrets")

local turrets = {}
local handlers -- forward declaration
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
--- @field circuit_enable_disable boolean

--- @param top TurretOnPlatform
--- @return Network[] indexed by connector (circuit_red/circuit_green)
local function getNetworksOfTurretOnPlatform(top)
    local networks = {}
    local cb = top.control_behavior

    for connector, wc in pairs(redAndGreenWC) do
        ---  @type LuaCircuitNetwork
        local cn = cb.valid and cb.get_circuit_network(wc)

        if cn then
            --- @type Network
            networks[connector] = {
                network_id = cn.network_id,
                -- we assume that cb still is valid here. If not - that is really bad karma ;-)
                circuit_condition = cb.circuit_condition,
                circuit_enable_disable = cb.circuit_enable_disable,
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
    local cc1 = data1.cc
    local cc2 = data2.cc
    local valid1 = utils.checkCircuitCondition(cc1)
    local valid2 = utils.checkCircuitCondition(cc2)

    if valid1 and valid2 then
        -- further comparisions only if both CircuitCondtions are valid for use in D.A.R.T
        local n1 = data1.num_connections
        local n2 = data2.num_connections
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
    else
        return not valid1 -- treat cc1 as smaller if it's not valid - covers the other 3 cases too
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

local ccInvalidCapsAndStyles = {
    [utils.CircuitConditionChecks.firstSignalEmpty]         = { { "gui.dart-turret-1stsignal-empty" }, "bold_orange_label" },
    [utils.CircuitConditionChecks.secondSignalNotSupported] = { { "gui.dart-turret-2ndsignal-unsupported" }, "bold_orange_label" },
    [utils.CircuitConditionChecks.invalidComparator]        = { { "gui.dart-turret-invalidComparator" }, "bold_orange_label" },
    [utils.CircuitConditionChecks.noFalse]                  = { { "gui.dart-turret-noFalse" }, "bold_orange_label" },
    [utils.CircuitConditionChecks.noTrue]                   = { { "gui.dart-turret-noTrue" }, "bold_orange_label" },
    [utils.CircuitConditionChecks.unknown]                  = { { "gui.dart-turret-unknown" }, "bold_red_label" },
}

--- @param tc TurretConnection
local function networkCondition(tc)
    local lblcaption, lblstyle, cc

    local state = configureTurrets.checkNetworkCondition(tc);

    -- emulate case switch - lua is so ...
    local actions = {
        -- not connected
        [configureTurrets.states.notConnected] = function()
            lblcaption = { "gui.dart-turret-offline" }
            lblstyle = "bold_red_label"
        end,
        -- connected twice
        [configureTurrets.states.connectedTwice] = function()
            lblcaption = { "gui.dart-turret-connected-twice" }
            lblstyle = "bold_orange_label"
        end,
        -- connected to multiple fccs
        [configureTurrets.states.connectedToMultipleFccs] = function()
            lblcaption = { "gui.dart-turret-connected-to-multiple-fccs" }
            lblstyle = "bold_orange_label"
        end,
        -- circuit network disabled in turret
        [configureTurrets.states.circuitNetworkDisabledInTurret] = function()
            lblcaption = { "gui.dart-turret-not-controlled" }
            lblstyle = "bold_orange_label"
            -- see ticket #53
            tc.mayBeAutoConfigured = true
            tc.stateConfiguration = state
        end,
        -- the CircuitCondition is valid for use in D.A.R.T.
        [configureTurrets.states.ok] = function()
            lblcaption = tc.network_id
            lblstyle = col_style[tc.connector]
            cc = tc.cc
        end,
    }

    local meta = { __index = function(t, key)
        return function()
            Log.logLine(key, function(m)log(m)end, Log.FINER)
            local capStyle = ccInvalidCapsAndStyles[key] or ccInvalidCapsAndStyles[utils.CircuitConditionChecks.unknown]
            lblcaption =  capStyle[1]
            lblstyle = capStyle[2]
            -- single connection, but not well configured (see ticket #53)
            tc.mayBeAutoConfigured = true
            tc.stateConfiguration = state
        end -- default for case/switch
    end }

    setmetatable(actions, meta)

    Log.logLine(state, function(m)log(m)end, Log.FINER)
    actions[state]()

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
              [defines.events.on_gui_leave] = eventHandler.handlers.camera_left,
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
        elems[sig2].caption = cc.constant
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
        sig2elem.caption = cc.constant
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
--- @field circuit_enable_disable boolean true if the turret enable/disable state is controlled by circuit condition
--- @field managedBy uint[] IDs of the circuit networks (of fccs) connected to this turret
--- @field mayBeAutoConfigured boolean? (optional) indicates a not well configured connection to a turret, which may be
---        automatically configured (see ticket #53)
--- @field stateConfiguration number? indicates the misconfiguration
---
--- @param data TurretOnPlatform[]
--- @param nwOfFcc uint[] IDs of the circuit networks of fcc shown in gui
--- @param otherFccsNetworks uint[] IDs of the circuit networks of other fccs of platform (those not shown in gui)
--- @return TurretConnection[]
local function extractDataForPresentation(data, nwOfFcc, otherFccsNetworks)
    local pdata = {}

    for _, top in pairs(data) do
        if top.turret.valid then
            -- all networks of turret
            local networks = getNetworksOfTurretOnPlatform(top)

            local num_connections = 0 -- how often is the turret connected to fcc
            local nwid, cc, conn, circuit_enable_disable
            local managedBy = {}

            for connector, nw in pairs(networks) do
                if nwOfFcc[nw.network_id] then
                    managedBy[nw.network_id] = true
                    if num_connections > 0 then
                        -- 2nd connection :-/
                        num_connections = 2
                        break
                    end
                    -- network of turret is connected to fcc managed in gui
                    nwid = nw.network_id
                    cc = nw.circuit_condition
                    circuit_enable_disable = nw.circuit_enable_disable
                    conn = connector
                    num_connections = 1
                elseif otherFccsNetworks[nw.network_id] then
                    -- turret is connected to another fcc
                    managedBy[nw.network_id] = true
                end
            end

            --[[
            at this point we can have these combinations (other combinations are not possible)
            num_connections | managedBy           | intended behaviour
                 0          |  {}                 | show message "uncontrolled"
                 0          |  { ofcc }           | suppress (turret is managed by other fcc)
                 0          |  { ofcc1, ofcc2 }   | suppress (turret is managed by multiple other fccs, has to be managed there)
                 1          |  { fcc }            | show (turret is managed by this fcc)
                 1          |  { fcc, ofcc, ... } | show message "multiple fccs" (condition is more than 1 entry in managedBy)
                 2          |  { fcc }            | show message "connected twice"
                 2          |  { fcc, ofcc, ... } | show message "connected twice" (has precedence before "multiple fccs")
            ]]

            -- suppress this turret if num_connections == 0 and managedBy ~= {}
            if (num_connections > 0) or (table_size(managedBy) == 0) then
                pdata[#pdata + 1] = {
                    turret = top.turret,
                    network_id = nwid,
                    connector = conn,
                    cc = cc,
                    num_connections = num_connections,
                    circuit_enable_disable = circuit_enable_disable,
                    managedBy = managedBy,
                }
            end
        else
            Log.logBlock("ignored invalid turret during display", function(m)log(m)end, Log.WARN)
        end
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
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function getNetworkOfFcc(fcc, networks)
    for _, wc in pairs(redAndGreenWC) do
        -- get the circuit networks of fcc in gui
        local cn = fcc.get_circuit_network(wc)
        if cn then
            networks[cn.network_id] = true
        end
    end
end
-- ###############################################################

--- @param elems GuiAndElements
--- @param pons Pons
function turrets.dataForPresentation(elems, pons)
    local data = pons.turretsOnPlatform
    -- fcc managed in gui
    local entity = elems.entity

    -- look for FCCs networks
    local otherFccsNetworks = {}
    local nwOfFcc = {}
    for _, ofcc in pairs(pons.fccsOnPlatform) do
        if ofcc.fcc_un == entity.unit_number then
            -- get the circuit networks of fcc in gui
            getNetworkOfFcc(entity, nwOfFcc)
        else
            -- other fcc on platform
            getNetworkOfFcc(ofcc.fcc, otherFccsNetworks)
        end
    end

    Log.logLine(nwOfFcc, function(m)log(m)end, Log.FINER)
    Log.logLine(otherFccsNetworks, function(m)log(m)end, Log.FINER)

    return extractDataForPresentation(data, nwOfFcc, otherFccsNetworks)
end
-- ###############################################################

--- @param gae GuiAndElements
--- @param pons Pons
--- @param pd PlayerData
function turrets.update(gae, pons, pd)
    local pdata = turrets.dataForPresentation(gae, pons)
    -- sort data
    local sorteddata = pdata
    local sortings = gae.sortings[gae.activeTab] -- turrets are on 2nd tab
    local active = sortings.active
    if (active ~= "") then
        sorteddata = utils.sort(pdata, sortings.sorting[active], comparators[active])
    end

    components.updateVisualizedData(gae, sorteddata, getTableAndTab, appendTableRow, updateTableRow)
    -- sorteddata now also contains the result of checking the need/possibility for autoConfigure turrets
    local mayBeAutoConfigured = {}

    for k, v in pairs(sorteddata) do
        if v.mayBeAutoConfigured then
            mayBeAutoConfigured[#mayBeAutoConfigured + 1] = v
        end
    end

    Log.logBlock(mayBeAutoConfigured, function(m)log(m)end, Log.FINE)
    -- show button if needed and autoConfigure is possible
    gae.elems.turrets_bottom_button_frame.visible = table_size(mayBeAutoConfigured) > 0
    gae.mayBeAutoConfigured = mayBeAutoConfigured -- remember misconfigured
    Log.logBlock(gae, function(m)log(m)end, Log.FINER)
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
            {
                type = "frame",
                style = "dart_bottom_button_frame",
                visible = false,
                name = "turrets_bottom_button_frame",
                {
                    type = "flow",
                    style = "dart_bottom_button_flow",
                    {
                        type = "button",
                        caption = { "gui.dart-turret-autoconfigure" },
                        name = "turrets_autoconfigure",
                        handler = { [defines.events.on_gui_click] = handlers.autoconfigure, }
                    },
                }
            }
        }
    }
end
-- ###############################################################

--- @param gae GuiAndElements
--- @param event EventData
local function autoconfigure(gae, event)
    Log.logBlock(gae.elems, function(m)log(m)end, Log.FINEST)
    Log.logBlock({ gae = gae, event = dump.dumpEvent(event) }, function(m)log(m)end, Log.FINE)

    local pd = global_data.getPlayer_data(event.player_index)
    local platform = gae.entity.surface.platform
    local pons = pd.pons[platform.index]


    configureTurrets.autoConfigure(gae.mayBeAutoConfigured, pons)

    script.raise_event(on_dart_gui_needs_update_event, { player_index = event.player_index, entity = gae.entity })
end
-- ###############################################################

handlers = {
    autoconfigure = autoconfigure,
}

-- register local handlers in flib
components.add_handler(handlers)

return turrets