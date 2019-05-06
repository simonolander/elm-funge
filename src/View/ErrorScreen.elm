module View.ErrorScreen exposing (layout, view)

import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Html
import Html.Attributes as Attribute
import View.Layout


layout : String -> Html.Html msg
layout =
    view >> View.Layout.layout


view : String -> Element msg
view errorMessage =
    paragraph
        [ width fill
        , height fill
        , centerX
        , Background.color (rgb 0.1 0.1 0.1)
        , padding 40
        , htmlAttribute (Attribute.class "pre")
        , scrollbars
        , Font.color (rgb 1 0.51 0.35)
        , Font.size 30
        ]
        [ text errorMessage ]
