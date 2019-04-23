module Data.SolutionId exposing (SolutionId, decoder, encode, generator)

import Array
import Json.Decode as Decode
import Json.Encode as Encode
import Random


type alias SolutionId =
    String



-- RANDOM


generator : Random.Generator SolutionId
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


encode : SolutionId -> Encode.Value
encode =
    Encode.string


decoder : Decode.Decoder SolutionId
decoder =
    Decode.string
