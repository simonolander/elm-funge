module Model exposing (AlphaDisclaimerModel, ApiMsg(..), AuthorizationToken, Board, BoardSketch, BrowsingLevelsMessage(..), Direction(..), Execution, ExecutionMsg(..), ExecutionState(..), ExecutionStep, GameState(..), IO, Input, Instruction(..), InstructionPointer, InstructionTool(..), InstructionToolbox, Level, LevelId, LevelProgress, LocalStorageMsg(..), Model, Msg(..), NavigationMessage(..), Output, Position, SketchMsg(..), SketchingState(..), Stack, WindowSize)

import Http
import PortFunnel.LocalStorage as LocalStorage
import PortFunnels
import RemoteData exposing (WebData)


type GameState
    = BrowsingLevels
        { selectedLevelId : Maybe LevelId
        , levels : WebData (List LevelProgress)
        , token : Maybe String
        }
    | Sketching
        { levelProgress : LevelProgress
        , state : SketchingState
        , token : Maybe String
        }
    | Executing
        { execution : Execution
        , state : ExecutionState
        , token : Maybe String
        }
    | AlphaDisclaimer AlphaDisclaimerState


type BrowsingLevelsMessage
    = SelectLevel LevelId


type NavigationMessage
    = GoToBrowsingLevels (Maybe LevelId)
    | GoToSketching LevelId
    | GoToExecuting LevelId


type ExecutionMsg
    = ExecutionStepOne
    | ExecutionUndo
    | ExecutionRun
    | ExecutionFastForward
    | ExecutionPause


type LocalStorageMsg
    = LocalStorageProcess LocalStorage.Value
    | Clear


type ApiMsg
    = GetLevelsMsg (Result.Result Http.Error LevelProgress)


type Msg
    = BrowsingLevelsMessage BrowsingLevelsMessage
    | SketchMsg SketchMsg
    | ExecutionMsg ExecutionMsg
    | LocalStorageMsg LocalStorageMsg
    | NavigationMessage NavigationMessage
    | ApiMsg ApiMsg


type alias Model =
    { windowSize : WindowSize
    , gameState : GameState
    , funnelState : PortFunnels.State
    }
