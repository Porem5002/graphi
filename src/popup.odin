package main

import "core:strings"
import "core:strconv"

import rl "vendor:raylib"

COLOR_MATRIX := [2][4]rl.Color {
    { rl.RED, rl.GREEN, rl.BLUE, rl.VIOLET },
    { rl.YELLOW, rl.ORANGE,  rl.PURPLE, rl.BROWN }
}

curr_popup := popup_data {
    mode = .NONE
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

get_popup_mode :: proc() -> popup_mode
{
    return curr_popup.mode
}

handle_popup_color_picker_input :: proc(mouse_pos: rl.Vector2)
{
    screen := screen_vector()

    menu_rect: rl.Rectangle
    menu_rect.width = screen.x * 0.45
    menu_rect.height = screen.y * 0.5
    menu_rect.x = screen.x/2 - menu_rect.width/2
    menu_rect.y = screen.y/2 - menu_rect.height/2

    close_btn_rect: rl.Rectangle
    close_btn_rect.width = 30;
    close_btn_rect.height = 30;
    close_btn_rect.x = menu_rect.x + menu_rect.width - close_btn_rect.width
    close_btn_rect.y = menu_rect.y

    if rl.IsMouseButtonDown(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, close_btn_rect)
    {
        close_popup()
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
            if rl.IsMouseButtonDown(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, opt_rect)
            {
                curr_popup.color_picker.curr_color = color
                return
            }

            opt_rect.x += opt_rect.width + opt_spacing_x
        }

        opt_rect.y += opt_rect.height + opt_spacing_y
    }

    save_btn_rect: rl.Rectangle
    save_btn_rect.width = menu_rect.width*0.25
    save_btn_rect.height = menu_rect.height*0.12
    save_btn_rect.x = menu_rect.x + menu_rect.width/2 - save_btn_rect.width/2
    save_btn_rect.y = menu_rect.y + menu_rect.height*0.8

    if rl.IsMouseButtonDown(.LEFT) && rl.CheckCollisionPointRec(mouse_pos, save_btn_rect)
    {
        curr_popup.color_picker.dest^ = curr_popup.color_picker.curr_color
        close_popup()
    }
}

draw_popup_color_picker :: proc()
{
    screen := screen_vector()
    screen_rect := rl.Rectangle { x = 0, y = 0 }
    screen_rect.width = screen.x
    screen_rect.height = screen.y

    rl.DrawRectangleRec(screen_rect, rl.Color { 0, 0, 0, 75 })

    menu_rect: rl.Rectangle
    menu_rect.width = screen.x * 0.45
    menu_rect.height = screen.y * 0.5
    menu_rect.x = screen.x/2 - menu_rect.width/2
    menu_rect.y = screen.y/2 - menu_rect.height/2
    rl.DrawRectangleRec(menu_rect, rl.GetColor(UI_OBJECT_SECTION_BACKGROUND_COLOR))

    close_btn_rect: rl.Rectangle
    close_btn_rect.width = 30;
    close_btn_rect.height = 30;
    close_btn_rect.x = menu_rect.x + menu_rect.width - close_btn_rect.width
    close_btn_rect.y = menu_rect.y
    rl.DrawRectangleRec(close_btn_rect, rl.RED)
    draw_text_centered("+", close_btn_rect)

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
            rl.DrawRectangleRec(opt_rect, color)

            opt_rect.x += opt_rect.width + opt_spacing_x
        }

        opt_rect.y += opt_rect.height + opt_spacing_y
    }

    old_color_rect: rl.Rectangle
    old_color_rect.width = menu_rect.width * 0.4
    old_color_rect.height = menu_rect.height * 0.15
    old_color_rect.x = menu_rect.x + menu_rect.width/2 - old_color_rect.width
    old_color_rect.y = menu_rect.y + menu_rect.height*0.7 - old_color_rect.height
    rl.DrawRectangleRec(old_color_rect, curr_popup.color_picker.old_color)

    curr_color_rect := old_color_rect
    curr_color_rect.x += curr_color_rect.width
    rl.DrawRectangleRec(curr_color_rect, curr_popup.color_picker.curr_color)
    
    border_colors_rect := old_color_rect
    border_colors_rect.width *= 2
    rl.DrawRectangleLinesEx(border_colors_rect, 1, rl.WHITE)

    save_btn_rect: rl.Rectangle
    save_btn_rect.width = menu_rect.width*0.25
    save_btn_rect.height = menu_rect.height*0.12
    save_btn_rect.x = menu_rect.x + menu_rect.width/2 - save_btn_rect.width/2
    save_btn_rect.y = menu_rect.y + menu_rect.height*0.8
    rl.DrawRectangleRec(save_btn_rect, rl.GRAY)
    draw_text_centered("Save", save_btn_rect)
}

open_popup_color_picker :: proc(old_color: rl.Color, dest: ^rl.Color)
{
    curr_popup.mode = .COLOR_PICKER
    curr_popup.color_picker = {
        old_color = old_color,
        curr_color = old_color,
        dest = dest
    }
}

close_popup :: proc()
{
    text_input_unbind()
    curr_popup.mode = .NONE
}