package main

import "core:fmt"
import "core:math"
import "core:c"

import grh "graph"

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

editor_tab := ui_editor_tab {
    content_offset_y = 0,
    spacing = 20,
    area = object_edit_area,
}

ui_objects: [dynamic]ui_object

objects := grh.object_pool {
    on_object_added = register_ui_object,
}

main :: proc()
{
    rl.InitWindow(900, 900, "GraPhi")
    
    flags := rl.ConfigFlags { rl.ConfigFlag.WINDOW_RESIZABLE }
    rl.SetWindowState(flags)

    rl.SetTargetFPS(TARGET_FPS)

    grh.add_values_to_pool(&objects, { 1, 5, 3, -2 }, color = rl.GREEN)
    grh.add_points_to_pool(&objects, { {1, 2} , {3, 4} }, color = rl.GREEN)
    grh.add_mathexpr_to_pool(&objects, "sin(x) + x", graph_display_area_width, color = rl.YELLOW)
    grh.add_mathexpr_to_pool(&objects, "5", graph_display_area_width, color = rl.BLUE)
    grh.add_mathexpr_to_pool(&objects, "-x * x", graph_display_area_width, color = rl.RED)

    for (!rl.WindowShouldClose())
    {
        mouse_pos := rl.GetMousePosition()
        mouse_wheel_y := rl.GetMouseWheelMove()
        delta_time := rl.GetFrameTime()

        // UI Object Interaction
        total_height := calc_ui_objects_height(ui_objects[:], editor_tab.spacing)
        scroll_max := total_height - object_edit_area().height

        if(scroll_max > 0 && is_point_in_rect(object_edit_area(), mouse_pos))
        {
            scroll -= mouse_wheel_y * delta_time * SCROLL_FACTOR
            scroll = scroll_max <= 0 ? 0 : clamp(scroll, 0, 1)
        }
        else if(scroll_max <= 0)
        {
            scroll = 0 
        }

        editor_tab.content_offset_y = scroll * scroll_max
        check_ui_objects_interaction_in_tab(mouse_pos, ui_objects[:], editor_tab)
    
        // Graph Interaction
        if(is_point_in_rect(graph_display_area(), mouse_pos))
        {
            /* Scale Controls */
            graph.scale -= mouse_wheel_y * delta_time * SCALE_FACTOR
            graph.scale = max(graph.scale, math.F32_EPSILON)

            /* Offset/Movement Controls */
            if(rl.IsKeyPressed(.W) || rl.IsKeyDown(.W))
            {
                graph.y_axis.offset += delta_time * MOVEMENT_SPEED * graph.scale
            }

            if(rl.IsKeyPressed(.S) || rl.IsKeyDown(.S))
            {
                graph.y_axis.offset -= delta_time * MOVEMENT_SPEED * graph.scale
            }

            if(rl.IsKeyPressed(.D) || rl.IsKeyDown(.D))
            {
                graph.x_axis.offset += delta_time * MOVEMENT_SPEED * graph.scale
            }

            if(rl.IsKeyPressed(.A) || rl.IsKeyDown(.A))
            {
                graph.x_axis.offset -= delta_time * MOVEMENT_SPEED * graph.scale
            }
        }

        rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)

            grh.draw_vertical_step_indicators(graph, rl.GRAY)
            grh.draw_horizontal_step_indicators(graph, rl.GRAY)
            grh.draw_objects_in_graph(objects, graph)

            rl.DrawRectangleRec(object_edit_area(), rl.GetColor(UI_OBJECT_SECTION_BACKGROUND_COLOR))            

            draw_ui_objects_in_tab(ui_objects[:], editor_tab)

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

register_ui_object :: proc(obj: ^grh.object)
{
    ui_obj := ui_object { object = obj }
    append(&ui_objects, ui_obj)
}