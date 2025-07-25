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

  -- runtime
    {
    type = "bool-setting",
    name = "dart-show-detection-area",
    order = "a",
    setting_type = "runtime-global",
    localised_description = { "mod-setting-description.dart-show-detection-area" },
    default_value = false,
  },
  {
    type = "bool-setting",
    name = "dart-show-defended-area",
    order = "b",
    setting_type = "runtime-global",
    localised_description = { "mod-setting-description.dart-show-defended-area" },
    default_value = false,
  },
  {
    type = "bool-setting",
    name = "dart-mark-targets",
    order = "c",
    setting_type = "runtime-global",
    localised_description = { "mod-setting-description.dart-mark-targets" },
    default_value = false,
  },
  {
    type = "string-setting",
    name = "dart-msgLevel",
    order = "m",
    setting_type = "runtime-global",
    localised_description = { "mod-setting-description.dart-msgLevel" },
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
    localised_description = { "mod-setting-description.dart-low-ammo-warning" },
    default_value = true,
  },
  {
    type = "int-setting",
    name = "dart-low-ammo-warning-threshold-default",
    order = "m-aa",
    setting_type = "runtime-global",
    localised_description = { "mod-setting-description.dart-low-ammo-warning-threshold-default" },
    default_value = 200,
    minimum_value = 10,
  },
  {
    type = "string-setting",
    name = "dart-logLevel",
    order = "z",
    setting_type = "runtime-global",
    localised_description = { "mod-setting-description.dart-logLevel" },
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
