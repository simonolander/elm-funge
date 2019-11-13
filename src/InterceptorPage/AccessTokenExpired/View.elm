module InterceptorPage.AccessTokenExpired.View exposing (view)

import Api.Auth0 as Auth0
import Data.AccessToken exposing (AccessToken)
import Data.Session exposing (Session)
import Data.VerifiedAccessToken as VerifiedAccessToken exposing (VerifiedAccessToken(..))
import Element exposing (..)
import Element.Font as Font
import Html exposing (Html)
import InterceptorPage.AccessTokenExpired.Msg exposing (Msg(..))
import View.Constant exposing (color, icons)
import View.Layout as Layout
import ViewComponents


view : Session -> Maybe ( String, Html Msg )
view session =
    VerifiedAccessToken.getInvalid session.accessToken
        |> Maybe.map (viewInvalidAccessToken session)
        |> Maybe.map Layout.layout
        |> Maybe.map (Tuple.pair "Access token expired")


viewInvalidAccessToken : Session -> AccessToken -> Element Msg
viewInvalidAccessToken session accessToken =
    column
        [ centerX
        , centerY
        , spacing 20
        ]
        [ image
            [ width (px 36)
            , centerX
            ]
            icons.alert.orange
        , paragraph
            [ width shrink
            , centerX
            , centerY
            , Font.center
            , Font.size 28
            , color.font.error
            ]
            [ text "Your credentials are either expired or invalid. "
            ]
        , link
            [ width (px 300)
            , centerX
            ]
            { label = ViewComponents.textButton [] Nothing "Sign in"
            , url = Auth0.login (Just session.url)
            }
        , ViewComponents.textButton
            [ width (px 300)
            , centerX
            ]
            (Just ClickedContinueOffline)
            "Continue offline"
        ]
