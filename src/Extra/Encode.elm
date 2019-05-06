module Extra.Encode exposing (tuple)

import Json.Encode exposing (..)


tuple : (a -> Value) -> (b -> Value) -> ( a, b ) -> Value
tuple encodeA encodeB ( a, b ) =
    Json.Encode.list identity [ encodeA a, encodeB b ]
