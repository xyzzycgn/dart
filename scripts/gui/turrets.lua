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
              name = "turrets_tab",
            }
        },
        content = {
            type = "frame", direction = "vertical",
            style = "dart_deep_frame",
            name = "turrets_tab_content",
            {
                -- TODO
                type = "label",
                caption = "turrets",
            },
        }
    }

end




return turrets