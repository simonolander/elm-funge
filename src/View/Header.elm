module View.Header exposing (view)

import Api.Auth0
import Data.User as User
import Element exposing (..)
import Element.Background as Background


view session =
    let
        loginButton =
            link
                [ alignRight
                , padding 20
                , mouseOver
                    [ Background.color (rgb 0.5 0.5 0.5) ]
                ]
                (if User.isLoggedIn session.user then
                    { url = Api.Auth0.logout
                    , label = text "Sign out"
                    }

                 else
                    { url = Api.Auth0.login
                    , label = text "Sign in"
                    }
                )
    in
    row
        [ width fill
        , Background.color (rgb 0.1 0.1 0.1)
        ]
        [ loginButton ]
