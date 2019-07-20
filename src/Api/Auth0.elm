module Api.Auth0 exposing (LoginResponse, login, loginResponseFromUrl, logout)

import Data.AccessToken as AccessToken exposing (AccessToken)
import Dict
import Maybe.Extra
import Route exposing (Route)
import Set
import Url exposing (Url)
import Url.Builder



-- PRIVATE CONSTANTS


prePath =
    "https://dev-253xzd4c.eu.auth0.com"


clientId =
    "QnLYsQ4CDaqcGViA43t90z6lo7L77JK6"


responseType =
    String.join " "
        [ "token"
        ]


redirectUri =
    "http://localhost:3000"


returnTo =
    redirectUri


scope =
    Set.fromList
        [ "openid"
        , "profile"
        , "read:drafts"
        , "read:blueprints"
        , "edit:drafts"
        , "edit:blueprints"
        , "submit:solutions"
        , "publish:blueprints"
        ]


audience =
    "https://us-central1-luminous-cubist-234816.cloudfunctions.net"



-- MODEL


type alias LoginResponse =
    { accessToken : AccessToken
    , expiresIn : Int
    , route : Route
    }


loginResponseFromUrl : Url -> Maybe LoginResponse
loginResponseFromUrl url =
    let
        fragmentParameters =
            url.fragment
                |> Maybe.withDefault ""
                |> String.split "&"
                |> List.map (String.split "=")
                |> List.map
                    (\list ->
                        case list |> Debug.log "fragment" of
                            key :: value :: [] ->
                                Just ( key, value )

                            _ ->
                                Nothing
                    )
                |> Maybe.Extra.values
                |> Dict.fromList

        maybeAccessToken =
            Dict.get "access_token" fragmentParameters
                |> Maybe.map AccessToken.fromString

        maybeExpiresIn =
            Dict.get "expires_in" fragmentParameters
                |> Maybe.andThen String.toInt

        route =
            Dict.get "state" fragmentParameters
                |> Maybe.andThen Url.percentDecode
                |> Maybe.map (\path -> { url | fragment = Just path })
                |> Maybe.andThen Route.fromUrl
                |> Maybe.withDefault Route.Home
    in
    case ( maybeAccessToken, maybeExpiresIn ) of
        ( Just accessToken, Just expiresIn ) ->
            Just
                { accessToken = accessToken
                , expiresIn = expiresIn
                , route = route
                }

        _ ->
            Nothing


login : Maybe Url -> String
login url =
    let
        path =
            [ "authorize" ]

        scopes =
            scope
                |> Set.toList
                |> String.join " "

        parameters =
            Maybe.Extra.values
                [ Just (Url.Builder.string "client_id" clientId)
                , Just (Url.Builder.string "response_type" responseType)
                , Just (Url.Builder.string "redirect_uri" redirectUri)
                , Just (Url.Builder.string "scope" scopes)
                , Just (Url.Builder.string "audience" audience)
                , url
                    |> Maybe.andThen .fragment
                    |> Maybe.map (Url.Builder.string "state")
                ]
    in
    Url.Builder.crossOrigin prePath
        path
        parameters


logout =
    Url.Builder.crossOrigin prePath
        [ "v2", "logout" ]
        [ Url.Builder.string "client_id" clientId
        , Url.Builder.string "returnTo" returnTo
        ]
