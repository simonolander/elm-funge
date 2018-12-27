module InstructionToolView exposing (view)

import Element exposing (..)
import InstructionView
import Model exposing (..)


view : List (Attribute msg) -> InstructionTool -> Element msg
view attributes instructionTool =
    case instructionTool of
        JustInstruction instruction ->
            InstructionView.view attributes instruction

        ChangeAnyDirection direction ->
            image attributes
                { src = "assets/instruction-images/four-filled-arrows.svg"
                , description = "Change direction"
                }

        BranchAnyDirection trueDirection falseDirection ->
            image attributes
                { src = "assets/instruction-images/four-half-filled-arrows.svg"
                , description = "Branch"
                }
