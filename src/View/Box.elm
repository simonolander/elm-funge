module View.Box exposing (nonInteractive, simpleError, simpleNonInteractive)

import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import View.Constant exposing (color)


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


simpleNonInteractive : String -> Element msg
simpleNonInteractive message =
    paragraph
        [ Font.color color.font.subtle
        , Font.center
        ]
        [ text message ]
        |> nonInteractive


simpleError : String -> Element msg
simpleError message =
    paragraph
        [ Font.color color.font.error
        , Font.center
        ]
        [ text message ]
        |> nonInteractive