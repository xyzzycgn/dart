local global_data = require("scripts.global_data")

log("migration to 1.1.0 started")

-- supplement new data for fcc
for _, pons in pairs(global_data.getPlatforms()) do
    local fccs = pons.fccsOnPlatform
    for _, fcc in pairs(fccs) do
        -- set ammo_warning_threshold to default if nothing is set
        fcc.ammo_warning_threshold = fcc.ammo_warning_threshold or settings.global["dart-low-ammo-warning-threshold-default"].value
    end
end

log("migration to 1.1.0 finished")
