# Copyright 2021 Mattia Giambirtone
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# A parsing Token
import strformat

type
  TokenType* {.pure.} = enum
    # Data types
    Int, Float,
    # Operators
    Plus, Minus, Div, Exp, Modulo,
    Mul, RightParen, LeftParen,
    # Identifiers
    Ident,
    # Other
    Eof, Comma
  Token* = object
    # A token object
    lexeme*: string
    kind*: TokenType


proc `$`*(self: Token): string =
  ## Returns a string representation of a token
  result = &"Token({self.kind}, '{self.lexeme}')"
