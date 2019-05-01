module View.Layout exposing (layout)

import Element exposing (..)
import Element.Font as Font
import Html


layout : Element msg -> Html.Html msg
layout =
    Element.layout
        [ width fill
        , height fill
        , Font.color (rgb 1 1 1)
        , Font.family
            [ Font.monospace
            ]
        ]
