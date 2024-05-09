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
    screen_rect := ui_vec_to_rect(screen)
    drawing.add_entry_rect(draw_group, rl.Color { 0, 0, 0, 75 }, screen_rect)

    menu_rect := ui_dimensions_to_rect(screen.x * 0.45, screen.y * 0.5)
    menu_rect = ui_rect_centered_inside(menu_rect, screen_rect)
    drawing.add_entry_rect(draw_group, rl.GetColor(UI_OBJECT_SECTION_BACKGROUND_COLOR), menu_rect)

    close_btn_rect := ui_dimensions_to_rect(30, 30)
    close_btn_rect = ui_rect_place_in_corner(close_btn_rect, menu_rect, .TOP_RIGHT)
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
    opt_side := min(opt_spacing_x, opt_spacing_y)

    opt_table_width, opt_table_height := ui_calc_table_dimensions(opt_side, opt_side, opt_spacing_x, opt_spacing_y, 2, 4)

    opt_table_area := ui_dimensions_to_rect(opt_table_width, opt_table_height)
    opt_table_area.x = ui_scalar_centered(menu_rect.x, menu_rect.width, opt_table_width)
    opt_table_area.y = menu_rect.y + menu_rect.height * 0.15

    opt_rect_table := ui_gen_rect_table(opt_table_area, opt_spacing_x, opt_spacing_y, 2, 4)

    for opt_rect_line, l in opt_rect_table
    {
        for opt_rect, c in opt_rect_line
        {
            color := COLOR_MATRIX[l][c]
            new_rect := opt_rect

            hover, click = ui_rect_hovered_and_clicked(.LEFT, new_rect)

            if hover
            {
                new_rect = ui_scale_rect(new_rect, 1.15)
                program.curr_cursor = .POINTING_HAND
            }

            if click do color_picker.curr_color = color

            drawing.add_entry_rect(draw_group, color, new_rect)
        }    
    }

    color_row_area_width := ui_calc_sequence_length(menu_rect.width * 0.4, 0, 2)
    color_row_area := ui_dimensions_to_rect(color_row_area_width, menu_rect.height * 0.15)
    color_row_area.x = ui_scalar_centered(menu_rect.x, menu_rect.width, color_row_area.width)
    color_row_area.y = menu_rect.y + menu_rect.height*0.7 - color_row_area.height
    color_row_rects := ui_gen_rect_row(color_row_area, 0, 2)

    drawing.add_entry_rect(draw_group, color_picker.old_color, color_row_rects[0])
    drawing.add_entry_rect(draw_group, color_picker.curr_color, color_row_rects[1])
    drawing.add_entry_rect_lines(draw_group, rl.WHITE, color_row_area)

    save_btn_rect := ui_dimensions_to_rect(menu_rect.width*0.25, menu_rect.height*0.12)
    save_btn_rect.x = ui_scalar_centered(menu_rect.x, menu_rect.width, save_btn_rect.width)
    save_btn_rect.y = menu_rect.y + menu_rect.height*0.8
    save_btn_color := rl.GRAY

    hover, click = ui_rect_hovered_and_clicked(.LEFT, save_btn_rect)

    if hover
    {
        save_btn_color = rl.ColorBrightness(save_btn_color, 0.3)
        program.curr_cursor = .POINTING_HAND
    }

    if click
    {
        color_picker.dest^ = color_picker.curr_color
        close_popup(popup)
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