module Api.GCP exposing
    ( RequestBuilder
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
import Data.DetailedHttpError as DetailedHttpError exposing (DetailedHttpError)
import Http exposing (Expect, Header)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Url.Builder


type alias RequestBuilder response =
    { method : String
    , path : List String
    , queryParameters : List Url.Builder.QueryParameter
    , accessToken : Maybe AccessToken
    , body : Maybe Encode.Value
    , decoder : Decode.Decoder response
    , timeout : Maybe Float
    , tracker : Maybe String
    }


get : Decode.Decoder response -> RequestBuilder response
get decoder =
    { method = "GET"
    , path = []
    , queryParameters = []
    , accessToken = Nothing
    , body = Nothing
    , decoder = decoder
    , timeout = Nothing
    , tracker = Nothing
    }


post : Decode.Decoder response -> RequestBuilder response
post decoder =
    let
        empty =
            get decoder
    in
    { empty | method = "POST" }


put : Decode.Decoder response -> RequestBuilder response
put decoder =
    let
        empty =
            get decoder
    in
    { empty | method = "put" }


withPath : List String -> RequestBuilder response -> RequestBuilder response
withPath path builder =
    { builder | path = path }


withQueryParameters : List Url.Builder.QueryParameter -> RequestBuilder response -> RequestBuilder response
withQueryParameters queryParameters builder =
    { builder | queryParameters = queryParameters }


withAccessToken : AccessToken -> RequestBuilder response -> RequestBuilder response
withAccessToken accessToken builder =
    { builder | accessToken = Just accessToken }


withBody : Encode.Value -> RequestBuilder response -> RequestBuilder response
withBody body builder =
    { builder | body = Just body }


withTimeout : Float -> RequestBuilder response -> RequestBuilder response
withTimeout timeout builder =
    { builder | timeout = Just timeout }


withTracker : String -> RequestBuilder response -> RequestBuilder response
withTracker tracker builder =
    { builder | tracker = Just tracker }


request : (Result DetailedHttpError response -> msg) -> RequestBuilder response -> Cmd msg
request toMsg builder =
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

        expect =
            expectDetailedJson toMsg builder.decoder
    in
    Http.request
        { method = builder.method
        , headers = headers
        , url = url
        , body = body
        , expect = expect
        , timeout = builder.timeout
        , tracker = builder.tracker
        }



-- PRIVATE


expectDetailedJson : (Result DetailedHttpError a -> msg) -> Decode.Decoder a -> Http.Expect msg
expectDetailedJson toMsg decoder =
    let
        toResult response =
            case response of
                Http.BadUrl_ url ->
                    Err (DetailedHttpError.BadUrl url)

                Http.Timeout_ ->
                    Err DetailedHttpError.Timeout

                Http.NetworkError_ ->
                    Err DetailedHttpError.NetworkError

                Http.BadStatus_ metadata body ->
                    case metadata.statusCode of
                        404 ->
                            Err DetailedHttpError.NotFound

                        403 ->
                            Err DetailedHttpError.InvalidAccessToken

                        _ ->
                            Err (DetailedHttpError.BadStatus metadata.statusCode)

                Http.GoodStatus_ metadata body ->
                    case Decode.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (DetailedHttpError.BadBody metadata.statusCode (Decode.errorToString err))
    in
    Http.expectStringResponse toMsg toResult
