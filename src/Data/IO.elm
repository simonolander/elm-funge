module Data.IO exposing (IO, decoder, encode)

import Data.Input exposing (Input)
import Data.Output exposing (Output)
import Json.Decode as Decode
    exposing
        ( Decoder
        , andThen
        , field
        , succeed
        )
import Json.Encode
    exposing
        ( Value
        , int
        , list
        , object
        )


type alias IO =
    { input : Input
    , output : Output
    }



-- JSON


encode : IO -> Value
encode io =
    object
        [ ( "input", list int io.input )
        , ( "output", list int io.output )
        ]


decoder : Decoder IO
decoder =
    field "input" (Decode.list Decode.int)
        |> andThen
            (\input ->
                field "output" (Decode.list Decode.int)
                    |> andThen
                        (\output ->
                            succeed
                                { input = input
                                , output = output
                                }
                        )
            )
