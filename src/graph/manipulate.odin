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

//FIXME: Pointers to objects become invalid as the array grows 
object_pool :: struct
{
    on_object_added: proc(^object),
    objects: [dynamic]object
} 

add_to_pool :: proc(pool: ^object_pool, o: object) -> ^object
{
    last_index := len(pool.objects)
    append(&pool.objects, o)

    obj_ptr := &pool.objects[last_index]
    
    if pool.on_object_added != nil
    {
        pool.on_object_added(obj_ptr)
    }
    
    return obj_ptr
}

add_values_to_pool :: proc(pool: ^object_pool, values: []f32, style := visual_style.LINES, thickness: f32 = BASE_THICKNESS, color := rl.RED) -> ^object
{
    vs: [dynamic]f32
    append(&vs, ..values)

    o := object_values {
        values = vs,
        visual_options = { style, thickness, color },
    }

    return add_to_pool(pool, o)
}

add_points_to_pool :: proc(pool: ^object_pool, points: []rl.Vector2, style := visual_style.LINES, thickness: f32 = BASE_THICKNESS, color := rl.RED) -> ^object
{
    ps: [dynamic]rl.Vector2
    append(&ps, ..points)

    o := object_points {
        points = ps,
        visual_options = { style, thickness, color },
    }

    return add_to_pool(pool, o)
}

add_mathexpr_to_pool :: proc(pool: ^object_pool, text_expr: string, point_count: responsive(f32), style := visual_style.LINES, thickness: f32 = BASE_THICKNESS, color := rl.RED) -> ^object
{
    o := object_function {
        text = strings.clone(text_expr),
        expr = mathexpr.parse(text_expr),
        point_count = point_count,
        visual_options = { style, thickness, color },
    }

    return add_to_pool(pool, o)
}

update_values_object :: proc(obj: ^object, values: []f32)
{
    clean_object(obj)

    vs: [dynamic]f32
    append(&vs, ..values)

    //TODO: Correctly convert from other object types
    o := &obj.(object_values)
    o.values = vs
}

update_points_object :: proc(obj: ^object, points: []rl.Vector2)
{
    clean_object(obj)

    ps: [dynamic]rl.Vector2
    append(&ps, ..points)

    //TODO: Correctly convert from other object types
    o := &obj.(object_points)
    o.points = ps
}

update_mathexpr_object :: proc(obj: ^object, text_expr: string) -> bool
{
    clean_object(obj)

    //TODO: Correctly convert from other object types
    o := &obj.(object_function)
    o.text = strings.clone(text_expr)
    o.expr = mathexpr.parse(text_expr)
    return o.expr != nil
}

clean_object :: proc(obj: ^object)
{
    switch o in obj
    {
        case object_values:
            if o.values != nil
            {
                delete(o.values)
            }
        case object_points:
            if o.points != nil
            {
                delete(o.points)
            }
        case object_function:
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