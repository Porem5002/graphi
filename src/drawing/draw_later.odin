package drawing

import rl "vendor:raylib"

draw_group :: distinct [dynamic]draw_entry

draw_entry_kind :: enum
{
    RECT,
    RECT_LINES,
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

        centered_text: struct
        {
            color: rl.Color,
            container: rl.Rectangle,
            text: cstring,
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

add_entry_centered_text :: proc(group: ^draw_group, text: cstring, container: rl.Rectangle, color: rl.Color)
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