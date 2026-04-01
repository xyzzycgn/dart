local global_data = require("scripts.global_data")

log("migration to 1.2.10 started")
local removed = 0

for _, playerData in pairs(global_data.getAllPlayer_data()) do
    local ro = playerData and playerData.guis and playerData.guis.recentlyopen
    if ro and #ro > 0 then
        local new = {}
        for _, v in pairs(ro) do
            if table_size(v) > 0 then
                new[#new + 1] = v
            else
                removed = removed + 1
            end
        end
        playerData.guis.recentlyopen = new
    end
end

log("migration to 1.2.10 finished - removed " .. removed .. " stale entries")
