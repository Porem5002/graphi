package main

import "core:fmt"
import "core:strings"

import grh "graph"
import "mathexpr"

import rl "vendor:raylib" 

ui_editor_tab :: struct
{
    content_offset_y: f32,
    spacing: f32,
    area: grh.responsive(rl.Rectangle),
}

ui_object :: struct
{
    open: bool,
    object: ^grh.object,
}

UI_OBJECT_HEIGHT :: 100
UI_OBJECT_SPACING :: 20
UI_OBJECT_BACKGROUND_COLOR :: 0x202120ff

UI_OBJECT_SECTION_BACKGROUND_COLOR :: 0x111211ff

text_buffer: [300]byte = {}

is_point_in_rect :: proc(rect: rl.Rectangle, point: rl.Vector2) -> bool
{
    return point.x >= rect.x && point.x <= rect.x + rect.width &&
           point.y >= rect.y && point.y <= rect.y + rect.height 
}

ui_text_printf :: proc(format: string, args: ..any) -> cstring
{
    str := fmt.bprintf(text_buffer[:len(text_buffer)-1], format, ..args)
    text_buffer[len(str)] = 0
    return cast(cstring) &text_buffer[0] 
}

get_ui_object_element_count :: proc(object: ui_object) -> int
{
    if(!object.open) do return 1

    switch o in object.object
    {
        case grh.object_values:
            return len(o.values)
        case grh.object_points:
            return len(o.points)
        case grh.object_function:
            return 1
    }

    panic("unreachable")
}

calc_ui_objects_height :: proc(ui_objects: []ui_object, spacing: f32) -> f32
{
    height := spacing

    for ui_o in ui_objects
    {
        element_count := get_ui_object_element_count(ui_o)
        height += spacing + UI_OBJECT_HEIGHT * f32(element_count)
    }

    return height
}

check_ui_objects_interaction_in_tab :: proc(mouse_pos: rl.Vector2, ui_objects: []ui_object, tab: ui_editor_tab)
{
    tab_area := grh.resolve(rl.Rectangle, tab.area)

    yoffset := tab.spacing - tab.content_offset_y
    base_rect := rl.Rectangle { tab_area.x, tab_area.y, tab_area.width, UI_OBJECT_HEIGHT }

    for _, i in ui_objects
    {
        ui_o := &ui_objects[i]

        element_count := get_ui_object_element_count(ui_o^)
        rect := base_rect
        rect.y += yoffset

        if(rl.IsMouseButtonPressed(.LEFT) && is_point_in_rect(rect, mouse_pos))
        {
            ui_o.open = !ui_o.open
        }

        if(rl.IsMouseButtonPressed(.RIGHT) && is_point_in_rect(rect, mouse_pos))
        {
            //TODO: Handle non function objects correctly 
            init_text := ui_o.object.(grh.object_function).text
            text_input_bind(init_text, ui_o.object, proc(dest: rawptr, s: string) {
                dest := cast(^grh.object) dest
                grh.update_mathexpr_object(dest, s)
            })
        }

        yoffset += tab.spacing + rect.height * f32(element_count)
    }
}

draw_ui_objects_in_tab :: proc(ui_objects: []ui_object, tab: ui_editor_tab)
{
    tab_area := grh.resolve(rl.Rectangle, tab.area)

    yoffset := tab.spacing - tab.content_offset_y
    base_rect := rl.Rectangle { tab_area.x, tab_area.y, tab_area.width, UI_OBJECT_HEIGHT }

    for ui_o in ui_objects
    {
        element_count := get_ui_object_element_count(ui_o)
    
        for i in 0..<element_count
        {
            rect := base_rect
            rect.y += yoffset

            rl.DrawRectangleRec(rect, rl.GetColor(UI_OBJECT_BACKGROUND_COLOR))

            switch o in ui_o.object
            {
                case grh.object_values:
                    text := ui_text_printf("%f", o.values[i])
                    draw_text_centered(text, rect, color = o.visual_options.color)
                case grh.object_points:
                    text := ui_text_printf("%f %f", o.points[i].x, o.points[i].y)
                    draw_text_centered(text, rect, color = o.visual_options.color)
                case grh.object_function:
                    text := strings.clone_to_cstring(o.text)
                    draw_text_centered(text, rect, color = o.visual_options.color)
                    delete(text)
            }
        
            yoffset += rect.height
        }

        yoffset += tab.spacing
    }
}

draw_text_centered :: proc(text: cstring, container: rl.Rectangle, font_size: f32 = 23, spacing: f32 = 3, color: rl.Color = rl.WHITE)
{
    font := rl.GetFontDefault()
    text_size := rl.MeasureTextEx(font, text, font_size, spacing)
    rl.DrawTextEx(font, text, { container.x, container.y } + { container.width, container.height }/2 - text_size/2, font_size, spacing, color)
}