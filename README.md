# NimKalc - A math parsing library

NimKalc is a simple implementation of a recursive-descent top-down parser that can evaluate
mathematical expressions. Notable mentions are support for common mathematical constants (pi, tau, euler's number, etc),
functions (`sin`, `cos`, `tan`...), equation-solving algos using newton's method and scientific notation numbers (such as `2e5`)


## Current limitations
- No functions (coming soon)
- No equation-solving (coming soon)
- The parsing is a bit weird because `2 2` will parse the first 2 and just stop instead of erroring out (FIXME)


## How to use it

NimKalc parses mathematical expressions following this process:
- Tokenize the input
- Generate an AST
- Visit the nodes

Each of these steps can be run separately, but for convenience a wrapper
`eval` procedure has been defined which takes in a string and returns a
single AST node containing the result of the given expression.

## Supported operators

Beyond the classical 4 operators (`+`, `-`, `/` and `*`), NimKalc supports:
- `%` for modulo division
- `^` for exponentiation
- unary `-` for negation
- Arbitrarily nested parentheses (__not__ empty ones!) to enforce precedence


## Exceptions

NimKalc defines 2 exceptions:
- `ParseError` is used when the expression is invalid
- `MathError` is used when there is an arithmetical error such as division by 0 or domain errors (e.g. `log(0)`)

## Design

NimKalc treats all numerical values as `float` to simplify the implementation of the underlying operators. To tell integers
from floating point numbers the `AstNode` object has a `kind` discriminant which will be equal to `NodeKind.Integer` for ints
and `NodeKind.Float` for decimals. It is advised that you take this into account when using the library


__Note__: The string representation of integer nodes won't show the decimal part for clarity

## String representations

All of NimKalc's objects implement the `$` operator and are therefore printable. Integer nodes will look like `Integer(x)`, while
floats are represented with `Float(x.x)`. Unary operators print as `Unary(operator, right)`, while binary operators print as `Binary(left, operator, right)`.
Parenthesized expressions print as `Grouping(expr)`, where `expr` is the expression enclosed in parentheses (as an AST node, obviously).
Token objects will print as `Token(kind, lexeme)`: an example for the number 2 would be `Token(Integer, '2')`


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

__Note__: If you don't need the intermediate representations shown here (tokens, AST) you can just `import nimkalc` and use
the `eval` procedure, which takes in a string and returns the evaluated result as a primary AST node like so:

```nim
import nimkalc

echo eval("2+2")  # Prints Integer(4)

```

## Installing

You can clone this repository and then install the package via nimble:
- `git clone https://github.com/nocturn9x/nimkalc`
- `cd nimkalc`
- `nimble install`


__Note__: Nim 1.2.0 or higher is required to build NimKalc! Other versions are likely work if they're not too old, but they have not been tested