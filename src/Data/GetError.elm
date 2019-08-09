module Data.GetError exposing
    ( GetError(..)
    , consoleError
    , expect
    , expectMaybe
    , toString
    )

import Http exposing (Expect, Response(..), expectStringResponse)
import Json.Decode exposing (Decoder, decodeString, errorToString)
import Ports.Console


type GetError
    = NetworkError
    | InvalidAccessToken String
    | Other String


toString : GetError -> String
toString detailedHttpError =
    case detailedHttpError of
        NetworkError ->
            "Could not connect to server"

        InvalidAccessToken string ->
            string

        Other string ->
            string


consoleError : GetError -> Cmd msg
consoleError error =
    Ports.Console.errorString (toString error)


maybeResult : Decoder a -> Response String -> Result GetError (Maybe a)
maybeResult decoder response =
    case response of
        BadUrl_ url ->
            Err (Other ("Bad url: " ++ url))

        Timeout_ ->
            Err NetworkError

        NetworkError_ ->
            Err NetworkError

        BadStatus_ metadata body ->
            case metadata.statusCode of
                404 ->
                    Ok Nothing

                403 ->
                    Err (InvalidAccessToken body)

                statusCode ->
                    Err (Other ("Status " ++ String.fromInt statusCode ++ ": " ++ body))

        GoodStatus_ _ body ->
            case decodeString decoder body of
                Ok value ->
                    Ok (Just value)

                Err err ->
                    Err (Other ("Bad response: " ++ errorToString err))


result : Decoder a -> Response String -> Result GetError a
result decoder response =
    case response of
        BadUrl_ url ->
            Err (Other ("Bad url: " ++ url))

        Timeout_ ->
            Err NetworkError

        NetworkError_ ->
            Err NetworkError

        BadStatus_ metadata body ->
            case metadata.statusCode of
                403 ->
                    Err (InvalidAccessToken body)

                statusCode ->
                    Err (Other ("Status " ++ String.fromInt statusCode ++ ": " ++ body))

        GoodStatus_ metadata body ->
            case decodeString decoder body of
                Ok value ->
                    Ok value

                Err err ->
                    Err (Other ("Bad response: " ++ errorToString err))


expect : Decoder a -> (Result GetError a -> msg) -> Expect msg
expect decoder toMsg =
    expectStringResponse toMsg (result decoder)


expectMaybe : Decoder a -> (Result GetError (Maybe a) -> msg) -> Expect msg
expectMaybe decoder toMsg =
    expectStringResponse toMsg (maybeResult decoder)
