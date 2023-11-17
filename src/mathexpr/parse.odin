package mathexpr

import "core:math"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"

token_type :: enum
{
    ERROR,

    NUMBER,
    SPEC_NUMBER,
    
    VAR,
    FUNC,

    PIPE,
    PLUS,
    MINUS,
    ASTERISK,
    SLASH,

    PAREN_OPEN,
    PAREN_CLOSE,

    END,
}

token :: struct
{
    type: token_type,

    as: union
    {
        f32,
        special_number,
        builtin_func_type,
    }
}

parser :: struct
{
    text: []rune,
    text_section: []rune, 
}

syms_to_tokens: map[string] token = {
    "e" = { type = .SPEC_NUMBER, as = special_number.E },
    "pi"= { type = .SPEC_NUMBER, as = special_number.PI },
    
    "x" = { type = .VAR },
    
    "sin" = { type = .FUNC, as = builtin_func_type.SIN },
    "cos" = { type = .FUNC, as = builtin_func_type.COS },
    "tan" = { type = .FUNC, as = builtin_func_type.TAN },
    "cosec" = { type = .FUNC, as = builtin_func_type.COSEC },
    "sec" = { type = .FUNC, as = builtin_func_type.SEC },
    "cot" = { type = .FUNC, as = builtin_func_type.COT },
    "ln" = { type = .FUNC, as = builtin_func_type.LN },
    "sqrt" = { type = .FUNC, as = builtin_func_type.SQRT },

    "|"= { type = .PIPE },
    
    "+"= { type = .PLUS },
    "-"= { type = .MINUS },
    "*"= { type = .ASTERISK },
    "/"= { type = .SLASH },

    "("= { type = .PAREN_OPEN },
    ")"= { type = .PAREN_CLOSE },
}

next_token :: proc(text: []rune) -> (tk: token, new_slice: []rune)
{
    text := text

    for len(text) != 0 && unicode.is_space(text[0])
    {
        text = text[1:]
    }

    if len(text) == 0
    {
        return { type = .END }, text
    }

    if unicode.is_letter(text[0])
    {
        return collect_token_word(text)
    }

    if unicode.is_digit(text[0])
    {
        return collect_token_number(text)
    }

    switch text[0]
    {
        case '|': tk = { type = .PIPE }
        case '+': tk = { type = .PLUS }
        case '-': tk = { type = .MINUS }
        case '*': tk = { type = .ASTERISK }
        case '/': tk = { type = .SLASH }
        case '(': tk = { type = .PAREN_OPEN }
        case ')': tk = { type = .PAREN_CLOSE }
        case: return { type = .ERROR }, {}
    }

    new_slice = text[1:]
    return
}

collect_token_word :: proc(text: []rune) -> (tk: token, new_slice: []rune)
{
    word_runes := get_word_slice(text)
    assert(len(word_runes) != 0)

    s := utf8.runes_to_string(word_runes)
    defer delete(s)
    
    switch s
    {
        case "x": tk = { type = .VAR }
        case "e": tk = { type = .SPEC_NUMBER, as = special_number.E }
        case "pi", "π": tk = { type = .FUNC, as = special_number.PI }
        
        case "sin": tk = { type = .FUNC, as = builtin_func_type.SIN }
        case "cos": tk = { type = .FUNC, as = builtin_func_type.COS }
        case "tan": tk = { type = .FUNC, as = builtin_func_type.TAN }

        case "cosec": tk = { type = .FUNC, as = builtin_func_type.COSEC }
        case "sec": tk ={ type = .FUNC, as = builtin_func_type.SEC }
        case "cot": tk = { type = .FUNC, as = builtin_func_type.COT }

        case "ln": tk = { type = .FUNC, as = builtin_func_type.LN }
        case "sqrt": tk = { type = .FUNC, as = builtin_func_type.SQRT }
        case: return { type = .ERROR }, {}
    }

    new_slice = text[len(s):]
    return
}

