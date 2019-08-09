module Api.GCP exposing
    ( RequestBuilder
    , delete
    , get
    , post
    , put
    , request
    , withAccessToken
    , withBody
    , withPath
    , withQueryParameters
    , withTimeout
    , withTracker
    )

import Data.AccessToken as AccessToken exposing (AccessToken)
import Http exposing (Expect, Header, Response)
import Json.Encode as Encode
import Maybe.Extra
import Url.Builder


type alias RequestBuilder =
    { method : String
    , path : List String
    , queryParameters : List Url.Builder.QueryParameter
    , accessToken : Maybe AccessToken
    , body : Maybe Encode.Value
    , timeout : Maybe Float
    , tracker : Maybe String
    }


get : RequestBuilder
get =
    { method = "GET"
    , path = []
    , queryParameters = []
    , accessToken = Nothing
    , body = Nothing
    , timeout = Nothing
    , tracker = Nothing
    }


post : RequestBuilder
post =
    { get | method = "POST" }


put : RequestBuilder
put =
    { get | method = "PUT" }


delete : RequestBuilder
delete =
    { get | method = "DELETE" }


withPath : List String -> RequestBuilder -> RequestBuilder
withPath path builder =
    { builder | path = path }


withQueryParameters : List Url.Builder.QueryParameter -> RequestBuilder -> RequestBuilder
withQueryParameters queryParameters builder =
    { builder | queryParameters = queryParameters }


withAccessToken : AccessToken -> RequestBuilder -> RequestBuilder
withAccessToken accessToken builder =
    { builder | accessToken = Just accessToken }


withBody : Encode.Value -> RequestBuilder -> RequestBuilder
withBody body builder =
    { builder | body = Just body }


withTimeout : Float -> RequestBuilder -> RequestBuilder
withTimeout timeout builder =
    { builder | timeout = Just timeout }


withTracker : String -> RequestBuilder -> RequestBuilder
withTracker tracker builder =
    { builder | tracker = Just tracker }


request : Expect msg -> RequestBuilder -> Cmd msg
request expect builder =
    let
        headers =
            let
                authorizationHeader =
                    case builder.accessToken of
                        Just accessToken ->
                            Just (Http.header "Authorization" ("Bearer " ++ AccessToken.toString accessToken))

                        Nothing ->
                            Nothing
            in
            Maybe.Extra.values
                [ authorizationHeader ]

        url =
            Url.Builder.crossOrigin
                "https://us-central1-luminous-cubist-234816.cloudfunctions.net"
                builder.path
                builder.queryParameters

        body =
            builder.body
                |> Maybe.map Http.jsonBody
                |> Maybe.withDefault Http.emptyBody
    in
    Http.request
        { method = builder.method
        , headers = headers
        , url = url
        , body = body
        , timeout = builder.timeout
        , tracker = builder.tracker
        , expect = expect
        }
