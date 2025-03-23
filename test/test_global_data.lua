---
--- Created by xyzzycgn.
--- DateTime: 28.12.24 10:31
---
require('test.BaseTest')
local lu = require('lib.luaunit')
local gd = require('scripts.global_data')
local PlayerData = require('scripts.player_data')

local serpent = require("lib.serpent")

-- needed by Log.log() which is called by init()
function log()
end

TestGlobalData = {}

function TestGlobalData:setUp()
    -- simulated (global) storage object
    storage =  {}
    -- gd must be initialized
    gd.init({})

    -- mock the game object
    game = {}
    --game.tick = 4711
    --game.connected_players = {}
end
-- ###############################################################

function TestGlobalData:test_init()
    lu.assertEquals({}, storage.players)
    lu.assertEquals({}, storage.dart)
end
-- ###############################################################

function TestGlobalData:test_addPlayerSimple()
    -- test
    local p = { index = 17 }
    local pd = {}
    lu.assertNotNil(pd)
    gd.addPlayer_data(p, pd)

    lu.assertEquals(storage.players[p.index], pd)
end
-- ###############################################################

function TestGlobalData:test_addPlayerGetPLayerWithRealPD()
    -- test
    local p = { index = 17 }
    local pd = PlayerData.init_player_data(p)
    lu.assertNotNil(pd)
    gd.addPlayer_data(p, pd)

    lu.assertEquals(storage.players[p.index], pd)

    local fromGD = gd.getPlayer_data(p.index)
    lu.assertEquals(fromGD, pd)
end
-- ###############################################################

local function checkDart(dart, output, run, oun, cb)
    run = run or 4711
    oun = oun or 0815
    cb = cb or "mocked CB"
    lu.assertNotNil(dart)
    lu.assertEquals(dart.output_un, oun)
    lu.assertEquals(dart.radar_un, run)
    lu.assertEquals(dart.control_behavior, cb)
    lu.assertEquals(dart.output, output)
end


function TestGlobalData:test_setDart()
    local dart_radar = {
        unit_number = 4711
    }
    local dart_output = {
        unit_number = 0815,
        get_or_create_control_behavior = function()
            return "mocked CB"
        end
    }

    -- test
    gd.setDart(dart_radar, dart_output)

    local gdoun = storage.dart[0815]
    checkDart(gdoun, dart_output)
    local gdrun = storage.dart[4711]
    checkDart(gdrun, dart_output)
end


function TestGlobalData:test_getDart()
    local dart_radar = {
        unit_number = 4711
    }
    local dart_output = {
        unit_number = 0815,
        get_or_create_control_behavior = function()
            return "mocked CB"
        end
    }
    gd.setDart(dart_radar, dart_output)

    local dart_radar2 = {
        unit_number = 47112
    }
    local dart_output2 = {
        unit_number = 08152,
        get_or_create_control_behavior = function()
            return "mocked CB2"
        end
    }
    gd.setDart(dart_radar2, dart_output2)


    -- test
    local gd_dart= gd.getDart(4711)
    checkDart(gd_dart, dart_output)
end


function TestGlobalData:test_clearDart()
    local dart_radar = {
        unit_number = 4711
    }
    local dart_output = {
        unit_number = 0815,
        get_or_create_control_behavior = function()
            return "mocked CB"
        end
    }
    gd.setDart(dart_radar, dart_output)

    local dart_radar2 = {
        unit_number = 47112
    }
    local dart_output2 = {
        unit_number = 08152,
        get_or_create_control_behavior = function()
            return "mocked CB2"
        end
    }
    gd.setDart(dart_radar2, dart_output2)

    -- test
    lu.assertNotNil(storage.dart[0815])
    lu.assertNotNil(storage.dart[4711])

    gd.clearDart(4711)
    gd.clearDart(0815)

    lu.assertNil(storage.dart[0815])
    lu.assertNil(storage.dart[4711])
    local gdoun = storage.dart[08152]
    checkDart(gdoun, dart_output2, 47112, 08152, "mocked CB2")
    local gdrun = storage.dart[47112]
    checkDart(gdoun, dart_output2, 47112, 08152, "mocked CB2")
end

BaseTest:hookTests()
