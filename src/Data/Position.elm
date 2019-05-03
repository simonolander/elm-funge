module Data.Position exposing (Position, decoder, encode)

import Json.Decode as Decode
import Json.Encode as Encode


type alias Position =
    { x : Int
    , y : Int
    }



-- JSON


encode : Position -> Encode.Value
encode position =
    Encode.object
        [ ( "x", Encode.int position.x )
        , ( "y", Encode.int position.y )
        ]


decoder : Decode.Decoder Position
decoder =
    Decode.field "x" Decode.int
        |> Decode.andThen
            (\x ->
                Decode.field "y" Decode.int
                    |> Decode.andThen
                        (\y ->
                            Decode.succeed
                                { x = x
                                , y = y
                                }
                        )
            )
