module Data.ExecutionState exposing (ExecutionState(..))


type ExecutionState
    = ExecutionPaused
    | ExecutionRunning Float
