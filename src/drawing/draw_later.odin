package drawing

import rl "vendor:raylib"

draw_group :: distinct [dynamic]draw_entry

draw_entry_kind :: enum
{
    RECT,
    RECT_LINES,
    CIRCLE,
    CIRCLE_WITH_BORDER,
    CENTERED_TEXT_C,
    CENTERED_TEXT,
}

draw_entry :: struct
{
    kind: draw_entry_kind,

    using _: struct #raw_union
    {
        rect: struct
        {
            color: rl.Color,
            rect: rl.Rectangle,
        },

        rect_lines: struct
        {
            color: rl.Color,
            rect: rl.Rectangle,
        },

        circle: struct
        {
            color: rl.Color,
            center: rl.Vector2,
            radius: f32,
        },

        centered_text_c: struct
        {
            color: rl.Color,
            container: rl.Rectangle,
            text: cstring,
        },

        centered_text: struct
        {
            color: rl.Color,
            container: rl.Rectangle,
            text: string,
        },

        circle_with_border: struct
        {
            center: rl.Vector2,
            radius: f32,
            color: rl.Color,
        }
    }
}

add_entry_rect :: proc(group: ^draw_group, color: rl.Color, rect: rl.Rectangle)
{
    entry := draw_entry {
        kind = .RECT,
        rect = {
            color = color,
            rect = rect,
        }
    }

    append(group, entry)
}

add_entry_rect_lines :: proc(group: ^draw_group, color: rl.Color, rect: rl.Rectangle)
{
    entry := draw_entry {
        kind = .RECT_LINES,
        rect_lines = {
            color = color,
            rect = rect,
        }
    }

    append(group, entry)
}

add_entry_circle :: proc(group: ^draw_group, center: rl.Vector2, radius: f32, color: rl.Color)
{
    entry := draw_entry {
        kind = .CIRCLE,
        circle = {
            color = color,
            center = center,
            radius = radius,
        }
    }

    append(group, entry)
}

add_entry_circle_with_border :: proc(group: ^draw_group, center: rl.Vector2, radius: f32, color: rl.Color)
{
    entry := draw_entry {
        kind = .CIRCLE_WITH_BORDER,
        circle_with_border = {
            center = center,
            radius = radius,
            color = color,
        }
    }

    append(group, entry)
}

add_entry_centered_text :: proc
{
    add_entry_centered_cstring,
    add_entry_centered_string,
}

add_entry_centered_cstring :: proc(group: ^draw_group, text: cstring, container: rl.Rectangle, color: rl.Color)
{
    entry := draw_entry {
        kind = .CENTERED_TEXT_C,
        centered_text_c = {
            color = color,
            container = container,
            text = text,
        }
    }

    append(group, entry)
}

add_entry_centered_string :: proc(group: ^draw_group, text: string, container: rl.Rectangle, color: rl.Color)
{
    entry := draw_entry {
        kind = .CENTERED_TEXT,
        centered_text = {
            color = color,
            container = container,
            text = text,
        }
    }

    append(group, entry)
}