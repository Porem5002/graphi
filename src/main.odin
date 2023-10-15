package main

import "core:fmt"
import "core:math"
import "core:c"

import rl "vendor:raylib"

graph := graph_info {
    display_area = graph_display_area,
    x_axis = axis_segment { offset = -1, span = 2, step = 0.5 },
    y_axis = axis_segment { offset = -1, span = 2, step = 0.5 },
    scale = 1.0
}

POINT_SIZE :: 4.0
SCALE_FACTOR :: 10.0
MOVEMENT_SPEED :: 3.0

TARGET_FPS :: 60

main :: proc ()
{
    rl.InitWindow(900, 900, "GraPhi")
    
    flags := rl.ConfigFlags { rl.ConfigFlag.WINDOW_RESIZABLE }
    rl.SetWindowState(flags)

    rl.SetTargetFPS(TARGET_FPS)
 
    for (!rl.WindowShouldClose())
    {
        /* Scale Controls */
        graph.scale -= rl.GetMouseWheelMove() * rl.GetFrameTime() * SCALE_FACTOR
        graph.scale = max(graph.scale, math.F32_EPSILON)

        /* Offset/Movement Controls */
        if(rl.IsKeyPressed(.W) || rl.IsKeyDown(.W))
        {
            graph.y_axis.offset += rl.GetFrameTime() * MOVEMENT_SPEED * graph.scale
        }

        if(rl.IsKeyPressed(.S) || rl.IsKeyDown(.S))
        {
            graph.y_axis.offset -= rl.GetFrameTime() * MOVEMENT_SPEED * graph.scale
        }

        if(rl.IsKeyPressed(.D) || rl.IsKeyDown(.D))
        {
            graph.x_axis.offset += rl.GetFrameTime() * MOVEMENT_SPEED * graph.scale
        }

        if(rl.IsKeyPressed(.A) || rl.IsKeyDown(.A))
        {
            graph.x_axis.offset -= rl.GetFrameTime() * MOVEMENT_SPEED * graph.scale
        }

        rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)
            rl.DrawFPS(10, 10)

            draw_vertical_step_indicators(graph, rl.GRAY)
            draw_horizontal_step_indicators(graph, rl.GRAY)

            draw_values_in_graph([]f32 { 85, 70, 65, 75, 44, 54, 23, 60 }, graph, .LINES, POINT_SIZE, rl.GREEN)
            draw_values_in_graph([]f32 { 85, 70, 65, 75, 44, 54, 23, 60 }, graph, .POINTS, POINT_SIZE, rl.BLUE)

            draw_points_in_graph([]rl.Vector2 { {10, 9}, {1.8, 1.7}, {2.8, 9}, {5, 12} }, graph, .LINES, POINT_SIZE, rl.BLUE)

            draw_function_in_graph(f, graph, graph_display_area().width, .LINES, POINT_SIZE, rl.GREEN)
            draw_function_in_graph(math.exp_f32, graph, graph_display_area().width, .LINES, POINT_SIZE, rl.YELLOW)
            draw_function_in_graph(math.tan_f32, graph, graph_display_area().width, .LINES, POINT_SIZE, rl.VIOLET)
        rl.EndDrawing()
    }

    rl.CloseWindow()
}

graph_display_area :: proc() -> rl.Rectangle
{
    screen_size := screen_vector()
    return { 0, 0, screen_size.x, screen_size.y }
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