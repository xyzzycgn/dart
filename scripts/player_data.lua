---
--- Created by xyzzycgn.
---

--- @class Sortings any sorting parameters for all columns in a table
--- @field sorting boolean[] true = ascending
--- @field active int index of column used for sorting, -1 means no sorting

--- @class GuiAndElements any
--- @field gui LuaGuiElement top level Element of the gui
--- @field elems table<string, LuaGuiElement>
--- @field entity LuaEntity Entity shown in gui
--- @field activeTab int|nil (optional) ndx of active tab
--- @field rowsShownLastInTab int[] (optional) number of rows shown in table on tab n the last time
--- @field sortings Sortings[] (optional) sorting parameters for all columns in table on tab n
--- @field highlight LuaEntity (optional) highlight-box used for marking hovered entity in main gui

--- @class GuiData any
--- @field recentlyopen GuiAndElements[] previously opened guis (hidden after opening a new one)
--- @field open GuiAndElements

--- @class PlayerData any  convenience class for handling player_data
--- @field player LuaPlayer the player to whom these data belong
--- @field guis GuiData data of the opened guis
--- @field pons Pons[] platforms owned by the player

local playerData = {}

--- @param player LuaPlayer
--- @return PlayerData
function playerData.init_player_data(player)
    -- Player data used during game
    local pd = {
        guis = {},
        player = player,
        pons = {}
    }

    return pd
end

return playerData