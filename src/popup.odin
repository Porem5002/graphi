package main

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

update_popup :: proc(program: ^program_data, popup: ^popup_data, draw_group: ^drawing.draw_group)
{
    switch popup.mode
    {
        case .NONE:
        case .COLOR_PICKER:
            update_popup_color_picker(program, popup, draw_group)
    }
}

update_popup_color_picker :: proc(program: ^program_data, popup: ^popup_data, draw_group: ^drawing.draw_group)
{
    hover, click: bool
    color_picker := &popup.color_picker

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
    close_btn_color := rl.RED

    hover, click = ui_rect_hovered_and_clicked(.LEFT, close_btn_rect)

    if hover
    {
        close_btn_color = rl.ColorBrightness(close_btn_color, 0.3)
        program.curr_cursor = .POINTING_HAND
    }

    if click
    {
        close_popup(popup)
        return
    }
    
    drawing.add_entry_rect(draw_group, close_btn_color, close_btn_rect)
    drawing.add_entry_centered_cstring(draw_group, "+", close_btn_rect, rl.WHITE)

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
            hover, click = ui_rect_hovered_and_clicked(.LEFT, opt_rect)

            if hover do program.curr_cursor = .POINTING_HAND

            if click do color_picker.curr_color = color

            drawing.add_entry_rect(draw_group, color, opt_rect)

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
    save_btn_color := rl.GRAY

    hover, click = ui_rect_hovered_and_clicked(.LEFT, save_btn_rect)

    if hover
    {
        save_btn_color = rl.ColorBrightness(save_btn_color, 0.3)
        program.curr_cursor = .POINTING_HAND
    }

    if click //allow_click && click
    {
        color_picker.dest^ = color_picker.curr_color
        close_popup(popup)
        //allow_click = false
    }

    drawing.add_entry_rect(draw_group, save_btn_color, save_btn_rect)
    drawing.add_entry_centered_cstring(draw_group, "Save", save_btn_rect, rl.WHITE)
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