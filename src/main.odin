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

POINT_COUNT :: 200
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

            draw_vertical_step_indicators(graph, rl.GRAY)
            draw_horizontal_step_indicators(graph, rl.GRAY)

            // Draw Function Graph
            for i in 0..=POINT_COUNT
            {
                x := graph.x_axis.offset + graph.x_axis.span * graph.scale * (f32(i) / POINT_COUNT)
                y := graph_function(x)
                draw_point_in_graph({ x, y }, graph, 10, rl.RED)
            }

        rl.EndDrawing()
    }

    rl.CloseWindow()
}

graph_function :: proc(x: f32) -> f32
{
    return math.sin(x)
}

graph_display_area :: proc() -> rl.Rectangle
{
    screen_size := screen_vector()
    return { 0, 0, screen_size.x, screen_size.y - 100 }
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