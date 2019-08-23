module Extra.Maybe exposing (cons, update)

import Dict exposing (Dict)


cons : Maybe a -> List a -> List a
cons =
    Maybe.map (::) >> Maybe.withDefault identity


update : Maybe comparable -> (Maybe v -> Maybe v) -> Dict comparable v -> Dict comparable v
update maybe function =
    case maybe of
        Just key ->
            Dict.update key function

        Nothing ->
            identity
