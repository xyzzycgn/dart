---
--- Created by xyzzycgn.
--- DateTime: 04.04.25 11:33
--- defines additional events (at the moment for internal use only)

-- must be global
on_target_assigned_event = script.generate_event_name()
log("registered on_target_assigned_event: " .. on_target_assigned_event)
on_target_unassigned_event = script.generate_event_name()
log("registered on_target_unassigned_event: " .. on_target_unassigned_event)
on_asteroid_detected_event = script.generate_event_name()
log("registered on_asteroid_detected_event: " .. on_asteroid_detected_event)
on_asteroid_lost_event = script.generate_event_name()
log("registered on_asteroid_lost_event: " .. on_asteroid_lost_event)
on_target_destroyed_event = script.generate_event_name()
log("registered on_target_destroyed_event: " .. on_target_destroyed_event)


on_dart_component_build_event = script.generate_event_name()
log("registered on_dart_component_build_event: " .. on_dart_component_build_event)
on_dart_component_removed_event = script.generate_event_name()
log("registered on_dart_component_removed_event: " .. on_dart_component_removed_event)
