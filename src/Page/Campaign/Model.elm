module Page.Campaign.Model exposing (Model)

import Data.CampaignId exposing (CampaignId)
import Data.LevelId exposing (LevelId)


type alias Model =
    { campaignId : CampaignId
    , selectedLevelId : Maybe LevelId
    }
