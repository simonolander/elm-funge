module InstructionView exposing (view)

import Element exposing (..)
import Model exposing (..)


view : List (Attribute msg) -> Instruction -> Element msg
view attributes instruction =
    case instruction of
        NoOp ->
            el attributes none

        ChangeDirection Left ->
            image attributes
                { src = "assets/instruction-images/change-direction-left.svg"
                , description = ""
                }

        ChangeDirection Up ->
            image attributes
                { src = "assets/instruction-images/change-direction-up.svg"
                , description = ""
                }

        ChangeDirection Right ->
            image attributes
                { src = "assets/instruction-images/change-direction-right.svg"
                , description = ""
                }

        ChangeDirection Down ->
            image attributes
                { src = "assets/instruction-images/change-direction-down.svg"
                , description = ""
                }

        Branch Left Left ->
            image attributes
                { src = "assets/instruction-images/branch-left-left.svg"
                , description = ""
                }

        Branch Left Up ->
            image attributes
                { src = "assets/instruction-images/branch-left-up.svg"
                , description = ""
                }

        Branch Left Right ->
            image attributes
                { src = "assets/instruction-images/branch-left-right.svg"
                , description = ""
                }

        Branch Left Down ->
            image attributes
                { src = "assets/instruction-images/branch-left-down.svg"
                , description = ""
                }

        Branch Up Left ->
            image attributes
                { src = "assets/instruction-images/branch-up-left.svg"
                , description = ""
                }

        Branch Up Up ->
            image attributes
                { src = "assets/instruction-images/branch-up-up.svg"
                , description = ""
                }

        Branch Up Right ->
            image attributes
                { src = "assets/instruction-images/branch-up-right.svg"
                , description = ""
                }

        Branch Up Down ->
            image attributes
                { src = "assets/instruction-images/branch-up-down.svg"
                , description = ""
                }

        Branch Right Left ->
            image attributes
                { src = "assets/instruction-images/branch-right-left.svg"
                , description = ""
                }

        Branch Right Up ->
            image attributes
                { src = "assets/instruction-images/branch-right-up.svg"
                , description = ""
                }

        Branch Right Right ->
            image attributes
                { src = "assets/instruction-images/branch-right-right.svg"
                , description = ""
                }

        Branch Right Down ->
            image attributes
                { src = "assets/instruction-images/branch-right-down.svg"
                , description = ""
                }

        Branch Down Left ->
            image attributes
                { src = "assets/instruction-images/branch-down-left.svg"
                , description = ""
                }

        Branch Down Up ->
            image attributes
                { src = "assets/instruction-images/branch-down-up.svg"
                , description = ""
                }

        Branch Down Right ->
            image attributes
                { src = "assets/instruction-images/branch-down-right.svg"
                , description = ""
                }

        Branch Down Down ->
            image attributes
                { src = "assets/instruction-images/branch-down-down.svg"
                , description = ""
                }

        Add ->
            image attributes
                { src = "assets/instruction-images/add.svg"
                , description = ""
                }

        Subtract ->
            image attributes
                { src = "assets/instruction-images/subtract.svg"
                , description = ""
                }

        Read ->
            image attributes
                { src = "assets/instruction-images/read.svg"
                , description = ""
                }

        Print ->
            image attributes
                { src = "assets/instruction-images/print.svg"
                , description = ""
                }

        Duplicate ->
            image attributes
                { src = "assets/instruction-images/duplicate.svg"
                , description = ""
                }

        Increment ->
            image attributes
                { src = "assets/instruction-images/increment.svg"
                , description = ""
                }

        Decrement ->
            image attributes
                { src = "assets/instruction-images/decrement.svg"
                , description = ""
                }

        Terminate ->
            image attributes
                { src = "assets/instruction-images/terminate.svg"
                , description = ""
                }

        _ ->
            el attributes (text (Debug.toString instruction))
