package main

import "core:strings"
import "core:unicode/utf8"

import rl "vendor:raylib"

text_update_event :: #type proc(event_data: rawptr, new_text: string)
text_unbind_event :: #type proc(event_data: rawptr)

text_input_state :: struct
{
    active: bool,
    text_index: int,
    text_builder: strings.Builder,

    event_data: rawptr,
    on_text_update: text_update_event,
    on_text_unbind: text_unbind_event,
}

text_input: text_input_state

text_input_init :: proc()
{
    text_input.text_builder = strings.builder_make()
}

text_input_bind :: proc(init_text: string, event_data: rawptr, on_text_update: text_update_event, on_text_unbind: text_unbind_event = nil)
{
    text_input_unbind()
    
    text_input.active = true
    text_input.event_data = event_data
    text_input.text_index = 0
    text_input.on_text_update = on_text_update
    text_input.on_text_unbind = on_text_unbind
    strings.builder_reset(&text_input.text_builder)
    strings.write_string(&text_input.text_builder, init_text)
}

text_input_unbind :: proc()
{
    if(text_input.active && text_input.on_text_unbind != nil)
    {
        text_input.on_text_unbind(text_input.event_data)
    }

    text_input.active = false
}

// TODO: Handle UTF8 text correctly
text_input_update :: proc()
{
    if !text_input.active do return

    requires_update := false
    
    if(rl.IsKeyPressed(.LEFT)) do text_input.text_index -= 1
    if(rl.IsKeyPressed(.RIGHT)) do text_input.text_index += 1

    max_index := len(strings.to_string(text_input.text_builder))
    text_input.text_index = clamp(text_input.text_index, 0, max_index)

    if(rl.IsKeyPressed(.BACKSPACE) && text_input.text_index > 0)
    {
        requires_update = true
        
        text := strings.to_string(text_input.text_builder)
        text_runes := utf8.string_to_runes(text)
        defer delete(text_runes)

        left_text := text_runes[:text_input.text_index-1]
        right_text := text_runes[text_input.text_index:]

        strings.builder_reset(&text_input.text_builder)
        
        for r in left_text do strings.write_rune(&text_input.text_builder, r)
        for r in right_text do strings.write_rune(&text_input.text_builder, r)

        text_input.text_index -= 1
    }

    // Register new characters
    c := rl.GetCharPressed()
    for !strings.is_null(c)
    {
        requires_update = true

        text := strings.to_string(text_input.text_builder)
        text_runes := utf8.string_to_runes(text)
        defer delete(text_runes)

        left_text := text_runes[:text_input.text_index]
        right_text := text_runes[text_input.text_index:]

        strings.builder_reset(&text_input.text_builder)

        for r in left_text do strings.write_rune(&text_input.text_builder, r)
        strings.write_rune(&text_input.text_builder, c)
        for r in right_text do strings.write_rune(&text_input.text_builder, r)

        text_input.text_index += 1

        c = rl.GetCharPressed()
    }

    if requires_update
    {
        new_text := strings.to_string(text_input.text_builder)
        text_input.on_text_update(text_input.event_data, new_text)
    }
}