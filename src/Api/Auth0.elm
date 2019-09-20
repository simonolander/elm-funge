module Api.Auth0 exposing (LoginResponse, login, loginResponseFromUrl, logout, reLogin)

import Data.AccessToken as AccessToken exposing (AccessToken)
import Dict
import Json.Decode
import Json.Encode
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
--    "http://localhost:3000"
    "https://efng.simonolander.com

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
        , "read:solutions"
        , "submit:solutions"
        , "publish:blueprints"
        ]


audience =
    "https://us-central1-luminous-cubist-234816.cloudfunctions.net"



-- MODEL


type alias State =
    { route : String }


type alias LoginResponse =
    { accessToken : AccessToken
    , expiresIn : Int
    , route : Route
    }


encodeState : State -> Json.Encode.Value
encodeState state =
    Json.Encode.object
        [ ( "route", Json.Encode.string state.route )
        ]


stateDecoder : Json.Decode.Decoder State
stateDecoder =
    let
        routeDecoder =
            Json.Decode.field "route" Json.Decode.string
                |> Json.Decode.maybe
                |> Json.Decode.map (Maybe.withDefault "")
    in
    routeDecoder
        |> Json.Decode.andThen (\route -> Json.Decode.succeed { route = route })


loginResponseFromUrl : Url -> Maybe LoginResponse
loginResponseFromUrl url =
    let
        fragmentParameters =
            url.fragment
                |> Maybe.withDefault ""
                |> String.split "&"
                |> List.map (String.split "=")
                |> Debug.log "fragment"
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
            Dict.get "access_token" fragmentParameters
                |> Maybe.map AccessToken.fromString

        maybeExpiresIn =
            Dict.get "expires_in" fragmentParameters
                |> Maybe.andThen String.toInt

        state =
            Dict.get "state" fragmentParameters
                |> Maybe.andThen Url.percentDecode
                |> Maybe.andThen (Json.Decode.decodeString stateDecoder >> Result.toMaybe)
                |> Maybe.withDefault { route = "" }

        route =
            { url | fragment = Just state.route }
                |> Route.fromUrl
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

        state =
            { route =
                url
                    |> Maybe.Extra.orElse (Route.toUrl Route.Home)
                    |> Maybe.andThen .fragment
                    |> Maybe.withDefault ""
            }
                |> encodeState
                |> Json.Encode.encode 0

        parameters =
            [ Url.Builder.string "client_id" clientId
            , Url.Builder.string "response_type" responseType
            , Url.Builder.string "redirect_uri" redirectUri
            , Url.Builder.string "scope" scopes
            , Url.Builder.string "audience" audience
            , Url.Builder.string "state" state
            ]
    in
    Url.Builder.crossOrigin prePath
        path
        parameters


logout : String
logout =
    Url.Builder.crossOrigin prePath
        [ "v2", "logout" ]
        [ Url.Builder.string "client_id" clientId
        , Url.Builder.string "returnTo" returnTo
        ]


reLogin : Maybe Url -> String
reLogin url =
    Url.Builder.crossOrigin prePath
        [ "v2", "logout" ]
        [ Url.Builder.string "client_id" clientId
        , Url.Builder.string "returnTo" (login url)
        ]
