module Data.LevelId exposing (LevelId, decoder, encode, urlParser)

import Json.Decode as Decode
import Json.Encode as Encode
import Url.Parser


type alias LevelId =
    String


urlParser : Url.Parser.Parser (LevelId -> a) a
urlParser =
    Url.Parser.custom "DRAFT ID" (\str -> Just str)



-- JSON


encode : LevelId -> Encode.Value
encode =
    Encode.string


decoder : Decode.Decoder LevelId
decoder =
    Decode.string
