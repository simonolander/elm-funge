module InstructionToolView exposing (description, view)

import Element exposing (..)
import InstructionView
import Model exposing (..)


description : InstructionTool -> String
description instructionTool =
    case instructionTool of
        JustInstruction instruction ->
            InstructionView.description instruction

        ChangeAnyDirection direction ->
            "Change direction"

        BranchAnyDirection trueDirection falseDirection ->
            "Branch direction (if 0 go black, else go white)"


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
