module Data.SubmitSolutionError exposing (SubmitSolutionError(..), consoleError, expect, fromResponse, toString)

import Data.EndpointResult as EndpointResult
import Extra.Result exposing (getError)
import Http exposing (Expect, Response(..), expectStringResponse)
import Json.Decode as Decode
import Ports.Console


type SubmitSolutionError
    = NetworkError
    | InvalidAccessToken String
    | Duplicate
    | ConflictingId
    | Other String


toString : SubmitSolutionError -> String
toString detailedHttpError =
    case detailedHttpError of
        NetworkError ->
            "Could not connect to server"

        InvalidAccessToken string ->
            string

        Duplicate ->
            "Duplicate"

        ConflictingId ->
            "Conflicting id"

        Other string ->
            string


fromResponse : Response String -> Result SubmitSolutionError ()
fromResponse response =
    case response of
        BadUrl_ string ->
            Err (Other ("Bad url: " ++ string))

        Timeout_ ->
            Err (Other "Request timed out")

        NetworkError_ ->
            Err NetworkError

        BadStatus_ metadata body ->
            case Decode.decodeString EndpointResult.decoder body of
                Ok EndpointResult.ConflictingId ->
                    Err ConflictingId

                Ok EndpointResult.Duplicate ->
                    Err Duplicate

                Ok (EndpointResult.InvalidAccessToken messages) ->
                    Err (InvalidAccessToken (String.join "\n" messages))

                Ok other ->
                    Err (Other (EndpointResult.toString other))

                Err _ ->
                    Err (Other ("Status " ++ String.fromInt metadata.statusCode ++ ": " ++ body))

        GoodStatus_ _ _ ->
            Ok ()


expect : (Maybe SubmitSolutionError -> msg) -> Expect msg
expect toMsg =
    expectStringResponse (getError >> toMsg) fromResponse


consoleError : SubmitSolutionError -> Cmd msg
consoleError error =
    Ports.Console.errorString (toString error)
