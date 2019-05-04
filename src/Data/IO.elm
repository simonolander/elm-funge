module Data.IO exposing (IO, constraints, decoder, encode, withInput, withOutput)

import Data.Input exposing (Input)
import Data.Output exposing (Output)
import Json.Decode as Decode
import Json.Encode as Encode


type alias IO =
    { input : Input
    , output : Output
    }


constraints =
    { max = (2 ^ 16) - 1
    , min = -(2 ^ 16)
    }


withInput : Input -> IO -> IO
withInput input io =
    { io | input = input }


withOutput : Output -> IO -> IO
withOutput output io =
    { io | output = output }



-- JSON


encode : IO -> Encode.Value
encode io =
    Encode.object
        [ ( "input", Encode.list Encode.int io.input )
        , ( "output", Encode.list Encode.int io.output )
        ]


decoder : Decode.Decoder IO
decoder =
    Decode.field "input" (Decode.list Decode.int)
        |> Decode.andThen
            (\input ->
                Decode.field "output" (Decode.list Decode.int)
                    |> Decode.andThen
                        (\output ->
                            Decode.succeed
                                { input = input
                                , output = output
                                }
                        )
            )
