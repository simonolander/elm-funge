module Data.InstructionToolbox exposing (InstructionToolbox, getSelected, set)

import Array exposing (Array)
import Data.InstructionTool exposing (InstructionTool)


type alias InstructionToolbox =
    { instructionTools : Array InstructionTool
    , selectedIndex : Maybe Int
    }


getSelected : InstructionToolbox -> Maybe InstructionTool
getSelected toolbox =
    Maybe.andThen
        (\index -> Array.get index toolbox.instructionTools)
        toolbox.selectedIndex


set : Int -> InstructionTool -> InstructionToolbox -> InstructionToolbox
set index tool toolbox =
    { toolbox
        | instructionTools =
            Array.set
                index
                tool
                toolbox.instructionTools
    }
