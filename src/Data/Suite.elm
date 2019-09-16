module Data.Suite exposing (Suite, constraints, decoder, empty, encode, withInput, withOutput)

import Data.Input exposing (Input)
import Data.Int16 as Int16
import Data.Output exposing (Output)
import Json.Decode as Decode
import Json.Encode as Encode


type alias Suite =
    { input : Input
    , output : Output
    }


empty : Suite
empty =
    { input = [], output = [] }


constraints =
    { max = (2 ^ 16) - 1
    , min = -(2 ^ 16)
    }


withInput : Input -> Suite -> Suite
withInput input suite =
    { suite | input = input }


withOutput : Output -> Suite -> Suite
withOutput output suite =
    { suite | output = output }



-- JSON


encode : Suite -> Encode.Value
encode suite =
    Encode.object
        [ ( "input", Encode.list Int16.encode suite.input )
        , ( "output", Encode.list Int16.encode suite.output )
        ]


decoder : Decode.Decoder Suite
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
