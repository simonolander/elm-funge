module Extra.Encode exposing (set, tuple)

import Json.Encode exposing (..)
import Set


tuple : (a -> Value) -> (b -> Value) -> ( a, b ) -> Value
tuple encodeA encodeB ( a, b ) =
    list identity [ encodeA a, encodeB b ]


set : (a -> Value) -> Set.Set a -> Value
set encoder s =
    list encoder (Set.toList s)
