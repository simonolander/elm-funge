module View.Card exposing (link)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Html.Attributes
import View.Constant exposing (color)


link : { url : String, content : Element msg, marked : Bool, selected : Bool } -> Element msg
link parameters =
    let
        class =
            [ ( "solved", parameters.marked ) ]
                |> Html.Attributes.classList
                |> htmlAttribute

        attributes =
            [ padding 20
            , Border.width 3
            , width fill
            , class
            , mouseOver
                [ color.background.hovering
                ]
            , if parameters.selected then
                color.background.selected

              else
                color.background.black
            ]

        label =
            parameters.content
    in
    Element.link
        attributes
        { url = parameters.url
        , label = label
        }
