package main

import "core:strings"
import "core:unicode/utf8"

import rl "vendor:raylib"

text_bind_event :: #type proc(event_data: rawptr)
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

text_input_bind :: proc(init_text: string, bind_data: rawptr, on_bind: text_bind_event, event_data: rawptr, on_update: text_update_event, on_unbind: text_unbind_event = nil)
{
    text_input_unbind()
    
    text_input.active = true
    text_input.event_data = event_data
    text_input.text_index = 0
    text_input.on_text_update = on_update
    text_input.on_text_unbind = on_unbind
    strings.builder_reset(&text_input.text_builder)
    strings.write_string(&text_input.text_builder, init_text)

    // Guarantees that setup logic and state is assigned and done after any possible unbind side effects
    on_bind(bind_data)
}

text_input_unbind :: proc()
{
    if(text_input.active && text_input.on_text_unbind != nil)
    {
        text_input.on_text_unbind(text_input.event_data)
    }

    text_input.active = false
}

text_input_update :: proc()
{
    if !text_input.active do return

    requires_update := false
    
    if(rl.IsKeyPressed(.LEFT)) do text_input.text_index -= 1
    if(rl.IsKeyPressed(.RIGHT)) do text_input.text_index += 1

    max_index := utf8.rune_count(strings.to_string(text_input.text_builder))
    text_input.text_index = clamp(text_input.text_index, 0, max_index)

    if(rl.IsKeyPressed(.BACKSPACE) && text_input.text_index > 0)
    {
        requires_update = true
        
        text := strings.to_string(text_input.text_builder)
        text_runes := utf8.string_to_runes(text)
        defer delete(text_runes)

        left, right := rem_rune_at(text_runes, text_input.text_index)
        strings.builder_reset(&text_input.text_builder)
        
        for r in left do strings.write_rune(&text_input.text_builder, r)
        for r in right do strings.write_rune(&text_input.text_builder, r)

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

        left, right := divide_runes_at(text_runes, text_input.text_index)
        strings.builder_reset(&text_input.text_builder)

        for r in left do strings.write_rune(&text_input.text_builder, r)
        strings.write_rune(&text_input.text_builder, c)
        for r in right do strings.write_rune(&text_input.text_builder, r)

        text_input.text_index += 1

        c = rl.GetCharPressed()
    }

    if requires_update
    {
        new_text := strings.to_string(text_input.text_builder)
        text_input.on_text_update(text_input.event_data, new_text)
    }
}

// Example: "ABC", 1 -> "A" "BC" 
divide_runes_at :: proc(rs: []rune, index: int) -> (left: []rune, right:[]rune)
{
    if index <= 0 do return rs[0:0], rs[:]
    if index >= len(rs) do return rs[:], rs[0:0]
    return rs[:index], rs[index:]
}

// Example: "ABC", 1 -> "" "BC"
rem_rune_at :: proc(rs: []rune, index: int) -> (left: []rune, right:[]rune)
{
    if index <= 0 do return rs[0:0], rs[:]
    if index > len(rs) do return rs[:], rs[0:0]
    return rs[:index-1], rs[index:]
}