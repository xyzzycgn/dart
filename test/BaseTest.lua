---
--- Created by xyzzycgn.
--- DateTime: 28.12.24 14:43
---
--- executes all tests

local Require = require("test.require")
require = Require.replace(require)

local lu = require('lib.luaunit')
serpent=require('lib.serpent') -- must be global

--########################################################
-- needed by Log.log() which is called by some tests
function log()
end

-- mock several global objects - normally provided by game
settings = {
    global = {
        ["dart-logLevel"] = { value = 5 }, -- == Log.INFO
    }
}

storage = {}

script = {
    mod_name = "TEST_OF_MOD"
}

defines = {
    events = {},
    train_state = {
        on_the_path = 0,
        no_schedule = 1,
        no_path = 2,
        arrive_signal = 3,
        wait_signal = 4,
        arrive_station = 5,
        manual_control_stop = 6,
        manual_control = 7,
        wait_station = 9,
        destination_full = 9,
    }
}

-- simulating internal events - normally created in internalEvents
on_target_assigned_event = 1704
on_target_unassigned_event = 1705
on_target_destroyed_event = 1706
on_asteroid_detected_event = 1707
on_asteroid_lost_event = 1708



--########################################################

BaseTest = {
    hooked = false
}

function BaseTest:hookTests()
    if (not self.hooked) then
        os.exit(lu.LuaUnit.run())
        self.hooked = true
    end
end

-- mock function table_size (normally provided by the game runtime)
function table_size(table)
    print("################ BUUUUUUU")
    if (table) then
        print("################ BUUUUUUU 2")
        if (type(table) == "table") then
            print("################ BUUUUUUU 3")
            local count = 0
            for _ in pairs(table) do
                count = count + 1
            end
            return count
        end
    end

    return 0
end



