---
--- Created by xyzzycgn.
--- handling async functions
local global_data = require("scripts.global_data")
local Log = require("__log4factorio__.Log")

local asyncHandler = {}

-- hold the registered functions
local asyncs = {}

--- register a function to be handled asynchronously
--- has to be called prior to all calls of enqueue() or dequeue()
--- @param func function to be handled
--- @return int handle to be used in enqueue()
function asyncHandler.registerAsync(func)
    Log.logBlock(type(func), function(m)log(m)end, Log.FINEST)

    local ndx = #asyncs + 1
    asyncs[ndx] = func
    return ndx
end
-- ###############################################################

--- enqueue a call to a registered function
--- @param funcHandle int handle returned from call to registerAsync()
--- @param arg any argument to be passed to function when it's dequeued
function asyncHandler.enqueue(funcHandle, arg, delay)
    local untiltick = game.tick + delay
    Log.logBlock( { arg = arg, delay = delay, untiltick = untiltick }, function(m)log(m)end, Log.FINEST)
    local next = {
        ndxfunc = funcHandle,
        arg = arg,
    }

    local queued = global_data.getQueued()
    local entry = queued[untiltick] or {}

    entry[#entry + 1] = next
    queued[untiltick] = entry
end

function asyncHandler.dequeue(event)
    local queued = global_data.getQueued()
    local tick = event.tick

    -- execute all enqueued functions whose untiltick is <= the tick from event
    for untiltick, entries in pairs(queued) do
        if untiltick <= tick then
            Log.logBlock(entries, function(m)log(m)end, Log.FINEST)
            for _, entry in pairs(entries) do
                local func = asyncs[entry.ndxfunc]
                func(entry.arg)
            end

            -- done - delete entries from queue
            queued[untiltick] = nil
        else
            -- the others still have to wait
            break
        end
    end
end
-- ###############################################################

return asyncHandler