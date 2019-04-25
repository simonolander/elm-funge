module Data.CampaignId exposing (CampaignId, blueprints, decoder, encode, standard, urlParser)

import Json.Decode as Decode
import Json.Encode as Encode
import Url.Parser


type alias CampaignId =
    String


blueprints : CampaignId
blueprints =
    "blueprints"


standard : CampaignId
standard =
    "standard"



-- URL


urlParser : Url.Parser.Parser (CampaignId -> a) a
urlParser =
    Url.Parser.custom "CAMPAIGN ID" (\str -> Just str)



-- JSON


encode : CampaignId -> Encode.Value
encode =
    Encode.string


decoder : Decode.Decoder CampaignId
decoder =
    Decode.string
