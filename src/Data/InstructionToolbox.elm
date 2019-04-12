module Data.InstructionToolbox exposing (InstructionToolbox, getSelected, init, set)

import Array exposing (Array)
import Basics.Extra exposing (flip)
import Data.InstructionTool exposing (InstructionTool)


type alias InstructionToolbox =
    { instructionTools : Array InstructionTool
    , selectedIndex : Maybe Int
    }


getSelected : InstructionToolbox -> Maybe InstructionTool
getSelected toolbox =
    Maybe.andThen (flip Array.get toolbox.instructionTools) toolbox.selectedIndex


set : Int -> InstructionTool -> InstructionToolbox -> InstructionToolbox
set index tool toolbox =
    { toolbox
        | instructionTools =
            Array.set
                index
                tool
                toolbox.instructionTools
    }


init : List InstructionTool -> InstructionToolbox
init instructionToolList =
    { instructionTools = Array.fromList instructionToolList
    , selectedIndex = Nothing
    }
