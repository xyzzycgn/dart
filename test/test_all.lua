---
--- Created by xyzzycgn.
--- DateTime: 28.12.24 13:54
---
local lu = require('lib.luaunit')
require('test.BaseTest')

--########################################################

BaseTest.hooked = true

require('test.test_player_data')
require('test.test_global_data')

BaseTest.hooked = false
BaseTest:hookTests()
