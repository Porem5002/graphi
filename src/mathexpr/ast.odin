package mathexpr

import "core:math"

special_number :: enum
{
    E,
    PI,
}

unop_type :: enum
{
    NEG,
    ABS,
}

binop_type :: enum
{
    ADD,
    SUB,
    MULT,
    DIV,
}

builtin_func_type :: enum
{
    SIN,
    COS,
    TAN,

    COSEC,
    SEC,
    COT,

    LN,
    SQRT,
}

ast :: union
{
    f32,
    special_number,
    ast_variable,
    ast_unop,
    ast_binop,
    ast_builtin_func,
}

ast_variable :: struct { }

ast_unop :: struct
{
    op: unop_type,
    input: ^ast,
}

ast_binop :: struct
{
    op: binop_type,
    a: ^ast,
    b: ^ast,
}

ast_builtin_func :: struct
{
    func: builtin_func_type,
    input: ^ast,
}

eval_ast :: proc(expr: ^ast, x: f32) -> f32
{
    switch e in expr
    {
        case f32:
            return e
        case special_number:
            return eval_special_number(e)
        case ast_variable:
            return x
        case ast_unop:
            return eval_unop(&expr.(ast_unop), x)
        case ast_binop:
            return eval_binop(&expr.(ast_binop), x)
        case ast_builtin_func:
            return eval_builtin_func(&expr.(ast_builtin_func), x)
    }

    panic("unreachable")
}

eval_special_number :: proc(special_number: special_number) -> f32
{
    switch special_number
    {
        case .E:
            return math.E
        case .PI:
            return math.PI
    }

    panic("unreachable")
}

eval_unop :: proc(expr: ^ast_unop, x: f32) -> f32
{
    input := eval_ast(expr.input, x)

    switch expr.op
    {
        case .NEG:
            return -input
        case .ABS:
            return abs(input)
    }

    panic("unreachable")
}

eval_binop :: proc(expr: ^ast_binop, x: f32) -> f32
{
    a := eval_ast(expr.a, x)
    b := eval_ast(expr.b, x)

    switch expr.op
    {
        case .ADD:
            return a + b
        case .SUB:
            return a - b
        case .MULT:
            return a * b
        case .DIV:
            return a / b
    }

    panic("unreachable")
}

eval_builtin_func :: proc(expr: ^ast_builtin_func, x: f32) -> f32
{
    input := eval_ast(expr.input, x)

    switch expr.func
    {
        case .SIN:
            return math.sin(input)
        case .COS:
            return math.cos(input)
        case .TAN:
            return math.tan(input)
        case .COSEC:
            return 1 / math.sin(input)
        case .SEC:
            return 1 / math.cos(input)
        case .COT:
            return 1 / math.tan(input)
        case .LN:
            return math.ln(input)
        case .SQRT:
            return math.sqrt(input)
    }

    panic("unreachable")
}

free_ast :: proc(expr: ^ast)
{
    switch e in expr
    {
        case f32:
        case special_number:
        case ast_variable:
        case ast_unop:
            free_ast(e.input)
        case ast_binop:
            free_ast(e.a)
            free_ast(e.b)
        case ast_builtin_func:
            free_ast(e.input)
    }

    free(expr)
}