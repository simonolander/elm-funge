module Page.Blueprints.Msg exposing (Msg(..))

import Data.Blueprint exposing (Blueprint)
import Data.BlueprintId exposing (BlueprintId)


type Msg
    = BlueprintGenerated Blueprint
    | SelectedBlueprintId BlueprintId
    | BlueprintNameChanged String
    | BlueprintDescriptionChanged String
    | ClickedNewBlueprint
    | ClickedDeleteBlueprint BlueprintId
    | ClickedConfirmDeleteBlueprint
    | ClickedCancelDeleteBlueprint
