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
---@param msg LocalisedString
---@param lvl MessageLevel severity of message to print
---@param force LuaForce?
function messaging.printmsg(msg, lvl, force)
    if utils.bitoper(lvl, messaging.getLevel(), utils.bitOps.AND) > 0 then
        if force and force.valid then
            force.print(msg, settings)
        else
            game.print(msg, settings)
        end
    end
end

return messaging

