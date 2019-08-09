module Data.SaveError exposing (SaveError(..), consoleError, expect, toString)

import Extra.Result exposing (getError)
import Http exposing (Expect, Response(..), expectStringResponse)
import Ports.Console


type SaveError
    = NetworkError
    | InvalidAccessToken String
    | Other String


toString : SaveError -> String
toString detailedHttpError =
    case detailedHttpError of
        NetworkError ->
            "Could not connect to server"

        InvalidAccessToken string ->
            string

        Other string ->
            string


fromResponse : Response String -> Result SaveError ()
fromResponse response =
    case response of
        BadUrl_ string ->
            Err (Other ("Bad url: " ++ string))

        Timeout_ ->
            Err (Other "Request timed out")

        NetworkError_ ->
            Err NetworkError

        BadStatus_ metadata body ->
            case metadata.statusCode of
                403 ->
                    Err (InvalidAccessToken body)

                statusCode ->
                    Err (Other ("Status " ++ String.fromInt statusCode ++ ": " ++ body))

        GoodStatus_ _ _ ->
            Ok ()


expect : (Maybe SaveError -> msg) -> Expect msg
expect toMsg =
    expectStringResponse (getError >> toMsg) fromResponse


consoleError : SaveError -> Cmd msg
consoleError error =
    Ports.Console.errorString (toString error)
