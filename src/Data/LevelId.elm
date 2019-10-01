module Data.LevelId exposing (LevelId, decoder, encode, generator, urlParser)

import Data.Id as Id exposing (Id)
import Json.Decode as Decode
import Json.Encode as Encode
import Random
import Url.Parser exposing (Parser)


type alias LevelId =
    Id


urlParser : Parser (LevelId -> a) a
urlParser =
    Id.urlParser


toString : LevelId -> String
toString =
    Id.toString



-- RANDOM


generator : Random.Generator LevelId
generator =
    Id.generator



-- JSON


encode : LevelId -> Encode.Value
encode =
    Id.encode


decoder : Decode.Decoder LevelId
decoder =
    Id.decoder
