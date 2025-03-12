---
--- Created by xyzzycgn.
--- DateTime: 03.03.25 20:51
---
local Log = require("__log4factorio__.Log")
Log.setSeverity(Log.CONFIG)

Log.logBlock(mods, function(m)log(m)end, Log.CONFIG)
Log.logBlock(data.raw["technology"], function(m)log(m)end, Log.FINER)

