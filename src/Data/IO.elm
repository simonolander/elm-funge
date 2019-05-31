module Data.IO exposing (IO, constraints, decoder, encode, withInput, withOutput)

import Data.Input exposing (Input)
import Data.Int16 as Int16
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
        [ ( "input", Encode.list Int16.encode io.input )
        , ( "output", Encode.list Int16.encode io.output )
        ]


decoder : Decode.Decoder IO
decoder =
    Decode.field "input" (Decode.list Int16.decoder)
        |> Decode.andThen
            (\input ->
                Decode.field "output" (Decode.list Int16.decoder)
                    |> Decode.andThen
                        (\output ->
                            Decode.succeed
                                { input = input
                                , output = output
                                }
                        )
            )
