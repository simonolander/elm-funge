module Page.Blueprints.Msg exposing (Msg(..))

import Data.Blueprint exposing (Blueprint)
import Data.BlueprintId exposing (BlueprintId)


type Msg
    = GeneratedBlueprint Blueprint
    | BlueprintNameChanged String
    | BlueprintDescriptionChanged String
    | ClickedBlueprint BlueprintId
    | ClickedNewBlueprint
    | ClickedDeleteBlueprint BlueprintId
    | ClickedConfirmDeleteBlueprint
    | ClickedCancelDeleteBlueprint
