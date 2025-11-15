--- Created by xyzzycgn.
--- DateTime: 02.05.25 13:59
---

local utils = {}

-- table.sort doesn't work with tables, that aren't gapless
-- because the size (# rows) of these tables shouldn't be large, a variant of bubblesort should be fast enough
-- although it's O(n²) ;-)
function utils.sort(data, ascending, func)
    local sortedData = {}

    for _, row in pairs(data) do
        for i = 1, #sortedData do
            if (func(sortedData[i], row) ~= ascending) then
                table.insert(sortedData, i, row)
                goto continue
            end
        end

        sortedData[#sortedData + 1] = row

       ::continue::
    end

    return sortedData
end
-- ###############################################################

--- possible details for checkCircuitCondition()
utils.CircuitConditionChecks = {
    ok = 0,
    firstSignalEmpty = 1,
    secondSignalNotSupported = 2,
    invalidComparator = 3,
    noFalse = 4,
    noTrue = 5,
    unknown = 99,
}

--- test functions for the different ComparatorStrings
local cmpfuncs = {
    ["="]  = function(val, const) return val == const end,
    [">="] = function(val, const) return val >= const end,
    [">"]  = function(val, const) return val >  const end,
    ["<="] = function(val, const) return val <= const end,
    ["<"]  = function(val, const) return val < const end,
    ["!="] = function(val, const) return val ~= const end,
}
--- alternates
cmpfuncs["≥"] = cmpfuncs[">="]
cmpfuncs["≤"] = cmpfuncs["<="]
cmpfuncs["≠"] = cmpfuncs["!="]

--- @param cc CircuitCondition to check
local function testCondition(cc)
    local comp = cc.comparator
    local const = cc.constant

    local func = cmpfuncs[comp]

    if not func then
        return false, utils.CircuitConditionChecks.invalidComparator
    elseif func(0, const) then
        -- false expected
        return false, utils.CircuitConditionChecks.noFalse
    elseif func(1, const) then
        -- everything is fine
        return true, utils.CircuitConditionChecks.ok
    else
        -- true expected
        return false, utils.CircuitConditionChecks.noTrue
    end
end


--- checks a CircuitCondition for validity (and usability for D.A.R.T.)
--- @param cc CircuitCondition to check
--- @return boolean retc returns true if the CircuitCondition is valid set and supported
--- @return number details @see utils.CircuitConditionChecks
function utils.checkCircuitCondition(cc)
    local details

    if cc then
        if cc.first_signal then
            if cc.second_signal then
                details = utils.CircuitConditionChecks.secondSignalNotSupported
            else
                return testCondition(cc)
            end
        else
            details = utils.CircuitConditionChecks.firstSignalEmpty
        end
    else
        details = utils.CircuitConditionChecks.unknown
    end

    return false, details
end
-- ###############################################################

--- @class BitOperations
utils.bitOps = {
    OR = 1,
    XOR = 3,
    AND = 4
}

--- @see https://stackoverflow.com/questions/32387117/bitwise-and-in-lua
--- @param oper BitOperations
--- @param a uint
--- @param a uint
function utils.bitoper(a, b, oper)
    local r, m, s = 0, 2 ^ 31
    repeat
        s, a, b = a + b + m, a % m, b % m
        r, m = r + m * oper % (s - a - b), m / 2
    until m < 1
    return r
end
-- ###############################################################

local two_pi = 2 * math.pi
--- calculates distance and angle between an asteroid and a turret
--- @param target LuaEntity asteroid which should be targeted
--- @param turret LuaEntity turret
--- @return float, RealOrientation distance and angle between turret and asteroid
function utils.distFromTurret(target, turret)
    local dx = target.position.x - turret.position.x
    local dy = target.position.y - turret.position.y
    return math.sqrt(dx * dx + dy * dy), 0.25 + math.atan(-dy, dx) / two_pi
end
-- ###############################################################

local direction2RealOrientation = {
    [defines.direction.north] = 0,
    [defines.direction.northnortheast] = 0.0625,
    [defines.direction.northeast] = 0.125,
    [defines.direction.eastnortheast] = 0.1875,
    [defines.direction.east] = 0.25,
    [defines.direction.eastsoutheast] = 0.3125,
    [defines.direction.southeast] = 0.375,
    [defines.direction.southsoutheast] = 0.4375,
    [defines.direction.south] = 0.5,
    [defines.direction.southsouthwest] = 0.5625,
    [defines.direction.southwest] = 0.625,
    [defines.direction.westsouthwest] = 0.6875,
    [defines.direction.west] = 0.75,
    [defines.direction.westnorthwest] = 0.8125,
    [defines.direction.northwest] = 0.875,
    [defines.direction.northnorthwest] = 0.9375,
}

--- converts a direction (from defines.direction) into a RealOrientation
function utils.directionToRealOrientation(dir)
    return direction2RealOrientation[dir] or 0
end

return utils