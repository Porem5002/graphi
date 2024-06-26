package graph

import "core:strings"

import "../mathexpr"

import rl "vendor:raylib"

BASE_THICKNESS :: 4.0

BASE_VISUAL_OPTIONS :: visual_options {
    style = .LINES,
    thickness = BASE_THICKNESS,
    color = rl.RED,
}

object_pool :: [dynamic]^object
object_const_pool :: []^object

@(require_results)
create_points :: proc(text_points: []string, style := visual_style.LINES, thickness: f32 = BASE_THICKNESS, color := rl.RED) -> ^object
{
    o := new(object)
    o^ = object {
        kind = .POINTS,
        visual_options = { style, thickness, color },
    }

    for text, i in text_points
    {
        update_point_in_object(o, text, i)
    }

    return o
}

@(require_results)
create_mathexpr :: proc(text_expr: string, point_count: responsive(f32), style := visual_style.LINES, thickness: f32 = BASE_THICKNESS, color := rl.RED) -> ^object
{
    o := new(object)
    o^ = object {
        kind = .MATHEXPR,
        visual_options = { style, thickness, color },
        o_func = {
            text = strings.clone(text_expr),
            expr = mathexpr.parse(text_expr),
            point_count = point_count,
        }
    }

    return o
}

update_point_in_object :: proc(obj: ^object, text: string, index: int)
{
    //TODO: Correctly convert from other object types
    o := &obj.o_points

    if len(o.points) <= index
    {
        append(&o.texts, "")
        append(&o.points, rl.Vector2 {})
    }

    if o.texts[index] != ""
    {
        delete(o.texts[index])
    }

    o.texts[index] = strings.clone(text)
    o.points[index] = parse_point(text).? or_else {}
}

update_mathexpr_object :: proc(o: ^object, text_expr: string) -> bool
{
    clean_object(o)

    //TODO: Correctly convert from other object types
    o := &o.o_func
    o.text = strings.clone(text_expr)
    o.expr = mathexpr.parse(text_expr)
    return o.expr != nil
}

clean_object :: proc(o: ^object)
{
    switch o.kind
    {
        case .POINTS:
            o := o.o_points
            if o.points != nil
            {
                delete(o.points)
            }
        case .MATHEXPR:
            o := &o.o_func
            if o.text != ""
            {
                delete(o.text)
                o.text = ""
            }
            if o.expr != nil
            {
                free(o.expr)
            }
    }
}

pool_remove :: proc(pool: ^object_pool, index: int)
{
    o := pool[index]
    ordered_remove(pool, index)
    free(o)
}