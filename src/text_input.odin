package main

import "core:strings"

import rl "vendor:raylib"

text_update_event :: #type proc(rawptr, string)

text_input_state :: struct
{
    active: bool,
    text_builder: strings.Builder,

    dest: rawptr,
    on_text_update: text_update_event,
}

text_input: text_input_state

text_input_init :: proc()
{
    text_input.text_builder = strings.builder_make()
}

text_input_bind :: proc(init_text: string, dest: rawptr, on_text_update: text_update_event)
{
    text_input.active = true
    text_input.dest = dest
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

    c := rl.GetCharPressed()

    // If no characters were pressed avoid updating
    if strings.is_null(c)
    {
        return
    }

    for !strings.is_null(c)
    {
        strings.write_rune(&text_input.text_builder, c)
        c = rl.GetCharPressed()
    }

    new_text := strings.to_string(text_input.text_builder)
    text_input.on_text_update(text_input.dest, new_text)
}