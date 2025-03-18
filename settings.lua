data:extend({
  {
    type = "string-setting",
    name = "dart-logLevel",
    order = "za",
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
    name = "dart-mark-targets",
    order = "zb",
    setting_type = "runtime-global",
    localised_description = { "mod-setting-description.dart-mark-targets" },
    default_value = false,
  },
})
