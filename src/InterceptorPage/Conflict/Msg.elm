module InterceptorPage.Conflict.Msg exposing (Msg(..))

import Data.BlueprintId exposing (BlueprintId)
import Data.DraftId exposing (DraftId)


type Msg
    = ClickedKeepLocalDraft DraftId
    | ClickedKeepServerDraft DraftId
    | ClickedKeepLocalBlueprint BlueprintId
    | ClickedKeepServerBlueprint BlueprintId
