package main

import rl "vendor:raylib" 

ui_object :: struct
{
    open: bool,
    rect: rl.Rectangle,
    object: graph_object,
}

UI_OBJECT_HEIGHT :: 100
UI_OBJECT_SPACING :: 20
UI_OBJECT_BACKGROUND_COLOR :: 0x111211ff

UI_OBJECT_SECTION_BACKGROUND_COLOR :: 0x111211ff

draw_text_centered :: proc(text: cstring, container: rl.Rectangle, font_size: f32 = 23, spacing: f32 = 3, color: rl.Color = rl.WHITE)
{
    font := rl.GetFontDefault()
    text_size := rl.MeasureTextEx(font, text, font_size, spacing)
    rl.DrawTextEx(font, text, { container.x, container.y } + { container.width, container.height }/2 - text_size/2, font_size, spacing, color)
}

is_point_in_rect :: proc(rect: rl.Rectangle, point: rl.Vector2) -> bool
{
    return point.x >= rect.x && point.x <= rect.x + rect.width &&
           point.y >= rect.y && point.y <= rect.y + rect.height 
}

get_graph_object_element_count :: proc(object: graph_object) -> int
{
    switch o in object
    {
        case graph_object_values:
            return len(o.values)
        case graph_object_points:
            return len(o.points)
        case graph_object_function:
            return 1
    }

    panic("unreachable")
}