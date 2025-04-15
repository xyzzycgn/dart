---
--- Created by xyzzycgn.
---

--- @class PlayerData any  convenience class for handling player_data
--- @field player LuaPlayer the player to whom these data belong
--- @field guis any data of the opened gui
--- @field pons Pons[] platforms owned by the player

local PlayerData = {}

---@param player LuaPlayer
function PlayerData.init_player_data(player)
    -- Player data used during game
    local pd = {
        guis = {},
        player = player,
        pons = {}
    }

    return pd
end

return PlayerData