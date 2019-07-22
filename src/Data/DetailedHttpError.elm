module Data.DetailedHttpError exposing (DetailedHttpError(..), toString)


type DetailedHttpError
    = BadUrl String
    | Timeout
    | NetworkError
    | NotFound
    | InvalidAccessToken
    | BadStatus Int
    | BadBody Int String


toString : DetailedHttpError -> String
toString detailedHttpError =
    case detailedHttpError of
        BadUrl url ->
            "Bad url: " ++ url

        Timeout ->
            "Timeout"

        NetworkError ->
            "NetworkError"

        NotFound ->
            "NotFound"

        InvalidAccessToken ->
            "InvalidAccessToken"

        BadStatus int ->
            "BadStatus int"

        BadBody int string ->
            "BadBody int string"
