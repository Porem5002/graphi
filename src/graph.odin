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

plotable_function :: #type proc "contextless" (_: f32) -> f32

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

visual_style :: enum
{
    POINTS,
    LINES,
}

visual_options :: struct
{
    style: visual_style,
    thickness: f32,
    color: rl.Color,
}

draw_vertical_step_indicators :: proc(graph: graph_info, color: rl.Color)
{
    display_area := resolve(rl.Rectangle, graph.display_area)
    x_step_start, x_step_end := get_axis_step_index_interval(graph.x_axis, graph.scale)

    for i in x_step_start..=x_step_end
    {
        x := map_to_x_coord(f32(i)*graph.x_axis.step, graph)
        rl.DrawLineV({x, display_area.y}, {x, display_area.y + display_area.height}, rl.GRAY)
    }
}

draw_horizontal_step_indicators :: proc(graph: graph_info, color: rl.Color)
{
    display_area := resolve(rl.Rectangle, graph.display_area)
    y_step_start, y_step_end := get_axis_step_index_interval(graph.y_axis, graph.scale)

    for i in y_step_start..=y_step_end
    {
        y := map_to_y_coord(f32(i)*graph.y_axis.step, graph)
        rl.DrawLineV({display_area.x, y}, {display_area.x + display_area.width, y}, rl.GRAY)
    }
}

draw_point_in_graph :: proc(point: rl.Vector2, graph: graph_info, radius: f32, color: rl.Color)
{
    screen_coords := map_to_coords(point, graph)
    rl.DrawCircleV(screen_coords, radius, color)
}

draw_line_in_graph :: proc(start: rl.Vector2, end: rl.Vector2, graph: graph_info, thickness: f32, color: rl.Color)
{
    start_screen_coords := map_to_coords(start, graph)
    end_screen_coords := map_to_coords(end, graph) 
    rl.DrawLineEx(start_screen_coords, end_screen_coords, thickness, color)
}

draw_values_in_graph :: proc(values: []f32, graph: graph_info, style: visual_style, thickness: f32, color: rl.Color)
{
    if(len(values) == 1)
    {
        draw_point_in_graph({ 1, values[0] }, graph, thickness, color)
        return
    }

    if(style == .POINTS)
    {
        for v, i in values
        {
            point := rl.Vector2 { f32(i+1), v }
            draw_point_in_graph(point, graph, thickness, color)
        }
    }
    else if(style == .LINES)
    {
        for i in 1..<len(values)
        {
            prev := rl.Vector2 { f32(i), values[i-1] }
            curr := rl.Vector2 { f32(i+1), values[i] }
            draw_line_in_graph(prev, curr, graph, thickness, color)
        }
    }
}

draw_points_in_graph :: proc(points: []rl.Vector2, graph: graph_info, style: visual_style, thickness: f32, color: rl.Color)
{
    if(len(points) == 1)
    {
        draw_point_in_graph(points[0], graph, thickness, color)
        return
    }

    if(style == .POINTS)
    {
        for p in points
        {
            draw_point_in_graph(p, graph, thickness, color)
        }
    }
    else if(style == .LINES)
    {
        for i in 1..<len(points)
        {
            prev := points[i-1]
            curr := points[i]
            draw_line_in_graph(prev, curr, graph, thickness, color)
        }
    }
}

draw_function_in_graph :: proc(f: plotable_function, graph: graph_info, point_count: f32, style: visual_style, thickness: f32, color: rl.Color)
{
    if(style == .POINTS)
    {
        for i in 0..=point_count
        {
            x := graph.x_axis.offset + graph.x_axis.span * graph.scale * (f32(i) / f32(point_count))
            y := f(x)
            draw_point_in_graph({ x, y }, graph, thickness, color)
        }
    }
    else if(style == .LINES)
    {
        prev: rl.Vector2
        prev.x = graph.x_axis.offset
        prev.y = f(prev.x)

        for i in 1..=point_count
        {
            x := graph.x_axis.offset + graph.x_axis.span * graph.scale * (f32(i) / f32(point_count))
            y := f(x)
            
            draw_line_in_graph(prev, { x, y }, graph, thickness, color)
            prev = { x, y }
        }
    }
}

map_to_coords :: proc(point: rl.Vector2, graph: graph_info) -> rl.Vector2
{
    x := map_to_x_coord(point.x, graph)
    y := map_to_y_coord(point.y, graph)
    return { x, y }
}

map_to_x_coord :: proc(value: f32, graph: graph_info) -> f32
{
    display_area := resolve(rl.Rectangle, graph.display_area)
    x := map_to_axis_percent(value, graph.x_axis, graph.scale)
    x = display_area.x + display_area.width * x
    return x
}

map_to_y_coord :: proc(value: f32, graph: graph_info) -> f32
{
    display_area := resolve(rl.Rectangle, graph.display_area)
    y := map_to_axis_percent(value, graph.y_axis, graph.scale)
    y = display_area.y + display_area.height * (1 - y)
    return y
}

map_to_axis_percent :: proc(value: f32, axis: axis_segment, scale: f32) -> f32
{
    return (value - axis.offset) / (axis.span * scale)
}

get_axis_step_index_interval :: proc(axis: axis_segment, scale: f32) -> (first, last: i64)
{
    first = cast(i64) math.floor(axis.offset / axis.step)
    last = cast(i64) math.floor((axis.offset + axis.span * scale) / axis.step)
    return
}
