module Extra.Decode exposing (tuple)

import Json.Decode exposing (..)


tuple : Json.Decode.Decoder a -> Json.Decode.Decoder b -> Json.Decode.Decoder ( a, b )
tuple aDecoder bDecoder =
    map List.length (list value)
        |> andThen
            (\length ->
                case length of
                    2 ->
                        index 0 aDecoder
                            |> andThen
                                (\a ->
                                    index 1 bDecoder
                                        |> andThen (Tuple.pair a >> succeed)
                                )

                    _ ->
                        fail ("Invalid length: expected 2 but was " ++ String.fromInt length)
            )
