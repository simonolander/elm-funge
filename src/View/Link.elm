module View.Link exposing (button)

import Element exposing (..)
import View.Button as Button


button : { text : String, url : String } -> Element msg
button { text, url } =
    link
        [ width fill ]
        { url = url, label = Button.textButton { onPress = Nothing, text = text } }
