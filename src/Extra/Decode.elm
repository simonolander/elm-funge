module Extra.Decode exposing (set, tuple)

import Json.Decode exposing (..)
import Set


tuple : Decoder a -> Decoder b -> Decoder ( a, b )
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


set : Decoder comparable -> Decoder (Set.Set comparable)
set decoder =
    map Set.fromList (list decoder)
