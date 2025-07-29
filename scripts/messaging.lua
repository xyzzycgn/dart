---
--- Created by xyzzycgn.
---
local utils = require("scripts.utils")

local messaging = {}

--- @class MessageFilter
messaging.filter = {
    NONE = 0,
    ALERTS = 6,
    INFOSONLY = 1,
    ALL = 7,
}

--- @class MessageLevel
messaging.level = {
    INFO = 1,
    WARNING = 2,
    ALERT = 4,
}

local icons = {
    [messaging.level.INFO] = "[img=utility/check_mark_green]",
    [messaging.level.WARNING] = "[img=utility/warning_icon]",
    [messaging.level.ALERT] = "[img=utility/danger_icon]",
}


--- configured level of messages to be shown
function messaging.getLevel()
  return messaging.filter[settings.global["dart-msgLevel"].value] or messaging.filter.ALL
end

---@type PrintSettings
local settings = {
    sound = defines.print_sound.use_player_settings,
    skip = defines.print_skip.if_visible,
}

--- write msg to console for all members of a force or all players
--- @param msg LocalisedString
--- @param lvl MessageLevel severity of message to print
--- @param force LuaForce? force receiving the message, if not set send to all players
--- @param useicon string? if not set lvl determines the icon, if == "" no icon is used
function messaging.printmsg(msg, lvl, force, useicon)
    if utils.bitoper(lvl, messaging.getLevel(), utils.bitOps.AND) > 0 then
        local icon
        if useicon then
            if useicon ~= "" then
                -- use a custom icon
                icon = "[img=" .. useicon .. "]"
            end
        else
            -- lvl determines the icon
            icon = icons[lvl]
        end

        if icon then
            -- icon should be used
            local mtype = type(msg)
            if mtype == "table" then
                table.insert(msg, 2, icon)
            elseif mtype == "string" then
                -- assumes, that msg contains placeholder __1__
                msg = { msg, icon }
            end
        end

        if force and force.valid then
            force.print(msg, settings)
        else
            game.print(msg, settings)
        end
    end
end

return messaging

