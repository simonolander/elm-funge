module Page.Campaign.Model exposing (Model, init)

import Data.CampaignId exposing (CampaignId)
import Data.LevelId exposing (LevelId)


type alias Model =
    { campaignId : CampaignId
    , selectedLevelId : Maybe LevelId
    }


init : CampaignId -> Maybe LevelId -> Model
init campaignId selectedLevelId =
    { campaignId = campaignId
    , selectedLevelId = selectedLevelId
    }
