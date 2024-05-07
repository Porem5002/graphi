package drawing

import rl "vendor:raylib"

CIRCLE_WITH_BORDER_SHADER_PATH :: "./assets/shaders/circle_with_border.fs"

draw_context :: struct
{
    circle_with_border_shader: rl.Shader,
    pixel_texture: rl.Texture
}

load_context :: proc() -> draw_context
{
    pixel_img := rl.GenImageColor(1, 1, rl.WHITE)
    defer rl.UnloadImage(pixel_img)

    return draw_context {
        circle_with_border_shader = rl.LoadShader(nil, CIRCLE_WITH_BORDER_SHADER_PATH),
        pixel_texture = rl.LoadTextureFromImage(pixel_img)
    }
}

get_pixel_texture_rect :: proc(ctx: draw_context) -> rl.Rectangle
{
    return rl.Rectangle {
        0,
        0,
        f32(ctx.pixel_texture.width),
        f32(ctx.pixel_texture.height),
    }
}

unload_context :: proc(ctx: draw_context)
{
    rl.UnloadShader(ctx.circle_with_border_shader)
    rl.UnloadTexture(ctx.pixel_texture)
}