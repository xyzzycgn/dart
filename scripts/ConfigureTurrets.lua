---
--- Created by xyzzycgn.
--- Module to manage auto configure of mis-/unconfigured but connected turrets
---
local Log = require("__log4factorio__.Log")
local utils = require("scripts/utils")

-- ###############################################################

local function copy(base, expand)
    copy = {}
    for k, v in pairs(base) do
        copy[k] = v
    end

    for k, v in pairs(expand) do
        copy[k] = v
    end

    return copy
end

local states = copy(utils.CircuitConditionChecks, {
    notConnected = 11,
    connectedTwice = 12,
    connectedToMultipleFccs = 13,
    circuitNetworkDisabledInTurret = 14,

    unknown = 99
})
-- ###############################################################

---@field tcs TurretConnection[] @ mis-/unconfigured but connected turrets
local function autoConfigure(tcs)
    for _, tc in pairs(tcs) do
        local cc = tc.cc
        local connector = tc.connector
        local turret = tc.turret
        local network_id = tc.network_id
        local stateConfiguration = tc.stateConfiguration

        Log.logBlock({ stateConfiguration=stateConfiguration,
                       cc=cc,
                       connector=connector,
                       turret=turret,
                       network_id=network_id}, function(m)log(m)end, Log.FINE)
    end
end
-- ###############################################################

---@field tc TurretConnection[] @ mis-/unconfigured but connected turrets
local function checkNetworkCondition(tc)
    local ret
    
    if tc.num_connections == 0 then
        -- not connected
        ret = states.notConnected
    elseif tc.num_connections == 2 then
        -- connected twice
        ret = states.connectedTwice
    elseif table_size(tc.managedBy) > 1 then
        -- connected to multiple fccs
        ret = states.connectedToMultipleFccs
    elseif not tc.circuit_enable_disable then
        -- circuit network disabled in turret
        ret = states.circuitNetworkDisabledInTurret
    else
        -- connected once
        local valid, details = utils.checkCircuitCondition(tc.cc)
        ret = valid and states.ok or details or states.unknown
    end
    Log.logLine({ ret = ret }, function(m)log(m)end, Log.FINE)

    return ret
end


local configureTurrets = {
    autoConfigure = autoConfigure,
    checkNetworkCondition = checkNetworkCondition,
    states = states
}

return configureTurrets