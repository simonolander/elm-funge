module Api.Auth0 exposing (LoginResponse, getUserInfo, login, loginResponseFromUrl, logout)

import Dict
import Http
import Maybe.Extra
import Route exposing (Route)
import Url exposing (Url)
import Url.Builder



-- PRIVATE CONSTANTS


prePath =
    "https://dev-253xzd4c.eu.auth0.com"


clientId =
    "QnLYsQ4CDaqcGViA43t90z6lo7L77JK6"


responseType =
    "token"


redirectUri =
    "http://localhost:3000"


returnTo =
    redirectUri


scope =
    String.join " "
        [ "openid"
        , "profile"
        ]


audience =
    "https://us-central1-luminous-cubist-234816.cloudfunctions.net"



-- MODEL


type alias LoginResponse =
    { accessToken : String
    , expiresIn : Int
    , tokenType : String
    , route : Route
    }


loginResponseFromUrl : Url -> Maybe LoginResponse
loginResponseFromUrl url =
    let
        queryParameters =
            url.fragment
                |> Maybe.withDefault ""
                |> String.split "&"
                |> List.map (String.split "=")
                |> List.map
                    (\list ->
                        case list of
                            key :: value :: [] ->
                                Just ( key, value )

                            _ ->
                                Nothing
                    )
                |> Maybe.Extra.values
                |> Dict.fromList

        maybeAccessToken =
            Dict.get "access_token" queryParameters

        maybeExpiresIn =
            Dict.get "expires_in" queryParameters
                |> Maybe.andThen String.toInt

        maybeTokenType =
            Dict.get "token_type" queryParameters

        maybeUrl =
            Dict.get "state" queryParameters
                |> Maybe.andThen Url.percentDecode
                |> Maybe.map (\path -> { url | fragment = Just path })
                |> Maybe.andThen Route.fromUrl
    in
    case ( ( maybeAccessToken, maybeExpiresIn ), ( maybeTokenType, maybeUrl ) ) of
        ( ( Just accessToken, Just expiresIn ), ( Just tokenType, Just route ) ) ->
            Just
                { accessToken = accessToken
                , expiresIn = expiresIn
                , tokenType = tokenType
                , route = route
                }

        _ ->
            Nothing


login url =
    Url.Builder.crossOrigin prePath
        [ "authorize" ]
        [ Url.Builder.string "client_id" clientId
        , Url.Builder.string "response_type" responseType
        , Url.Builder.string "redirect_uri" redirectUri
        , Url.Builder.string "scope" scope
        , Url.Builder.string "audience" audience
        , Url.Builder.string "state" (Maybe.withDefault "" url.fragment)
        ]


logout =
    Url.Builder.crossOrigin prePath
        [ "v2", "logout" ]
        [ Url.Builder.string "client_id" clientId
        , Url.Builder.string "returnTo" returnTo
        ]


getUserInfo accessToken toMsg =
    Http.request
        { method = "GET"
        , headers =
            [ Http.header "Authorization" ("Bearer " ++ accessToken)
            ]
        , url =
            Url.Builder.crossOrigin prePath
                [ "userinfo" ]
                []
        , body = Http.emptyBody
        , expect = Http.expectWhatever toMsg
        , timeout = Nothing
        , tracker = Nothing
        }
