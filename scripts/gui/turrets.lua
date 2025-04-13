---
--- Created by xyzzycgn.
--- DateTime: 13.04.25 21:06
---


local turrets = {}

function turrets.build()
    return {
        tab = {
            { type = "tab",
              caption = { "gui.dart-turrets" },
              ref = { "turrets", "tab" },
            }
        },
        content = {
            type = "frame", direction = "vertical",
            style = "dart_deep_frame",
            name = "turrets_tab",
            {
                type = "label",
                caption = "turrets",
                -- name = "trains_label" -- TODO löschen
            },
        }
    }

end




return turrets