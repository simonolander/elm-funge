module View.SingleSidebar exposing (layout, view)

import Api.Auth0
import Data.Session exposing (Session)
import Data.User as User
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html exposing (Html)
import Maybe.Extra


layout : List (Element msg) -> Element msg -> Session -> Html msg
layout sidebarContent mainContent session =
    view sidebarContent mainContent session
        |> Element.layout
            [ Background.color (rgb 0 0 0)
            , width fill
            , height fill
            , Font.family
                [ Font.monospace
                ]
            , Font.color (rgb 1 1 1)
            ]


view : List (Element msg) -> Element msg -> Session -> Element msg
view sidebarContent mainContent session =
    let
        sidebar =
            column
                [ width (fillPortion 1)
                , height fill
                , padding 20
                , spacing 20
                , alignTop
                , Background.color (rgb 0.05 0.05 0.05)
                , scrollbarY
                ]
                sidebarContent

        main =
            el
                [ width (fillPortion 3)
                , height fill
                , scrollbarY
                , padding 20
                ]
                mainContent

        loginButton =
            link
                [ alignRight
                , padding 20
                , mouseOver
                    [ Background.color (rgb 0.5 0.5 0.5) ]
                ]
                (if User.isLoggedIn session.user then
                    { url = Api.Auth0.logout
                    , label = text "Logout"
                    }

                 else
                    { url = Api.Auth0.login
                    , label = text "Login"
                    }
                )
    in
    scewn
        { north = Just loginButton
        , west = Just sidebar
        , center = Just main
        , east = Nothing
        , south = Nothing
        }


scewn :
    { south : Maybe (Element msg)
    , center : Maybe (Element msg)
    , east : Maybe (Element msg)
    , west : Maybe (Element msg)
    , north : Maybe (Element msg)
    }
    -> Element msg
scewn { south, center, east, west, north } =
    let
        middle =
            let
                toRow =
                    row [ width fill, height fill, scrollbars ]
            in
            case ( west, center, east ) of
                ( Just w, Just c, Just e ) ->
                    [ el [ width (fillPortion 1), height fill ] w
                    , el [ width (fillPortion 3), height fill ] c
                    , el [ width (fillPortion 1), height fill ] e
                    ]
                        |> toRow
                        |> Just

                ( Just w, Just c, Nothing ) ->
                    [ el [ width (fillPortion 1), height fill ] w
                    , el [ width (fillPortion 3), height fill ] c
                    ]
                        |> toRow
                        |> Just

                ( Just w, Nothing, Just e ) ->
                    [ el [ width (fillPortion 1), height fill ] w
                    , el [ width (fillPortion 1), height fill ] e
                    ]
                        |> toRow
                        |> Just

                ( Just w, Nothing, Nothing ) ->
                    Just (el [ width fill, height fill ] w)

                ( Nothing, Just c, Just e ) ->
                    [ el [ width (fillPortion 3), height fill ] c
                    , el [ width (fillPortion 1), height fill ] e
                    ]
                        |> toRow
                        |> Just

                ( Nothing, Just c, Nothing ) ->
                    Just (el [ width fill, height fill ] c)

                ( Nothing, Nothing, Just e ) ->
                    Just (el [ width fill, height fill ] e)

                ( Nothing, Nothing, Nothing ) ->
                    Just (el [ width fill, height fill ] none)

        top =
            Maybe.map (el [ width fill ]) north

        bottom =
            Maybe.map (el [ width fill ]) south
    in
    [ top, middle, bottom ]
        |> Maybe.Extra.values
        |> column [ width fill, height fill ]
