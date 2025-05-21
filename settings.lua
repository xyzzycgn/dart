data:extend({
  {
    type = "string-setting",
    name = "dart-logLevel",
    order = "a",
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
    order = "d",
    setting_type = "runtime-global",
    localised_description = { "mod-setting-description.dart-msgLevel" },
    default_value = "ALL",
    allowed_values = {
      "NONE",
      "ALERTS",
      "INFOSONLY",
      "ALL",
    }
  },})
