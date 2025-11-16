local global_data = require("scripts.global_data")

log("migration to 1.2.3 started")
local nturrets, nplatforms = 0, 0

for _, pons in pairs(global_data.getPlatforms()) do
    for _, top in pairs(pons.turretsOnPlatform) do
        local turret = top.turret
        local prot = prototypes.entity[turret.name]
        local ap = prot.attack_parameters
        local quality = turret.quality
        top.range = ap.range * quality.range_multiplier
        nturrets = nturrets + 1
    end

    nplatforms = nplatforms + 1
end

log(string.format("recalculated range with quality for %d turrets on %d platforms", nturrets, nplatforms))

log("migration to 1.2.3 finished")
