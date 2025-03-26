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
    lu.assertEquals({}, storage.platforms)
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


BaseTest:hookTests()
