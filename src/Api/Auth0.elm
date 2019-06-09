module Api.Auth0 exposing (LoginResponse, login, loginResponseFromUrl, logout)

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
    { accessToken : String
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


login url =
    Url.Builder.crossOrigin prePath
        [ "authorize" ]
        [ Url.Builder.string "client_id" clientId
        , Url.Builder.string "response_type" responseType
        , Url.Builder.string "redirect_uri" redirectUri
        , Url.Builder.string "scope" (scope |> Set.toList |> String.join " ")
        , Url.Builder.string "audience" audience
        , Url.Builder.string "state" (Maybe.withDefault "" url.fragment)
        ]


logout =
    Url.Builder.crossOrigin prePath
        [ "v2", "logout" ]
        [ Url.Builder.string "client_id" clientId
        , Url.Builder.string "returnTo" returnTo
        ]
