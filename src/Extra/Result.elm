module Extra.Result exposing (extractMaybe, getError, split)


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


split : List (Result error value) -> ( List value, List error )
split list =
    case list of
        (Ok value) :: tail ->
            let
                ( values, errors ) =
                    split tail
            in
            ( value :: values, errors )

        (Err error) :: tail ->
            let
                ( values, errors ) =
                    split tail
            in
            ( values, error :: errors )

        [] ->
            ( [], [] )
