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

# A recursive-descent top-down parser for mathematical expressions

import ../objects/token
import ../objects/ast
import ../objects/error

import parseutils
import strformat


{.experimental: "implicitDeref".}


type
  Parser* = ref object
    tokens: seq[Token]
    current: int


proc initParser*(): Parser = 
  new(result)
  result.current = 0
  result.tokens = @[]


# Forward declaration

proc binary(self: Parser): AstNode


template endOfFile: Token = 
  ## Creates an EOF token -- utility template
  Token(lexeme: "", kind: TokenType.Eof)


func done(self: Parser): bool = 
  result = self.current >= self.tokens.high()


proc peek(self: Parser): Token = 
  ## Peeks into the tokens list or
  ## returns an EOF token if we're at
  ## the end of the input
  if not self.done():
    result = self.tokens[self.current]
  else:
    result = endOfFile


proc step(self: Parser): Token = 
  ## Consumes a token from the input and
  ## steps forward or returns an EOF token 
  ## if we're at the end of the input
  if not self.done():
    result = self.peek()
    self.current += 1
  else:
    result = endOfFile


proc previous(self: Parser): Token = 
  ## Returns the previously consumed
  ## token
  result = self.tokens[self.current - 1]


proc check(self: Parser, kind: TokenType): bool = 
  ## Returns true if the current token matches
  ## the given type
  result = self.peek().kind == kind


proc match(self: Parser, kind: TokenType): bool = 
  ## Checks if the current token matches the
  ## given type and consumes it if it does, returns
  ## false otherwise. True is returned if the
  ## match is successful
  if self.check(kind):
    discard self.step()
    result = true
  else:
    result = false


proc match(self: Parser, kinds: varargs[TokenType]): bool = 
  ## Checks if the current token matches any of the
  ## given type(s) and consumes it if it does, returns
  ## false otherwise. True is returned at
  ## the first successful match
  for kind in kinds:
    if self.match(kind):
      return true
  result = false


proc error(self: Parser, message: string) = 
  ## Raises a parsing error with the given message
  raise newException(ParseError, message)


proc expect(self: Parser, kind: TokenType, message: string) = 
  ## Checks if the current token matches the given type
  ## and consumes it if it does, raises an error 
  ## with the given message otherwise.
  if not self.match(kind):
    self.error(message)


proc primary(self: Parser): AstNode = 
  ## Parses primary expressions
  let value = self.previous()
  case value.kind:
    of TokenType.Int:
      result = AstNode(kind: NodeKind.Integer, value: 0.0)
      discard parseFloat(value.lexeme, result.value)
    of TokenType.Float:
      result = AstNode(kind: NodeKind.Float, value: 0.0)
      discard parseFloat(value.lexeme, result.value)
    of TokenType.LeftParen:
      let expression = self.binary()
      self.expect(TokenType.RightParen, "unexpected EOL")
      result = AstNode(kind: NodeKind.Grouping, expr: expression)
    else:
      self.error(&"invalid token of kind '{value.kind}' in primary expression")


proc unary(self: Parser): AstNode = 
  ## Parses unary expressions such as -1
  case self.step().kind:
    of TokenType.Minus:
      result = AstNode(kind: NodeKind.Unary, unOp: self.previous(), operand: self.unary())
    else:
      result = self.primary()
  

proc pow(self: Parser): AstNode = 
  ## Parses exponentiation
  result = self.unary()
  var operator: Token
  while self.match(TokenType.Exp):
    operator = self.previous()
    result = AstNode(kind: NodeKind.Binary, left: result, right: self.unary(), binOp: operator)


proc mul(self: Parser): AstNode = 
  ## Parses divisions (including modulo) and
  ## multiplications
  result = self.pow()
  var operator: Token
  while self.match(TokenType.Div, TokenType.Modulo, TokenType.Mul):
    operator = self.previous()
    result = AstNode(kind: NodeKind.Binary, left: result, right: self.pow(), binOp: operator)


proc addition(self: Parser): AstNode = 
  ## Parses additions and subtractions
  result = self.mul()
  var operator: Token
  while self.match(TokenType.Plus, TokenType.Minus):
    operator = self.previous()
    result = AstNode(kind: NodeKind.Binary, left: result, right: self.mul(), binOp: operator)


proc binary(self: Parser): AstNode = 
  ## Parses binary expressions, the highest
  ## level of expression
  result = self.addition()



proc parse*(self: Parser, tokens: seq[Token]): AstNode = 
  ## Parses a list of tokens into an AST tree
  self.tokens = tokens
  result = self.binary()
  

