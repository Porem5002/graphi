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

ui_allow_tab_click :: proc(program: ^program_data) -> bool
{
    return program.popup.mode == .NONE && !program.clicked_button
}

ui_allow_popup_click :: proc(program: ^program_data) -> bool
{
    return program.popup.mode != .NONE && !program.clicked_button
}

ui_lock_click :: proc(program: ^program_data)
{
    program.clicked_button = true
}

update_tab :: proc(program: ^program_data)
{
    tab := &program.tab
    draw_group := &program.draw_group

    yoffset := tab.spacing - tab.content_offset_y

    base_rect := tab.area
    base_rect.height = tab.obj_height

    for i := 0; i < len(program.objects); i += 1
    {
        rect := base_rect
        rect.y += yoffset
        
        rem_btn_rect := get_ui_rem_btn_rect(rect)
        if ui_allow_tab_click(program) && ui_rect_clicked(.LEFT, rem_btn_rect) 
        {
            text_input_unbind()
            grh.pool_remove(&program.objects, i)
            ui_lock_click(program)
            
            i -= 1
            continue
        }

        o := program.objects[i]
        update_object_in_tab(program, rect, o, yoffset)
        yoffset += tab.spacing + get_object_height(tab^, o^)
    }

    add_btn_rect := get_single_object_rect(tab^, { 0, yoffset })
    if ui_allow_tab_click(program) && ui_rect_clicked(.LEFT, add_btn_rect)
    {
        append(&program.objects, grh.create_mathexpr("x", graph_display_area_width, color = rl.RED))
        ui_lock_click(program)
    }

    drawing.add_entry_rect(draw_group, rl.GRAY, add_btn_rect)
    drawing.add_entry_centered_cstring(draw_group, "+", add_btn_rect, rl.WHITE)
}

update_object_in_tab :: proc(program: ^program_data, rect: rl.Rectangle, o: ^grh.object, yoffset: f32)
{
    tab := &program.tab
    draw_group := &program.draw_group
    objs := &program.objects
    mouse_pos := program.mouse_pos

    color_btn_radius, color_btn_pos := get_ui_color_btn_circle(rect)

    if ui_allow_tab_click(program) && ui_circle_clicked(.LEFT, color_btn_pos, color_btn_radius)
    {
        text_input_unbind()
        
        color_ptr := get_object_color_ptr(o)
        open_popup_color_picker(&program.popup, color_ptr^, color_ptr)

        ui_lock_click(program)
    }

    overlap := get_object_overlap(tab^, { 0, yoffset }, o^, mouse_pos)

    if ui_allow_tab_click(program) && rl.IsMouseButtonPressed(.LEFT) && overlap == 0 && grh.get_object_type(o^) == .POINTS
    {
        ps := o.(grh.object_points)
        ps.open = !ps.open
        o^ = ps
        ui_lock_click(program)
    }

    if ui_allow_tab_click(program) && rl.IsMouseButtonPressed(.RIGHT) && overlap >= 0
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

        ui_lock_click(program)
    }

    elem_count := get_ui_object_element_count(o^)
    elem_rect := rect

    for i in 0..<elem_count
    {
        drawing.add_entry_rect(draw_group, rl.GetColor(UI_OBJECT_BACKGROUND_COLOR), elem_rect)

        switch o in o
        {
            case grh.object_points:
                drawing.add_entry_centered_text(draw_group, o.texts[i], elem_rect, o.color)
            case grh.object_function:
                drawing.add_entry_centered_text(draw_group, o.text, elem_rect, o.color)
        }
    
        elem_rect.y += elem_rect.height
    }

    rem_btn_rect := get_ui_rem_btn_rect(rect)
    drawing.add_entry_rect(draw_group, rl.GRAY, rem_btn_rect)
    drawing.add_entry_centered_cstring(draw_group, "-", rem_btn_rect, rl.WHITE)

    drawing.add_entry_circle(draw_group, color_btn_pos, color_btn_radius, rl.WHITE)
    drawing.add_entry_circle(draw_group, color_btn_pos, color_btn_radius*0.9, get_object_color(o))
}

ui_rect_clicked :: proc(mouse_btn: rl.MouseButton, rect: rl.Rectangle) -> bool
{
    mouse_pos := rl.GetMousePosition()
    return rl.IsMouseButtonPressed(mouse_btn) && rl.CheckCollisionPointRec(mouse_pos, rect)
}

ui_circle_clicked :: proc(mouse_btn: rl.MouseButton, center: rl.Vector2, radius: f32) -> bool
{
    mouse_pos := rl.GetMousePosition()
    return rl.IsMouseButtonPressed(mouse_btn) && rl.CheckCollisionPointCircle(mouse_pos, center, radius)
}

// TODO: Graph objects should use raw unions to avoid this
get_object_color :: proc(obj: ^grh.object) -> rl.Color
{
    switch o in obj
    {
        case grh.object_function:
            return o.color
        case grh.object_points:
            return o.color
    }

    panic("unreachable")
}

// TODO: Graph objects should use raw unions to avoid this
get_object_color_ptr :: proc(obj: ^grh.object) -> ^rl.Color
{
    switch o in obj
    {
        case grh.object_function:
            return &o.color
        case grh.object_points:
            return &o.color
    }

    panic("unreachable")
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