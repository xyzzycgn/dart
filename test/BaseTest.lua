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
    global ={
        ["rldman-logLevel"] = { value = 3 },
        ["rldman-num-alerts"] = { value = 20 },
        ["rldman-num-histories"] = { value = 20 },
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



