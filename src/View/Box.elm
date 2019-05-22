module View.Box exposing (nonInteractive)

import Element exposing (..)
import Element.Border as Border


gray : Color
gray =
    rgb 0.2 0.2 0.2


nonInteractive : Element msg -> Element msg
nonInteractive element =
    el
        [ Border.color gray
        , Border.width 3
        , padding 10
        , width fill
        ]
        element
