---
--- Created by xyzzycgn.
--- DateTime: 23.12.24 16:43
---
require('test.BaseTest')
local lu = require('luaunit')
local PlayerData = require('scripts.player_data')

TestPlayerData = {}

function TestPlayerData:test_player_date_init()
    -- mock the game object
    --game = {}
    --game.tick = 4711

    -- and the player
    player = {}

    local pd = PlayerData.init_player_data(player)

    lu.assertNotIsNil(pd)
    lu.assertNotIsNil(pd.guis)
    lu.assertEquals(player, pd.player)
end

BaseTest:hookTests()


