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

# A simple REPL to parse and evaluate mathematical expressions


import nimkalc

import strformat
import strutils


proc repl() =
  ## A simple REPL to demonstrate NimKalc's functionality
  var result: AstNode
  while true:
    try:
      stdout.write("=> ")
      result = eval(stdin.readLine())
      case result.kind:
        # The result is an AstNode object, specifically
        # either a node of type NodeKind.Float or a NodeKind.Integer
        of NodeKind.Float:
          echo result.value
        of NodeKind.Integer:
          echo int(result.value)
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
