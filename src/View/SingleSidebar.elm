module View.SingleSidebar exposing (layout, view)

import Data.Session exposing (Session)
import Element exposing (..)
import Element.Background as Background
import Html
import View.Header as Header
import View.Layout
import View.Scewn


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

        header =
            Header.view session
    in
    View.Scewn.view
        { north = Just header
        , west = Just sidebar
        , center = Just main
        , east = Nothing
        , south = Nothing
        , modal = Nothing
        }


layout : List (Element msg) -> Element msg -> Session -> Html.Html msg
layout a b c =
    view a b c |> View.Layout.layout
