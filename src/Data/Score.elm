module Data.Score exposing (Score, decoder, encode)

import Json.Decode as Decode
import Json.Encode as Encode


type alias Score =
    { numberOfSteps : Int
    , numberOfInstructions : Int
    }



-- JSON


encode : Score -> Encode.Value
encode score =
    Encode.object
        [ ( "numberOfSteps", Encode.int score.numberOfSteps )
        , ( "numberOfInstructions", Encode.int score.numberOfInstructions )
        ]


decoder : Decode.Decoder Score
decoder =
    Decode.field "numberOfSteps" Decode.int
        |> Decode.andThen
            (\numberOfSteps ->
                Decode.field "numberOfInstructions" Decode.int
                    |> Decode.andThen
                        (\numberOfInstructions ->
                            Decode.succeed
                                { numberOfSteps = numberOfSteps
                                , numberOfInstructions = numberOfInstructions
                                }
                        )
            )
