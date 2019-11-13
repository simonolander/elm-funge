module Page.Execution.Msg exposing (Msg(..))

import Data.Solution exposing (Solution)


type Msg
    = ClickedStep
    | ClickedUndo
    | ClickedRun
    | ClickedFastForward
    | ClickedPause
    | ClickedHome
    | Tick
