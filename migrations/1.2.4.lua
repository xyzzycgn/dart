local global_data = require("scripts.global_data")

log("migration to 1.2.4 started")
local nturrets, nplatforms = 0, 0

for _, pons in pairs(global_data.getPlatforms()) do
    for _, mt in pairs(pons.managedTurrets or {}) do
        for tun, dist in pairs(mt.targets_of_turret) do
            --- @type TargetOfTurret
            local tt = {
                distance = dist,
                is_priority_target = false
            }              
            mt.targets_of_turret[tun] = tt
        end
        nturrets = nturrets + 1
    end

    nplatforms = nplatforms + 1
end

log(string.format("reorganized %d managed_turrets on %d platforms", nturrets, nplatforms))

nturrets, nplatforms = 0, 0

for _, pons in pairs(global_data.getPlatforms()) do
    for _, top in pairs(pons.turretsOnPlatform) do
        local turret = top.turret
        local prot = prototypes.entity[turret.name]
        local ap = prot.attack_parameters
        top.min_range = ap.min_range or 0
        top.turn_range = ap.turn_range or 1
        nturrets = nturrets + 1
    end

    nplatforms = nplatforms + 1
end

log(string.format("determined min_range for %d turrets on %d platforms", nturrets, nplatforms))

log("migration to 1.2.4 finished")
