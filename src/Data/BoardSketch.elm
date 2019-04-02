module Data.BoardSketch exposing (BoardSketch)

import Data.Board exposing (Board)
import Data.History exposing (History)
import Data.InstructionToolbox exposing (InstructionToolbox)


type alias BoardSketch =
    { boardHistory : History Board
    , instructionToolbox : InstructionToolbox
    }
