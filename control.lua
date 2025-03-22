---
--- Created by xyzzycgn.
--- DateTime: 26.02.25 09:58
---
-- from lualib
local handler = require("event_handler")
-- initialization of mod and business logic
handler.add_lib(require("scripts.dart"))
-- GUI handling
handler.add_lib(require("__flib__.gui"))
handler.add_lib(require("scripts.dart-gui"))

