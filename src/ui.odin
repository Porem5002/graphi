package main

import "core:fmt"
import "core:strings"
import "core:mem"

import grh "graph"
import "mathexpr"
import "drawing"

import rl "vendor:raylib" 

ui_editor_tab :: struct
{
    content_offset_y: f32,
    obj_height: f32,
    spacing: f32,
    area: rl.Rectangle,
}

UI_OBJECT_HEIGHT :: 100
UI_OBJECT_SPACING :: 20
UI_OBJECT_BACKGROUND_COLOR :: 0x202120ff

UI_OBJECT_SECTION_BACKGROUND_COLOR :: 0x111211ff

text_buffer: [300]byte = {}

ui_text_printf :: proc(format: string, args: ..any) -> cstring
{
    str := fmt.bprintf(text_buffer[:len(text_buffer)-1], format, ..args)
    text_buffer[len(str)] = 0
    return cast(cstring) &text_buffer[0] 
}

get_ui_rem_btn_rect :: proc(obj_rect: rl.Rectangle) -> rl.Rectangle
{
    full_height := obj_rect.height
    btn_side := full_height / 3

    rect: rl.Rectangle
    rect.width = btn_side
    rect.height = btn_side
    rect.x = obj_rect.x + 15
    rect.y = obj_rect.y + full_height/2 - btn_side/2
    
    return rect
}

get_ui_color_btn_circle :: proc(obj_rect: rl.Rectangle) -> (radius: f32, center: rl.Vector2)
{
    full_height := obj_rect.height
    diameter := full_height / 3

    radius = diameter / 2
    center.x = obj_rect.x + obj_rect.width - radius*2 - 15;
    center.y = obj_rect.y + full_height/2 
    return
}

get_ui_object_element_count :: proc(obj: grh.object) -> int
{
    switch o in obj
    {
        case grh.object_points:
            return o.open ? len(o.points) : 1
        case grh.object_function:
            return 1
    }

    panic("unreachable")
}

handle_input_for_objects_in_tab :: proc(popup: ^popup_data, tab: ui_editor_tab, mouse_pos: rl.Vector2, objs: ^grh.object_pool)
{
    yoffset := tab.spacing - tab.content_offset_y

    base_rect := tab.area
    base_rect.height = tab.obj_height

    for o, i in objs
    {
        rect := base_rect
        rect.y += yoffset
        rem_btn_rect := get_ui_rem_btn_rect(rect)

        if(rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, rem_btn_rect))
        {
            text_input_unbind()
            grh.pool_remove(objs, i)
            return
        }

        color_btn_radius, color_btn_pos := get_ui_color_btn_circle(rect)

        if(rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointCircle(mouse_pos, color_btn_pos, color_btn_radius))
        {
            text_input_unbind()
            
            switch _ in o
            {
                case grh.object_function:
                    o := &o.(grh.object_function)
                    open_popup_color_picker(popup, o.color, &o.color)
                case grh.object_points:
                    o := &o.(grh.object_points)
                    open_popup_color_picker(popup, o.color, &o.color)
            }

            return
        }

        overlap := get_object_overlap(tab, { 0, yoffset }, o^, mouse_pos)

        if(rl.IsMouseButtonPressed(.LEFT) && overlap == 0 && grh.get_object_type(o^) == .POINTS)
        {
            ps := o.(grh.object_points)
            ps.open = !ps.open
            o^ = ps
        }

        if(rl.IsMouseButtonPressed(.RIGHT) && overlap >= 0)
        {
            //TODO: Allow editing of other object types
            if grh.get_object_type(o^) == .MATHEXPR
            { 
                init_text := o.(grh.object_function).text
                text_input_bind(init_text, { o, 0 }, proc(event_data: text_input_event_data, s: string)
                {
                    grh.update_mathexpr_object(event_data.o, s)
                })
            }
            else
            {
                init_text := o.(grh.object_points).texts[overlap]
                text_input_bind(init_text, { o, overlap }, proc(event_data: text_input_event_data, s: string)
                {
                    grh.update_point_in_object(event_data.o, s, event_data.i)
                })
            }
        }

        yoffset += tab.spacing + get_object_height(tab, o^)
    }

    add_btn_rect := get_single_object_rect(tab, { 0, yoffset })
    if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, add_btn_rect)
    {
        append(objs, grh.create_mathexpr("x", graph_display_area_width, color = rl.RED))
    }
}

draw_objects_in_tab :: proc(tab: ui_editor_tab, objs: grh.object_const_pool)
{
    yoffset := tab.spacing - tab.content_offset_y

    base_rect := tab.area
    base_rect.height = tab.obj_height

    for o in objs
    {
        element_count := get_ui_object_element_count(o^)
    
        for i in 0..<element_count
        {
            rect := base_rect
            rect.y += yoffset

            rl.DrawRectangleRec(rect, rl.GetColor(UI_OBJECT_BACKGROUND_COLOR))

            if i == 0
            {
                rem_btn_rect := get_ui_rem_btn_rect(rect)
                rl.DrawRectangleRec(rem_btn_rect, rl.GRAY)
                drawing.draw_cstring_centered("-", rem_btn_rect, color = rl.WHITE)
            }

            switch o in o
            {
                case grh.object_points:
                    if i == 0
                    {
                        color_btn_radius, color_btn_pos := get_ui_color_btn_circle(rect)
                        rl.DrawCircleV(color_btn_pos, color_btn_radius, rl.WHITE)
                        rl.DrawCircleV(color_btn_pos, color_btn_radius*0.9, o.visual_options.color)
                    }

                    drawing.draw_text_centered(o.texts[i], rect, color = o.visual_options.color)
                case grh.object_function:
                    if i == 0
                    {
                        color_btn_radius, color_btn_pos := get_ui_color_btn_circle(rect)
                        rl.DrawCircleV(color_btn_pos, color_btn_radius, rl.WHITE)
                        rl.DrawCircleV(color_btn_pos, color_btn_radius*0.9, o.visual_options.color)
                    }

                    drawing.draw_text_centered(o.text, rect, color = o.visual_options.color)
            }
        
            yoffset += rect.height
        }

        yoffset += tab.spacing
    }

    add_btn_rect := get_single_object_rect(tab, { 0, yoffset })
    rl.DrawRectangleRec(add_btn_rect, rl.GRAY)
    drawing.draw_cstring_centered("+", add_btn_rect, font_size = 30, color = rl.WHITE)
}

get_single_object_rect :: proc(tab: ui_editor_tab, offset: rl.Vector2) -> rl.Rectangle
{
    return rl.Rectangle { x = offset.x, y = offset.y, width = tab.area.width, height = tab.obj_height }
}

get_object_overlap :: proc(tab: ui_editor_tab, offset: rl.Vector2, obj: grh.object, p: rl.Vector2) -> int
{
    offset := offset
    ecount := get_ui_object_element_count(obj)

    for i in 0 ..< ecount
    {
        rect := get_single_object_rect(tab, offset)

        if rl.CheckCollisionPointRec(p, rect)
        {
            return i
        }

        offset.y += rect.height
    }

    return -1
}

get_object_height :: proc(tab: ui_editor_tab, obj: grh.object) -> f32
{
    ecount := get_ui_object_element_count(obj)
    return tab.obj_height * f32(ecount)
}

get_full_height :: proc(tab: ui_editor_tab, objs: grh.object_const_pool) -> f32
{
    height: f32 = tab.spacing

    for o in objs
    {
        height += get_object_height(tab, o^) + tab.spacing
    }

    // Consider '+' button
    height += tab.obj_height + tab.spacing

    return height
}