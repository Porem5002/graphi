package graph

import "core:strings"
import "core:fmt"

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

add_points_to_pool :: proc(pool: ^object_pool, text_points: []string, style := visual_style.LINES, thickness: f32 = BASE_THICKNESS, color := rl.RED) -> ^object
{
    o: object = object_points {
        visual_options = { style, thickness, color },
    }

    for text, i in text_points
    {
        update_point_in_object(&o, text, i)
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

update_point_in_object :: proc(obj: ^object, text: string, index: int)
{
    //TODO: Correctly convert from other object types
    o := &obj.(object_points)

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