module Data.LevelId exposing (LevelId, decoder, encode)

import Json.Decode as Decode
import Json.Encode as Encode


type alias LevelId =
    String



-- JSON


encode : LevelId -> Encode.Value
encode =
    Encode.string


decoder : Decode.Decoder LevelId
decoder =
    Decode.string
