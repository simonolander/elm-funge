module View.LoadingScreen exposing (layout, view)

import Element exposing (..)
import Element.Font as Font
import Html
import View.Layout


view : String -> Element msg
view message =
    text message
        |> List.singleton
        |> paragraph
            [ width shrink
            , centerX
            , centerY
            , Font.size 28
            ]


layout : String -> Html.Html msg
layout =
    view >> View.Layout.layout