collect_token_number :: proc(text: []rune) -> (tk: token, new_slice: []rune)
{
    number_runes := get_number_slice(text)
    assert(len(number_runes) != 0)

    s := utf8.runes_to_string(number_runes)
    defer delete(s)
 
    n: int
    v, vok := strconv.parse_f32(s, &n)

    if !vok
    {
        return { type = .ERROR }, {}
    }

    return { type = .NUMBER, as = v }, text[n:]
}

get_word_slice :: proc(text: []rune) -> []rune
{
    for c, i in text
    {

        if !unicode.is_letter(c)
        {
            return text[:i]
        }
    }

    return text
}

get_number_slice :: proc(text: []rune) -> []rune
{
    found_dot := false

    for c, i in text
    {
        if c == '.' && !found_dot
        {
            found_dot = true
            continue
        }

        if !unicode.is_digit(c)
        {
            return text[:i]
        }
    }

    return text
}

parser_eat_token :: proc(p: ^parser, type: token_type) -> bool
{
    tk: token
    tk, p.text_section = next_token(p.text_section)
    return tk.type == type
}

parse :: proc(s: string) -> ^ast
{
    runes := utf8.string_to_runes(s)
    defer delete(runes)

    p := parser { runes, runes }
    return parse_binop(&p)
}

parse_binop :: proc(p: ^parser) -> ^ast
{
    a := parse_operand(p)
    if a == nil do return nil

    tk, text_section := next_token(p.text_section)
    op: binop_type 

    #partial switch tk.type
    {
        case .PLUS:
            op = .ADD
        case .MINUS:
            op = .SUB
        case .ASTERISK:
            op = .MULT 
        case .SLASH:
            op = .DIV
        case .PIPE, .PAREN_CLOSE, .END:
            return a
        case:
            return nil
    }

    p.text_section = text_section

    b := parse_binop(p)
    if b == nil do return nil

    e := new(ast)
    e^ = ast_binop { op = op, a = a, b = b }
    return e
}

parse_operand :: proc(p: ^parser) -> ^ast
{
    tk: token
    tk, p.text_section = next_token(p.text_section)

    #partial switch tk.type
    {
        case .MINUS:
            return parse_neg(p)
        case .PIPE:
            return parse_abs(p)
        case .PAREN_OPEN:
            return parse_paren_enclosed(p)
        case .NUMBER:
            e := new(ast)
            e^ = tk.as.(f32)
            return e
        case .SPEC_NUMBER:
            e := new(ast)
            e^ = tk.as.(special_number)
            return e
        case .VAR:
            e := new(ast)
            e^ = ast_variable {}
            return e
        case .FUNC:
            return parse_func(p, tk.as.(builtin_func_type))
    }

    return nil
}

parse_neg :: proc(p: ^parser) -> ^ast
{
    inner := parse_operand(p)
    if inner == nil do return nil

    e := new(ast)
    e^ = ast_unop { op = .NEG, input = inner }
    return e
}

parse_abs :: proc(p: ^parser) -> ^ast
{
    inner := parse_binop(p)
    if inner == nil do return nil

    if !parser_eat_token(p, .PIPE) do return nil
    
    e := new(ast)
    e^ = ast_unop { op = .ABS, input = inner }
    return e
}

parse_paren_enclosed :: proc(p: ^parser) -> ^ast
{
    inner := parse_binop(p)
    if inner == nil do return nil

    if !parser_eat_token(p, .PAREN_CLOSE) do return nil
    
    return inner
}

parse_func :: proc(p: ^parser, func: builtin_func_type) -> ^ast
{
    if !parser_eat_token(p, .PAREN_OPEN) do return nil
    
    inner := parse_paren_enclosed(p)
    if inner == nil do return nil

    e := new(ast)
    e^ = ast_builtin_func { func = func, input = inner }
    return e
}