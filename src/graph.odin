package main

import "core:math"

import rl "vendor:raylib"

responsive :: union($T: typeid)
{
    T, proc() -> T,
}

resolve :: proc($T: typeid, v: responsive(T)) -> T
{
    switch v in v
    {
        case T: return v
        case proc() -> T: return v()
    }

    panic("unreachable")
}

graph_info :: struct
{
    display_area: responsive(rl.Rectangle),
    x_axis: axis_segment,
    y_axis: axis_segment,
    scale: f32,
}

axis_segment :: struct
{
    offset: f32,
    span: f32,
    step: f32,
}

draw_vertical_step_indicators :: proc(graph: graph_info, color: rl.Color)
{
    display_area := resolve(rl.Rectangle, graph.display_area)
    x_step_start, x_step_end := get_axis_step_index_interval(graph.x_axis, graph.scale)

    for i in x_step_start..=x_step_end
    {
        x, exists := map_to_x_coord(f32(i)*graph.x_axis.step, graph)
        if(exists)
        {
            rl.DrawLineV({x, display_area.y}, {x, display_area.y + display_area.height}, rl.GRAY)
        }
    }
}

draw_horizontal_step_indicators :: proc(graph: graph_info, color: rl.Color)
{
    display_area := resolve(rl.Rectangle, graph.display_area)
    y_step_start, y_step_end := get_axis_step_index_interval(graph.y_axis, graph.scale)

    for i in y_step_start..=y_step_end
    {
        y, exists := map_to_y_coord(f32(i)*graph.y_axis.step, graph)
        if(exists)
        {
            rl.DrawLineV({display_area.x, y}, {display_area.x + display_area.width, y}, rl.GRAY)
        }
    }
}

draw_point_in_graph :: proc(point: rl.Vector2, graph: graph_info, radius: f32, color: rl.Color)
{
    display_area := resolve(rl.Rectangle, graph.display_area)

    screen_x, xexists := map_to_x_coord(point.x, graph)
    if(!xexists)
    {
        return
    }

    screen_y, yexists := map_to_y_coord(point.y, graph)
    if(!yexists)
    {
        return
    }

    rl.DrawCircleV({ screen_x, screen_y }, radius, color)
}

map_to_x_coord :: proc(value: f32, graph: graph_info) -> (f32, bool)
{
    display_area := resolve(rl.Rectangle, graph.display_area)
    x, exists := map_to_axis_percent(value, graph.x_axis, graph.scale)
    
    if(!exists)
    {
        return 0, false
    }

    x = display_area.x + display_area.width * x
    return x, true
}

map_to_y_coord :: proc(value: f32, graph: graph_info) -> (f32, bool)
{
    display_area := resolve(rl.Rectangle, graph.display_area)
    y, exists := map_to_axis_percent(value, graph.y_axis, graph.scale)
    
    if(!exists)
    {
        return 0, false
    }

    y = display_area.y + display_area.height * (1 - y)
    return y, true
}

map_to_axis_percent :: proc(value: f32, axis: axis_segment, scale: f32) -> (f32, bool)
{
    if(value < axis.offset || value > axis.offset + axis.span * scale)
    {
        return 0, false
    }

    return (value - axis.offset) / (axis.span * scale), true
}

get_axis_step_index_interval :: proc(axis: axis_segment, scale: f32) -> (first, last: i64)
{
    first = cast(i64) math.floor(axis.offset / axis.step)
    last = cast(i64) math.floor((axis.offset + axis.span * scale) / axis.step)
    return
}
