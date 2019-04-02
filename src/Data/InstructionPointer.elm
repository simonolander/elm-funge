module Data.InstructionPointer exposing (InstructionPointer)

import Data.Direction exposing (Direction)
import Data.Position exposing (Position)


type alias InstructionPointer =
    { position : Position
    , direction : Direction
    }
