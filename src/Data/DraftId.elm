module Data.DraftId exposing (DraftId, decoder, encode, generator, toString, urlParser)

import Data.Id as Id exposing (Id)
import Json.Decode as Decode
import Json.Encode as Encode
import Random
import Url.Parser exposing (Parser)


type alias DraftId =
    Id


urlParser : Parser (DraftId -> a) a
urlParser =
    Id.urlParser


toString : DraftId -> String
toString =
    Id.toString



-- RANDOM


generator : Random.Generator DraftId
generator =
    Id.generator



-- JSON


encode : DraftId -> Encode.Value
encode =
    Id.encode


decoder : Decode.Decoder DraftId
decoder =
    Id.decoder
