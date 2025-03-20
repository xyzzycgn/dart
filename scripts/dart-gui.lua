---
--- Created by xyzzycgn.
--- DateTime: 04.03.25 21:27
---
--- Build the D.A.R.T Main UI window
--- @param player LuaPlayer @ Player object that is opening the combinator
--- @return GuiElemDef
---@diagnostic disable:missing-fields

local flib_gui = require("__flib__.gui")

local dart = {}

function dart.build(player)
  local elems, gui = flib_gui.add(player.gui.screen, {
      {
          type = "frame",
          direction = "vertical",
          visible = false,
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
  return elems, gui
end
-- ###############################################################


--- Handle opening the custom GUI to replace the builtin one when it opens.
--- @param e EventData.on_gui_opened
function dart.on_gui_opened(e)
    local player = game.get_player(e.player_index)
    if not player or player.opened_gui_type ~= defines.gui_type.entity then
        return
    end

    local entity = e.entity
    if not entity or not entity.valid or entity.name ~= "dart-radar" then
        return
    end

    open_gui(player, entity)
end
-- ###############################################################


return dart