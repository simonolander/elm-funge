module View.SingleSidebar exposing (layout, view)

import Data.Session exposing (Session)
import Element exposing (..)
import Element.Background as Background
import Html
import View.Header as Header
import View.Layout
import View.Scewn


view : { sidebar : List (Element msg), main : Element msg, session : Session, modal : Maybe (Element msg) } -> Element msg
view parameters =
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
                parameters.sidebar

        main =
            el
                [ width (fillPortion 3)
                , height fill
                , scrollbarY
                , padding 20
                ]
                parameters.main

        header =
            Header.view parameters.session
    in
    View.Scewn.view
        { north = Just header
        , west = Just sidebar
        , center = Just main
        , east = Nothing
        , south = Nothing
        , modal = Nothing
        }


layout : { sidebar : List (Element msg), main : Element msg, session : Session, modal : Maybe (Element msg) } -> Html.Html msg
layout parameters =
    View.Layout.layout (view parameters)
