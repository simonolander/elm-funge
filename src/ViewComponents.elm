module ViewComponents exposing
    ( descriptionTextbox
    , imageButton
    , instructionButton
    , instructionToolButton
    , textButton
    , viewTitle
    , branchDirectionExtraButton
    )

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import InstructionToolView
import InstructionView
import Model exposing (..)


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


branchDirectionExtraButton : List (Attribute msg) -> Maybe msg -> Bool -> Direction -> Element msg
branchDirectionExtraButton attributes onPress true direction =
    let
        ( sourceFile, description ) =
            case ( true, direction ) of
                ( True, Left ) ->
                    ( "assets/instruction-images/small-filled-arrow-left.svg"
                    , "Go left when not zero"
                    )

                ( True, Up ) ->
                    ( "assets/instruction-images/small-filled-arrow-up.svg"
                    , "Go up when not zero"
                    )

                ( True, Right ) ->
                    ( "assets/instruction-images/small-filled-arrow-right.svg"
                    , "Go right when not zero"
                    )

                ( True, Down ) ->
                    ( "assets/instruction-images/small-filled-arrow-down.svg"
                    , "Go down when not zero"
                    )

                ( False, Left ) ->
                    ( "assets/instruction-images/small-hollow-arrow-left.svg"
                    , "Go left when zero"
                    )

                ( False, Up ) ->
                    ( "assets/instruction-images/small-hollow-arrow-up.svg"
                    , "Go up when zero"
                    )

                ( False, Right ) ->
                    ( "assets/instruction-images/small-hollow-arrow-right.svg"
                    , "Go right when zero"
                    )

                ( False, Down ) ->
                    ( "assets/instruction-images/small-hollow-arrow-down.svg"
                    , "Go down when zero"
                    )
    in
    imageButton
        (List.concat
            [ attributes
            ]
        )
        onPress
        (image
            [ width fill
            , height fill
            ]
            { src = sourceFile
            , description = description
            }
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


descriptionTextbox : List (Attribute msg) -> List String -> Element msg
descriptionTextbox attributes description =
    let
        attrs =
            List.concat
                [ [ width fill
                  , padding 10
                  , spacing 15
                  , Border.width 3
                  , Border.color (rgb 1 1 1)
                  ]
                , attributes
                ]
    in
    description
        |> List.map (paragraph [] << List.singleton << text)
        |> column
            attrs


viewTitle : List (Attribute msg) -> String -> Element msg
viewTitle attributes title =
    el [ width fill, Font.center, Font.size 24 ] (paragraph [] [ text title ])
