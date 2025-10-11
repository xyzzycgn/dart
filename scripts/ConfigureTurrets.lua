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

--- possible fault conditions for a mis-/unconfigured but connected turret
local states = copy(utils.CircuitConditionChecks, {
    notConnected = 11,
    connectedTwice = 12,
    connectedToMultipleFccs = 13,
    circuitNetworkDisabledInTurret = 14,

    unknown = 99
})
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
        tc.circuit_enable_disable = true -- mark as fixed
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @param tc TurretConnection @ mis-/unconfigured but connected turret
--- @param first? (optional) name of signal prototype to be set as 1st signal
local function repairCircuitCondition(tc, first)
    Log.logBlock(tc, function(m)log(m)end, Log.FINE)
    local cb = getControlBehavior(tc)
    if cb and cb.valid then
        --- @type CircuitCondition
        local cc = cb.circuit_condition
        Log.logBlock(cc, function(m)log(m)end, Log.FINE)
        if first then
            cc.first_signal = { type = "virtual", name = first }
        end
        cc.comparator = '>'
        cc.constant = 0

        cb.circuit_condition = cc
    else
        Log.logMsg(function(m)log(m)end, Log.WARN, "No / invalid control behaviour - turret = %d", tc.turret.unit_number)
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--- @field tc TurretConnection @ mis-/unconfigured but connected turret
--- @field pons Pons
local function firstSignalEmpty(tc, pons)
    Log.logBlock(tc, function(m)log(m)end, Log.FINE)

    local turrets = pons.turretsOnPlatform
    local usedSignals = {}
    for tid, top in pairs(turrets) do
        local cb = top.control_behavior
        for _, wc in pairs({ defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green }) do
            local network = cb.valid and cb.get_circuit_network(wc)
            if network and tc.turret.unit_number ~= tid then
                -- other turret connected to a circuit network
                local cc = cb.circuit_condition
                local fs = cc.first_signal
                if fs and fs ~= "" then
                    usedSignals[fs.name] = true
                end
            end
        end
    end

    Log.logBlock(usedSignals, function(m)log(m)end, Log.FINE)

    local prototypes = prototypes.virtual_signal
    for _, v in pairs(prototypes) do
        -- ignore special signals (each, everything, ...) or such not valid
        if v.valid and not v.special then
            -- check if not already in use
            if not usedSignals[v.name] then
                repairCircuitCondition(tc, v.name)
                return
            end
        end
    end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

---@field tc TurretConnection @ possibly mis-/unconfigured but connected turret
local function updateTurretConnection(tc)
    local cb = getControlBehavior(tc)
    if cb and cb.valid then
        tc.cc = cb.circuit_condition
    else
        Log.logMsg(function(m)log(m)end, Log.WARN, "ControlBehavior not valid %d - IGNORED", tc.turret.unit_number)
    end

    return checkNetworkCondition(tc) -- check if succeeded
end

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- emulate case switch - lua is so sh...
local switch4autoConfigure = {
    [states.circuitNetworkDisabledInTurret] = circuitNetworkDisabledInTurret,
    [states.firstSignalEmpty] = firstSignalEmpty,
    [states.secondSignalNotSupported] = repairCircuitCondition,
    [states.invalidComparator] = repairCircuitCondition,
    [states.noFalse] = repairCircuitCondition,
    [states.noTrue] = repairCircuitCondition,
}
-- default for case/switch
local meta = { __index = function(_, key)
    return function()
        Log.logMsg(function(m)log(m)end, Log.WARN, "Unsupported case %d - IGNORED", key)
    end
end }
setmetatable(switch4autoConfigure, meta)

---@field tcs TurretConnection[] @ mis-/unconfigured but connected turrets
local function autoConfigure(tcs, pons)
    for _, tc in pairs(tcs) do
        Log.logBlock(tc, function(m)log(m)end, Log.FINE)

        switch4autoConfigure[tc.stateConfiguration](tc, pons)
        local fixed = {}


        local act = updateTurretConnection(tc) -- check if succeeded
        Log.logLine(act, function(m)log(m)end, Log.FINE)
        while (act ~= states.ok) do
            -- still an error in configuration
            -- (may happen for freshly added turret, that hasn't been configured at all yet)
            fixed[tc.stateConfiguration] = true -- remember last fix
            Log.logLine(fixed, function(m)log(m)end, Log.FINE)
            if fixed[act] then
                -- same error again - shouldn't happen, but who knows ;-)
                local function f()
                    return "aborted auto config - same erroneous condition(s): " .. serpent.line(fixed)
                end
                Log.logBlock(f, function(m)log(m)end, Log.WARN)
                act = states.ok -- leave while loop
            else
                tc.stateConfiguration = act -- try to fix next one
                switch4autoConfigure[tc.stateConfiguration](tc, pons)
                act = updateTurretConnection(tc)
            end

            Log.logLine(act, function(m)log(m)end, Log.FINE)
        end
    end
end
-- ###############################################################

-- exposed functions, constants, ...
local configureTurrets = {
    autoConfigure = autoConfigure,
    checkNetworkCondition = checkNetworkCondition,
    states = states
}

return configureTurrets