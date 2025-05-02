---
--- Created by xyzzycgn.
--- DateTime: 02.05.25 13:59
---

local utils = {}

-- table.sort doesn't work with tables, that aren't gapless
-- because the size (# rows) of these tables shouldn't be large, a variant of bubblesort should be fast enough
-- although it's O(n²) ;-)
function utils.sort(data, ascending, func)
    local sortedData = {}

    local ndx = 0
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

return utils