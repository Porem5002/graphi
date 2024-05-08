package main

import "core:fmt"

import grh "graph"
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

get_ui_object_element_count :: proc(o: grh.object) -> int
{
    switch o.kind
    {
        case .POINTS:
            o := o.o_points
            return o.open ? len(o.points) : 1
        case .MATHEXPR:
            return 1
    }

    panic("unreachable")
}

ui_tab_click_active :: proc(program: ^program_data) -> bool
{
    return program.popup.mode == .NONE && !program.clicked_button
}

ui_lock_click :: proc(program: ^program_data)
{
    program.clicked_button = true
}

update_tab :: proc(program: ^program_data)
{
    hover, click: bool

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
        rem_btn_color := rl.GRAY

        if ui_tab_click_active(program)
        {
            hover, click = ui_rect_hovered_and_clicked(.LEFT, rem_btn_rect)

            if hover
            {
                rem_btn_color = rl.ColorBrightness(rem_btn_color, 0.3)
                program.curr_cursor = .POINTING_HAND
            }

            if click 
            {
                text_input_unbind()
                grh.pool_remove(&program.objects, i)
                ui_lock_click(program)
                
                i -= 1
                continue
            }
        }

        o := program.objects[i]
        update_object_in_tab(program, rect, o, yoffset)

        drawing.add_entry_rect(draw_group, rem_btn_color, rem_btn_rect)
        drawing.add_entry_centered_cstring(draw_group, "-", rem_btn_rect, rl.WHITE)

        yoffset += tab.spacing + get_object_height(tab^, o^)
    }

    add_btn_rect := get_single_object_rect(tab^, { 0, yoffset })
    add_btn_color := rl.GRAY

    if ui_tab_click_active(program)
    {
        hover, click = ui_rect_hovered_and_clicked(.LEFT, add_btn_rect)

        if hover
        {
            add_btn_color = rl.ColorBrightness(add_btn_color, 0.3)
            program.curr_cursor = .POINTING_HAND
        }

        if click
        {
            append(&program.objects, grh.create_mathexpr("x", graph_display_area_width, color = rl.RED))
            ui_lock_click(program)
        }
    }

    drawing.add_entry_rect(draw_group, add_btn_color, add_btn_rect)
    drawing.add_entry_centered_cstring(draw_group, "+", add_btn_rect, rl.WHITE)
}

update_object_in_tab :: proc(program: ^program_data, rect: rl.Rectangle, o: ^grh.object, yoffset: f32)
{
    tab := &program.tab
    draw_group := &program.draw_group

    color_btn_radius, color_btn_pos := get_ui_color_btn_circle(rect)
    
    if ui_tab_click_active(program)
    {
        hover, click := ui_circle_hovered_and_clicked(.LEFT, color_btn_pos, color_btn_radius)

        if hover do program.curr_cursor = .POINTING_HAND

        if click
        {
            text_input_unbind()
            open_popup_color_picker(&program.popup, o.color, &o.color)
            ui_lock_click(program)
        }
    }

    mouse_pos := rl.GetMousePosition()
    overlap := get_object_overlap(tab^, { 0, yoffset }, o^, mouse_pos)

    if ui_tab_click_active(program) && rl.IsMouseButtonPressed(.LEFT) && overlap == 0 && o.kind == .POINTS
    {
        o.o_points.open = !o.o_points.open
        ui_lock_click(program)
    }

    if ui_tab_click_active(program) && rl.IsMouseButtonPressed(.RIGHT) && overlap >= 0
    {
        //TODO: Allow editing of other object types
        if o.kind == .MATHEXPR
        { 
            init_text := o.o_func.text
            text_input_bind(init_text, { o, 0 }, proc(event_data: text_input_event_data, s: string)
            {
                grh.update_mathexpr_object(event_data.o, s)
            })
        }
        else
        {
            init_text := o.o_points.texts[overlap]
            text_input_bind(init_text, { o, overlap }, proc(event_data: text_input_event_data, s: string)
            {
                grh.update_point_in_object(event_data.o, s, event_data.i)
            })
        }

        ui_lock_click(program)
    }

    elem_rect := rect

    if o.kind == .MATHEXPR
    {
        drawing.add_entry_rect(draw_group, rl.GetColor(UI_OBJECT_BACKGROUND_COLOR), elem_rect)
        drawing.add_entry_centered_text(draw_group, o.o_func.text, elem_rect, o.color)
    }
    else
    {
        for i in 0..<get_ui_object_element_count(o^)
        {
            drawing.add_entry_rect(draw_group, rl.GetColor(UI_OBJECT_BACKGROUND_COLOR), elem_rect)
            drawing.add_entry_centered_text(draw_group, o.o_points.texts[i], elem_rect, o.color)
            elem_rect.y += elem_rect.height
        }
    }
    
    drawing.add_entry_circle_with_border(draw_group, color_btn_pos, color_btn_radius, o.color)
}

ui_rect_hovered_and_clicked :: proc(mouse_btn: rl.MouseButton, rect: rl.Rectangle) -> (hover: bool, click: bool)
{
    mouse_pos := rl.GetMousePosition()
    hover = rl.CheckCollisionPointRec(mouse_pos, rect)
    click = hover && rl.IsMouseButtonPressed(mouse_btn)
    return
}

ui_circle_hovered_and_clicked :: proc(mouse_btn: rl.MouseButton, center: rl.Vector2, radius: f32) -> (hover: bool, click: bool)
{
    mouse_pos := rl.GetMousePosition()
    hover = rl.CheckCollisionPointCircle(mouse_pos, center, radius)
    click = hover && rl.IsMouseButtonPressed(mouse_btn)
    return
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