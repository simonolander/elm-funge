module View.Input exposing (TextConfiguration, multiline, numericInput, textInput)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input
import Html.Attributes
import Maybe.Extra


type alias TextConfiguration msg a =
    { a
        | onChange : String -> msg
        , text : String
        , labelText : String
        , placeholder : Maybe String
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
                ++ [ Background.color (rgb 0.1 0.1 0.1)
                   ]

        label =
            Input.labelAbove
                []
                (text configuration.labelText)

        placeholder =
            configuration.placeholder
                |> Maybe.map text
                |> Maybe.map (Input.placeholder [])
    in
    Input.text
        allAttributes
        { onChange = configuration.onChange
        , text = configuration.text
        , placeholder = placeholder
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
            , Just (Html.Attributes.class "number")
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


multiline :
    { onChange : String -> msg
    , text : String
    , labelText : String
    , spellcheck : Bool
    }
    -> Element msg
multiline conf =
    Input.multiline
        [ Background.color (rgb 0.1 0.1 0.1) ]
        { onChange = conf.onChange
        , text = conf.text
        , placeholder = Just (Input.placeholder [] (text "1\n3\n5\n10"))
        , label = Input.labelAbove [] (text conf.labelText)
        , spellcheck = conf.spellcheck
        }
