module Page.Blueprints.Model exposing (Modal(..), Model)

import Data.BlueprintId exposing (BlueprintId)


type Modal
    = ConfirmDelete BlueprintId


type alias Model =
    { selectedBlueprintId : Maybe BlueprintId
    , modal : Maybe Modal
    }
