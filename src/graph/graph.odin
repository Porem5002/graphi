package graph

import "core:math"
import "../mathexpr"

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

graph :: struct
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

object :: struct
{
    kind: object_type,

    using visual_options: visual_options,

    using _: struct #raw_union
    {
        o_points: object_points,
        o_func: object_function,
    }
}

object_points :: struct
{
    open: bool,
    texts: [dynamic]string,
    points: [dynamic]rl.Vector2,
}

object_function :: struct
{
    text: string,
    expr: ^mathexpr.ast,
    point_count: responsive(f32),
}

object_type :: enum
{
    POINTS,
    MATHEXPR,
}

draw_objects_in_graph :: proc
{
    draw_object_in_graph,
    draw_object_pool_in_graph,
}

draw_object_in_graph :: proc(obj: object, graph: graph)
{
    switch obj.kind
    {
        case .POINTS:
            o := obj.o_points
            draw_points_in_graph(o.points[:], graph, obj.visual_options)
        case .MATHEXPR:
            o := obj.o_func
            resolved_point_count := resolve(f32, o.point_count)
            draw_mathexpr_in_graph(o.expr, graph, resolved_point_count, obj.visual_options)
    }
}

draw_object_pool_in_graph :: proc(pool: object_const_pool, graph: graph)
{
    for o in pool
    {
        draw_object_in_graph(o^, graph)
    }
}

draw_vertical_step_indicators :: proc(graph: graph, color: rl.Color)
{
    display_area := resolve(rl.Rectangle, graph.display_area)
    x_step_start, x_step_end := get_axis_step_index_interval(graph.x_axis, graph.scale)

    for i in x_step_start..=x_step_end
    {
        x := map_to_x_coord(f32(i)*graph.x_axis.step, graph)
        rl.DrawLineV({x, display_area.y}, {x, display_area.y + display_area.height}, rl.GRAY)
    }
}

draw_horizontal_step_indicators :: proc(graph: graph, color: rl.Color)
{
    display_area := resolve(rl.Rectangle, graph.display_area)
    y_step_start, y_step_end := get_axis_step_index_interval(graph.y_axis, graph.scale)

    for i in y_step_start..=y_step_end
    {
        y := map_to_y_coord(f32(i)*graph.y_axis.step, graph)
        rl.DrawLineV({display_area.x, y}, {display_area.x + display_area.width, y}, rl.GRAY)
    }
}

draw_point_in_graph :: proc(point: rl.Vector2, graph: graph, radius: f32, color: rl.Color)
{
    screen_coords := map_to_coords(point, graph)
    rl.DrawCircleV(screen_coords, radius, color)
}

draw_line_in_graph :: proc(start: rl.Vector2, end: rl.Vector2, graph: graph, thickness: f32, color: rl.Color)
{
    start_screen_coords := map_to_coords(start, graph)
    end_screen_coords := map_to_coords(end, graph)
    rl.DrawLineEx(start_screen_coords, end_screen_coords, thickness, color)
}

draw_values_in_graph :: proc(values: []f32, graph: graph, using visual_options: visual_options)
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

draw_points_in_graph :: proc(points: []rl.Vector2, graph: graph, using visual_options: visual_options)
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

draw_mathexpr_in_graph :: proc(expr: ^mathexpr.ast, graph: graph, point_count: f32, using visual_options: visual_options)
{
    if expr == nil
    {
        return
    }

    if style == .POINTS
    {
        for i in 0..=point_count
        {
            x := graph.x_axis.offset + graph.x_axis.span * graph.scale * (f32(i) / f32(point_count))
            y := mathexpr.eval_ast(expr, x)
            draw_point_in_graph({ x, y }, graph, thickness, color)
        }
    }
    else if style == .LINES
    {
        prev: rl.Vector2
        prev.x = graph.x_axis.offset
        prev.y = mathexpr.eval_ast(expr, prev.x)

        for i in 1..=point_count
        {
            x := graph.x_axis.offset + graph.x_axis.span * graph.scale * (f32(i) / f32(point_count))
            y := mathexpr.eval_ast(expr, x)

            if(converges(prev.x, x, expr))
            {
                draw_line_in_graph(prev, { x, y }, graph, thickness, color)
            }

            prev = { x, y }
        }
    }
}

converges :: proc(x1: f32, x2: f32, expr: ^mathexpr.ast, threshold := 100) -> bool
{
    y1 := mathexpr.eval_ast(expr, x1)
    y2 := mathexpr.eval_ast(expr, x2)

    return abs(y1 - y2) <= f32(threshold)
}

map_to_coords :: proc(point: rl.Vector2, graph: graph) -> rl.Vector2
{
    x := map_to_x_coord(point.x, graph)
    y := map_to_y_coord(point.y, graph)
    return { x, y }
}

map_to_x_coord :: proc(value: f32, graph: graph) -> f32
{
    display_area := resolve(rl.Rectangle, graph.display_area)
    x := map_to_axis_percent(value, graph.x_axis, graph.scale)
    x = display_area.x + display_area.width * x
    return x
}

map_to_y_coord :: proc(value: f32, graph: graph) -> f32
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
