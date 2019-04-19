module Data.LevelId exposing (LevelId, decoder, encode, generator, urlParser)

import Array
import Json.Decode as Decode
import Json.Encode as Encode
import Random
import Url.Parser


type alias LevelId =
    String


urlParser : Url.Parser.Parser (LevelId -> a) a
urlParser =
    Url.Parser.custom "DRAFT ID" (\str -> Just str)



-- RANDOM


generator : Random.Generator LevelId
generator =
    let
        chars =
            --            "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
            "0123456789abcdef"
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



-- JSON


encode : LevelId -> Encode.Value
encode =
    Encode.string


decoder : Decode.Decoder LevelId
decoder =
    Decode.string
