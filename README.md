# NimKalc - A math parsing library

NimKalc is a simple implementation of a recursive-descent top-down parser that can evaluate
mathematical expressions.

__Disclaimer__: This library is __in beta__ and is not fully tested yet. It will be soon, though. If you
find any bugs or issues, please report them so we can fix them and make a proper test suite!


Features:
- Support for the following mathematical constants:
  - `pi`
  - `tau` (pi * 2)
  - `e` (Euler's number)
  - `inf` (Infinity)
  - `nan` (Not a number)
- Support for the following of nim's [math library](https://nim-lang.org/docs/math.html#log10%2Cfloat32) functions:
  - `binom`
  - `sin`
  - `cos`
  - `tan`
  - `sinh`
  - `tanh`
  - `cosh`
  - `arccos`
  - `arcsin`
  - `arctan`
  - `arcsinh`
  - `arccosh`
  - `arctanh`
  - `hypot`
  - `sqrt`
  - `cbrt`
  - `log10`
  - `log2`
  - `ln`
  - `log`
- Parentheses can be used to enforce different precedence levels
- Easy API for tokenization, parsing and evaluation of AST nodes


__Note__: Some procedures were not implemented because for any of the following reasons:
- They return booleans or other custom types that we don't support, like `classify`
- They weren't useful enough or their functionality was already implemented in other ways (such as `pow` which we use as the `^` operator)
- They just haven't made their way into the library yet, be patient!


## Current limitations
- No equation-solving (coming soon)


## How to use it

NimKalc parses mathematical expressions following this process:
- Tokenize the input
- Generate an AST
- Visit the nodes

Each of these steps can be run separately, but for convenience a wrapper `eval` procedure has been defined which takes in a string 
and returns a single AST node containing the result of the given expression.

## Supported operators

Beyond the classical 4 operators (`+`, `-`, `/` and `*`), NimKalc supports:
- `%` for modulo division
- `^` for exponentiation
- unary `-` for negation

## Exceptions

NimKalc defines various exceptions:
- `NimKalcException` is a generic superclass for all errors
- `ParseError` is used when the expression is syntactically invalid
- `MathError` is used when there is an arithmetical error such as division by 0 or domain errors (e.g. `log(0)`)
- `EvaluationError` is used when the runtime evaluation of an expression fails (e.g. trying to call something that isn't a function)

## Design

NimKalc treats all numerical values as `float` to simplify the implementation of the underlying operators. To tell integers
from floating point numbers the `AstNode` object has a `kind` discriminant which will be equal to `NodeKind.Integer` for ints
and `NodeKind.Float` for decimals. It is advised that you take this into account when using the library, since integers might
start losing precision when converted from their float counterpart due to the difference of the two types. Everything should
be fine as long as the value doesn't exceed 2 ^ 53, though


__Note__: The string representation of integer nodes won't show the decimal part for clarity

Some other notable design choices (due to the underlying simplicity of the language we parse) are as follows:
- Identifiers are checked when tokenizing, since they're all constant
- Mathematical constants are immediately mapped to their real values when tokenizing with no intermediate steps or tokens
- Type errors (such as trying to call an integer) are detected statically at parse time


## String representations

All of NimKalc's objects implement the `$` operator and are therefore printable. Integer nodes will look like `Integer(x)`, while
floats are represented with `Float(x.x)`. Unary operators print as `Unary(operator, right)`, while binary operators print as `Binary(left, operator, right)`.
Parenthesized expressions print as `Grouping(expr)`, where `expr` is the expression enclosed in parentheses (as an AST node, obviously).
Token objects will print as `Token(kind, lexeme)`: an example for the number 2 would be `Token(Integer, '2')`. Function calls print like `Call(name, args)`
where `name` is the function name and `args` is a list of arguments


## Example

Here is an example of a REPL using all of NimKalc's functionality to evaluate expressions from stdin (can be found at `examples/repl.nim`)

```nim
import nimkalc/objects/ast
import nimkalc/objects/token
import nimkalc/parsing/parser
import nimkalc/parsing/lexer
import nimkalc/objects/error


import strformat
import strutils


proc repl() =
  ## A simple REPL to demonstrate NimKalc's functionality
  var line: string
  var result: AstNode
  var tokens: seq[Token]
  let lexerObj = initLexer()
  let parserObj = initParser()
  let visitor = initNodeVisitor()
  echo "Welcome to the NimKalc REPL, type a math expression and press enter"
  while true:
    try:
      stdout.write("=> ")
      line = stdin.readLine()
      echo &"Parsing and evaluation of {line} below:"
      tokens = lexerObj.lex(line)
      # No-one cares about the EOF token after all
      echo &"Tokenization of {line}: {tokens[0..^2].join(\", \")}"
      result = parserObj.parse(tokens)
      echo &"AST for {line}: {result}"
      result = visitor.eval(result)
      case result.kind:
        # The result is an AstNode object, specifically
        # either a node of type NodeKind.Float or a NodeKind.Integer
        of NodeKind.Float:
          echo &"Value of {line}: {result.value}"
        of NodeKind.Integer:
          echo &"Value of {line}: {int(result.value)}"
        else:
          discard  # Unreachable
    except IOError:
      echo "\nGoodbye."
      break
    except ParseError:
      echo &"A parsing error occurred: {getCurrentExceptionMsg()}"
    except MathError:
      echo &"An arithmetic error occurred: {getCurrentExceptionMsg()}"
    except OverflowDefect:
      echo &"Value overflow/underflow detected: {getCurrentExceptionMsg()}"


when isMainModule:
  repl()

```

__Note__: If you don't need the intermediate representations shown here (tokens/AST) you can just `import nimkalc` and use
the `eval` procedure, which takes in a string and returns the evaluated result as a primary AST node like so:

```nim
import nimkalc

echo eval("2+2")  # Prints Integer(4)
```

## Installing

You can install the package via nimble with this command: `nimble install nimkalc`



__Note__: Nim 1.2.0 or higher is required to build NimKalc! Other versions are likely work if they're not too old, but they have not been tested
