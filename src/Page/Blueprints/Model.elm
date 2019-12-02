module Page.Blueprints.Model exposing (Modal(..), Model, init)

import Data.BlueprintId exposing (BlueprintId)


type Modal
    = ConfirmDelete BlueprintId


type alias Model =
    { selectedBlueprintId : Maybe BlueprintId
    , modal : Maybe Modal
    }


init : Maybe BlueprintId -> Model
init selectedBlueprintId =
    { selectedBlueprintId = selectedBlueprintId
    , modal = Nothing
    }
