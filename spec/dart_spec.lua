---
--- Created by xyzzycgn.
--- DateTime: 23.12.24 16:43
---
local Require = require("test.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)

require("spec.common")
require("scripts.internalEvents")

--require('factorio_def')

-- Utility function to get the size of a table.
local function getTableSize(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

local function init_storagePlatforms(fccs, ka, turrets, radars)
    local platform = { index = 4711, valid = true }
    local surface = { platform = platform, index = 2 }
    storage.platforms[2] = {
        surface = surface,
        platform = platform,
        fccsOnPlatform = fccs or {},
        knownAsteroids = ka or {},
        turretsOnPlatform = turrets or {},
        radarsOnPlatform = radars or {}
    }
end

local function createDart(valid)
    local dart = {
        radar_un = 4711,
        radar = {
            valid = valid,
        },
    }

    return dart
end

local function entityRemovedWithValidOutput(dart, valid)
    -- Prepare storage entries.
    init_storagePlatforms({ [4711] = createDart(valid) })

    -- Mock entity in event.
    local entity = {
        unit_number = 4711,
        name = "dart-fcc",
        surface = {
            index = 2
        },
        force = {
            index = 1,
            players = {
                {
                    index = 2,
                }
            }
        }
    }

    -- Mock event.
    local mock_event = {
        entity = entity,
    }

    -- Execute test subject.
    local eventhandler = dart.events[defines.events.script_raised_destroy]
    assert.are.equal("function", type(eventhandler))

    eventhandler(mock_event)

    assert.is_nil(storage.platforms[2].fccsOnPlatform[4711])
    assert.spy(script.raise_event).was_called_with(1707, {
        entity = {
            force = { index = 1, players = { { index = 2 } } },
            name = "dart-fcc",
            surface = { index = 2 },
            unit_number = 4711
        },
        player_index = 2
    })
    --assert.are.equal(1, #risen_event)
    --
    --local event = risen_event[1]
    --assert.is_not_nil(event)
    --assert.are.equal(1707, event.number)
    --assert.are.same({
    --    entity = {
    --        force = { index = 1, players = { { index = 2 } } },
    --        name = "dart-fcc",
    --        surface = { index = 2 },
    --        unit_number = 4711
    --    },
    --    player_index = 2
    --}, event.event_data)
end

describe("dart", function()
    local dart

    local function addDefines(ndx, what)
        _G.defines[ndx] = what
    end



    setup(function()
        _G.rendering = {
            draw_animation = function()
                return "mocked Animation"
            end
        }


        -- Mock the prototypes.
        _G.prototypes = {
            get_item_filtered = function()
                return {}
            end,
            get_entity_filtered = function()
                return {}
            end,
            asteroid_chunk = {},
            entity = {
                ["gun-turret"] = {
                    attack_parameters = {
                        range = 18
                    }
                }
            }
        }

        -- Mock the settings object.
        local gsg = _G.settings.global or {}
        gsg["dart-low-ammo-warning-threshold-default"] = { value = 200 }
        gsg["dart-asteroid-warning-threshold"] = { value = 15 }


        --- See the [events page](runtime:events) for more info on what events contain and when they get raised.
        addDefines("events", {
            on_achievement_gained = 0,
            on_ai_command_completed = 1,
            on_area_cloned = 2,
            on_biter_base_built = 3,
            on_brush_cloned = 4,
            on_build_base_arrived = 5,
            on_built_entity = 6,
            on_cancelled_deconstruction = 7,
            on_cancelled_upgrade = 8,
            on_cargo_pod_delivered_cargo = 9,
            on_cargo_pod_finished_ascending = 10,
            on_cargo_pod_finished_descending = 11,
            on_cargo_pod_started_ascending = 12,
            on_character_corpse_expired = 13,
            on_chart_tag_added = 14,
            on_chart_tag_modified = 15,
            on_chart_tag_removed = 16,
            on_chunk_charted = 17,
            on_chunk_deleted = 18,
            on_chunk_generated = 19,
            on_combat_robot_expired = 20,
            on_console_chat = 21,
            on_console_command = 22,
            on_cutscene_cancelled = 23,
            on_cutscene_finished = 24,
            on_cutscene_started = 25,
            on_cutscene_waypoint_reached = 26,
            on_entity_cloned = 27,
            on_entity_color_changed = 28,
            on_entity_damaged = 29,
            on_entity_died = 30,
            on_entity_logistic_slot_changed = 31,
            on_entity_renamed = 32,
            on_entity_settings_pasted = 33,
            on_entity_spawned = 34,
            on_equipment_inserted = 35,
            on_equipment_removed = 36,
            on_force_cease_fire_changed = 37,
            on_force_created = 38,
            on_force_friends_changed = 39,
            on_force_reset = 40,
            on_forces_merged = 41,
            on_forces_merging = 42,
            on_game_created_from_scenario = 43,
            on_gui_checked_state_changed = 44,
            on_gui_click = 45,
            on_gui_closed = 46,
            on_gui_confirmed = 47,
            on_gui_elem_changed = 48,
            on_gui_hover = 49,
            on_gui_leave = 50,
            on_gui_location_changed = 51,
            on_gui_opened = 52,
            on_gui_selected_tab_changed = 53,
            on_gui_selection_state_changed = 54,
            on_gui_switch_state_changed = 55,
            on_gui_text_changed = 56,
            on_gui_value_changed = 57,
            on_land_mine_armed = 58,
            on_lua_shortcut = 59,
            on_marked_for_deconstruction = 60,
            on_marked_for_upgrade = 61,
            on_market_item_purchased = 62,
            on_mod_item_opened = 63,
            on_multiplayer_init = 64,
            on_object_destroyed = 65,
            on_permission_group_added = 66,
            on_permission_group_deleted = 67,
            on_permission_group_edited = 68,
            on_permission_string_imported = 69,
            on_picked_up_item = 70,
            on_player_alt_reverse_selected_area = 71,
            on_player_alt_selected_area = 72,
            on_player_ammo_inventory_changed = 73,
            on_player_armor_inventory_changed = 74,
            on_player_banned = 75,
            on_player_built_tile = 76,
            on_player_cancelled_crafting = 77,
            on_player_changed_force = 78,
            on_player_changed_position = 79,
            on_player_changed_surface = 80,
            on_player_cheat_mode_disabled = 81,
            on_player_cheat_mode_enabled = 82,
            on_player_clicked_gps_tag = 83,
            on_player_configured_blueprint = 84,
            on_player_controller_changed = 85,
            on_player_crafted_item = 86,
            on_player_created = 87,
            on_player_cursor_stack_changed = 88,
            on_player_deconstructed_area = 89,
            on_player_demoted = 90,
            on_player_died = 91,
            on_player_display_density_scale_changed = 92,
            on_player_display_resolution_changed = 93,
            on_player_display_scale_changed = 94,
            on_player_driving_changed_state = 95,
            on_player_dropped_item = 96,
            on_player_dropped_item_into_entity = 97,
            on_player_fast_transferred = 98,
            on_player_flipped_entity = 99,
            on_player_flushed_fluid = 100,
            on_player_gun_inventory_changed = 101,
            on_player_input_method_changed = 102,
            on_player_joined_game = 103,
            on_player_kicked = 104,
            on_player_left_game = 105,
            on_player_locale_changed = 106,
            on_player_main_inventory_changed = 107,
            on_player_mined_entity = 108,
            on_player_mined_item = 109,
            on_player_mined_tile = 110,
            on_player_muted = 111,
            on_player_pipette = 112,
            on_player_placed_equipment = 113,
            on_player_promoted = 114,
            on_player_removed = 115,
            on_player_removed_equipment = 116,
            on_player_repaired_entity = 117,
            on_player_respawned = 118,
            on_player_reverse_selected_area = 119,
            on_player_rotated_entity = 120,
            on_player_selected_area = 121,
            on_player_set_quick_bar_slot = 122,
            on_player_setup_blueprint = 123,
            on_player_toggled_alt_mode = 124,
            on_player_toggled_map_editor = 125,
            on_player_trash_inventory_changed = 126,
            on_player_unbanned = 127,
            on_player_unmuted = 128,
            on_player_used_capsule = 129,
            on_player_used_spidertron_remote = 130,
            on_post_entity_died = 131,
            on_post_segmented_unit_died = 132,
            on_pre_build = 133,
            on_pre_chunk_deleted = 134,
            on_pre_entity_settings_pasted = 135,
            on_pre_ghost_deconstructed = 136,
            on_pre_ghost_upgraded = 137,
            on_pre_permission_group_deleted = 138,
            on_pre_permission_string_imported = 139,
            on_pre_player_crafted_item = 140,
            on_pre_player_died = 141,
            on_pre_player_left_game = 142,
            on_pre_player_mined_item = 143,
            on_pre_player_removed = 144,
            on_pre_player_toggled_map_editor = 145,
            on_pre_robot_exploded_cliff = 146,
            on_pre_scenario_finished = 147,
            on_pre_script_inventory_resized = 148,
            on_pre_surface_cleared = 149,
            on_pre_surface_deleted = 150,
            on_redo_applied = 151,
            on_research_cancelled = 152,
            on_research_finished = 153,
            on_research_moved = 154,
            on_research_queued = 155,
            on_research_reversed = 156,
            on_research_started = 157,
            on_resource_depleted = 158,
            on_robot_built_entity = 159,
            on_robot_built_tile = 160,
            on_robot_exploded_cliff = 161,
            on_robot_mined = 162,
            on_robot_mined_entity = 163,
            on_robot_mined_tile = 164,
            on_robot_pre_mined = 165,
            on_rocket_launch_ordered = 166,
            on_rocket_launched = 167,
            on_runtime_mod_setting_changed = 168,
            on_script_inventory_resized = 169,
            on_script_path_request_finished = 170,
            on_script_trigger_effect = 171,
            on_sector_scanned = 172,
            on_segment_entity_created = 173,
            on_segmented_unit_created = 174,
            on_segmented_unit_damaged = 175,
            on_segmented_unit_died = 176,
            on_selected_entity_changed = 177,
            on_singleplayer_init = 178,
            on_space_platform_built_entity = 179,
            on_space_platform_built_tile = 180,
            on_space_platform_changed_state = 181,
            on_space_platform_mined_entity = 182,
            on_space_platform_mined_item = 183,
            on_space_platform_mined_tile = 184,
            on_space_platform_pre_mined = 185,
            on_spider_command_completed = 186,
            on_string_translated = 187,
            on_surface_cleared = 188,
            on_surface_created = 189,
            on_surface_deleted = 190,
            on_surface_imported = 191,
            on_surface_renamed = 192,
            on_technology_effects_reset = 193,
            on_territory_created = 194,
            on_territory_destroyed = 195,
            on_tick = 196,
            on_tower_mined_plant = 197,
            on_tower_planted_seed = 198,
            on_tower_pre_mined_plant = 199,
            on_train_changed_state = 200,
            on_train_created = 201,
            on_train_schedule_changed = 202,
            on_trigger_created_entity = 203,
            on_trigger_fired_artillery = 204,
            on_udp_packet_received = 205,
            on_undo_applied = 206,
            on_unit_added_to_group = 207,
            on_unit_group_created = 208,
            on_unit_group_finished_gathering = 209,
            on_unit_removed_from_group = 210,
            on_worker_robot_expired = 211,
            script_raised_built = 212,
            script_raised_destroy = 213,
            script_raised_destroy_segmented_unit = 214,
            script_raised_revive = 215,
            script_raised_set_tiles = 216,
            script_raised_teleported = 217,
        })
        addDefines("wire_connector_id", {
            circuit_green = 1,
            circuit_red = 0,
            combinator_input_green = 3,
            combinator_input_red = 2,
            combinator_output_green = 5,
            combinator_output_red = 4,
            pole_copper = 6,
            power_switch_left_copper = 7,
            power_switch_right_copper = 8,
        })

        dart = _G.require('scripts.dart')

        -- set up spie for script.raise_event() and script.on_event()
        _G.script.raise_event = spy.new(function() end)
        _G.script.on_event = spy.new(function() end)
    end)
-- ###############################################################

    before_each(function()
        -- Simulated global storage object.
        _G.storage = {
            players = {},
            platforms = {},
        }

        -- Simulated player.
        _G.player = {}

        -- Mock the game object.
        _G.game = {
            surfaces = {},
            platforms = {}
        }

        -- clear history of spies
        _G.script.raise_event:clear()
        _G.script.on_event:clear()
    end)

    -- TODO Try to fix this. The tested method entityCreated() is no longer public.
    -- it("handles created entities", function()
    --     -- Mock dart-radar.
    --     local entity = {
    --         valid = true,
    --         unit_number = 4711,
    --         name = "dart-fcc",
    --         position = { 1, 2 },
    --         force = "A-Team",
    --         surface = {
    --             index = 2,
    --         },
    --         get_or_create_control_behavior = function()
    --             return "mocked CB"
    --         end
    --     }
    --
    --     storage.platforms = {
    --         [2] = {
    --             turrets = {},
    --             fccsOnPlatform = {}
    --         }
    --     }
    --
    --     -- Mock event.
    --     local event = {
    --         entity = entity,
    --     }
    --
    --     -- Execute test subject.
    --     local eventhandler = dart.events[defines.events.on_entity_cloned]
    --     assert.are.equal("function", type(eventhandler))
    --     eventhandler(event)
    --
    --     local dart_entity = storage.platforms[2].fccsOnPlatform[4711]
    --     assert.is_not_nil(dart_entity)
    --     assert.are.equal("mocked CB", dart_entity.control_behavior)
    -- end)

    teardown(function()
        _G.script.raise_event:revert()
        _G.script.on_event:revert()
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    it("removes an entity with valid output", function()
        entityRemovedWithValidOutput(dart, true)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    it("removes an entity with invalid output", function()
        entityRemovedWithValidOutput(dart, false)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    it("does not create platform storage for a surface without platform", function()
        local event = {
            surface_index = 2
        }
        game.surfaces[event.surface_index] = {}

        dart.events[defines.events.on_surface_created](event)

        assert.are.equal(0, getTableSize(storage.platforms))
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    it("creates platform storage for a surface with platform", function()
        -- Simulate event and new platform.
        local event = {
            surface_index = 2
        }
        local platform = {
            index = 4711,
            force = {
                players = {
                    [1] = { index = 3 }
                }
            }
        }
        local surface = { platform = platform, index = 2 }

        game.surfaces[event.surface_index] = surface

        storage.players[3] = { pons = {} }

        dart.events[defines.events.on_surface_created](event)

        assert.are.equal(1, getTableSize(storage.platforms))

        local pons = storage.platforms[2]
        assert.is_not_nil(pons)
        assert.are.equal(surface, pons.surface)
        assert.are.equal(platform, pons.platform)
        assert.are.same({}, pons.turretsOnPlatform)
        assert.are.same({}, pons.knownAsteroids)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

     it("deletes surface storage", function()
         local event = {
             surface_index = 2
         }

         dart.on_init()
         -- check if all (currently 7) events have been registered
         assert.spy(script.on_event).was_called(7)

         init_storagePlatforms()

         dart.events[defines.events.on_surface_deleted](event)
         assert.are.same({}, storage.platforms)
     end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    it("initializes storage and searches dart infrastructure", function()
        -- Start with an empty storage.
        storage = {}

        -- Simulate two surfaces, one of them a platform with a turret.
        game.surfaces = {
            nauvis = {
                index = 1,
            },
            platform_1 = {
                index = 2, -- Surface index.
                platform = {
                    index = 1, -- Platform index.
                    force = {
                        players = {
                            { index = 1 } -- Player index.
                        }
                    }
                },
                find_entities_filtered = function()
                    return {
                        tur1 = {
                            unit_number = 4711,
                            get_or_create_control_behavior = stub.new().returns("simulated CB"),
                            --get_or_create_control_behavior = function()
                            --    return "simulated CB"
                            --end,
                            name = "gun-turret",
                            quality = {
                                level = 2,
                                range_multiplier = 1.2
                            }
                        }
                    }
                end
            }
        }

        dart.on_init()
        -- check if all (currently 7) events have been registered
        assert.spy(script.on_event).was_called(7)

        -- too complex to check in detail
        assert.is_not_nil(_G.storage.players)

        -- Check results from searchDartInfrastructure().
        local plat = _G.storage.platforms[2]
        assert.is_not_nil(plat)
        assert.are.equal(1, getTableSize(plat.turretsOnPlatform))

        local tur = plat.turretsOnPlatform[4711]
        assert.is_not_nil(tur)
        assert.are.equal(18 * 1.2, tur.range)
        assert.are.equal("simulated CB", tur.control_behavior)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    it("registers events on load", function()
        dart.on_load()
        -- check if all (currently 7) events have been registered
        assert.spy(script.on_event).was_called(7)
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    it("runs business processing with empty platform data", function()
        dart.on_load()
        init_storagePlatforms()

        dart.on_nth_tick[60]()
        -- nothing should happen
        assert.spy(script.raise_event).was_not_called()
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    it("runs business processing with only an FCC", function()
        dart.on_load()

        local fcc = createDart(true)
        fcc.control_behavior = {
            get_circuit_network = function()
                return nil
            end,
            get_section = function()
                return { filters = {} }
            end
        }
        fcc.ammo_warning = {
            turret_types = {}
        }

        init_storagePlatforms({ [4711] = fcc })

        dart.on_nth_tick[60]()
        -- nothing should happen
        assert.spy(script.raise_event).was_not_called()
    end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    it("keeps storage unchanged on configuration change", function()
        -- Start with filled storage.
        _G.storage.player = { set = true }

        dart.on_configuration_changed()

        -- Storage should be unchanged.
        assert.are.same({ set = true }, _G.storage.player)
        -- and no further events registered
        assert.spy(script.on_event).was_not_called()
    end)
end)
