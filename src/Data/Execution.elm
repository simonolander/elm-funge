module Data.Execution exposing (Execution)

import Data.ExecutionStep exposing (ExecutionStep)
import Data.History exposing (History)


type alias Execution =
    { executionHistory : History ExecutionStep
    , level : Level
    }
