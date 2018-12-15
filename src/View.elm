module View exposing (view)

import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src)
import Model exposing (..)


view : Model -> Html Msg
view model =
    div []
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text (Debug.toString(model)) ]
        ]
