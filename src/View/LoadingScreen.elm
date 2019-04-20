module View.LoadingScreen exposing (layout, view)

import Element exposing (..)
import Element.Font as Font
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
            , Font.color (rgb 1 1 1)
            , Font.family
                [ Font.monospace
                ]
            ]
