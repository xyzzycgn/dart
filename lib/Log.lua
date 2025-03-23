---
--- Created by xyzzycgn.
--- DateTime: 17.01.25 08:45
---
local Log = {
    FATAL  = 8,
    ERROR  = 7,
    WARN   = 6,
    INFO   = 5,
    CONFIG = 4,
    FINE   = 3,
    FINER  = 2,
    FINEST = 1,
}

local DEFAULT = Log.CONFIG

local severity = DEFAULT

local MSG = {
    [8] = "[FATAL] ",
    [7] = "[ERROR] ",
    [6] = "[WARN] ",
    [5] = "[INFO] ",
    [4] = "[CONFIG] ",
    [3] = "[FINE] ",
    [2] = "[FINER] ",
    [1] = "[FINEST] ",
}

function Log.setSeverity(sev)
    severity = sev
end

function Log.setFromSettings(setting)
    severity = Log[settings.global[setting].value] or DEFAULT
end

function Log.log(msg, func, sev)
    sev = sev or DEFAULT
    if (sev >= severity) then
        func(MSG[sev] .. (msg or "<NIL>"))
    end
end

function Log.logBlock(msg, func, sev)
    sev = sev or DEFAULT
    if (sev >= severity) then
        func(MSG[sev] .. serpent.block(msg))
    end
end

return Log