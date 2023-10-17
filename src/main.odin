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

objects := [?]ui_object {
    {
        object = graph_object_values {
            values = { 85, 70, 65, 75, 44, 54, 23, 60 },
            style = .LINES,
            thickness = POINT_SIZE,
            color = rl.GREEN,
        },
    },
    {
        object = graph_object_points {
            points = { {10, 9}, {1.8, 1.7}, {2.8, 9}, {5, 12} },
            style = .LINES,
            thickness = POINT_SIZE,
            color = rl.BLUE,
        },
    },
    {
        object = graph_object_function {
            f = math.exp_f32,
            point_count = proc() -> f32 { return graph_display_area().width },
            style = .LINES,
            thickness = POINT_SIZE,
            color = rl.YELLOW,
        },
    },
    {
        object = graph_object_function {
            f = math.tan_f32,
            point_count = proc() -> f32 { return graph_display_area().width },
            style = .LINES,
            thickness = POINT_SIZE,
            color = rl.VIOLET,
        },
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
        mouse_pos := rl.GetMousePosition()

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

        //TODO: Clean up Code
        yoffset : f32 = UI_OBJECT_SPACING

        for _, i in objects
        {
            o := &objects[i]

            multiplier := o.open ? get_graph_object_element_count(o.object) : 1
            o.rect = rl.Rectangle { 0, yoffset, object_edit_area().width, f32(multiplier)*UI_OBJECT_HEIGHT }

            if(rl.IsMouseButtonPressed(.LEFT) && is_point_in_rect(o.rect, mouse_pos))
            {
                o.open = !o.open
            }

            yoffset += o.rect.height + UI_OBJECT_SPACING
        }

        rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)

            draw_vertical_step_indicators(graph, rl.GRAY)
            draw_horizontal_step_indicators(graph, rl.GRAY)

            for o in objects
            {
                draw_object_in_graph(o.object, graph)
            }

            rl.DrawRectangleRec(object_edit_area(), rl.GetColor(UI_OBJECT_SECTION_BACKGROUND_COLOR))            

            //TODO: Clean up Code
            text_buffer: [300]byte = {} 

            for ui_o in objects
            {
                multiplier := ui_o.open ? get_graph_object_element_count(ui_o.object) : 1

                rl.DrawRectangleRec(ui_o.rect, rl.ColorBrightness(rl.GetColor(UI_OBJECT_BACKGROUND_COLOR), 0.2))
            
                for i in 0..<multiplier
                {
                    subrect : rl.Rectangle = { ui_o.rect.x, ui_o.rect.y + f32(i) * UI_OBJECT_HEIGHT, ui_o.rect.width, UI_OBJECT_HEIGHT }
                    
                    switch o in ui_o.object
                    {
                        case graph_object_values:
                            text := fmt.bprintf(text_buffer[:], "%f%c", o.values[i], rune(0))
                            draw_text_centered(cast(cstring) &text_buffer[0], subrect, color = o.visual_options.color)
                        case graph_object_points:
                            text := fmt.bprintf(text_buffer[:], "%f %f%c", o.points[i].x, o.points[i].y, rune(0))
                            draw_text_centered(cast(cstring) &text_buffer[0], subrect, color = o.visual_options.color)
                        case graph_object_function:
                            draw_text_centered("Function", subrect, color = o.visual_options.color)
                    }
                }
            }

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