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

objects := [?]graph_object {
    graph_object_values {
        values = { 85, 70, 65, 75, 44, 54, 23, 60 },
        style = .LINES,
        thickness = POINT_SIZE,
        color = rl.GREEN,
    },
    graph_object_points {
        points = { {10, 9}, {1.8, 1.7}, {2.8, 9}, {5, 12} },
        style = .LINES,
        thickness = POINT_SIZE,
        color = rl.BLUE,
    },
    graph_object_function {
        f = math.exp_f32,
        point_count = proc() -> f32 { return graph_display_area().width },
        style = .LINES,
        thickness = POINT_SIZE,
        color = rl.YELLOW,
    },
    graph_object_function {
        f = math.tan_f32,
        point_count = proc() -> f32 { return graph_display_area().width },
        style = .LINES,
        thickness = POINT_SIZE,
        color = rl.VIOLET,
    },
}

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

            for o in objects
            {
                draw_object_in_graph(o, graph)
            }
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