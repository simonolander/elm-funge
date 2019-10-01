module Data.Id exposing (Id, decoder, encode, generator, toString, urlParser)

import Array
import Json.Decode as Decode
import Json.Encode as Encode
import Random
import Url.Parser exposing (Parser)


type alias Id =
    String


urlParser : Parser (Id -> a) a
urlParser =
    Url.Parser.custom "ID" (\str -> Just str)


toString : Id -> String
toString =
    identity



-- RANDOM


generator : Random.Generator Id
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


encode : Id -> Encode.Value
encode =
    Encode.string


decoder : Decode.Decoder Id
decoder =
    Decode.string
