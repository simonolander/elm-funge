module View.LoadingScreen exposing (layout, view)

import Element exposing (..)
import Html
import View.Layout


view : String -> Element msg
view message =
    text message
        |> List.singleton
        |> paragraph [ scale 3, centerX, centerY ]


layout : String -> Html.Html msg
layout =
    view >> View.Layout.layout
