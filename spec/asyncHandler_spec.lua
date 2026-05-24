---
--- Created by xyzzycgn.
---
local Require = require("test.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)

require("spec.common")

describe("AsyncHandler", function()
    local asyncHandler

    -- Test functions to be called asynchronously.
    local async1 = spy.new(function() end)
    local async2 = spy.new(function() end)
    local async3 = spy.new(function() end)

    setup(function()
        asyncHandler = require("scripts.asyncHandler")

        -- Register the test functions.
        asyncHandler.registerAsync(async1)
        asyncHandler.registerAsync(async2)
        asyncHandler.registerAsync(async3)
    end)

    before_each(function()
        async1:clear()
        async2:clear()
        async3:clear()

        -- Mock global storage.
        _G.storage = {
            queued = {},
        }

        -- Mock the game object.
        _G.game = {
            tick = 4711
        }
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("registerAsync", function()
        it("returns incrementing handles for newly registered functions", function()
            local h1 = asyncHandler.registerAsync(function() end)
            assert.are.equal(4, h1)

            local h2 = asyncHandler.registerAsync(function() end)
            assert.are.equal(5, h2)
        end)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("enqueue", function()
        it("queues calls by execution tick", function()
            -- First entry.
            asyncHandler.enqueue(1, "testarg1", 5)

            assert.are.same({
                queued = {
                    [4716] = {
                        {
                            arg = "testarg1",
                            ndxfunc = 1
                        }
                    }
                }
            }, storage)

            -- Second entry with another execution tick and another function.
            asyncHandler.enqueue(3, "testarg2", 6)

            assert.are.same({
                queued = {
                    [4716] = {
                        {
                            arg = "testarg1",
                            ndxfunc = 1
                        }
                    },
                    [4717] = {
                        {
                            arg = "testarg2",
                            ndxfunc = 3
                        }
                    }
                }
            }, storage)

            -- Third entry with the same execution tick as the second entry.
            asyncHandler.enqueue(1, "testarg3", 6)

            assert.are.same({
                queued = {
                    [4716] = {
                        {
                            arg = "testarg1",
                            ndxfunc = 1
                        }
                    },
                    [4717] = {
                        {
                            arg = "testarg2",
                            ndxfunc = 3
                        },
                        {
                            arg = "testarg3",
                            ndxfunc = 1
                        }
                    }
                }
            }, storage)
        end)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    describe("dequeue", function()
        it("executes queued calls when their target tick has been reached", function()
            -- Queue four calls.
            asyncHandler.enqueue(1, "testarg1", 5)
            asyncHandler.enqueue(3, "testarg2", 10)
            asyncHandler.enqueue(1, "testarg3", 10)
            asyncHandler.enqueue(1, "testarg4", 12)

            -- The second and third calls share the same target tick.
            assert.are.same({
                queued = {
                    [4716] = {
                        {
                            arg = "testarg1",
                            ndxfunc = 1
                        }
                    },
                    [4721] = {
                        {
                            arg = "testarg2",
                            ndxfunc = 3
                        },
                        {
                            arg = "testarg3",
                            ndxfunc = 1
                        }
                    },
                    [4723] = {
                        {
                            arg = "testarg4",
                            ndxfunc = 1
                        }
                    },
                }
            }, storage)

            -- Too early.
            asyncHandler.dequeue({ tick = 4712 })
            assert.spy(async1).was_not_called()
            assert.spy(async2).was_not_called()
            assert.spy(async3).was_not_called()

            -- Still too early.
            asyncHandler.dequeue({ tick = 4715 })

            assert.spy(async1).was_not_called()
            assert.spy(async2).was_not_called()
            assert.spy(async3).was_not_called()

            -- First matching tick.
            asyncHandler.dequeue({ tick = 4716 })

            assert.spy(async1).was_called_with("testarg1")
            assert.spy(async2).was_not_called()
            assert.spy(async3).was_not_called()


            -- The first queued tick should be removed.
            assert.are.same({
                queued = {
                    [4721] = {
                        {
                            arg = "testarg2",
                            ndxfunc = 3
                        },
                        {
                            arg = "testarg3",
                            ndxfunc = 1
                        }
                    },
                    [4723] = {
                        {
                            arg = "testarg4",
                            ndxfunc = 1
                        }
                    },
                }
            }, storage)
            -- clear call history
            async1:clear()

            -- Second matching tick, processed one tick late.
            asyncHandler.dequeue({ tick = 4722 })

            assert.spy(async1).was_called_with("testarg3")
            assert.spy(async2).was_not_called()
            assert.spy(async3).was_called_with("testarg2")

            -- The second queued tick should be removed.
            assert.are.same({
                queued = {
                    [4723] = {
                        {
                            arg = "testarg4",
                            ndxfunc = 1
                        }
                    },
                }
            }, storage)
        end)
    end)
end)