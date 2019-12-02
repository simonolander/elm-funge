module Page.Execution.Model exposing (Execution, ExecutionState(..), ExecutionStep, ExecutionSuite, Model, init)

import Data.Board exposing (Board)
import Data.DraftId exposing (DraftId)
import Data.History exposing (History)
import Data.Input exposing (Input)
import Data.InstructionPointer exposing (InstructionPointer)
import Data.Level exposing (Level)
import Data.LevelId exposing (LevelId)
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


type alias ExecutionSuite =
    { executionHistory : History ExecutionStep
    , expectedOutput : Output
    }


type alias Execution =
    { executionSuites : History ExecutionSuite
    , level : Level
    }


type ExecutionState
    = Paused
    | Running
    | FastForwarding


type alias Model =
    { draftId : DraftId
    , loadedLevelId : Maybe LevelId
    , execution : Maybe Execution
    , state : ExecutionState
    }


init : DraftId -> Model
init draftId =
    { draftId = draftId
    , loadedLevelId = Nothing
    , state = Paused
    , execution = Nothing
    }
