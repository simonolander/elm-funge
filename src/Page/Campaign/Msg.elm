module Page.Campaign.Msg exposing (Msg(..))

import Data.Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.LevelId exposing (LevelId)


type Msg
    = ClickedLevel LevelId
    | ClickedOpenDraft DraftId
    | ClickedGenerateDraft
    | GeneratedDraft Draft
