module Model exposing
    ( Board
    , BoardSketch
    , Direction(..)
    , Execution
    , ExecutionMsg(..)
    , ExecutionState(..)
    , ExecutionStep
    , GameState(..)
    , IO
    , Input
    , Instruction(..)
    , InstructionPointer
    , JumpLocation(..)
    , Level
    , LevelId
    , LevelProgress
    , Model
    , Msg(..)
    , Output
    , Position
    , SketchMsg(..)
    , Stack
    , WindowSize
    )

import Array exposing (Array)
import History exposing (History)


type alias LevelId =
    String


type alias Input =
    List Int


type alias Stack =
    List Int


type alias Output =
    List Int


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


type JumpLocation
    = Forward
    | Absolute Position
    | Offset Position


type Instruction
    = NoOp
    | ChangeDirection Direction
    | PushToStack Int
    | PopFromStack
    | Jump JumpLocation
    | Duplicate
    | Swap
    | Negate
    | Abs
    | Not
    | Increment
    | Decrement
    | Add
    | Subtract
    | Multiply
    | Divide
    | Equals
    | And
    | Or
    | XOr
    | Read
    | Print
    | Branch Direction Direction
    | Terminate


type alias Board =
    Array (Array Instruction)


type alias InstructionPointer =
    { position : Position, direction : Direction }


type alias ExecutionStep =
    { board : Board
    , instructionPointer : InstructionPointer
    , stack : Stack
    , input : Input
    , output : Output
    , terminated : Bool
    }


type alias Execution =
    { executionHistory : History ExecutionStep
    , level : Level
    }


type alias BoardSketch =
    { boardHistory : History Board
    , selectedInstruction : Maybe Instruction
    }


type alias IO =
    { input : Input
    , output : Output
    }


type alias Level =
    { id : LevelId
    , name : String
    , io : IO
    , initialBoard : Board
    , permittedInstructions : List Instruction
    }


type alias LevelProgress =
    { level : Level
    , boardSketch : BoardSketch
    , completed : Bool
    }


type ExecutionState
    = ExecutionPaused Execution
    | ExecutionRunning Execution Float


type GameState
    = BrowsingLevels
    | Sketching LevelId
    | Executing ExecutionState


type SketchMsg
    = PlaceInstruction Position Instruction
    | SelectInstruction Instruction
    | SketchUndo
    | SketchRedo
    | SketchClear
    | SketchExecute
    | SketchBackClicked


type ExecutionMsg
    = ExecutionStepOne
    | ExecutionUndo
    | ExecutionRun
    | ExecutionPause
    | ExecutionBackClicked
    | ExecutionBackToBrowsingLevels


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
