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

        _ ->
            el attributes (text (Debug.toString instruction))
