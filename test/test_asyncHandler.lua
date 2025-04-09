---
--- Created by xyzzycgn.
--- DateTime: 09.04.25 09:08
---

require('test.BaseTest')
local lu = require('lib.luaunit')

require('factorio_def')
local asyncHandler = require('scripts.asyncHandler')

TestAsyncHandler = {}

local handles = {}

local called = {}

local function countCall(func, arg)
    called[#called + 1] = { func = func, arg = arg, }
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- test functions to be called asynch
local function async1(arg)
    countCall(async1, arg)
end

local function async2(arg)
    countCall(async2, arg)
end

local function async3(arg)
    countCall(async3, arg)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- register the test functions
handles[1] = asyncHandler.registerAsync(async1)
handles[2] = asyncHandler.registerAsync(async2)
handles[3] = asyncHandler.registerAsync(async3)

local function getTableSize(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

function TestAsyncHandler:setUp()
    -- simulated (global) storage object
    storage = {
        queued = {},
    }
    -- mock the game object
    game = {
        tick = 4711
    }
end
-- ###############################################################

function TestAsyncHandler:test_registerAsync()
    local h1 = asyncHandler.registerAsync(function(arg) end)
    lu.assertEquals(h1, 4)

    local h2 = asyncHandler.registerAsync(function(arg) end)
    lu.assertEquals(h2, 5)

    local h3 = asyncHandler.registerAsync(function(arg) end)
    lu.assertEquals(h3, 6)
end

-- ###############################################################

function TestAsyncHandler:test_enqueue()
    -- 1st
    asyncHandler.enqueue(1, "testarg1", 5)

    lu.assertEquals(getTableSize(storage.queued), 1)
    local entries = storage.queued[4716]
    lu.assertNotNil(entries)

    lu.assertEquals(getTableSize(entries), 1)
    local entry = entries[1]
    lu.assertNotNil(entry)
    lu.assertEquals(entry.ndxfunc, 1)
    lu.assertEquals(entry.arg, "testarg1")


    -- 2nd (other time, other function)
    asyncHandler.enqueue(3, "testarg2", 6)

    lu.assertEquals(getTableSize(storage.queued), 2)
    local entries = storage.queued[4717]
    lu.assertNotNil(entries)
    lu.assertEquals(getTableSize(entries), 1)
    local entry = entries[1]
    lu.assertNotNil(entry)
    lu.assertEquals(entry.ndxfunc, 3)
    lu.assertEquals(entry.arg, "testarg2")

    -- 3rd (same time as 2nd, same function as 1st, other arg)
    asyncHandler.enqueue(1, "testarg3", 6)

    lu.assertEquals(getTableSize(storage.queued), 2)
    local entries = storage.queued[4717]
    lu.assertNotNil(entries)

    lu.assertEquals(getTableSize(entries), 2)
    local entry = entries[1]
    lu.assertNotNil(entry)
    lu.assertEquals(entry.ndxfunc, 3)
    lu.assertEquals(entry.arg, "testarg2")
    entry = entries[2]
    lu.assertNotNil(entry)
    lu.assertEquals(entry.ndxfunc, 1)
    lu.assertEquals(entry.arg, "testarg3")
end
-- ###############################################################

function TestAsyncHandler:test_dequeue()
    -- queue 4 calls
    -- 1st
    asyncHandler.enqueue(1, "testarg1", 5)
    -- 2nd (other time, other function)
    asyncHandler.enqueue(3, "testarg2", 10)
    -- 3rd (same time as 2nd, same function as 1st, other arg)
    asyncHandler.enqueue(1, "testarg3", 10)
    -- 4th (new time, same function as 1st, other arg)
    asyncHandler.enqueue(1, "testarg4", 12)

    lu.assertEquals(getTableSize(storage.queued), 3) -- due to same time for 2nd and 3rd
    lu.assertNotNil(storage.queued[4716])
    lu.assertNotNil(storage.queued[4721])
    lu.assertNotNil(storage.queued[4723])

    -- test
    -- too early
    local event = { tick = 4712}
    asyncHandler.dequeue(event)
    lu. assertEquals(called, {})

    -- still too early
    local event = { tick = 4715}
    asyncHandler.dequeue(event)
    lu. assertEquals(called, {})

    -- first hit
    local event = { tick = 4716 }
    asyncHandler.dequeue(event)
    lu. assertEquals(called, {{ func = async1, arg = "testarg1"}} )

    lu.assertEquals(getTableSize(storage.queued), 2) -- 1st should be deleted
    lu.assertNotNil(storage.queued[4721])
    lu.assertNotNil(storage.queued[4723])

    -- 2nd hit (1 tick too late ;-) }
    local event = { tick = 4722 }
    asyncHandler.dequeue(event)
    lu. assertEquals(called, {
        { func = async1, arg = "testarg1"}, -- from 1st hit
        { func = async3, arg = "testarg2"},
        { func = async1, arg = "testarg3"},
    })

    lu.assertEquals(getTableSize(storage.queued), 1) -- (former) 2nd should be deleted
    lu.assertNotNil(storage.queued[4723])
end

BaseTest:hookTests()
