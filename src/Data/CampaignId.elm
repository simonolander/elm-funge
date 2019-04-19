module Data.CampaignId exposing (CampaignId, blueprints, decoder, encode, standard)

import Json.Decode as Decode
import Json.Encode as Encode


type alias CampaignId =
    String


blueprints : CampaignId
blueprints =
    "blueprints"


standard : CampaignId
standard =
    "standard"



-- JSON


encode : CampaignId -> Encode.Value
encode =
    Encode.string


decoder : Decode.Decoder CampaignId
decoder =
    Decode.string
