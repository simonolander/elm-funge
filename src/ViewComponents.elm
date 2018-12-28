module ViewComponents exposing (imageButton, instructionButton, instructionToolButton, textButton)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import InstructionToolView
import InstructionView
import Model exposing (Instruction(..), InstructionTool(..))


textButton : List (Attribute msg) -> Maybe msg -> String -> Element msg
textButton attributes onPress buttonText =
    Input.button
        (List.concat
            [ [ width fill
              , Border.width 4
              , Border.color (rgb 1 1 1)
              , padding 10
              , mouseOver [ Background.color (rgba 1 1 1 0.5) ]
              ]
            , attributes
            ]
        )
        { onPress = onPress
        , label =
            el [ centerX, centerY ] (text buttonText)
        }


imageButton : List (Attribute msg) -> Maybe msg -> Element msg -> Element msg
imageButton attributes onPress image =
    Input.button
        [ Border.width 3
        , Border.color (rgb 1 1 1)
        ]
        { onPress = onPress
        , label =
            el
                (List.concat
                    [ [ width (px 100)
                      , height (px 100)
                      , Font.center
                      , padding 10
                      , mouseOver [ Background.color (rgb 0.5 0.5 0.5) ]
                      ]
                    , attributes
                    ]
                )
                image
        }


instructionButton : List (Attribute msg) -> Maybe msg -> Instruction -> Element msg
instructionButton attributes onPress instruction =
    let
        attrs2 =
            case instruction of
                Exception _ ->
                    [ Background.color (rgba 1 0 0 0.1) ]

                _ ->
                    []
    in
    imageButton
        (List.concat
            [ attrs2
            , attributes
            ]
        )
        onPress
        (InstructionView.view
            [ width fill
            , height fill
            ]
            instruction
        )


instructionToolButton : List (Attribute msg) -> Maybe msg -> InstructionTool -> Element msg
instructionToolButton attributes onPress instructionTool =
    let
        attrs2 =
            case instructionTool of
                JustInstruction (Exception _) ->
                    [ Background.color (rgba 1 0 0 0.1) ]

                _ ->
                    []
    in
    imageButton
        (List.concat
            [ attrs2
            , attributes
            ]
        )
        onPress
        (InstructionToolView.view
            [ width fill
            , height fill
            ]
            instructionTool
        )