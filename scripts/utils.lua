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
return utils