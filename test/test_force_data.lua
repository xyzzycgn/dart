---
--- Created by xyzzycgn.
--- DateTime: 27.10.25 
---
require('test.BaseTest')
local lu = require('luaunit')
local ForceData = require('scripts.force_data')

TestForceData = {}

function TestForceData:test_init_force_data()
    local fd = ForceData.init_force_data()
    
    lu.assertNotIsNil(fd)
    lu.assertEquals(0, fd.techLevel)
    lu.assertEquals('table', type(fd))
end

function TestForceData:test_init_force_data_creates_new_instance()
    local fd1 = ForceData.init_force_data()
    local fd2 = ForceData.init_force_data()
    
    -- assert that different instances are created
    lu.assertFalse(fd1 == fd2)
    
    -- both must have the same start value
    lu.assertEquals(fd1.techLevel, fd2.techLevel)
end

function TestForceData:test_force_data_structure()
    local fd = ForceData.init_force_data()
    
    -- check all expected fields
    lu.assertNotIsNil(fd.techLevel)
    
    -- check type of fields
    lu.assertEquals('number', type(fd.techLevel))
end

function TestForceData:test_tech_level_can_be_modified()
    local fd = ForceData.init_force_data()
    
    -- check, if techLevel can be modified
    fd.techLevel = 5
    lu.assertEquals(5, fd.techLevel)
    
    fd.techLevel = 10
    lu.assertEquals(10, fd.techLevel)
end

BaseTest:hookTests()
