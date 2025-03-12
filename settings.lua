data:extend({
  {
    type = "string-setting",
    name = "dart-logLevel",
    order = "za",
    setting_type = "runtime-global",
    localised_description = "Log Level für D.A.R.T",
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
    localised_description = "Ziele für D.A.R.T hervorheben",
    default_value = false,
  },
})
