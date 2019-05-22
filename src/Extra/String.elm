module Extra.String exposing (fromHttpError)

import Http


fromHttpError : Http.Error -> String
fromHttpError error =
    case error of
        Http.BadUrl string ->
            "Bad url: " ++ string

        Http.Timeout ->
            "The request timed out"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus int ->
            "Bad status: " ++ String.fromInt int

        Http.BadBody string ->
            string
