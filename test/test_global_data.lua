---
--- Created by xyzzycgn.
--- DateTime: 28.12.24 10:31
---
require('test.BaseTest')
local lu = require('lib.luaunit')
local gd = require('scripts.global_data')
local PlayerData = require('scripts.player_data')


-- needed by Log.log() which is called by init()
function log()
end

TestDeliveryData = {}

function TestDeliveryData:setUp()
    -- simulated (global) storage object
    storage =  {}
    -- gd must be initialized
    gd.init({})

    -- mock the game object
    game = {}
    --game.tick = 4711
    --game.connected_players = {}
end

function TestDeliveryData:test_init()
    lu.assertEquals({}, storage.players)
    lu.assertEquals({}, storage.dart)
end

function TestDeliveryData:test_addPlayerSimple()
    -- test
    local p = { index = 17 }
    local pd = {}
    lu.assertNotNil(pd)
    gd.addPlayer_data(p, pd)

    lu.assertEquals(storage.players[p.index], pd)
end

function TestDeliveryData:test_addPlayerGetPLayerWithRealPD()
    -- test
    local p = { index = 17 }
    local pd = PlayerData.init_player_data(p)
    lu.assertNotNil(pd)
    gd.addPlayer_data(p, pd)

    lu.assertEquals(storage.players[p.index], pd)

    fromGD = gd.getPlayer_data(p.index)
    lu.assertEquals(fromGD, pd)
end

BaseTest:hookTests()
