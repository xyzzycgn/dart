---
--- Created by xyzzycgn.
--- common definitions used in busted test
---

_G.serpent = require("serpent") -- must be global

_G.defines = {
    direction = {
        east = 4,
        eastnortheast = 3,
        eastsoutheast = 5,
        north = 0,
        northeast = 2,
        northnortheast = 1,
        northnorthwest = 15,
        northwest = 14,
        south = 8,
        southeast = 6,
        southsoutheast = 7,
        southsouthwest = 9,
        southwest = 10,
        west = 12,
        westnorthwest = 13,
        westsouthwest = 11,
    },
    events = {},
    print_sound = {
        use_player_settings = true
    },
    print_skip = {
        if_visible = true
    }
}
-- ###############################################################

_G.storage = {}
-- ###############################################################

local event_num = 1700

_G.script = {
    mod_name = "TEST_OF_MOD",
    generate_event_name = function()
        event_num = event_num + 1
        return event_num
    end,
}
-- ###############################################################

settings = {
    global = {
        ["dart-logLevel"] = { value = 5 }, -- == Log.INFO
    },
    startup = {
        ["dart-update-stock-period"] = { value = 10 },
        ["dart-release-control"] = { value = false },
    }
}
-- ###############################################################

-- Required by Log.log() from log4factorio
function _G.log()
end

-- mock function table_size (normally provided by the game runtime)
function table_size(table)
    if (table) then
        if (type(table) == "table") then
            local count = 0
            for _ in pairs(table) do
                count = count + 1
            end
            return count
        end
    end

    return 0
end

