module Data.SolutionId exposing (SolutionId, decoder, encode, generator)

import Data.Id as Id exposing (Id)
import Json.Decode as Decode
import Json.Encode as Encode
import Random
import Url.Parser exposing (Parser)


type alias SolutionId =
    Id


urlParser : Parser (SolutionId -> a) a
urlParser =
    Id.urlParser


toString : SolutionId -> String
toString =
    Id.toString



-- RANDOM


generator : Random.Generator SolutionId
generator =
    Id.generator



-- JSON


encode : SolutionId -> Encode.Value
encode =
    Id.encode


decoder : Decode.Decoder SolutionId
decoder =
    Id.decoder
