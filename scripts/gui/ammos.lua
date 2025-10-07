---
--- Created by xyzzycgn.
--- DateTime: 03.06.25 20:23
---
local flib_gui = require("__flib__.gui")
local Log = require("__log4factorio__.Log")
local dump = require("scripts.dump")
local utils = require("scripts/utils")
local global_data = require("scripts.global_data")
local components = require("scripts/gui/components")
local eventHandler = require("scripts/gui/eventHandler")

local ammos = {}

local handlers -- forward declaration

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

--- @param v AmmoWarningThresholdAndStock
local function dataOfRow(v)
    local ammo = v.threshold.type
    local stock = v.stockInHub or 0
    local enabled = v.threshold.enabled
    local th_val = v.threshold.threshold

    return ammo, stock, enabled, th_val
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param button LuaGuiElement the sprite-button
--- @param v number its number to be shown
--- @param k string|nil containing the item, i.e. "item=firearm-magazine"
local function setStock(button, v, k)
    button.number = v
    if k then
        button.elem_tooltip = { type="item", name=string.gsub(k, "item=", "")}
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- perform needed updates of fields
--- @param updateAllFields boolean if false only set non input fields (prevent inputs made by user from being overridden)
--- @param table LuaGuiElement table for update of row
--- @param v AmmoWarningThresholdAndStock
--- @param at_row number of row
local function allUpdateOfTableRow(updateAllFields, table, v, at_row)
    Log.logBlock(table, function(m)log(m)end, Log.FINER)
    Log.logBlock(table.children_names, function(m)log(m)end, Log.FINEST)

    local prefix, slot, switch, threshold = names(at_row)

    Log.logBlock({slot=slot, switch=switch, threshold=threshold}, function(m)log(m)end, Log.FINER)

    local ammo, stock, enabled, th_val = dataOfRow(v)
    local offset = at_row * 3 + 1

    if updateAllFields then
        table[switch].switch_state = components.switchState(enabled)
        --- @type LuaGuiElement
        local tfield = table[threshold]
        tfield.enabled = enabled
        tfield.text = "" .. th_val
    end

    local item = "item=" .. ammo
    components.updateSpritesInSlots(table.children[offset], { [item] = stock }, setStock)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- perform only updates of non input fields
--- @param table LuaGuiElement table for update of row
--- @param v AmmoWarningThresholdAndStock
--- @param at_row number of row
local function updateTableRow(table, v, at_row)
    allUpdateOfTableRow(false, table, v, at_row)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- perform updates of all fields
--- @param table LuaGuiElement table for update of row
--- @param v AmmoWarningThresholdAndStock
--- @param at_row number of row
local function updateFullTableRow(table, v, at_row)
    allUpdateOfTableRow(true, table, v, at_row)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param table LuaGuiElement table to add row
--- @param v AmmoWarningThreshold
--- @param at_row number of row
local function appendTableRow(table, v, at_row)
    Log.logBlock(v, function(m)log(m)end, Log.FINER)

    local prefix, slot, switch, threshold = names(at_row)
    local ammo, stock, enabled, th_val = dataOfRow(v)

    local elems, _ = flib_gui.add(table, {
        components.slot_table(prefix, 1),
        {
            type = "switch",
            left_label_caption = { "gui.dart-ammo-enable-warn-left" },
            right_label_caption = { "gui.dart-ammo-enable-warn-right" },
            name = switch,
            switch_state = components.switchState(enabled),
            handler = { [defines.events.on_gui_switch_state_changed] = handlers.switch_changed, }
        },
        {
            type = "textfield",
            numeric = true,
            text = th_val,
            name = threshold,
            enabled = enabled,
            handler = { [defines.events.on_gui_text_changed] = handlers.threshold_changed, }
        },
    })

    local item = "item=" .. ammo
    components.addSprites2Slots(elems[slot], { [item] = stock }, setStock)
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

