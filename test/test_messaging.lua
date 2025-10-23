
---
--- Created by xyzzycgn.
--- DateTime: 29.07.25 10:00
---
require('test.BaseTest')
local lu = require('lib.luaunit')

-- Mock defines (need to be done BEFORE requiring scripts.messaging
require('factorio_def')

local messaging = require('scripts.messaging')

TestMessaging = {}

function TestMessaging:setUp()
    -- Mock settings
    settings = settings or {}
    settings = {
        global = {
            ["dart-msgLevel"] = { value = "ALL" }
        }
    }

    -- Mock game object
    game = {
        print = function(msg, settings)
            game.last_printed_msg = msg
            game.last_print_settings = settings
        end,
        last_printed_msg = nil,
        last_print_settings = nil
    }

    -- Mock a force
    self.mockForce = {
        valid = true,
        print = function(msg, settings)
            self.mockForce.last_printed_msg = msg
            self.mockForce.last_print_settings = settings
        end,
        last_printed_msg = nil,
        last_print_settings = nil
    }

end

-- ###############################################################
-- Tests für messaging.filter
-- ###############################################################

function TestMessaging:test_filter_constants()
    lu.assertEquals(messaging.filter.NONE, 0)
    lu.assertEquals(messaging.filter.ALERTS, 6)
    lu.assertEquals(messaging.filter.INFOSONLY, 1)
    lu.assertEquals(messaging.filter.ALL, 7)
end

-- ###############################################################
-- Tests für messaging.level
-- ###############################################################

function TestMessaging:test_level_constants()
    lu.assertEquals(messaging.level.INFO, 1)
    lu.assertEquals(messaging.level.WARNING, 2)
    lu.assertEquals(messaging.level.ALERT, 4)
end

-- ###############################################################
-- Tests für messaging.getLevel()
-- ###############################################################

function TestMessaging:test_getLevel_ALL()
    settings.global["dart-msgLevel"] = { value = "ALL" }
    lu.assertEquals(messaging.getLevel(), messaging.filter.ALL)
end

function TestMessaging:test_getLevel_ALERTS()
    settings.global["dart-msgLevel"] = { value = "ALERTS" }
    lu.assertEquals(messaging.getLevel(), messaging.filter.ALERTS)
end

function TestMessaging:test_getLevel_INFOSONLY()
    settings.global["dart-msgLevel"] = { value = "INFOSONLY" }
    lu.assertEquals(messaging.getLevel(), messaging.filter.INFOSONLY)
end

function TestMessaging:test_getLevel_NONE()
    settings.global["dart-msgLevel"] = { value = "NONE" }
    lu.assertEquals(messaging.getLevel(), messaging.filter.NONE)
end

function TestMessaging:test_getLevel_invalid_setting()
    settings.global["dart-msgLevel"] = { value = "INVALID" }
    lu.assertEquals(messaging.getLevel(), messaging.filter.ALL)
end

function TestMessaging:test_getLevel_missing_setting()
    settings.global["dart-msgLevel"].value = nil
    lu.assertEquals(messaging.getLevel(), messaging.filter.ALL)
end

-- ###############################################################
-- Tests für messaging.printmsg()
-- ###############################################################

function TestMessaging:test_printmsg_string_message_with_default_icon()
    settings.global["dart-msgLevel"] = { value = "ALL" }
    local msg = "Test message __1__"

    messaging.printmsg(msg, messaging.level.INFO)

    lu.assertNotNil(game.last_printed_msg)
    lu.assertEquals(type(game.last_printed_msg), "table")
    lu.assertEquals(game.last_printed_msg[1], "Test message __1__")
    lu.assertEquals(game.last_printed_msg[2], "[img=utility/check_mark_green]")
end

function TestMessaging:test_printmsg_table_message_with_default_icon()
    settings.global["dart-msgLevel"] = { value = "ALL" }
    local msg = {"Test message", "param1"}

    messaging.printmsg(msg, messaging.level.WARNING)

    lu.assertNotNil(game.last_printed_msg)
    lu.assertEquals(type(game.last_printed_msg), "table")
    lu.assertEquals(game.last_printed_msg[1], "Test message")
    lu.assertEquals(game.last_printed_msg[2], "[img=utility/warning_icon]")
    lu.assertEquals(game.last_printed_msg[3], "param1")
end

function TestMessaging:test_printmsg_with_custom_icon()
    settings.global["dart-msgLevel"] = { value = "ALL" }
    local msg = "Test message __1__"
    local custom_icon = "custom/icon"

    messaging.printmsg(msg, messaging.level.INFO, nil, custom_icon)

    lu.assertNotNil(game.last_printed_msg)
    lu.assertEquals(type(game.last_printed_msg), "table")
    lu.assertEquals(game.last_printed_msg[2], "[img=custom/icon]")
end

function TestMessaging:test_printmsg_with_no_icon()
    settings.global["dart-msgLevel"] = { value = "ALL" }
    local msg = "Test message"

    messaging.printmsg(msg, messaging.level.INFO, nil, "")

    lu.assertEquals(game.last_printed_msg, "Test message")
end

function TestMessaging:test_printmsg_alert_level_icon()
    settings.global["dart-msgLevel"] = { value = "ALL" }
    local msg = "Alert message __1__"

    messaging.printmsg(msg, messaging.level.ALERT)

    lu.assertNotNil(game.last_printed_msg)
    lu.assertEquals(game.last_printed_msg[2], "[img=utility/danger_icon]")
end

function TestMessaging:test_printmsg_to_force()
    settings.global["dart-msgLevel"] = { value = "ALL" }
    local msg = "Force message"

    messaging.printmsg(msg, messaging.level.INFO, self.mockForce)

    lu.assertEquals(self.mockForce.last_printed_msg, {"Force message", "[img=utility/check_mark_green]"})
    lu.assertNil(game.last_printed_msg)
end

function TestMessaging:test_printmsg_to_invalid_force()
    settings.global["dart-msgLevel"] = { value = "ALL" }
    local msg = "Message"
    local invalidForce = { valid = false }

    messaging.printmsg(msg, messaging.level.INFO, invalidForce)

    lu.assertEquals(game.last_printed_msg, {"Message", "[img=utility/check_mark_green]"})
    lu.assertNil(invalidForce.last_printed_msg)
end

function TestMessaging:test_printmsg_level_filtering_none()
    settings.global["dart-msgLevel"] = { value = "NONE" }
    local msg = "Should not print"

    messaging.printmsg(msg, messaging.level.INFO)

    lu.assertNil(game.last_printed_msg)
end

function TestMessaging:test_printmsg_level_filtering_infos_only_info()
    settings.global["dart-msgLevel"] = { value = "INFOSONLY" }
    local msg = "Info message"

    messaging.printmsg(msg, messaging.level.INFO)

    lu.assertEquals(game.last_printed_msg, {"Info message", "[img=utility/check_mark_green]"})
end

function TestMessaging:test_printmsg_level_filtering_infos_only_warning()
    settings.global["dart-msgLevel"] = { value = "INFOSONLY" }
    local msg = "Warning message"

    messaging.printmsg(msg, messaging.level.WARNING)

    lu.assertNil(game.last_printed_msg)
end

function TestMessaging:test_printmsg_level_filtering_alerts_only_alert()
    settings.global["dart-msgLevel"] = { value = "ALERTS" }
    local msg = "Alert message"

    messaging.printmsg(msg, messaging.level.ALERT)

    lu.assertNotNil(game.last_printed_msg)
end

function TestMessaging:test_printmsg_level_filtering_alerts_only_warning()
    settings.global["dart-msgLevel"] = { value = "ALERTS" }
    local msg = "Warning message"

    messaging.printmsg(msg, messaging.level.WARNING)

    lu.assertNotNil(game.last_printed_msg)
end

function TestMessaging:test_printmsg_level_filtering_alerts_only_info()
    settings.global["dart-msgLevel"] = { value = "ALERTS" }
    local msg = "Info message"

    messaging.printmsg(msg, messaging.level.INFO)

    lu.assertNil(game.last_printed_msg)
end

function TestMessaging:test_printmsg_print_settings()
    settings.global["dart-msgLevel"] = { value = "ALL" }
    local msg = "Test message"

    messaging.printmsg(msg, messaging.level.INFO)

    lu.assertNotNil(game.last_print_settings)
    lu.assertEquals(game.last_print_settings.sound, defines.print_sound.use_player_settings)
    lu.assertEquals(game.last_print_settings.skip, defines.print_skip.if_visible)
end

function TestMessaging:test_printmsg_complex_table_message()
    settings.global["dart-msgLevel"] = { value = "ALL" }
    local msg = {"complex.message", "param1", "param2", "param3"}

    messaging.printmsg(msg, messaging.level.INFO)

    lu.assertNotNil(game.last_printed_msg)
    lu.assertEquals(type(game.last_printed_msg), "table")
    lu.assertEquals(game.last_printed_msg[1], "complex.message")
    lu.assertEquals(game.last_printed_msg[2], "[img=utility/check_mark_green]")
    lu.assertEquals(game.last_printed_msg[3], "param1")
    lu.assertEquals(game.last_printed_msg[4], "param2")
    lu.assertEquals(game.last_printed_msg[5], "param3")
end

-- ###############################################################
-- Edge Cases Tests
-- ###############################################################

function TestMessaging:test_printmsg_nil_message()
    settings.global["dart-msgLevel"] = { value = "ALL" }

    messaging.printmsg(nil, messaging.level.INFO)

    lu.assertEquals(game.last_printed_msg, nil)
end

function TestMessaging:test_printmsg_empty_string_message()
    settings.global["dart-msgLevel"] = { value = "ALL" }
    local msg = ""

    messaging.printmsg(msg, messaging.level.INFO, nil, "")

    lu.assertEquals(game.last_printed_msg, "")
end

function TestMessaging:test_printmsg_zero_level()
    settings.global["dart-msgLevel"] = { value = "ALL" }
    local msg = "Zero level message"

    messaging.printmsg(msg, 0)

    lu.assertNil(game.last_printed_msg)
end

BaseTest:hookTests()