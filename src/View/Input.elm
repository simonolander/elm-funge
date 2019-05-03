module View.Input exposing (TextConfiguration, numericInput, textInput)

import Element exposing (..)
import Element.Background as Background
import Element.Input as Input
import Html.Attributes
import Maybe.Extra


type alias TextConfiguration msg a =
    { a
        | onChange : String -> msg
        , text : String
        , labelText : String
    }


type alias NumericTextConfiguration msg =
    TextConfiguration msg
        { min : Maybe Float
        , max : Maybe Float
        , step : Maybe Float
        }


textInput : List (Attribute msg) -> TextConfiguration msg a -> Element msg
textInput attributes configuration =
    let
        allAttributes =
            attributes
                ++ [ Background.color (rgb 0.1 0.1 0.1) ]

        label =
            Input.labelAbove
                []
                (text configuration.labelText)
    in
    Input.text
        allAttributes
        { onChange = configuration.onChange
        , text = configuration.text
        , placeholder = Nothing
        , label = label
        }


numericInput : List (Attribute msg) -> NumericTextConfiguration msg -> Element msg
numericInput attributes configuration =
    let
        numericAttributes =
            [ Just (Html.Attributes.type_ "number")
            , Maybe.map (String.fromFloat >> Html.Attributes.min) configuration.min
            , Maybe.map (String.fromFloat >> Html.Attributes.max) configuration.max
            , Maybe.map (String.fromFloat >> Html.Attributes.step) configuration.step
            ]
                |> Maybe.Extra.values
                |> List.map htmlAttribute

        allAttributes =
            List.concat
                [ numericAttributes
                , attributes
                ]
    in
    textInput allAttributes configuration
