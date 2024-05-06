package graph

import "core:strconv"
import "core:strings"

import rl "vendor:raylib"

parse_point :: proc(text: string) -> Maybe(rl.Vector2)
{
    ss := strings.split(text, ",")
    defer delete(ss)

    if len(ss) != 2
    {
        return nil
    }

    x, ok1 := strconv.parse_f32(strings.trim_space(ss[0]))
    y, ok2 := strconv.parse_f32(strings.trim_space(ss[1]))

    if !ok1 || !ok2
    {
        return nil
    }

    return rl.Vector2 { x, y }
}