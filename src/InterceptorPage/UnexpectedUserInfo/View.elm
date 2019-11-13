module InterceptorPage.UnexpectedUserInfo.View exposing (view)

import Data.Session exposing (Session)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Element exposing (..)
import Element.Font as Font
import Html exposing (Html)
import InterceptorPage.UnexpectedUserInfo.Msg exposing (Msg(..))
import RemoteData
import View.Constant exposing (icons)
import View.ErrorScreen
import View.Info as Info
import View.Layout
import View.LoadingScreen
import ViewComponents


view : Session -> Maybe ( String, Html Msg )
view session =
    if VerifiedAccessToken.isUnverified session.accessToken then
        Just <|
            case session.actualUserInfo of
                RemoteData.NotAsked ->
                    View.ErrorScreen.layout "Error code: np25g6d18wazzunx"

                RemoteData.Loading ->
                    View.LoadingScreen.layout "Verifying credentials"

                RemoteData.Failure error ->
                    View.ErrorScreen.layout "Error code: ynnimwz2oq6fvrmm"

                RemoteData.Success actualUserInfo ->
                    View.Layout.layout <|
                        Info.view
                            { title = "New sign in detected"
                            , icon = icons.alert.orange
                            , elements =
                                case session.expectedUserInfo of
                                    Just expectedUserInfo ->
                                        [ paragraph [ Font.center ]
                                            [ text "You're trying to sign in as "
                                            , text actualUserInfo.sub |> el [ Font.color (rgb255 163 179 222) ]
                                            , text " but there is unsaved data belonging to "
                                            , text expectedUserInfo.sub |> el [ Font.color (rgb255 163 179 222) ]
                                            , text ". Either clear the local data and continue or log in to the other account."
                                            ]
                                        , ViewComponents.textButton [] (Just ClickedDeleteLocalData) "Delete data"
                                        , ViewComponents.textButton [] (Just ClickedSignInToOtherAccount) "Sign in to the other account"
                                        ]

                                    Nothing ->
                                        [ paragraph [ Font.center ]
                                            [ text "There is unsaved data on the local storage. Either import it to this account or delete it."
                                            ]
                                        , ViewComponents.textButton [] (Just ClickedImportLocalData) "Import data"
                                        , ViewComponents.textButton [] (Just ClickedDeleteLocalData) "Delete data"
                                        ]
                            }

    else
        Nothing
