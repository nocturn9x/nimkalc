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

# An Abstract Syntax Tree and node visitor implementation
import token
import error

import strformat
import tables
import math
import strutils


type
  NodeKind* {.pure.} = enum
    # An enum for all kinds of AST nodes
    Grouping, Unary, Binary, Integer,
    Float, Call, Ident
  AstNode* = ref object
    # An AST node object
    case kind*: NodeKind
      of NodeKind.Grouping:
        expr*: AstNode
      of NodeKind.Unary:
        unOp*: Token
        operand*: AstNode
      of NodeKind.Binary:
        binOp*: Token
        left*: AstNode
        right*: AstNode
      of NodeKind.Integer, NodeKind.Float:
        # The kind makes us differentiate between
        # floats and integers, but for our purposes
        # using a double precision float for everything
        # is just easier
        value*: float64
      of NodeKind.Ident:
        name*: string
      of NodeKind.Call:
          arguments*: seq[AstNode]
          function*: AstNode
  NodeVisitor* = ref object
    # A node visitor object


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



proc initNodeVisitor*(): NodeVisitor =
  ## Initializes a node visitor
  new(result)


template handleBinary(left, right: AstNode, operator: untyped): AstNode =
  ## Handy template that avoids us the hassle of copy-pasting
  ## the same checks over and over again in the visitor
  let r = operator(left.value, right.value)
  if float(int(r)) == r:
    ## It's a whole number!
    AstNode(kind: NodeKind.Integer, value: r)
  else:
    AstNode(kind: NodeKind.Float, value: r)


template ensureNonZero(node: AstNode) =
  ## Handy template to ensure that a given node's value is not 0
  if node.value == 0.0:
      case node.kind:
        of NodeKind.Float, NodeKind.Integer:
            raise newException(MathError, &"{($node.kind).toLowerAscii()} can't be zero")
        else:
          raise newException(CatchableError, &"invalid node kind '{node.kind}' for ensureNonZero")


template ensureIntegers(left, right: AstNode) =
  ## Ensures both operands are integers
  if left.kind != NodeKind.Integer or right.kind != NodeKind.Integer:
    raise newException(MathError, "an integer is required")


# Forward declarations
proc visit_literal(self: NodeVisitor, node: AstNode): AstNode
proc visit_unary(self: NodeVisitor, node: AstNode): AstNode
proc visit_binary(self: NodeVisitor, node: AstNode): AstNode
proc visit_grouping(self: NodeVisitor, node: AstNode): AstNode
proc visit_call(self: NodeVisitor, node: AstNode): AstNode


proc accept(self: AstNode, visitor: NodeVisitor): AstNode =
  ## Implements the accept part of the visitor pattern
  ## for our AST visitor
  case self.kind:
    of NodeKind.Integer, NodeKind.Float, NodeKind.Ident:
      result =  visitor.visit_literal(self)
    of NodeKind.Binary:
      result = visitor.visit_binary(self)
    of NodeKind.Unary:
      result = visitor.visit_unary(self)
    of NodeKind.Grouping:
      result = visitor.visit_grouping(self)
    of NodeKind.Call:
      result = visitor.visit_call(self)


proc eval*(self: NodeVisitor, node: AstNode): AstNode =
  ## Evaluates an AST node
  result = node.accept(self)


proc visit_literal(self: NodeVisitor, node: AstNode): AstNode =
  ## Visits a literal AST node (such as integers)
  result = node   # Not that we can do anything else after all, lol


proc visit_call(self: NodeVisitor, node: AstNode): AstNode =
  ## Visits function call expressions
  var args: seq[AstNode] = @[]
  for arg in node.arguments:
    args.add(self.eval(arg))
  if node.function.name == "sin":
    let r = sin(args[0].value)
    if r is float:
      result = AstNode(kind: NodeKind.Float, value: r)
    else:
      result = AstNode(kind: NodeKind.Integer, value: float(r))
  if node.function.name == "cos":
    let r = cos(args[0].value)
    if r is float:
      result = AstNode(kind: NodeKind.Float, value: r)
    else:
      result = AstNode(kind: NodeKind.Integer, value: float(r))
  if node.function.name == "tan":
    let r = tan(args[0].value)
    if r is float:
      result = AstNode(kind: NodeKind.Float, value: r)
    else:
      result = AstNode(kind: NodeKind.Integer, value: float(r))


proc visit_grouping(self: NodeVisitor, node: AstNode): AstNode =
  ## Visits grouping (i.e. parenthesized) expressions. Parentheses
  ## have no other meaning than to allow a lower-precedence expression
  ## where a higher-precedence one is expected so that 2 * (3 + 1) is
  ## different from 2 * 3 + 1
  return self.eval(node.expr)


proc visit_binary(self: NodeVisitor, node: AstNode): AstNode =
  ## Visits a binary AST node and evaluates it
  let right = self.eval(node.right)
  let left = self.eval(node.left)
  case node.binOp.kind:
    of TokenType.Plus:
      result = handleBinary(left, right, `+`)
    of TokenType.Minus:
      result = handleBinary(left, right, `-`)
    of TokenType.Div:
      ensureNonZero(right)
      result = handleBinary(left, right, `/`)
    of TokenType.Modulo:
      # Modulo is a bit special since we must have integers
      ensureNonZero(right)
      ensureIntegers(left, right)
      result = AstNode(kind: NodeKind.Integer, value: float(int(left.value) mod int(right.value)))
    of TokenType.Exp:
      result = handleBinary(left, right, pow)
    of TokenType.Mul:
      result = handleBinary(left, right, `*`)
    else:
      discard  # Unreachable


proc visit_unary(self: NodeVisitor, node: AstNode): AstNode =
  ## Visits unary expressions and evaluates them
  let expr = self.eval(node.operand)
  case node.unOp.kind:
    of TokenType.Minus:
      case expr.kind:
        of NodeKind.Float:
          result = AstNode(kind: NodeKind.Float, value: -expr.value)
        of NodeKind.Integer:
          result = AstNode(kind: NodeKind.Integer, value: -expr.value)
        else:
          discard  # Unreachable
    else:
      discard  # Unreachable
