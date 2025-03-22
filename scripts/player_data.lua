---
--- Created by xyzzycgn.
---

-- convenience class for handling player_data
local PlayerData = {}

---@param player LuaPlayer
function PlayerData.init_player_data(player)
    -- Player data used during game
    local pd = {
        guis = {},
        player = player,
    }

    return pd
end

return PlayerData