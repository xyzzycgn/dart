local global_data = require("scripts.global_data")

log("migration to 1.1.0 started")

--- @field registeredEntities RegisteredEntity
--- @field what LuaEntity
--- @field reference any reference to according xyzOnPlatform structure in pons
local function register(registeredEntities, what, reference)
    local registrationNumber, uid = script.register_on_object_destroyed(what)
    registeredEntities[registrationNumber] = {
        referenceOnPlatform = reference,
        useful_id = uid,
    }
end
-- ###############################################################

-- register all fccs, radars and ammo-turrets (for usage in "remove all entities" in editor mode - see ticket #52)
local registeredEntities = global_data.getRegisteredEntities()
local nfccs, nradars, nturrets, nplatforms = 0, 0, 0, 0
for _, pons in pairs(global_data.getPlatforms()) do
    for _, fop in pairs(pons.fccsOnPlatform) do
        register(registeredEntities, fop.fcc, pons.fccsOnPlatform)
        nfccs = nfccs + 1
    end

    for _, rop in pairs(pons.radarsOnPlatform) do
        register(registeredEntities, rop.radar, pons.radarsOnPlatform)
        nradars = nradars + 1
    end

    for _, top in pairs(pons.turretsOnPlatform) do
        register(registeredEntities, top.turret, pons.turretsOnPlatform)
        nturrets = nturrets + 1
    end

    nplatforms = nplatforms + 1
end

log(string.format("registered %d FCCs, %d radars and %d turrets on %d platforms for on_object_destroyed",
        nfccs, nradars, nturrets, nplatforms))
log("migration to 1.1.0 finished")
