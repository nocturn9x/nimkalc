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

# A simple lexer module

import strutils
import strformat
import tables

import ../objects/token
import ../objects/error


# Table of all tokens
const tokens = to_table({
              '(': TokenType.LeftParen, ')': TokenType.RightParen,
              '-': TokenType.Minus, '+': TokenType.Plus,
              '*': TokenType.Mul, '/': TokenType.Div,
              '%': TokenType.Modulo, '^': TokenType.Exp,
              ',': TokenType.Comma})
 # All the identifiers and constants (such as PI)
 # Since they're constant we don't even need to bother adding another
 # AST node kind, we can just map the name to a float literal ;)
const constants = to_table({
    "pi": Token(kind: TokenType.Float, lexeme: "3.141592653589793"),
    "e": Token(kind: TokenType.Float, lexeme: "2.718281828459045"),
    "tau": Token(kind: TokenType.Float, lexeme: "6.283185307179586"),
    "inf": Token(kind: TokenType.Float, lexeme: "inf"),
    "nan": Token(kind: TokenType.Float, lexeme: "nan"),
    "phi": Token(kind: TokenType.Float, lexeme: "1.618033988749895"),
})
# Since also math functions are hardcoded, we can use an array
const functions = ["sin", "cos", "tan", "cosh",
                   "tanh", "sinh", "arccos", "arcsin",
                   "arctan", "log", "log10", "ln", "log2",
                   "hypot", "sqrt", "cbrt", "arctanh", "arcsinh",
                   "arccosh"]


type
    Lexer* = ref object
        # A lexer object
        source*: string
        tokens*: seq[Token]
        start*: int
        current*: int


func initLexer*(): Lexer =
    ## Initializes the lexer in an empty state
    result = Lexer(source: "", tokens: @[], start: 0, current: 0)


func done(self: Lexer): bool =
    ## Returns true if we reached EOF
    result = self.current >= self.source.len


proc step(self: Lexer): char =
    ## Steps one character forward in the
    ## source. A null terminator is returned
    ## if the lexer is at EOF
    if self.done():
        return '\0'
    self.current = self.current + 1
    result = self.source[self.current - 1]


proc peek(self: Lexer): char =
    ## Returns the current character in the
    ## source without consuming it.
    ## A null terminator is returned
    ## if the lexer is at EOF
    if self.done():
        result = '\0'
    else:
        result = self.source[self.current]


func createToken(self: Lexer, tokenType: TokenType): Token =
    ## Creates a token object for later use in the parser
    result = Token(kind: tokenType,
                   lexeme: self.source[self.start..<self.current],
        )


proc parseNumber(self: Lexer) =
    ## Parses numeric literals
    var kind = TokenType.Int
    var scientific: bool = false
    var sign: bool = false
    while true:
        if self.peek().isDigit():
            discard self.step()
        elif self.peek() == '.':
            # The dot for floats
            kind = TokenType.Float
            discard self.step()
        elif self.peek().toLowerAscii() == 'e':
            # Scientific notation
            kind = TokenType.Float
            discard self.step()
            scientific = true
        elif self.peek().toLowerAscii() in {'-', '+'} and scientific and not sign:
            # So we can parse stuff like 2e-5
            sign = true
            discard self.step()
        else:
            break
    self.tokens.add(self.createToken(kind))


proc parseIdentifier(self: Lexer) =
    ## Parses identifiers. Note that
    ## multi-character tokens such as
    ## UTF runes are not supported
    while self.peek().isAlphaNumeric() or self.peek() in {'_', }:
        discard self.step()
    var text: string = self.source[self.start..<self.current]
    if text.toLowerAscii() in constants:
        self.tokens.add(constants[text])
    elif text.toLowerAscii() in functions:
        self.tokens.add(self.createToken(TokenType.Ident))
    else:
        raise newException(ParseError, &"Unknown identifier '{text}'")


proc scanToken(self: Lexer) =
    ## Scans a single token. This method is
    ## called iteratively until the source
    ## string reaches EOF
    var single = self.step()
    if single in [' ', '\t', '\r', '\n']: # We skip whitespaces, tabs and other stuff
        return
    elif single.isDigit():
        self.parseNumber()
    elif single in tokens:
        self.tokens.add(self.createToken(tokens[single]))
    elif single.isAlphanumeric() or single == '_':
        self.parseIdentifier()
    else:
        raise newException(ParseError, &"Unexpected token '{single}'")


proc lex*(self: Lexer, source: string): seq[Token] =
    ## Lexes a source string, converting a stream
    ## of characters into a series of tokens
    self.source = source
    self.tokens = @[]
    self.current = 0
    while not self.done():
        self.start = self.current
        self.scanToken()
    self.tokens.add(Token(kind: TokenType.Eof, lexeme: ""))
    result = self.tokens
