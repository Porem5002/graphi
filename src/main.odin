package main

import "core:fmt"
import "core:math"
import "core:c"

import grh "graph"
import "drawing"

import rl "vendor:raylib"

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

scroll: f32 = 0.0

objects := grh.object_pool {}

main :: proc()
{
    flags := rl.ConfigFlags { 
        rl.ConfigFlag.MSAA_4X_HINT,
        rl.ConfigFlag.WINDOW_RESIZABLE,
    }
    rl.SetConfigFlags(flags)

    text_input_init()
    rl.InitWindow(900, 900, "GraPhi")

    rl.SetTargetFPS(TARGET_FPS)

    popup := popup_data { .NONE, {} }

    draw_group := drawing.draw_group {}

    tab := ui_editor_tab {
        content_offset_y = 0,
        area = object_edit_area(),
        spacing = UI_OBJECT_SPACING,
        obj_height = UI_OBJECT_HEIGHT
    }

    append(&objects, grh.create_points({ "1, 2" , "2, 4", "3, 6", "4, 8" }, color = rl.GREEN))
    append(&objects, grh.create_mathexpr("sin(x) + x", graph_display_area_width, color = rl.YELLOW))
    append(&objects, grh.create_mathexpr("5", graph_display_area_width, color = rl.BLUE))
    append(&objects, grh.create_mathexpr("-x * x", graph_display_area_width, color = rl.RED))

    for !rl.WindowShouldClose()
    {
        mouse_pos := rl.GetMousePosition()
        mouse_wheel_y := rl.GetMouseWheelMove()
        delta_time := rl.GetFrameTime()

        popup_exists := popup.mode != .NONE
        tab.area = object_edit_area()

        // UI Object Interaction
        total_height := get_full_height(tab, objects[:])
        scroll_max := total_height - tab.area.height

        if !popup_exists && scroll_max > 0 && rl.CheckCollisionPointRec(mouse_pos, tab.area)
        {
            scroll -= mouse_wheel_y * delta_time * SCROLL_FACTOR
            scroll = scroll_max <= 0 ? 0 : clamp(scroll, 0, 1)
        }
        else if scroll_max <= 0
        {
            scroll = 0
        }

        tab.content_offset_y = scroll * scroll_max

        if !popup_exists
        {
            handle_input_for_objects_in_tab(&popup, tab, mouse_pos, &objects)
        }
        else
        {
            update_popup(&popup, &draw_group, mouse_pos)
        }

        // Graph Interaction
        if !popup_exists && rl.CheckCollisionPointRec(mouse_pos, graph_display_area())
        {
            /* Scale Controls */
            graph.scale -= mouse_wheel_y * delta_time * SCALE_FACTOR
            graph.scale = max(graph.scale, math.F32_EPSILON)

            /* Offset/Movement Controls */
            if rl.IsKeyPressed(.W) || rl.IsKeyDown(.W)
            {
                graph.y_axis.offset += delta_time * MOVEMENT_SPEED * graph.scale
            }

            if rl.IsKeyPressed(.S) || rl.IsKeyDown(.S)
            {
                graph.y_axis.offset -= delta_time * MOVEMENT_SPEED * graph.scale
            }

            if rl.IsKeyPressed(.D) || rl.IsKeyDown(.D)
            {
                graph.x_axis.offset += delta_time * MOVEMENT_SPEED * graph.scale
            }

            if rl.IsKeyPressed(.A) || rl.IsKeyDown(.A)
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
            grh.draw_objects_in_graph(objects[:], graph)

            rl.DrawRectangleRec(object_edit_area(), rl.GetColor(UI_OBJECT_SECTION_BACKGROUND_COLOR))            

            draw_objects_in_tab(tab, objects[:])

            drawing.draw_all(&draw_group)

            rl.DrawFPS(10, 10)
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