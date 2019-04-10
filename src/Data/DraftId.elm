module Data.DraftId exposing (DraftId(..), decoder, encode, generate, toString, urlParser)

import Array
import Json.Decode as Decode
import Json.Encode as Encode
import Random
import Url.Parser exposing (Parser)


type DraftId
    = DraftId String


urlParser : Parser (DraftId -> a) a
urlParser =
    Url.Parser.custom "DRAFT ID" (\str -> Just (DraftId str))


toString : DraftId -> String
toString (DraftId id) =
    id



-- RANDOM


generate : Random.Generator DraftId
generate =
    let
        chars =
            "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
                |> String.toList
                |> Array.fromList

        getChar i =
            Array.get i chars
                |> Maybe.withDefault '0'

        char =
            Random.int 0 (Array.length chars - 1)
                |> Random.map getChar
    in
    Random.list 16 char
        |> Random.map String.fromList
        |> Random.map DraftId



-- JSON


encode : DraftId -> Encode.Value
encode =
    toString >> Encode.string


decoder : Decode.Decoder DraftId
decoder =
    Decode.map DraftId Decode.string
