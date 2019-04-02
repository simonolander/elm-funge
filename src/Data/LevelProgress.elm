module Data.LevelProgress exposing (LevelProgress)

import Data.BoardSketch exposing (BoardSketch)
import Data.Level exposing (Level)


type alias LevelProgress =
    { level : Level
    , boardSketch : BoardSketch
    , solved : Bool
    }
