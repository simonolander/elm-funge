module Extra.Result exposing (extractMaybe, getError)


extractMaybe : Result error (Maybe value) -> Maybe (Result error value)
extractMaybe result =
    case result of
        Ok maybeValue ->
            Maybe.map Result.Ok maybeValue

        Err error ->
            Just (Result.Err error)


getError : Result error value -> Maybe error
getError result =
    case result of
        Ok _ ->
            Nothing

        Err error ->
            Just error
