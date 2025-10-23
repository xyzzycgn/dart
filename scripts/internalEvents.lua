---
--- defines additional events (at the moment for internal use only)
--- Created by xyzzycgn.
---

local registered = {}

--- registers a new event and logs it
--- @param name string name of the new event
local function register(name)
    local _event = script.generate_event_name()

    registered[_event] = name

    log("registered " .. name .. ": " .. _event)

    return _event
end
-- ###############################################################

-- vars must be global
on_target_assigned_event = register("on_target_assigned_event")
on_target_unassigned_event = register("on_target_unassigned_event")
on_asteroid_detected_event = register("on_asteroid_detected_event")
on_asteroid_lost_event = register("on_asteroid_lost_event")
on_target_destroyed_event = register("on_target_destroyed_event")

on_dart_component_build_event = register("on_dart_component_build_event")
on_dart_component_removed_event = register("on_dart_component_removed_event")

on_dart_gui_needs_update_event = register("on_dart_gui_needs_update_event")
on_dart_gui_close_event = register("on_dart_gui_close_event")
on_dart_ammo_in_stock_updated_event = register("on_dart_ammo_in_stock_updated_event")


local internalEvents = {}

function internalEvents.getEventName(eventNum)
    return registered[eventNum]
end

return internalEvents