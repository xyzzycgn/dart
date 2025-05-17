---
--- Created by xyzzycgn.
--- DateTime: 13.04.25 21:05
---
local Log = require("__log4factorio__.Log")
local flib_gui = require("__flib__.gui")
local components = require("scripts/gui/components")
local utils = require("scripts/utils")
local eventHandler = require("scripts/gui/eventHandler")
local global_data = require("scripts.global_data")
local dump = require("scripts.dump")
local constants = require("scripts.constants")

local radars = {}

local sortFields = {
    unit = "radar-unit",
    detect = "radar-detect",
    defense = "radar-defense",
}

local handlers -- forward declaration

--- @param elems table<string, LuaGuiElement>
local function getTableAndTab(elems)
    return elems.radars_table, elems.radars_tab
end
-- ###############################################################

--- @param data RadarOnPlatform
local function dataOfRow(data)
    Log.logBlock(data, function(m)log(m)end, Log.FINER)

    return data.radar.position, data.radar.surface_index, data.radar.backer_name, data.detectionRange, data.defenseRange
end
-- ###############################################################

--- custom gui for dart-radar for setting defense-radius
--- @param player LuaPlayer
--- @param rop RadarOnPlatform a dart-radar
function radars.buildGui(player, rop)
    local entity = rop.radar
    local elems, gui = flib_gui.add(player.gui.screen, {
        {
            type = "frame",
            direction = "vertical",
            visible = false,
            handler = { [defines.events.on_gui_closed] = eventHandler.handlers.close_gui },
            style = "dart_top_frame",
            style_mods = { maximal_height = 700, },
            {
                type = "flow",
                direction = "horizontal",
                name = "titlebar",
                {
                    type = "label",
                    style = "frame_title",
                    caption = { "entity-name.dart-radar" },
                    ignored_by_interaction = true,
                },
                { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
                {
                    type = "sprite-button",
                    name = "gui_close_button",
                    style = "close_button",
                    sprite = "utility/close",
                    hovered_sprite = "utility/close_black",
                    tooltip = { "gui.dart-close-button-tt" },
                    handler = { [defines.events.on_gui_click] = eventHandler.handlers.close_gui },
                },
            },
            { type = "frame", name = "content_frame", direction = "vertical", style = "dart_content_frame",
                {
                    type = "frame",
                    style = "dart_content_frame",
                    direction = "vertical",
                    {
                        type = "flow",
                        direction = "horizontal",
                        style_mods = { horizontal_align = "center", horizontally_stretchable = true, },
                        {
                            type = "camera",
                            style = "dart_camera_wide",
                            position = entity.position,
                            surface_index = entity.surface_index,
                            name = "radar_view",
                            zoom = 0.50,
                        },
                    },
                    components.radar_slider("zoom-slider", { "gui.dart-radar-zoom-camera" }, 0, 100, 50, handlers.zoom_slider_moved, true),
                },
                {
                    type = "frame",
                    style = "dart_content_frame",
                    direction = "vertical",
                    components.radar_slider("defense-slider", { "gui.dart-radar-defense"}, 0,
                                            constants.max_defenseRange, rop.defenseRange, handlers.defense_slider_moved),
                    components.radar_slider("detect-slider", { "gui.dart-radar-detect" }, 0,
                                            constants.max_detectionRange, rop.detectionRange, handlers.detection_slider_moved),
                },
            }
        }
    })

    elems.titlebar.drag_target = gui

    return elems, gui
end

-- as vanilla radar (and thus also dart-radar) doesn't have a standard gui a special handling is required
--- @param gae GuiAndElements
--- @param event EventData
local function clicked(gae, event)
    Log.logBlock({ gae = gae, event = dump.dumpEvent(event) }, function(m)log(m)end, Log.FINEST)
    local entity = event.element.entity
    local player = game.get_player(event.player_index)
    local rop = global_data.getRadarOnPlatform(entity)
    local elems, gui = radars.buildGui(player, rop)
    rop.edited = true

    ---@type PlayerData
    local pd = components.openNewGui(event.player_index, gui, elems, entity)
    pd.guis.open.dart_gui_type = components.dart_guis.dart_radar_gui
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param gae GuiAndElements
--- @param event EventData
local function zoom_slider_moved(gae, event)
    local slider = event.element
    local val = slider.slider_value
    gae.elems.radar_view.zoom = val / 100
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param gae GuiAndElements
--- @param event EventData
local function detection_slider_moved(gae, event)
    Log.logBlock({ gae = gae, event = dump.dumpEvent(event), element = dump.dumpLuaGuiElement(event.element) }, function(m)log(m)end, Log.FINEST)
    local entity = gae.entity
    local rop = global_data.getRadarOnPlatform(entity)
    local slider = event.element
    local val = slider.slider_value
    rop.detectionRange = val
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param gae GuiAndElements
--- @param event EventData
local function defense_slider_moved(gae, event)
    Log.logBlock({ gae = gae, event = dump.dumpEvent(event), element = dump.dumpLuaGuiElement(event.element) }, function(m)log(m)end, Log.FINEST)
    local entity = gae.entity
    local rop = global_data.getRadarOnPlatform(entity)
    local slider = event.element
    local val = slider.slider_value
    rop.defenseRange = val
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

handlers = {
    radar_clicked = clicked,
    zoom_slider_moved = zoom_slider_moved,
    detection_slider_moved = detection_slider_moved,
    defense_slider_moved = defense_slider_moved,
}

-- register local handlers in flib
flib_gui.add_handlers(handlers, function(e, handler)
    local guiAndElements = global_data.getPlayer_data(e.player_index).guis.open
    if guiAndElements then
        handler(guiAndElements, e)
    end
end)
-- ###############################################################

local function names(ndx)
    local prefix = "radar_" .. ndx
    local cframe = prefix .. "_cframe"
    local camera = prefix .. "_camera"
    local bn = prefix .. "_backername"
    local det = prefix .. "_detect"
    local def = prefix .. "_defense"

    return cframe, camera, bn, det, def
end

--- @param v RadarOnPlatform
local function appendTableRow(table, v, at_row)
    local position, surface_index, name, detect, defense = dataOfRow(v)
    local cframe, camera, bn, det, def = names(at_row)
    local elems, _ = flib_gui.add(table, {
        {
            type = "frame",
            direction = "vertical",
            name = cframe,
            { type = "camera",
              position = position,
              style = "dart_camera",
              zoom = 0.6,
              surface_index = surface_index,
              name = camera,
              raise_hover_events = true,
              handler = {
                  [defines.events.on_gui_hover] = eventHandler.handlers.camera_hovered,
                  [defines.events.on_gui_leave] = eventHandler.handlers.camera_left,
                  [defines.events.on_gui_click] = handlers.radar_clicked,
              }
            },
            { type = "label", style = "dart_minimap_label", name = bn, caption = name },
        },
        { type = "label", style = "dart_stretchable_label_style", name = det, caption = detect },
        { type = "label", style = "dart_stretchable_label_style", name = def, caption = defense },
    })

    elems[camera].entity = v.radar
end
-- ###############################################################

--- @param v RadarOnPlatform
local function updateTableRow(table, v, at_row)
    local position, surface_index, name, detect, defense = dataOfRow(v)
    local cframe, camera, bn, det, def = names(at_row)
    local cframeElem = table[cframe]
    local camElem = cframeElem[camera]
    if (position) then
        camElem.position = position
        camElem.surface_index = surface_index
        camElem.entity = v.radar
        camElem.enabled = true
    else
        camElem.enabled = false
    end
    cframeElem[bn].caption = name
    table[det].caption = detect
    table[def].caption = defense
end
-- ###############################################################

local function sort_checkbox(name)
    return components.sort_checkbox( name, nil, false, false, eventHandler.handlers.sort_clicked)
end
-- ###############################################################

--- @param data1 RadarOnPlatform
--- @param data2 RadarOnPlatform
--- @return true if backer_name of data1 < backer_name of data2
local function cmpUnit(data1, data2)
    return data1.radar.backer_name < data2.radar.backer_name
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param data1 RadarOnPlatform
--- @param data2 RadarOnPlatform
--- @return true if data1.detectionRange < data2.detectionRange
local function cmpDetect(data1, data2)
    return data1.detectionRange < data2.detectionRange
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param data1 RadarOnPlatform
--- @param data2 RadarOnPlatform
--- @return true if data1.defenseRange < data2.defenseRange
local function cmpDefense(data1, data2)
    return data1.defenseRange < data2.defenseRange
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local comparators = {
    [sortFields.unit] = cmpUnit,
    [sortFields.detect] = cmpDetect,
    [sortFields.defense] = cmpDefense,
}

--- @param elems GuiAndElements
--- @param data RadarOnPlatform[]
--- @param pd PlayerData
function radars.update(elems, data, pd)
    Log.logBlock(data, function(m)log(m)end, Log.FINER)

    -- sort data
    local sorteddata = data
    local gae = pd.guis.open

    local sortings = gae.sortings[gae.activeTab] -- radars are on 1st tab
    local active = sortings.active
    if (active ~= "") then
        sorteddata = utils.sort(data, sortings.sorting[active], comparators[active])
    end

    components.updateVisualizedData(elems, sorteddata, getTableAndTab, appendTableRow, updateTableRow)
end
-- ###############################################################

---  @return Sortings defaults for the turret tab
function radars.sortings()
    return {
        sorting = {
            [sortFields.unit] = false,
            [sortFields.detect] = false,
            [sortFields.defense] = false,
        },
        active = ""
    }
end
-- ###############################################################

--- @return any content for the radars tab
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
                  column_count = 3,
                  draw_horizontal_line_after_headers = true,
                  style = "dart_table_style",
                  name = "radars_table",
                  visible = false,
                  sort_checkbox(sortFields.unit),
                  sort_checkbox(sortFields.detect),
                  sort_checkbox(sortFields.defense),
               }
            },
        }
    }
end
-- ###############################################################

return radars