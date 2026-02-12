---
--- Created by xyzzycgn.
--- DateTime: 28.12.24 10:31
---
require('test.BaseTest')
local lu = require('luaunit')
local gd = require('scripts.global_data')
local PlayerData = require('scripts.player_data')
local force_data = require('scripts.force_data')

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
    lu.assertEquals({}, storage.platforms)
end
-- ###############################################################

function TestGlobalData:test_addPlayerSimple()
    local p = { index = 17 }
    local pd = {}
    lu.assertNotNil(pd)
    gd.addPlayer_data(p, pd)

    lu.assertEquals(storage.players[p.index], pd)
end
-- ###############################################################

function TestGlobalData:test_addPlayerGetPLayerWithRealPD()
    local p = { index = 17 }
    local pd = PlayerData.init_player_data(p)
    lu.assertNotNil(pd)
    gd.addPlayer_data(p, pd)

    lu.assertEquals(storage.players[p.index], pd)

    local fromGD = gd.getPlayer_data(p.index)
    lu.assertEquals(fromGD, pd)
end
-- ###############################################################

function TestGlobalData:test_addForceData()
    local force = {
        index = 1
    }
    local fd = force_data.init_force_data()
    lu.assertNotNil(fd)

    gd.addForce_data(force, fd)
    lu.assertEquals(storage.forces[1], fd)
    lu.assertNil(storage.forces[2])

    gd.addForce_data(2, fd)
    lu.assertEquals(storage.forces[2], fd)
end
-- ###############################################################

function TestGlobalData:test_getForceData()
    local fd = force_data.init_force_data()
    lu.assertNotNil(fd)
    storage.forces[1] = fd

    lu.assertEquals(gd.getForce_data(1), fd)
end
-- ###############################################################

function TestGlobalData:test_deleteForceData()
    local fd = force_data.init_force_data()
    lu.assertNotNil(fd)
    storage.forces[1] = fd

    gd.deleteForce_data(1)
    lu.assertNil(storage.forces[1])
end
-- ###############################################################

BaseTest:hookTests()
