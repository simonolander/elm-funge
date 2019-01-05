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
    , InstructionTool(..)
    , InstructionToolbox
    , JumpLocation(..)
    , Level
    , LevelId
    , LevelProgress
    , LocalStorageMsg(..)
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
import PortFunnel.LocalStorage as LocalStorage
import PortFunnels


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
    | CompareLessThan
    | And
    | Or
    | XOr
    | Read
    | Print
    | Branch Direction Direction
    | Terminate
    | SendToBottom
    | Exception String


type InstructionTool
    = JustInstruction Instruction
    | ChangeAnyDirection Direction
    | BranchAnyDirection Direction Direction
    | PushValueToStack String


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
    , exception : Maybe String
    , stepCount : Int
    }


type alias Execution =
    { executionHistory : History ExecutionStep
    , level : Level
    }


type alias InstructionToolbox =
    { instructionTools : List InstructionTool
    , selectedIndex : Maybe Int
    }


type alias BoardSketch =
    { boardHistory : History Board
    , instructionToolbox : InstructionToolbox
    }


type alias IO =
    { input : Input
    , output : Output
    }


type alias Level =
    { id : LevelId
    , name : String
    , description : List String
    , io : IO
    , initialBoard : Board
    , instructionTools : List InstructionTool
    }


type alias LevelProgress =
    { level : Level
    , boardSketch : BoardSketch
    , solved : Bool
    }


type ExecutionState
    = ExecutionPaused Execution
    | ExecutionRunning Execution Float


type GameState
    = BrowsingLevels (Maybe LevelId)
    | Sketching LevelId
    | Executing ExecutionState


type SketchMsg
    = PlaceInstruction Position Instruction
    | NewInstructionToolbox InstructionToolbox
    | SketchUndo
    | SketchRedo
    | SketchClear
    | SketchExecute
    | SketchBackClicked


type ExecutionMsg
    = ExecutionStepOne
    | ExecutionUndo
    | ExecutionRun
    | ExecutionFastForward
    | ExecutionPause
    | ExecutionBackClicked
    | ExecutionBackToBrowsingLevels


type LocalStorageMsg
    = LocalStorageProcess LocalStorage.Value
    | Clear


type Msg
    = Resize WindowSize
    | SelectLevel LevelId
    | SketchLevelProgress LevelId
    | SketchMsg SketchMsg
    | ExecutionMsg ExecutionMsg
    | LocalStorageMsg LocalStorageMsg


type alias Model =
    { windowSize : WindowSize
    , levelProgresses : List LevelProgress
    , gameState : GameState
    , funnelState : PortFunnels.State
    }
