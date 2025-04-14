---
--- Created by xyzzycgn.
--- DateTime: 13.04.25 21:05
---

local radars = {}

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
                type = "label",
                caption = "radars",
            },
            {
                type = "scroll-pane",
                { type = "table",
                  column_count = 4,
                  draw_horizontal_line_after_headers = true,
                  style = "dart_table_style",
                  name = "radars_table",
                  visible = false,
                  { type = "label", caption = { "gui.dart-radar-id" }, style = "dart_stretchable_label_style", },
                  --{ type = "label", caption = { "gui.dart-radar-status" }, style = "dart_stretchable_label_style", },
                }
            },
        }
    }

end




return radars