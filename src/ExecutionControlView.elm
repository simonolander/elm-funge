module ExecutionControlView exposing (ExecutionControlInstruction(..), view)

import Element exposing (..)


type ExecutionControlInstruction
    = Step
    | Undo
    | Play
    | FastForward
    | Pause


view : List (Attribute msg) -> ExecutionControlInstruction -> Element msg
view attributes instruction =
    case instruction of
        Step ->
            image attributes
                { src = "assets/execution-control-images/step.svg"
                , description = "Step"
                }

        Undo ->
            image attributes
                { src = "assets/execution-control-images/undo.svg"
                , description = "Step Back"
                }

        Play ->
            image attributes
                { src = "assets/execution-control-images/play.svg"
                , description = "Play"
                }

        FastForward ->
            image attributes
                { src = "assets/execution-control-images/fast-forward.svg"
                , description = "Fast Forward"
                }

        Pause ->
            image attributes
                { src = "assets/execution-control-images/pause.svg"
                , description = "Pause"
                }
