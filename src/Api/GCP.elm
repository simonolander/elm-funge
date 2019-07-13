module Api.GCP exposing
    ( authorizedGet
    , get
    , post
    )

import Data.AccessToken as AccessToken exposing (AccessToken)
import Http exposing (Expect, Header)
import Json.Decode as Decode
import Json.Encode as Encode
import Result exposing (Result)
import Url.Builder


get : List String -> List Url.Builder.QueryParameter -> Decode.Decoder a -> (Result Http.Error a -> msg) -> Cmd msg
get path queryParameters decoder toMsg =
    let
        url =
            buildUrl path queryParameters

        expect =
            Http.expectJson toMsg decoder
    in
    Http.get
        { url = url
        , expect = expect
        }


authorizedGet : List String -> List Url.Builder.QueryParameter -> Decode.Decoder a -> (Result Http.Error a -> msg) -> AccessToken -> Cmd msg
authorizedGet path queryParameters decoder toMsg accessToken =
    let
        url =
            buildUrl path queryParameters

        expect =
            Http.expectJson toMsg decoder
    in
    internalAuthorizedGet url accessToken expect


post : AccessToken -> List String -> List Url.Builder.QueryParameter -> Http.Expect msg -> Encode.Value -> Cmd msg
post accessToken path queryParameters expect value =
    authorizedPost
        (buildUrl path queryParameters)
        accessToken
        value
        expect



-- PRIVATE


buildUrl : List String -> List Url.Builder.QueryParameter -> String
buildUrl =
    Url.Builder.crossOrigin gcpPrePath


gcpPrePath : String
gcpPrePath =
    "https://us-central1-luminous-cubist-234816.cloudfunctions.net"


authorizationHeader : AccessToken -> Http.Header
authorizationHeader token =
    Http.header "Authorization" ("Bearer " ++ AccessToken.toString token)


internalAuthorizedGet : String -> AccessToken -> Http.Expect msg -> Cmd msg
internalAuthorizedGet url token expect =
    Http.request
        { method = "GET"
        , headers = [ authorizationHeader token ]
        , url = url
        , body = Http.emptyBody
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }


authorizedPost : String -> AccessToken -> Encode.Value -> Http.Expect msg -> Cmd msg
authorizedPost url token body expect =
    Http.request
        { method = "POST"
        , headers = [ authorizationHeader token ]
        , url = url
        , body = Http.jsonBody body
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }
