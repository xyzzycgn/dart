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

---@field tc TurretConnection @ mis-/unconfigured but connected turret
--- @return LuaTurretControlBehavior
local function getControlBehavior(tc)
     --- @type LuaEntity
    local turret = tc.turret
    if turret.valid then
        local cb = turret.get_control_behavior()
        if cb.valid then
            return cb
        end
    end
    Log.log("entity or control behaviour not valid", function(m)log(m)end, Log.WARN)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

---@field tc TurretConnection @ mis-/unconfigured but connected turret
local function circuitNetworkDisabledInTurret(tc)
    Log.logBlock(tc, function(m)log(m)end, Log.FINE)
    local cb = getControlBehavior(tc)
    if cb then
        cb.circuit_enable_disable = true
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

---@field tc TurretConnection @ mis-/unconfigured but connected turret
local function firstSignalEmpty(tc)
    Log.logBlock(tc, function(m)log(m)end, Log.FINE)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function repairCircuitCondition(tc)
    Log.logBlock(tc, function(m)log(m)end, Log.FINE)
    local cb = getControlBehavior(tc)
    Log.logBlock(cb, function(m)log(m)end, Log.FINE)
    if cb then
        --- @type CircuitCondition
        local cc = cb.circuit_condition
        Log.logBlock(cc, function(m)log(m)end, Log.FINE)
        cc.comparator = '>'
        cc.constant = 0

        cb.circuit_condition = cc
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- emulate case switch - lua is so ...
local switch4autoConfigure = {
    [states.circuitNetworkDisabledInTurret] = circuitNetworkDisabledInTurret,
    [states.firstSignalEmpty] = firstSignalEmpty,
    [states.secondSignalNotSupported] = repairCircuitCondition,
    [states.invalidComparator] = repairCircuitCondition,
    [states.noFalse] = repairCircuitCondition,
    [states.noTrue] = repairCircuitCondition,
}

local meta = { __index = function(t, key)
    return function()
        Log.logMsg(function(m)log(m)end, Log.WARN, "Unsupported case %d - IGNORED", key)
    end -- default for case/switch
end }

setmetatable(switch4autoConfigure, meta)

---@field tcs TurretConnection[] @ mis-/unconfigured but connected turrets
local function autoConfigure(tcs)
    for _, tc in pairs(tcs) do
        Log.logBlock(tc, function(m)log(m)end, Log.FINE)

        switch4autoConfigure[tc.stateConfiguration](tc)
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
    Log.logLine({ ret = ret }, function(m)log(m)end, Log.FINER)

    return ret
end


local configureTurrets = {
    autoConfigure = autoConfigure,
    checkNetworkCondition = checkNetworkCondition,
    states = states
}

return configureTurrets