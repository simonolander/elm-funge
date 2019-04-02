module JsonUtils exposing
    ( boardDecoder
    , directionDecoder
    , encodeBoard
    , encodeDirection
    , encodeInstruction
    , encodeLevel
    , fromString
    , instructionDecoder
    , levelDecoder
    , toString
    )

import Array
import Json.Decode as Decode exposing (Decoder, andThen, fail, field, succeed)
import Json.Encode exposing (..)


toString : Value -> String
toString =
    encode 2


fromString : Decoder a -> String -> Result Decode.Error a
fromString =
    Decode.decodeString
