---
--- Created by xyzzycgn.
--- DateTime: 28.12.24 13:54
---
local lu = require('luaunit')
require('test.BaseTest')

--########################################################

BaseTest.hooked = true

require('test.test_player_data')
require('test.test_global_data')
require('test.test_dart')
require('test.test_utils')
require('test.test_asyncHandler')
require('test.test_hub')
require('test.test_messaging')
require('test.test_configure_turrets')
require('test.test_force')
require('test.test_force_data')
require('test.test_radars')

BaseTest.hooked = false
BaseTest:hookTests()
