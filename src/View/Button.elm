module View.Button exposing (textButton)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input


textButton : { onPress : Maybe msg, text : String } -> Element msg
textButton params =
    Input.button
        [ width fill
        , Border.width 4
        , Border.color (rgb 1 1 1)
        , padding 10
        , mouseOver [ Background.color (rgba 1 1 1 0.5) ]
        ]
        { onPress = params.onPress
        , label =
            el [ centerX, centerY ] (text params.text)
        }
