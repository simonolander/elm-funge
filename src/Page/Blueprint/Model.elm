module Page.Blueprint.Model exposing (Model, init)

import Array exposing (Array)
import Data.BlueprintId exposing (BlueprintId)
import Data.InstructionTool as InstructionTool exposing (InstructionTool)


type alias Model =
    { blueprintId : BlueprintId
    , loadedBlueprintId : Maybe BlueprintId
    , width : String
    , height : String
    , input : String
    , output : String
    , error : Maybe String
    , instructionTools : Array InstructionTool
    , selectedInstructionToolIndex : Maybe Int
    , enabledInstructionTools : Array ( InstructionTool, Bool )
    }


init : BlueprintId -> Model
init levelId =
    { blueprintId = levelId
    , loadedBlueprintId = Nothing
    , width = ""
    , height = ""
    , input = ""
    , output = ""
    , error = Nothing
    , instructionTools = Array.fromList InstructionTool.all
    , selectedInstructionToolIndex = Nothing
    , enabledInstructionTools = Array.empty
    }
