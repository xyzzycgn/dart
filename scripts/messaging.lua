---
--- Created by xyzzycgn.
---
local messaging = {}

--- @class MessageLevel
messaging.level = {
    NONE = 0,
    ALARM = 1,
    WARNINGS = 2,
    ALL = 3,
}

--- configured level of messages to be shown
function messaging.getLevel()
  return messaging.level[settings.global["dart-msgLevel"].value] or messaging.level.ALL
end

---@type PrintSettings
local settings = {
    sound = defines.print_sound.use_player_settings,
    skip = defines.print_skip.if_visible,
}

--- write msg to console for all members of a force or all players
---@param msg LocalisedString
---@param lvl MessageLevel level of message to print
---@param force LuaForce?
function messaging.printmsg(msg, lvl, force)
    if lvl <= messaging.getLevel() then
        if force and force.valid then
            force.print(msg, settings)
        else
            game.print(msg, settings)
        end
    end
end

return messaging

