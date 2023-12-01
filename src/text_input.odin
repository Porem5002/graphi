package main

import "core:strings"

import rl "vendor:raylib"

text_update_event :: #type proc(event_data: rawptr, new_text: string)

text_input_state :: struct
{
    active: bool,
    text_builder: strings.Builder,

    event_data: rawptr,
    on_text_update: text_update_event,
}

text_input: text_input_state

text_input_init :: proc()
{
    text_input.text_builder = strings.builder_make()
}

text_input_bind :: proc(init_text: string, event_data: rawptr, on_text_update: text_update_event)
{
    text_input.active = true
    text_input.event_data = event_data
    text_input.on_text_update = on_text_update
    strings.builder_reset(&text_input.text_builder)
    strings.write_string(&text_input.text_builder, init_text)
}

text_input_unbind :: proc()
{
    text_input.active = false
}

text_input_update :: proc()
{
    if !text_input.active
    {
        return
    }

    requires_update := false
    
    if(rl.IsKeyPressed(.BACKSPACE) || rl.IsKeyPressed(.BACKSPACE))
    {
        requires_update = true
        strings.pop_rune(&text_input.text_builder)
    }

    // Register new characters
    c := rl.GetCharPressed()
    for !strings.is_null(c)
    {
        requires_update = true
        strings.write_rune(&text_input.text_builder, c)
        c = rl.GetCharPressed()
    }

    if !requires_update
    {
        return
    }

    new_text := strings.to_string(text_input.text_builder)
    text_input.on_text_update(text_input.event_data, new_text)
}