module Data.Execution exposing (Execution)

import Data.ExecutionStep exposing (ExecutionStep)
import Data.History exposing (History)
import Data.Level exposing (Level)


type alias Execution =
    { executionHistory : History ExecutionStep
    , level : Level
    }
