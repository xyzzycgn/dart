---
--- Created by xyzzycgn.
--- common definitions used in busted test
---

defines = {
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


local event_num = 1700

script = {
    mod_name = "TEST_OF_MOD",
    generate_event_name = function()
        event_num = event_num + 1
        return event_num
    end,
    raise_event = function(number, event_data)
        risen_event[#risen_event + 1] = {
            number = number,
            event_data = event_data
        }
    end
}

-- Required by Log.log() from log4factorio
function log()
end


