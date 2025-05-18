local global_data = require("scripts.global_data")
local player_data = require("scripts.player_data")

log("migration to 1.0.2 started")

-- supplement missing pons entries and player_data structures
for _, pons in pairs(global_data.getPlatforms()) do
    local platform = pons.platform
    for _, player in pairs(platform.force.players) do
        local pd = global_data.getPlayer_data(player.index)
        if not pd then
            pd = player_data.init_player_data(player)
            global_data.addPlayer_data(player, pd)
            log("created missing player data for player=" .. player.index)
        end
        if not pd.pons[platform.index] then
            pd.pons[platform.index] = pons
            log("added pons in player data for player=" .. player.index)
        end
    end
end

log("migration to 1.0.2 finished")
