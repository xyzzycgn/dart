---
--- Created by xyzzycgn.
--- DateTime: 04.03.25 21:27
---
--- Build the D.A.R.T Main UI window
--- @param player LuaPlayer @ Player object that is opening the combinator
--- @return GuiElemDef
---@diagnostic disable:missing-fields

local Log = require("__log4factorio__.Log")
local dump = require("scripts.dump")
local global_data = require("scripts.global_data")
local PlayerData = require("scripts.player_data")

local flib_gui = require("__flib__.gui")

local function close(gui, event)
    Log.logBlock(event, function(m)log(m)end, Log.FINE)
    Log.logBlock(gui, function(m)log(m)end, Log.FINE)
    local pd = global_data.getPlayer_data(event.player_index)
    pd.guis.main = nil
    gui.visible = false
    gui.destroy()
end

local handlers = {
    close_gui = close
}

flib_gui.add_handlers(handlers, function(e, handler)
    local self = global_data.getPlayer_data(e.player_index).guis.main
    if self then
        handler(self, e)
    end
end)


-- ###############################################################

--- creates the custom gui
--- @param player LuaPlayer who opens the entity
--- @param entity Entity to be shown in the GUI
local function build(player, entity)
  local elems, gui = flib_gui.add(player.gui.screen, {
      {
          type = "frame",
          direction = "vertical",
          visible = false,
          handler = { [defines.events.on_gui_closed] = handlers.close_gui},
          --style = "rldman_top_frame",
          {
              type = "flow",
              direction = "horizontal",
              name = "titlebar",
              {
                  type = "label",
                  style = "frame_title",
                  caption = { "mod-name.dart" },
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
                  handler = { [defines.events.on_gui_click] = handlers.close_gui },
             },
          },
          { type = "frame", name = "content_frame", direction = "vertical", -- style = "rldman_content_frame",
            {
                type = "label",
                caption = "Huhu GUI",
                name = "main_label_TBDel"
            }
          }
      }
  })

   elems.titlebar.drag_target = gui


    return elems, gui
end
-- ###############################################################

local function open(gui)
    gui.force_auto_center()
    gui.bring_to_front()
    gui.visible = true
end
-- ###############################################################

local function gui_open(event)
    local entity = event.entity
    if event.gui_type == defines.gui_type.entity and entity.type == "constant-combinator" and entity.name == "dart-output" then
        Log.logBlock(event, function(m)log(m)end, Log.FINE)
        Log.logBlock(defines.gui_type, function(m)log(m)end, Log.FINEST)

        local pd = global_data.getPlayer_data(event.player_index)
        Log.logBlock(pd, function(m)log(m)end, Log.FINER)

        if (pd == nil) then
            local p = game.get_player(event.player_index)
            pd = PlayerData.init_player_data(p)
            global_data.addPlayer_data(p, pd)
        end

        local player = game.get_player(event.player_index)
        Log.logBlock(player, function(m)log(m)end, Log.FINE)
        local elems, gui = build(player, entity)
        Log.logBlock(gui, function(m)log(m)end, Log.FINE)
        Log.logBlock(elems, function(m)log(m)end, Log.FINE)
        player.opened = gui
        -- store reference to gui in storage
        pd.guis.main = gui

        -- dart-output
        local un = entity.unit_number
        Log.logBlock(un, function(m)log(m)end, Log.FINE)
        local dart = global_data.getPlatforms[entity.surface.index].dartsOnPlatform(un)
        Log.logBlock(dump.dumpControlBehavior(dart.control_behavior), function(m)log(m)end, Log.FINE)

        open(gui)
    end
end

-- GUI events - TBC
local dart_gui = {}

dart_gui.events = {
    [defines.events.on_gui_opened] = gui_open,
}

return dart_gui