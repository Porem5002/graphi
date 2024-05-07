package drawing

import "core:strings"

import rl "vendor:raylib"

draw_text_centered :: proc {
    draw_cstring_centered,
    draw_string_centered,
}

draw_cstring_centered :: proc(text: cstring, container: rl.Rectangle, font_size: f32 = 23, spacing: f32 = 3, color: rl.Color = rl.WHITE)
{
    font := rl.GetFontDefault()
    text_size := rl.MeasureTextEx(font, text, font_size, spacing)
    rl.DrawTextEx(font, text, { container.x, container.y } + { container.width, container.height }/2 - text_size/2, font_size, spacing, color)
}

draw_string_centered :: proc(text: string, container: rl.Rectangle, font_size: f32 = 23, spacing: f32 = 3, color: rl.Color = rl.WHITE)
{
    ctext := strings.clone_to_cstring(text)
    draw_cstring_centered(ctext, container, font_size, spacing, color)
    delete(ctext)
}

draw_all :: proc(ctx: draw_context, group: ^draw_group)
{
    for entry in group
    {
        switch entry.kind
        {
            case .RECT:
                entry := entry.rect
                rl.DrawRectangleRec(entry.rect, entry.color)
            case .RECT_LINES:
                entry := entry.rect_lines
                rl.DrawRectangleLinesEx(entry.rect, 1, entry.color)
            case .CIRCLE:
                entry := entry.circle
                rl.DrawCircleV(entry.center, entry.radius, entry.color)
            case .CENTERED_TEXT_C:
                entry := entry.centered_text_c
                draw_text_centered(entry.text, entry.container, color = entry.color)
            case .CENTERED_TEXT:
                entry := entry.centered_text
                draw_text_centered(entry.text, entry.container, color = entry.color)
            case .CIRCLE_WITH_BORDER:
                entry := entry.circle_with_border

                scale := entry.radius*2
                texture_rect := get_pixel_texture_rect(ctx)
                
                dest_rect := rl.Rectangle {
                    entry.center.x,
                    entry.center.y,
                    texture_rect.width * scale,
                    texture_rect.height * scale
                }

                origin := rl.Vector2 { dest_rect.width/2.0, dest_rect.height/2.0 }

                rl.BeginShaderMode(ctx.circle_with_border_shader)
                    rl.DrawTexturePro(ctx.pixel_texture, texture_rect, dest_rect, origin, 0, entry.color)
                rl.EndShaderMode()
        }
    }

    clear(group)
}