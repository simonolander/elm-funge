module View.SingleSidebar exposing (view)

import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Html exposing (Html)


view : List (Element msg) -> Element msg -> Html msg
view sidebarContent mainContent =
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
    in
    layout
        [ Background.color (rgb 0 0 0)
        , width fill
        , height fill
        , Font.family
            [ Font.monospace
            ]
        , Font.color (rgb 1 1 1)
        ]
        (row
            [ width fill
            , height fill
            ]
            [ sidebar
            , main
            ]
        )