--- @param data1 AmmoWarningThresholdAndStock
--- @param data2 AmmoWarningThresholdAndStock
--- @return true if data1.stockInHub < data2.stockInHub
local function cmpType(data1, data2)
    return data1.stockInHub < data2.stockInHub
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param data1 AmmoWarningThresholdAndStock
--- @param data2 AmmoWarningThresholdAndStock
--- @return true if data1.threshold.enabled < data2.threshold.enabled (false considered < true)
local function cmpEnableWarn(data1, data2)
    local d1 = data1.threshold.enabled and 1 or 0
    local d2 = data2.threshold.enabled and 1 or 0
    return d1 < d2
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param data1 AmmoWarningThresholdAndStock
--- @param data2 AmmoWarningThresholdAndStock
--- @return true if data1.threshold.threshold < data2.threshold.threshold
local function cmpThreshold(data1, data2)
    return data1.threshold.threshold < data2.threshold.threshold
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param thresholds AmmoWarningThreshold[]
--- @param inv table<string, uint> List of all suitable ammos in the inventory of the Hub.
--- @return AmmoWarningThresholdAndStock[]
local function presentationData(thresholds, inv)
    Log.logBlock(thresholds, function(m)log(m)end, Log.FINER)

    local pdata = {}
    for ammo, threshold in pairs(thresholds) do
        local ad = {
            threshold = threshold,
            stockInHub = inv and inv[ammo] or 0,
        }
        pdata[#pdata + 1] = ad
    end

    return pdata
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param elems GuiAndElements
--- @param pons Pons
function ammos.dataForPresentation(elems, pons)
    -- fcc managed in gui
    local entity = elems.entity
    local fop = pons.fccsOnPlatform[entity.unit_number]

    return presentationData(fop.ammo_warning.thresholds, pons.ammoInStockPerType)
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
    Log.log("ammos.update", function(m)log(m)end, Log.FINE)
    --- @type FccOnPlatform[]
    local data = pons.fccsOnPlatform

    -- fcc entity managed in gui
    local entity = elems.entity
    -- corresponding FccOnPlatform
    local fop = data[entity.unit_number]

    local sorteddata = presentationData(fop.ammo_warning.thresholds, pons.ammoInStockPerType)
    Log.logBlock(sorteddata, function(m)log(m)end, Log.FINER)

    local gae = pd.guis.open

    Log.logLine(gae, function(m)log(m)end, Log.FINE)

    local sortings = gae.sortings[gae.activeTab] -- ammos are on 3rd tab
    local active = sortings.active
    if (active ~= "") then
        sorteddata = utils.sort(sorteddata, sortings.sorting[active], comparators[active])
    end

    Log.logLine(gae.fields_initialized, function(m)log(m)end, Log.FINE)
    components.updateVisualizedData(elems, sorteddata, getTableAndTab, appendTableRow,
                     gae.fields_initialized and updateTableRow or updateFullTableRow)
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
            {
                type = "frame",
                style = "dart_bottom_button_frame",
                {
                    type = "button",
                    style = "dart_bottom_button",
                    caption = { "gui.dart-ammo-save" },
                    name = "ammos_save",
                    handler = { [defines.events.on_gui_click] = handlers.save_clicked, }
                },
            }
        }
    }
end
-- ###############################################################

--- @param gae GuiAndElements
--- @param event EventData
local function save_clicked(gae, event)
    Log.logBlock(gae.elems, function(m)log(m)end, Log.FINEST)
    Log.logBlock({ gae = gae, event = dump.dumpEvent(event) }, function(m)log(m)end, Log.FINE)
    local pd = global_data.getPlayer_data(event.player_index)
    local platform = gae.entity.surface.platform
    local pons = pd.pons[platform.index]
    --
    local fop = pons.fccsOnPlatform[gae.entity.unit_number]
    -- old values (may need update)
    local thresholds = fop.ammo_warning.thresholds

    local sorteddata = presentationData(fop.ammo_warning.thresholds, pons.ammoInStockPerType)
    Log.logBlock( sorteddata, function(m)log(m)end, Log.FINE)

    for ndx, v in pairs(sorteddata) do
        local _, _, switch, threshold = names(ndx)
        local onOff = components.switchStateAsBoolean(gae.elems["ammos_table"][switch].switch_state)

        local awt = thresholds[v.threshold.type]
        if onOff then
            local newthreshold = gae.elems["ammos_table"][threshold].text
            awt.threshold = tonumber(newthreshold) or 0
            awt.enabled = true
            Log.logLine({ onOff = onOff, newthreshold = awt.threshold }, function(m)log(m)end, Log.CONFIG)
        else
            Log.logLine(onOff, function(m)log(m)end, Log.CONFIG)
            awt.enabled = false
        end
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- en-/disables threshold depending on state of switch
--- @param gae GuiAndElements
--- @param event EventData
local function switch_changed(gae, event)
    Log.logBlock({ gae = gae,
                   event = dump.dumpEvent(event),
                   elem = dump.dumpLuaGuiElement(event.element) }, function(m)log(m)end, Log.FINER)
    local switch = event.element
    local onOff = switch.switch_state
    local name = switch.name
    local thres_name = string.gsub(name, "_switch", "_threshold")
    local thres = gae.elems["ammos_table"][thres_name]

    Log.logBlock({ name = name, onOff = onOff, thres_name = thres_name, thres = dump.dumpLuaGuiElement(thres) },
                 function(m)log(m)end, Log.FINE)
    thres.enabled = components.switchStateAsBoolean(onOff)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


handlers = {
    save_clicked = save_clicked,
    switch_changed = switch_changed,
}

-- register local handlers in flib
components.add_handler(handlers)
-- ###############################################################

return ammos