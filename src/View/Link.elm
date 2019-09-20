module View.Link exposing (button)

import Element exposing (Element)
import View.Button as Button


button : { text : String, url : String } -> Element msg
button { text, url } =
    Element.link
        [ Element.width Element.fill ]
        { url = url, label = Button.textButton { onPress = Nothing, text = text } }
