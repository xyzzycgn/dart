--- Created by xyzzycgn.
--- DateTime: 26.12.24 06:01
---

local flib_data_util = require("__flib__.data-util")

local styles = data.raw["gui-style"].default

local function graphical_set(filename)
    return { filename = "__core__/graphics/arrows/" .. filename, size = { 16, 16 }, scale = 0.5, }
end

local empty_checkmark = {
    filename = flib_data_util.empty_image,
    priority = "very-low",
    width = 1,
    height = 1,
    frame_count = 1,
    scale = 8,
}

styles.dart_camera = {
    type = "camera_style",
    size = 90,
}

styles.dart_camera_wide = {
    type = "camera_style",
    size = 360,
}

styles.dart_content_frame = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "off",
    horizontally_stretchable = "on",
}

styles.dart_controls_flow = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontal_spacing = 16
}

styles.dart_bottom_button_frame = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "off",
    horizontally_stretchable = "on",
    horizontal_align = "center",
}

styles.dart_bottom_button_flow = {
    type = "horizontal_flow_style",
    vertically_stretchable = "off",
    horizontally_stretchable = "on",
    horizontal_align = "center",
}

styles.dart_centered_stretch_off_flow = {
    type = "horizontal_flow_style",
    vertically_stretchable = "off",
    horizontally_stretchable = "off",
    horizontal_align = "center",
}

styles.dart_centered_flow = {
    type = "horizontal_flow_style",
    vertically_stretchable = "off",
    horizontally_stretchable = "on",
    horizontal_align = "center",
}


styles.dart_controls_textfield = {
    type = "textbox_style",
    width = 36
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

styles.dart_draggable_space_header = {
    type = "empty_widget_style",
    parent = "draggable_space_header",
    horizontally_stretchable = "on",
    left_margin = 4,
    right_margin = 4,
    height = 24,
}

styles.dart_minimap = {
    type = "minimap_style",
    size = 90,
}

styles.dart_minimap_label = {
    type = "label_style",
    font = "default-small",
    font_color = { 0, 0.7, 0 },
    width = 90,
    vertical_align = "bottom",
    horizontal_align = "left",
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

-- selected is orange by default
styles.dart_selected_sort_checkbox = {
    type = "checkbox_style",
    parent = "dart_sort_checkbox",
    default_graphical_set = graphical_set("table-header-sort-arrow-down-active.png"),
    selected_graphical_set = graphical_set("table-header-sort-arrow-up-active.png"),
}

for _, color in ipairs({ "default", "red", "green", "blue" }) do
    styles["dart_small_slot_button_" .. color] = {
        type = "button_style",
        parent = "flib_slot_button_" .. color,
        size = 36,
    }
end

styles.dart_small_slot_table_frame = {
    type = "frame_style",
    minimal_height = 36,
    padding = 0,
}

-- inactive is grey until hovered
-- checked = ascending, unchecked = descending
styles.dart_sort_checkbox = {
    type = "checkbox_style",
    font = "default-bold",
    padding = 0,
    default_graphical_set = graphical_set("table-header-sort-arrow-down-white.png"),
    hovered_graphical_set = graphical_set("table-header-sort-arrow-down-hover.png"),
    clicked_graphical_set = graphical_set("table-header-sort-arrow-down-white.png"),
    disabled_graphical_set = graphical_set("table-header-sort-arrow-down-white.png"),
    selected_graphical_set = graphical_set("table-header-sort-arrow-up-white.png"),
    selected_hovered_graphical_set = graphical_set("table-header-sort-arrow-up-hover.png"),
    selected_clicked_graphical_set = graphical_set("table-header-sort-arrow-up-white.png"),
    selected_disabled_graphical_set = graphical_set("table-header-sort-arrow-up-white.png"),
    checkmark = empty_checkmark,
    disabled_checkmark = empty_checkmark,
    text_padding = 5,
    horizontally_stretchable = "stretch_and_expand",
}

styles.dart_stretchable_label_style = {
    parent = "label",
    horizontally_stretchable = "stretch_and_expand",
    type = "label_style"
}

styles.dart_stretchable_flow_style = {
    type = "horizontal_flow_style",
    horizontally_stretchable = "stretch_and_expand",
}

styles.dart_stretchable_vertical_flow_style = {
    type = "vertical_flow_style",
    horizontally_stretchable = "stretch_and_expand",
}

styles.dart_content_frame_stretchable = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "off",
    horizontally_stretchable = "stretch_and_expand",
    horizontal_flow_style = styles.dart_stretchable_flow_style
}

styles.dart_tabbed_pane = {
    type = "tabbed_pane_style",
    tab_content_frame = {
        type = "frame_style",
        parent = "tabbed_pane_frame",
        left_padding = 12,
        right_padding = 12,
        bottom_padding = 8,
    },
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

styles.dart_top_frame = {
    type = "frame_style",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
    vertically_squashable = "on",
    horizontally_squashable = "on",
    maximal_height = 600,
    maximal_width = 1000,
}

styles.dart_top_frame_800 = {
    type = "frame_style",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
    vertically_squashable = "on",
    horizontally_squashable = "on",
    maximal_height = 800,
    maximal_width = 1000,
}