---
--- Created by xyzzycgn.
--- DateTime: 03.06.25 20:23
---
local flib_gui = require("__flib__.gui")
local components = require("scripts/gui/components")
local Log = require("__log4factorio__.Log")
local utils = require("scripts/utils")
local Hub = require("scripts.Hub")
local eventHandler = require("scripts/gui/eventHandler")

local ammos = {}

local sortFields = {
    type = "ammo-type",
    enable_warn = "ammo-enable-warn",
    threshold = "ammo-threshold",
}
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function names(ndx)
    local prefix = "ammos_" .. ndx
    local slot = prefix .. "_slot_table"
    local switch = prefix .. "_switch"
    local threshold = prefix .. "_threshold"

    return prefix, slot, switch, threshold
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param elems table<string, LuaGuiElement>
local function getTableAndTab(elems)
    return elems.ammos_table, elems.ammos_tab
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param v AmmoWarningThreshold
local function dataOfRow(v)
    local ammo = v.type
    local enabled = v.enabled
    local th_val = v.threshold

    return ammo, enabled, th_val
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param table LuaGuiElement table for update of row
--- @param v AmmoWarningThreshold
--- @param at_row number of row
local function updateTableRow(table, v, at_row)
    local slot, switch, threshold = names(at_row)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param table LuaGuiElement table to add row
--- @param v AmmoWarningThreshold
--- @param at_row number of row
local function appendTableRow(table, v, at_row)
    Log.logBlock(v, function(m)log(m)end, Log.FINE)

    local prefix, slot, switch, threshold = names(at_row)
    local ammo, enabled, th_val = dataOfRow(v)

    local elems, slot_table = flib_gui.add(table, {
        components.slot_table(prefix, 1),
        {
            type = "switch",
            left_label_caption = { "gui.dart-ammo-enable-warn-left" },
            right_label_caption = { "gui.dart-ammo-enable-warn-right" },
            name = switch,
            switch_state = components.switchState(enabled)
        },
        { type = "textfield", numeric = true, text = th_val, name = threshold, enabled = enabled },
    })

    local item = "item=" .. ammo
    components.addSprites2Slots(elems[slot], { [item] = 8000 })
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
            [sortFields.type] = false,
            [sortFields.enable_warn] = false,
            [sortFields.threshold] = false,
        },
        active = ""
    }
end
-- ###############################################################

--- @param data1 ???
--- @param data2 ??
--- @return true if ???
local function cmpType(data1, data2)
    --return data1.radar.backer_name < data2.radar.backer_name
    return true -- TODO
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param data1 ???
--- @param data2 ??
--- @return true if ???
local function cmpEnableWarn(data1, data2)
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
    [sortFields.type] = cmpType,
    [sortFields.enable_warn] = cmpEnableWarn,
    [sortFields.threshold] = cmpThreshold,
}

--- @param elems GuiAndElements
--- @param pons Pons
--- @param pd PlayerData
function ammos.update(elems, pons, pd)
    --- @type FccOnPlatform[]
    local data = pons.fccsOnPlatform

    local inv = Hub.getInventoryOfHub(pons)
    Log.logBlock({ platform = pons.platform.name, inv=inv }, function(m)log(m)end, Log.FINE)

    -- fcc entity managed in gui
    local entity = elems.entity
    -- corresponding FccOnPlatform
    local fop = data[entity.unit_number]

    local sorteddata = fop.ammo_warning.thresholds
    Log.logBlock(sorteddata, function(m)log(m)end, Log.FINE)

    local gae = pd.guis.open

    local sortings = gae.sortings[gae.activeTab] -- ammos are on 3rd tab
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
                  sort_checkbox(sortFields.type),
                  sort_checkbox(sortFields.enable_warn),
                  sort_checkbox(sortFields.threshold),
                }
            },
        }
    }
end
-- ###############################################################

return ammos