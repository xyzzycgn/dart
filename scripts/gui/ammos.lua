---
--- Created by xyzzycgn.
--- DateTime: 03.06.25 20:23
---
local flib_gui = require("__flib__.gui")
local components = require("scripts/gui/components")
local Log = require("__log4factorio__.Log")
local utils = require("scripts/utils")
local eventHandler = require("scripts/gui/eventHandler")

local ammos = {}

local sortFields = {
    slot = "ammos-slot",
    switch = "ammos-switch",
    threshold = "ammos-threshold",
}
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function names(ndx)
    local prefix = "ammos_" .. ndx
    local slot = prefix .. "_slot"
    local switch = prefix .. "_switch"
    local threshold = prefix .. "_threshold"

    return slot, switch, threshold
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param elems table<string, LuaGuiElement>
local function getTableAndTab(elems)
    return elems.ammos_table, elems.ammos_tab
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param table LuaGuiElement table for update of row
--- @param v TurretConnection
--- @param at_row number of row
local function updateTableRow(table, v, at_row)
    local slot, switch, threshold = names(at_row)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param table LuaGuiElement table to add row
--- @param v TurretConnection
--- @param at_row number of row
local function appendTableRow(table, v, at_row)
    local slot, switch, threshold = names(at_row)
    local elems, slot_table = flib_gui.add(table, {
        components.slot_table(slot, 1),
        { type = "switch", left_label_caption = "aus", right_label_caption = "an", name = switch },
        { type = "label", caption = "123", name = threshold }, -- TODO
    })

    Log.logBlock(elems, function(m)log(m)end, Log.FINE)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function sort_checkbox(name)
    return components.sort_checkbox( name, nil, false, false, eventHandler.handlers.sort_clicked)
end
-- ###############################################################

---  @return Sortings defaults for the turret tab
function ammos.sortings()
    return {
        sorting = {
            [sortFields.slot] = false,
            [sortFields.switch] = false,
            [sortFields.threshold] = false,
        },
        active = ""
    }
end
-- ###############################################################

--- @param data1 ???
--- @param data2 ??
--- @return true if ???
local function cmpSlot(data1, data2)
    --return data1.radar.backer_name < data2.radar.backer_name
    return true -- TODO
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param data1 ???
--- @param data2 ??
--- @return true if ???
local function cmpSwitch(data1, data2)
    --return data1.detectionRange < data2.detectionRange
    return true -- TODO
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param data1 ???
--- @param data2 ??
--- @return true if ???
local function cmpThreshold(data1, data2)
    --return data1.defenseRange < data2.defenseRange
    return true -- TODO
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local comparators = {
    [sortFields.slot] = cmpSlot,
    [sortFields.switch] = cmpSwitch,
    [sortFields.threshold] = cmpThreshold,
}

--- @param elems GuiAndElements
--- @param data FccOnPlatform[]
--- @param pd PlayerData
function ammos.update(elems, data, pd)
    -- fcc managed in gui
    local entity = elems.entity

    local shownFcc = data[entity.unit_number]

    local sorteddata = shownFcc.ammo_warning.thresholds
    Log.logBlock(sorteddata, function(m)log(m)end, Log.FINE)

    local gae = pd.guis.open

    local sortings = gae.sortings[gae.activeTab] -- radars are on 1st tab
    local active = sortings.active
    if (active ~= "") then
        sorteddata = utils.sort(data, sortings.sorting[active], comparators[active])
    end

    components.updateVisualizedData(elems, sorteddata, getTableAndTab, appendTableRow, updateTableRow)
end
-- ###############################################################

function ammos.build()
    return {
        tab = {
            { type = "tab",
              caption = { "gui.dart-ammos" },
              name = "ammos_tab",
            }
        },
        content = {
            type = "frame", direction = "vertical",
            style = "dart_deep_frame",
            name = "ammos_tab_content",
            {
                type = "scroll-pane",
                { type = "table",
                  column_count = 3,
                  draw_horizontal_line_after_headers = true,
                  style = "dart_table_style",
                  name = "ammos_table",
                  visible = true, -- TODO false
                  sort_checkbox(sortFields.slot),
                  sort_checkbox(sortFields.switch),
                  sort_checkbox(sortFields.threshold),
                }
            },
        }
    }
end
-- ###############################################################

return ammos