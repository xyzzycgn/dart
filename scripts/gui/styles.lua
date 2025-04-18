---
--- Created by xyzzycgn.
--- DateTime: 26.12.24 06:01
---

local styles = data.raw["gui-style"].default

styles.dart_top_frame = {
    type = "frame_style",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
    vertically_squashable = "on",
    horizontally_squashable = "on",
    maximal_height = 600,
    maximal_width = 1000,
}

styles.dart_content_frame = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "off",
    horizontally_stretchable = "on",
}

styles.dart_draggable_space_header = {
    type = "empty_widget_style",
    parent = "draggable_space_header",
    horizontally_stretchable = "on",
    left_margin = 4,
    right_margin = 4,
    height = 24,
}

styles.dart_controls_flow = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontal_spacing = 16
}

styles.dart_controls_textfield = {
    type = "textbox_style",
    width = 36
}

styles.dart_stretchable_label_style = {
    parent = "label",
    horizontally_stretchable = "stretch_and_expand",
    type = "label_style"
}

styles.dart_deep_frame = {
    type = "frame_style",
    parent = "deep_frame_in_shallow_frame",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
    vertically_squashable = "on",
    horizontally_squashable = "on",
    top_margin = 8,
    left_margin = 8,
    right_margin = 8,
    bottom_margin = 4
}

styles.dart_tabbed_pane = {
    type = "tabbed_pane_style",
    tab_content_frame = {
        type = "frame_style",
        parent = "tabbed_pane_frame",
        --vertically_stretchable = "on",
        --horizontally_stretchable = "on",
        --vertically_squashable = "on",
        --horizontally_squashable = "on",
        left_padding = 12,
        right_padding = 12,
        bottom_padding = 8,
    },
}

styles.dart_scrollpane_style = {
    type = "scroll_pane_style",
    parent = "flib_naked_scroll_pane_no_padding",
    vertical_flow_style = {
        type = "vertical_flow_style",
        vertical_spacing = 1,
    },
    horizontally_stretchable = "stretch_and_expand",
    vertically_stretchable = "on",
}

styles.dart_table_style = {
    type = "table_style",
    horizontally_stretchable = "stretch_and_expand",
    vertically_stretchable = "on",
    top_margin = 8,
    left_margin = 8,
    right_margin = 8,
    bottom_margin = 4
}

styles.dart_small_slot_table_frame = {
  type = "frame_style",
  minimal_height = 36,
  padding = 0,
  --background_graphical_set = {
  --  base = {
  --    position = { 282, 17 },
  --    corner_size = 8,
  --    overall_tiling_horizontal_padding = 4,
  --    overall_tiling_horizontal_size = 28,
  --    overall_tiling_horizontal_spacing = 8,
  --    overall_tiling_vertical_padding = 4,
  --    overall_tiling_vertical_size = 28,
  --    overall_tiling_vertical_spacing = 8,
  --  },
  --},
}

for _, color in ipairs({ "default", "red", "green", "blue" }) do
    styles["dart_small_slot_button_" .. color] = {
        type = "button_style",
        parent = "flib_slot_button_" .. color,
        size = 36,
    }
end



styles.dart_minimap = {
  type = "minimap_style",
  size = 90,
}

styles.dart_minimap_label = {
  type = "label_style",
  font = "default-game",
  font_color = default_font_color,
  size = 90,
  vertical_align = "bottom",
  horizontal_align = "right",
  right_padding = 4,
}