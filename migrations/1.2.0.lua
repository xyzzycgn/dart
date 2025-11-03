local global_data = require("scripts.global_data")
local force_data = require("scripts.force_data")
local constants = require("scripts.constants")
local entities_radar = require("scripts.entities.radars")

log("migration to 1.2.0 started")

storage.forces = storage.forces or {}
local known_forces = {}
-- determine the forces the players belong to
for _, player in pairs(game.players) do
    local force = player.force
    if not known_forces[force] then
        known_forces[force] = true
    end
end

-- add the forces to global_data
for force, _ in pairs(known_forces) do
    local fd = force_data.init_force_data()
    global_data.addForce_data(force, fd)
end

log(string.format("added %d force(s) to global data", table_size(known_forces)))

-- increase detection_range for all existing radars to new max
for _, pons in pairs(global_data.getPlatforms()) do
    for _, rop in pairs(pons.radarsOnPlatform) do
       rop.detectionRange = entities_radar.addIncreaseBasedOnQuality(rop, constants.max_detectionRange)
    end
end
log("increased detectionRange to new max for all existing dart-radars")

log("migration to 1.2.0 finished")
