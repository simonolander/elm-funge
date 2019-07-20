module View.LoadingScreen exposing (layout, view)

import Element exposing (..)
import Element.Font as Font
import Html
import View.Layout


view : String -> Element msg
view message =
    column
        [ centerX
        , centerY
        , spacing 20
        ]
        [ paragraph
            [ width shrink
            , centerX
            , centerY
            , Font.size 28
            , Font.center
            ]
            [ text message ]
        , image
            [ width (px 36)
            , centerX
            ]
            { src = "assets/spinner.svg"
            , description = "Loading animation"
            }
        ]


layout : String -> Html.Html msg
layout =
    view >> View.Layout.layout
