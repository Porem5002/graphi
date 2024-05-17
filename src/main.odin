package main

import "core:math"
import c "core:c/libc"

import grh "graph"
import "drawing"

import rl "vendor:raylib"

program_data :: struct
{
    clicked_button: bool,

    prev_cursor: rl.MouseCursor,
    curr_cursor: rl.MouseCursor,

    tab: ui_editor_tab,
    objects: grh.object_pool,

    draw_group: drawing.draw_group,
    popup: popup_data,

    scroll: f32,
}

graph := grh.graph {
    display_area = graph_display_area,
    x_axis = { offset = -1, span = 2, step = 0.5 },
    y_axis = { offset = -1, span = 2, step = 0.5 },
    scale = 1.0
}

POINT_SIZE :: 4.0
SCALE_FACTOR :: 10.0
MOVEMENT_SPEED :: 3.0
SCROLL_FACTOR :: 6.0

TARGET_FPS :: 60   

main :: proc()
{
    flags := rl.ConfigFlags { 
        rl.ConfigFlag.MSAA_4X_HINT,
        rl.ConfigFlag.WINDOW_RESIZABLE,
    }
    rl.SetConfigFlags(flags) 

    text_input_init()
    
    rl.InitWindow(500, 500, "GraPhi")
    setup_window_size_and_pos()

    rl.SetTargetFPS(TARGET_FPS)
    rl.SetExitKey(.KEY_NULL)

    draw_ctx := drawing.load_context()
    defer drawing.unload_context(draw_ctx)

    program: program_data
    program.draw_group = {}
    program.prev_cursor = .DEFAULT
    program.curr_cursor = .DEFAULT
    program.popup = popup_data { .NONE, {} }
    program.objects = {}
    program.scroll = 0
    program.tab = ui_editor_tab {
        content_offset_y = 0,
        area = object_edit_area(),
        spacing = UI_OBJECT_SPACING,
        obj_height = UI_OBJECT_HEIGHT
    }

    append(&program.objects, grh.create_mathexpr("x", graph_display_area_width, color = rl.RED))

    for !rl.WindowShouldClose()
    {
        mouse_pos := rl.GetMousePosition()
        mouse_wheel_y := rl.GetMouseWheelMove()
        delta_time := rl.GetFrameTime()

        popup_exists := program.popup.mode != .NONE
        program.tab.area = object_edit_area()
        program.clicked_button = false

        // UI Object Interaction
        total_height := get_full_height(program.tab, program.objects[:])
        scroll_max := total_height - program.tab.area.height

        if !popup_exists && scroll_max > 0 && rl.CheckCollisionPointRec(mouse_pos, program.tab.area)
        {
            program.scroll -= mouse_wheel_y * delta_time * SCROLL_FACTOR
            program.scroll = scroll_max <= 0 ? 0 : clamp(program.scroll, 0, 1)
        }
        else if scroll_max <= 0
        {
            program.scroll = 0
        }

        program.tab.content_offset_y = program.scroll * scroll_max

        update_tab(&program)
        update_popup(&program, &program.popup, &program.draw_group)

        if program.prev_cursor != program.curr_cursor
        {
            rl.SetMouseCursor(program.curr_cursor)
            program.prev_cursor = program.curr_cursor
        }

        program.curr_cursor = .DEFAULT

        // Graph Interaction
        if !popup_exists && rl.CheckCollisionPointRec(mouse_pos, graph_display_area())
        {
            /* Scale Controls */
            graph.scale -= mouse_wheel_y * delta_time * SCALE_FACTOR
            graph.scale = max(graph.scale, math.F32_EPSILON)

            /* Offset/Movement Controls */
            if !text_input.active && (rl.IsKeyPressed(.W) || rl.IsKeyDown(.W))
            {
                graph.y_axis.offset += delta_time * MOVEMENT_SPEED * graph.scale
            }

            if !text_input.active && (rl.IsKeyPressed(.S) || rl.IsKeyDown(.S))
            {
                graph.y_axis.offset -= delta_time * MOVEMENT_SPEED * graph.scale
            }

            if !text_input.active && (rl.IsKeyPressed(.D) || rl.IsKeyDown(.D))
            {
                graph.x_axis.offset += delta_time * MOVEMENT_SPEED * graph.scale
            }

            if !text_input.active && (rl.IsKeyPressed(.A) || rl.IsKeyDown(.A))
            {
                graph.x_axis.offset -= delta_time * MOVEMENT_SPEED * graph.scale
            }
        }

        if rl.IsKeyPressed(.ENTER) do text_input_unbind()

        text_input_update()

        rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)

            grh.draw_vertical_step_indicators(graph, rl.GRAY)
            grh.draw_horizontal_step_indicators(graph, rl.GRAY)
            grh.draw_objects_in_graph(program.objects[:], graph)

            rl.DrawRectangleRec(object_edit_area(), rl.GetColor(UI_OBJECT_SECTION_BACKGROUND_COLOR))

            drawing.draw_all(draw_ctx, &program.draw_group)

            when ODIN_DEBUG do rl.DrawFPS(10, 10)
        rl.EndDrawing()
    }

    rl.CloseWindow()
}

object_edit_area :: proc() -> rl.Rectangle
{
    screen_size := screen_vector()
    return { 0, 0, screen_size.x*0.2, screen_size.y }
}

graph_display_area :: proc() -> rl.Rectangle
{
    object_area := object_edit_area()
    screen_size := screen_vector()
    return { object_area.width, 0, screen_size.x - object_area.width, screen_size.y }
}

graph_display_area_width :: proc() -> f32
{
    return graph_display_area().width
}

setup_window_size_and_pos :: proc()
{
    monitor := rl.GetCurrentMonitor()
    width := rl.GetMonitorWidth(monitor)
    height := rl.GetMonitorHeight(monitor)

    window_width := c.int(f32(width) * 0.8)
    window_height := c.int(f32(height) * 0.8)

    rl.SetWindowSize(window_width, window_height)
    rl.SetWindowPosition((width - window_width)/2, (height - window_height)/2)
}

screen_vector :: proc() -> rl.Vector2
{
    x, y: f32 = ---, ---

    if(rl.IsWindowFullscreen())
    {
        monitor := rl.GetCurrentMonitor()
        x = cast(f32) rl.GetMonitorWidth(monitor)
        y = cast(f32) rl.GetMonitorHeight(monitor)
    }
    else
    {
        x = cast(f32) rl.GetScreenWidth()
        y = cast(f32) rl.GetScreenHeight()
    }

    return { x, y }
}