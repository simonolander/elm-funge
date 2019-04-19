module View.LoadingScreen exposing (layout, view)

import Element exposing (..)
import Html exposing (Html)


view : String -> Element msg
view message =
    text message
        --        |> List.singleton
        --        |> paragraph []
        |> el [ scale 3, centerX, centerY ]


layout : String -> Html msg
layout message =
    view message
        |> Element.layout
            [ width fill
            , height fill
            ]
