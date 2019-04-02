module Data.InstructionToolbox exposing (InstructionToolbox)

import Data.InstructionTool exposing (InstructionTool)


type alias InstructionToolbox =
    { instructionTools : List InstructionTool
    , selectedIndex : Maybe Int
    }
