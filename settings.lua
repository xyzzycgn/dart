data:extend({
    -- Startup
    {
        type = 'int-setting',
        name = 'dart-update-stock-period',
        setting_type = 'startup',
        default_value = 10,
        maximum_value = 60,
        minimum_value = 5,
        order = 'a',
    },
    {
        type = "bool-setting",
        name = "dart-release-control",
        order = "b-a",
        setting_type = "startup",
        default_value = false,
    },
    {
        type = "int-setting",
        name = "dart-release-control-threshold-default",
        order = "b-aa",
        setting_type = "startup",
        default_value = 10,
        minimum_value = 1,
    },

    -- runtime
    {
        type = "bool-setting",
        name = "dart-show-detection-area",
        order = "a",
        setting_type = "runtime-global",
        default_value = false,
    },
    {
        type = "bool-setting",
        name = "dart-show-defended-area",
        order = "b",
        setting_type = "runtime-global",
        default_value = false,
    },
    {
        type = "bool-setting",
        name = "dart-mark-targets",
        order = "c",
        setting_type = "runtime-global",
        default_value = false,
    },
    {
        type = "bool-setting",
        name = "dart-auto-increment-detection-range",
        order = "d",
        setting_type = "runtime-global",
        default_value = true,
    },
    {
        type = "string-setting",
        name = "dart-msgLevel",
        order = "m",
        setting_type = "runtime-global",
        default_value = "ALL",
        allowed_values = {
            "NONE",
            "ALERTS",
            "INFOSONLY",
            "ALL",
        }
    },
    {
        type = "bool-setting",
        name = "dart-low-ammo-warning",
        order = "m-a",
        setting_type = "runtime-global",
        default_value = true,
    },
    {
        type = "int-setting",
        name = "dart-low-ammo-warning-threshold-default",
        order = "m-aa",
        setting_type = "runtime-global",
        default_value = 200,
        minimum_value = 10,
    },
    {
        type = "string-setting",
        name = "dart-logLevel",
        order = "z",
        setting_type = "runtime-global",
        default_value = "FINE",
        allowed_values = {
            "FATAL",
            "ERROR",
            "WARN",
            "INFO",
            "CONFIG",
            "FINE",
            "FINER",
            "FINEST",
        }
    },
})
