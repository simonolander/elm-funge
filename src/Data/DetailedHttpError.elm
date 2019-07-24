module Data.DetailedHttpError exposing (DetailedHttpError(..), consoleError, toString)

import Ports.Console


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

        BadStatus status ->
            "BadStatus: " ++ String.fromInt status

        BadBody int error ->
            "BadBody: " ++ error


consoleError : DetailedHttpError -> Cmd msg
consoleError error =
    Ports.Console.errorString (toString error)
