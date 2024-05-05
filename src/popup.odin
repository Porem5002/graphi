package main

import "core:strings"
import "core:strconv"

import rl "vendor:raylib"
import "drawing"

COLOR_MATRIX := [2][4]rl.Color {
    { rl.RED, rl.GREEN, rl.BLUE, rl.VIOLET },
    { rl.YELLOW, rl.ORANGE,  rl.PURPLE, rl.BROWN }
}

popup_mode :: enum
{
    NONE,
    COLOR_PICKER
}

popup_data :: struct
{
    mode: popup_mode,
    color_picker: popup_color_picker
}

popup_color_picker :: struct
{
    old_color: rl.Color,
    curr_color: rl.Color,
    dest: ^rl.Color,
}

update_popup :: proc(popup: ^popup_data, draw_group: ^drawing.draw_group, mouse_pos: rl.Vector2)
{
    switch popup.mode
    {
        case .NONE:
        case .COLOR_PICKER:
            update_popup_color_picker(popup, draw_group, mouse_pos)
    }
}

update_popup_color_picker :: proc(popup: ^popup_data, draw_group: ^drawing.draw_group, mouse_pos: rl.Vector2)
{
    color_picker := &popup.color_picker
    clicked := false

    screen := screen_vector()
    screen_rect := rl.Rectangle { x = 0, y = 0 }
    screen_rect.width = screen.x
    screen_rect.height = screen.y
    drawing.add_entry_rect(draw_group, rl.Color { 0, 0, 0, 75 }, screen_rect)

    menu_rect: rl.Rectangle
    menu_rect.width = screen.x * 0.45
    menu_rect.height = screen.y * 0.5
    menu_rect.x = screen.x/2 - menu_rect.width/2
    menu_rect.y = screen.y/2 - menu_rect.height/2
    drawing.add_entry_rect(draw_group, rl.GetColor(UI_OBJECT_SECTION_BACKGROUND_COLOR), menu_rect)

    close_btn_rect: rl.Rectangle
    close_btn_rect.width = 30;
    close_btn_rect.height = 30;
    close_btn_rect.x = menu_rect.x + menu_rect.width - close_btn_rect.width
    close_btn_rect.y = menu_rect.y
    drawing.add_entry_rect(draw_group, rl.RED, close_btn_rect)
    drawing.add_entry_centered_text(draw_group, "+", close_btn_rect, rl.WHITE)

    if !clicked && rl.IsMouseButtonDown(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, close_btn_rect)
    {
        close_popup(popup)
        clicked = true
        return
    }

    opt_spacing_x := menu_rect.width*0.1
    opt_spacing_y := menu_rect.height*0.1

    opt_rect: rl.Rectangle
    opt_rect.width = min(opt_spacing_x, opt_spacing_y)
    opt_rect.height = opt_rect.width
    opt_rect.x = menu_rect.x + menu_rect.width/2 - ((opt_rect.width + opt_spacing_x) * len(COLOR_MATRIX[0]) - opt_spacing_x) / 2
    opt_rect.y = menu_rect.y + menu_rect.height * 0.15

    start_x := opt_rect.x

    for _, y in COLOR_MATRIX
    {
        opt_rect.x = start_x

        for color in COLOR_MATRIX[y]
        {
            drawing.add_entry_rect(draw_group, color, opt_rect)

            if !clicked && rl.IsMouseButtonDown(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, opt_rect)
            {
                color_picker.curr_color = color
                clicked = true
            }

            opt_rect.x += opt_rect.width + opt_spacing_x
        }

        opt_rect.y += opt_rect.height + opt_spacing_y
    }

    old_color_rect: rl.Rectangle
    old_color_rect.width = menu_rect.width * 0.4
    old_color_rect.height = menu_rect.height * 0.15
    old_color_rect.x = menu_rect.x + menu_rect.width/2 - old_color_rect.width
    old_color_rect.y = menu_rect.y + menu_rect.height*0.7 - old_color_rect.height
    drawing.add_entry_rect(draw_group, color_picker.old_color, old_color_rect)

    curr_color_rect := old_color_rect
    curr_color_rect.x += curr_color_rect.width
    drawing.add_entry_rect(draw_group, color_picker.curr_color, curr_color_rect)
    
    border_colors_rect := old_color_rect
    border_colors_rect.width *= 2
    drawing.add_entry_rect_lines(draw_group, rl.WHITE, border_colors_rect)

    save_btn_rect: rl.Rectangle
    save_btn_rect.width = menu_rect.width*0.25
    save_btn_rect.height = menu_rect.height*0.12
    save_btn_rect.x = menu_rect.x + menu_rect.width/2 - save_btn_rect.width/2
    save_btn_rect.y = menu_rect.y + menu_rect.height*0.8
    drawing.add_entry_rect(draw_group, rl.GRAY, save_btn_rect)
    drawing.add_entry_centered_text(draw_group, "Save", save_btn_rect, rl.WHITE)

    if !clicked && rl.IsMouseButtonDown(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, save_btn_rect)
    {
        color_picker.dest^ = color_picker.curr_color
        close_popup(popup)
        clicked = true
    }
}

open_popup_color_picker :: proc(popup: ^popup_data, old_color: rl.Color, dest: ^rl.Color)
{
    popup.mode = .COLOR_PICKER
    popup.color_picker = {
        old_color = old_color,
        curr_color = old_color,
        dest = dest
    }
}

close_popup :: proc(popup: ^popup_data)
{
    text_input_unbind()
    popup.mode = .NONE
}