module Data.BlueprintId exposing (BlueprintId, decoder, encode, generator, urlParser)

import Data.Id as Id exposing (Id)
import Json.Decode as Decode
import Json.Encode as Encode
import Random
import Url.Parser exposing (Parser)


type alias BlueprintId =
    Id


urlParser : Parser (BlueprintId -> a) a
urlParser =
    Id.urlParser


toString : BlueprintId -> String
toString =
    Id.toString



-- RANDOM


generator : Random.Generator BlueprintId
generator =
    Id.generator



-- JSON


encode : BlueprintId -> Encode.Value
encode =
    Id.encode


decoder : Decode.Decoder BlueprintId
decoder =
    Id.decoder
