---
--- Created by xyzzycgn.
---
local Log = require("__log4factorio__.Log")

-- determine mapping only once per game session
local needs_initialization = true
local mapAmmos = {}

local function getMapAmmos()
    if needs_initialization then
        --- contains all specific ammos of a ammo_category
        --- @class AmmosByCategory table<string, string[]> maps name of ammo_category to names of all corresponding ammos
        --- i.e. { ["bullet"] = {"firearm-magazine", "piercing-rounds-magazine", ...} }
        local ammosByCategory = {}

        -- thanks to wube that ammo has to be handled as item while turrets as entities, although in wiki both look equal
        -- see https://wiki.factorio.com/Firearm_magazine vs. https://wiki.factorio.com/Gun_turret where
        -- the former one links to AmmoItemPrototype (an **Item**Prototype) and the latter one to AmmoTurretPrototype
        -- (an **Entity**ProtoType), when clicking on "Prototype type"
        for name, item in pairs(prototypes.get_item_filtered ({ { filter = "type", type = "ammo" }})) do
            local ac = item.ammo_category
            Log.logLine({name = name, item=item, ammo_cat=ac, ammo_cat_name=ac.name, ammo_cat_type=ac.type, }, function(m)log(m)end, Log.FINER)

            local ammoCat = ammosByCategory[ac.name] or {}
            ammoCat[#ammoCat + 1] = name
            ammosByCategory[ac.name] = ammoCat
        end

        -- get all types of ammo-turrets
        local turrets = prototypes.get_entity_filtered ({ { filter = "type", type = "ammo-turret" }})

        --- @class AmmoTurretMapping table<string, AmmosByCategory> contains the mapping from ammo-turret to corresponding ammo
        --- i.e.: {
        ---   ["gun-turret"] = {
        ---       ["bullet"] = {"firearm-magazine", "piercing-rounds-magazine"}
        ---   }
        --- }

        for name, turret in pairs(turrets) do
            Log.logLine({ name=name, turret = turret, ap = turret.attack_parameters }, function(m)log(m)end, Log.FINER)

            mapAmmos[name] = {}
            for _, cat in pairs(turret.attack_parameters.ammo_categories) do
                mapAmmos[name][cat] = ammosByCategory[cat]
            end
        end
        -- mapAmmos now conatins the mapping between turret and ammo (grouped by ammo-type)
        Log.logBlock(mapAmmos, function(m)log(m)end, Log.FINE)

        needs_initialization = false
    end

    return mapAmmos
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local ammoTurretMapping = {}

--- @return AmmoTurretMapping
function ammoTurretMapping.getAmmoTurretMapping()
    return getMapAmmos()
end

return ammoTurretMapping

