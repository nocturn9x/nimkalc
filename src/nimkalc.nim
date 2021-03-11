# Copyright 2021 Mattia Giambirtone
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## Top-level module for nimkalc

import nimkalc/parsing/parser
import nimkalc/objects/ast
import nimkalc/parsing/lexer
import nimkalc/parsing/token


import strutils
import strformat


proc `$`*(self: AstNode): string =
  ## Stringifies an AST node
  case self.kind:
      of NodeKind.Grouping:
        result = &"Grouping({self.expr})"
      of NodeKind.Unary:
        result = &"Unary({$self.unOp.kind}, {$self.operand})"
      of NodeKind.Binary:
        result = &"Binary({$self.left}, {$self.binOp.kind}, {$self.right})"
      of NodeKind.Integer:
        result = &"Integer({$int(self.value)})"
      of NodeKind.Float:
        result = &"Float({$self.value})"
      of NodeKind.Call:
        result = &"Call({self.function.name}, {self.arguments})"
      of NodeKind.Ident:
        result = &"Identifier({self.name})"


proc `$`*(self: Token): string =
  ## Returns a string representation of a token
  result = &"Token({self.kind}, '{self.lexeme}')"


proc eval*(source: string): AstNode =
  ## Evaluates a mathematical expression as a string
  ## and returns a leaf node representing the result
  let l = initLexer()
  let p = initParser()
  let v = initNodeVisitor()
  result = v.eval(p.parse(l.lex(source)))

