package main

import "core:fmt"
import "core:math"
import "core:c"

import rl "vendor:raylib"

axis_segment :: struct
{
    offset: f32,
    span: f32,
    step: f32,
}

x_axis := axis_segment { offset = -1, span = 2, step = 0.5 }
y_axis := axis_segment { offset = -1, span = 2, step = 0.5 }
scale: f32 = 1.0

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
        scale -= rl.GetMouseWheelMove() * rl.GetFrameTime() * SCALE_FACTOR
        scale = max(scale, math.F32_EPSILON)

        /* Offset/Movement Controls */
        if(rl.IsKeyPressed(.W) || rl.IsKeyDown(.W))
        {
            y_axis.offset += rl.GetFrameTime() * MOVEMENT_SPEED * scale
        }

        if(rl.IsKeyPressed(.S) || rl.IsKeyDown(.S))
        {
            y_axis.offset -= rl.GetFrameTime() * MOVEMENT_SPEED * scale
        }

        if(rl.IsKeyPressed(.D) || rl.IsKeyDown(.D))
        {
            x_axis.offset += rl.GetFrameTime() * MOVEMENT_SPEED * scale
        }

        if(rl.IsKeyPressed(.A) || rl.IsKeyDown(.A))
        {
            x_axis.offset -= rl.GetFrameTime() * MOVEMENT_SPEED * scale
        }

        rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)

            /* Draw Vertical Lines */
            x_step_start := axis_first_step_index(x_axis)
            x_step_end := axis_last_step_index(x_axis, scale)

            for i in x_step_start..=x_step_end
            {
                x, exists := map_to_axis(f32(i)*x_axis.step, x_axis, scale)
                x *= screen_vector().x

                if(exists)
                {
                    rl.DrawLineV({x, 0}, {x, screen_vector().y}, rl.GRAY)
                }
            }

            /* Draw Horizontal Lines */
            y_step_start := axis_first_step_index(y_axis)
            y_step_end := axis_last_step_index(y_axis, scale)

            for i in y_step_start..=y_step_end
            {
                y, exists := map_to_axis(f32(i)*y_axis.step, y_axis, scale)
                y = screen_vector().y * (1 - y)
                
                if(exists)
                {
                    rl.DrawLineV({0, y}, {screen_vector().x, y}, rl.GRAY)
                }
            }

            for i in 0..=POINT_COUNT
            {
                x := x_axis.offset + (f32(i) * x_axis.span * scale) / POINT_COUNT
                y := graph_function(x)
                map_and_draw_point(x, y, x_axis, y_axis, scale, rl.RED)
            }

        rl.EndDrawing()
    }

    rl.CloseWindow()
}

graph_function :: proc(x: f32) -> f32
{
    return math.sin(x)
}

map_and_draw_point :: proc(x: f32, y: f32, x_axis: axis_segment, y_axis: axis_segment, scale: f32, color: rl.Color)
{
    screen_x, xexists := map_to_axis(x, x_axis, scale)
    if(!xexists)
    {
        return
    }

    screen_y, yexists := map_to_axis(y, y_axis, scale)
    if(!yexists)
    {
        return
    }

    screen_x = screen_vector().x * screen_x
    screen_y = screen_vector().y * (1 - screen_y)
    rl.DrawCircleV({ screen_x, screen_y }, 10, color)
}

map_to_axis :: proc(value: f32, axis: axis_segment, scale: f32) -> (f32, bool)
{
    if(value < axis.offset || value > axis.offset + axis.span * scale)
    {
        return 0, false
    }

    return (value - axis.offset) / (axis.span * scale), true
}

axis_first_step_index :: proc(axis: axis_segment) -> i64
{
    return cast(i64) math.floor(axis.offset / axis.step)
}

axis_last_step_index :: proc(axis: axis_segment, scale: f32) -> i64
{
    return cast(i64) math.floor((axis.offset + axis.span * scale) / axis.step)
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