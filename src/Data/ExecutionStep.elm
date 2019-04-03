module Data.ExecutionStep exposing (ExecutionStep)

import Data.Board exposing (Board)
import Data.Input exposing (Input)
import Data.InstructionPointer exposing (InstructionPointer)
import Data.Output exposing (Output)
import Data.Stack exposing (Stack)


type alias ExecutionStep =
    { board : Board
    , instructionPointer : InstructionPointer
    , stack : Stack
    , input : Input
    , output : Output
    , terminated : Bool
    , exception : Maybe String
    , stepCount : Int
    }
