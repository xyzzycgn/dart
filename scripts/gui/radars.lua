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
              ref = { "radars", "tab" },
            }
        },
        content = {
            type = "frame", direction = "vertical",
            style = "dart_deep_frame",
            name = "radars_tab",
            {
                type = "label",
                caption = "radars",
                -- name = "trains_label" -- TODO löschen
            },
        }
    }

end




return radars