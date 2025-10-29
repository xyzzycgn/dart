---
--- Created by xyzzycgn.
--- DateTime: 28.12.24 14:43
---
--- executes all tests

local Require = require("test.require")
require = Require.replace(require)

local lu = require('luaunit')
serpent=require('serpent') -- must be global

--########################################################
-- needed by Log.log() which is called by some tests
function log()
end

-- mock several global objects - normally provided by game
settings = {
    global = {
        ["dart-logLevel"] = { value = 5 }, -- == Log.INFO
    },
    startup = {
        ["dart-update-stock-period"] = { value = 10 }
    }
}

storage = {}

local event_num = 1700

script = {
    mod_name = "TEST_OF_MOD",
    generate_event_name = function()
        event_num = event_num + 1
        return event_num
    end
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



