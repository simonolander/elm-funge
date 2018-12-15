module Model exposing
    ( Board
    , BoardSketch
    , Case
    , Direction(..)
    , Execution
    , ExecutionMsg(..)
    , ExecutionStep
    , GameState(..)
    , Instruction(..)
    , InstructionPointer
    , Level
    , LevelProgress
    , Model
    , Msg(..)
    , Position
    , SketchMsg(..)
    , WindowSize
    )

import Array exposing (Array)
import History exposing (History)


type alias LevelId =
    String


type alias WindowSize =
    { width : Int
    , height : Int
    }


type alias Position =
    { x : Int
    , y : Int
    }


type Direction
    = Left
    | Up
    | Right
    | Down


type Instruction
    = NoOp
    | ChangeDirection Direction
    | PushToStack Int
    | Add
    | Subtract
    | Multiply
    | Divide
    | Read
    | Print


type alias Board =
    Array (Array Instruction)


type alias InstructionPointer =
    { position : Position, direction : Direction }


type alias ExecutionStep =
    { board : Board
    , instructionPointer : InstructionPointer
    , input : List Int
    , output : List Int
    }


type alias Execution =
    { executionHistory : History ExecutionStep
    , level : Level
    }


type alias BoardSketch =
    { boardHistory : History Board
    }


type alias Case =
    { input : List Int
    , output : List Int
    }


type alias Level =
    { id : LevelId
    , name : String
    , cases : List Case
    , initialBoard : Board
    }


type alias LevelProgress =
    { level : Level
    , boardSketch : BoardSketch
    , completed : Bool
    }


type GameState
    = BrowsingLevels
    | Sketching LevelId
    | Executing Execution


type SketchMsg
    = PlaceInstruction Position Instruction
    | Undo
    | Redo
    | Execute


type ExecutionMsg
    = Step
    | UndoExecutionStep


type Msg
    = Resize WindowSize
    | SelectLevel LevelId
    | SketchMsg SketchMsg
    | ExecutionMsg ExecutionMsg


type alias Model =
    { windowSize : WindowSize
    , levelProgresses : List LevelProgress
    , gameState : GameState
    }
