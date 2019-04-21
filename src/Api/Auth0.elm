module Api.Auth0 exposing (LoginResponse, getUserInfo, login, loginResponseFromUrl, logout)

import Dict
import Http
import Maybe.Extra
import Url exposing (Url)
import Url.Builder
import Url.Parser
import Url.Parser.Query



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



-- MODEL


type alias LoginResponse =
    { accessToken : String
    , expiresIn : Int
    , tokenType : String
    }


parser =
    Url.Parser.Query.map3
        (\maybeAccessToken maybeExpiresIn maybeTokenType ->
            case ( maybeAccessToken, maybeExpiresIn, maybeTokenType ) of
                ( Just accessToken, Just expiresIn, Just tokenType ) ->
                    Just
                        { accessToken = accessToken
                        , expiresIn = expiresIn
                        , tokenType = tokenType
                        }

                _ ->
                    Nothing
        )
        (Url.Parser.Query.string "access_token")
        (Url.Parser.Query.int "expires_in")
        (Url.Parser.Query.string "token_type")
        |> Url.Parser.query


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
    in
    case ( maybeAccessToken, maybeExpiresIn, maybeTokenType ) of
        ( Just accessToken, Just expiresIn, Just tokenType ) ->
            Just
                { accessToken = accessToken
                , expiresIn = expiresIn
                , tokenType = tokenType
                }

        _ ->
            Nothing


login =
    Url.Builder.crossOrigin prePath
        [ "authorize" ]
        [ Url.Builder.string "client_id" clientId
        , Url.Builder.string "response_type" responseType
        , Url.Builder.string "redirect_uri" redirectUri
        , Url.Builder.string "scope" scope
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
