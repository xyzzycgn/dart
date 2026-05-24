---
--- Created by xyzzycgn.
---
local Require = require("test.require")
-- _G is needed - otherwise test fails with "module '__log4factorio__.dump' not found"
_G.require = Require.replace(_G.require)

require("spec.common")
require("scripts.internalEvents")

describe("Messaging", function()
    local messaging
    local mockForce

    local printSettings = {
        sound = _G.defines.print_sound.use_player_settings,
        skip = _G.defines.print_skip.if_visible,
    }

    local green_mark = "[img=utility/check_mark_green]"
    local warning_icon = "[img=utility/warning_icon]"
    local danger_icon = "[img=utility/danger_icon]",

    setup(function()
        -- Mock settings
        _G.settings = {
            global = {
                ["dart-msgLevel"] = { value = "ALL" }
            }
        }
        -- Mock the game object.
        _G.game = {
            print = spy.new()
        }

        -- Mock a force.
        mockForce = {
            valid = true,
            print = spy.new()
        }

        messaging = require("scripts.messaging")
    end)

    before_each(function()
        -- reset calling states of spies
        _G.game.print:clear()
        mockForce.print:clear()
    end)
-- ###############################################################

    describe("filter constants", function()
        it("defines the expected filter values", function()
            assert.are.equal(0, messaging.filter.NONE)
            assert.are.equal(6, messaging.filter.ALERTS)
            assert.are.equal(1, messaging.filter.INFOSONLY)
            assert.are.equal(7, messaging.filter.ALL)
        end)
    end)
-- ###############################################################

    describe("level constants", function()
        it("defines the expected message level values", function()
            assert.are.equal(1, messaging.level.INFO)
            assert.are.equal(2, messaging.level.WARNING)
            assert.are.equal(4, messaging.level.ALERT)
        end)
    end)
-- ###############################################################

    describe("getLevel", function()
        it("returns ALL for the ALL setting", function()
            settings.global["dart-msgLevel"] = { value = "ALL" }

            assert.are.equal(messaging.filter.ALL, messaging.getLevel())
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns ALERTS for the ALERTS setting", function()
            settings.global["dart-msgLevel"] = { value = "ALERTS" }

            assert.are.equal(messaging.filter.ALERTS, messaging.getLevel())
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns INFOSONLY for the INFOSONLY setting", function()
            settings.global["dart-msgLevel"] = { value = "INFOSONLY" }

            assert.are.equal(messaging.filter.INFOSONLY, messaging.getLevel())
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("returns NONE for the NONE setting", function()
            settings.global["dart-msgLevel"] = { value = "NONE" }

            assert.are.equal(messaging.filter.NONE, messaging.getLevel())
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("falls back to ALL for an invalid setting", function()
            settings.global["dart-msgLevel"] = { value = "INVALID" }

            assert.are.equal(messaging.filter.ALL, messaging.getLevel())
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("falls back to ALL when the setting value is missing", function()
            settings.global["dart-msgLevel"].value = nil

            assert.are.equal(messaging.filter.ALL, messaging.getLevel())
        end)
    end)
-- ###############################################################

    describe("printmsg", function()
        it("prints a string message with the default info icon", function()
            settings.global["dart-msgLevel"] = { value = "ALL" }
            local msg = "Test message __1__"

            messaging.printmsg(msg, messaging.level.INFO)
            assert.spy(_G.game.print).was_called_with( { msg, green_mark }, printSettings)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("prints a table message with the default warning icon", function()
            settings.global["dart-msgLevel"] = { value = "ALL" }
            local msg = { "Test message", "param1" }

            messaging.printmsg(msg, messaging.level.WARNING)
            assert.spy(_G.game.print).was_called_with( { "Test message", warning_icon, "param1" }, printSettings)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("prints a message with a custom icon", function()
            settings.global["dart-msgLevel"] = { value = "ALL" }
            local msg = "Test message __1__"

            messaging.printmsg(msg, messaging.level.INFO, nil, "custom/icon")
            assert.spy(_G.game.print).was_called_with( { msg, "[img=custom/icon]" }, printSettings)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("prints a message without an icon when the icon is empty", function()
            settings.global["dart-msgLevel"] = { value = "ALL" }
            local msg = "Test message"

            messaging.printmsg("Test message", messaging.level.INFO, nil, "")
            assert.spy(_G.game.print).was_called_with(msg, printSettings)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("prints an alert message with the default alert icon", function()
            settings.global["dart-msgLevel"] = { value = "ALL" }
            local msg = "Alert message __1__"

            messaging.printmsg(msg, messaging.level.ALERT)
            assert.spy(_G.game.print).was_called_with( { msg, danger_icon }, printSettings)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("prints to a valid force instead of the game object", function()
            settings.global["dart-msgLevel"] = { value = "ALL" }
            local msg = "Force message"

            messaging.printmsg(msg, messaging.level.INFO, mockForce)
            assert.spy(_G.game.print).was_not_called()
            assert.spy(mockForce.print).was_called_with( { msg, green_mark }, printSettings)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("prints to the game object when the force is invalid", function()
            settings.global["dart-msgLevel"] = { value = "ALL" }
            local invalidForce = { valid = false }
            local msg = "Message"

            messaging.printmsg(msg, messaging.level.INFO, invalidForce)
            assert.spy(_G.game.print).was_called_with( { msg, green_mark }, printSettings)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("does not print when the message filter is NONE", function()
            settings.global["dart-msgLevel"] = { value = "NONE" }

            messaging.printmsg("Should not print", messaging.level.INFO)
            assert.spy(_G.game.print).was_not_called()
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("prints info messages when the filter is INFOSONLY", function()
            settings.global["dart-msgLevel"] = { value = "INFOSONLY" }
            local msg = "Info message"

            messaging.printmsg(msg, messaging.level.INFO)
            assert.spy(_G.game.print).was_called_with( { msg, green_mark }, printSettings)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("does not print warning messages when the filter is INFOSONLY", function()
            settings.global["dart-msgLevel"] = { value = "INFOSONLY" }

            messaging.printmsg("Warning message", messaging.level.WARNING)
            assert.spy(_G.game.print).was_not_called()
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("prints alert messages when the filter is ALERTS", function()
            settings.global["dart-msgLevel"] = { value = "ALERTS" }
            local msg = "Alert message"

            messaging.printmsg(msg, messaging.level.ALERT)
            assert.spy(_G.game.print).was_called_with( { msg, danger_icon }, printSettings)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("prints warning messages when the filter is ALERTS", function()
            settings.global["dart-msgLevel"] = { value = "ALERTS" }
            local msg = "Warning message"

            messaging.printmsg(msg, messaging.level.WARNING)
            assert.spy(_G.game.print).was_called_with( { msg, warning_icon }, printSettings)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("does not print info messages when the filter is ALERTS", function()
            settings.global["dart-msgLevel"] = { value = "ALERTS" }

            messaging.printmsg("Info message", messaging.level.INFO)
            assert.spy(_G.game.print).was_not_called()
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("uses the expected print settings", function()
            settings.global["dart-msgLevel"] = { value = "ALL" }
            local msg = "Test message"

            messaging.printmsg(msg, messaging.level.INFO)
            assert.spy(_G.game.print).was_called_with( { msg, green_mark }, printSettings)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("prints a complex table message and inserts icon at position 2 and keeps all other parameters", function()
            settings.global["dart-msgLevel"] = { value = "ALL" }

            messaging.printmsg({ "complex.message", "param1", "param2", "param3" }, messaging.level.INFO)
            assert.spy(_G.game.print).was_called_with({"complex.message", "[img=utility/check_mark_green]", "param1", "param2", "param3"}, printSettings)
        end)
    end)
-- ###############################################################

    describe("edge cases", function()
        it("does not print nil messages", function()
            settings.global["dart-msgLevel"] = { value = "ALL" }

            messaging.printmsg(nil, messaging.level.INFO)
            assert.spy(_G.game.print).was_called_with(nil, printSettings)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("prints an empty string message", function()
            settings.global["dart-msgLevel"] = { value = "ALL" }

            messaging.printmsg("", messaging.level.INFO, nil, "")
            assert.spy(_G.game.print).was_called_with("", printSettings)
        end)
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        it("does not print messages with level zero", function()
            settings.global["dart-msgLevel"] = { value = "ALL" }

            messaging.printmsg("Zero level message", 0)
            assert.spy(_G.game.print).was_not_called()
        end)
    end)
end)
