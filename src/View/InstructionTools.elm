module View.InstructionTools exposing (view)

import Array exposing (Array)
import Data.Direction as Direction
import Data.IO as IO
import Data.Instruction exposing (Instruction(..))
import Data.InstructionTool as InstructionTool exposing (InstructionTool(..))
import Element exposing (..)
import Element.Background as Background
import Html.Attributes
import InstructionToolView
import Maybe.Extra
import View.Input
import ViewComponents exposing (branchDirectionExtraButton, instructionButton, instructionToolButton)


view :
    { instructionTools : Array InstructionTool
    , selectedIndex : Maybe Int
    , onSelect : Maybe (Int -> msg)
    , onReplace : Int -> InstructionTool -> msg
    }
    -> Element msg
view conf =
    let
        viewTool index instructionTool =
            let
                selected =
                    conf.selectedIndex
                        |> Maybe.map ((==) index)
                        |> Maybe.withDefault False

                attributes =
                    if selected then
                        [ Background.color (rgba 1 1 1 0.25)
                        , InstructionToolView.description instructionTool
                            |> Html.Attributes.title
                            |> htmlAttribute
                        ]

                    else
                        [ InstructionToolView.description instructionTool
                            |> Html.Attributes.title
                            |> htmlAttribute
                        ]

                onPress =
                    Maybe.map ((|>) index) conf.onSelect
            in
            instructionToolButton attributes onPress instructionTool

        toolExtraView =
            case conf.selectedIndex of
                Just index ->
                    case Array.get index conf.instructionTools of
                        Just (ChangeAnyDirection selectedDirection) ->
                            Direction.all
                                |> List.map
                                    (\direction ->
                                        let
                                            attributes =
                                                if selectedDirection == direction then
                                                    [ Background.color (rgb 0.25 0.25 0.25) ]

                                                else
                                                    []

                                            onPress =
                                                Just (conf.onReplace index (ChangeAnyDirection direction))

                                            instruction =
                                                ChangeDirection direction
                                        in
                                        instructionButton attributes onPress instruction
                                    )
                                |> wrappedRow
                                    [ spacing 10
                                    , width (px 222)
                                    , centerX
                                    ]
                                |> Just

                        Just (BranchAnyDirection trueDirection falseDirection) ->
                            row
                                [ centerX
                                , spacing 10
                                ]
                                [ Direction.all
                                    |> List.map
                                        (\direction ->
                                            let
                                                attributes =
                                                    if trueDirection == direction then
                                                        [ Background.color (rgb 0.25 0.25 0.25) ]

                                                    else
                                                        []

                                                onPress =
                                                    Just (conf.onReplace index (BranchAnyDirection direction falseDirection))
                                            in
                                            branchDirectionExtraButton attributes onPress True direction
                                        )
                                    |> column
                                        [ spacing 10 ]
                                , Direction.all
                                    |> List.map
                                        (\direction ->
                                            let
                                                attributes =
                                                    if falseDirection == direction then
                                                        [ Background.color (rgb 0.25 0.25 0.25) ]

                                                    else
                                                        []

                                                onPress =
                                                    Just (conf.onReplace index (BranchAnyDirection trueDirection direction))
                                            in
                                            branchDirectionExtraButton attributes onPress False direction
                                        )
                                    |> column
                                        [ spacing 10 ]
                                ]
                                |> Just

                        Just (PushValueToStack value) ->
                            View.Input.numericInput
                                []
                                { onChange = PushValueToStack >> conf.onReplace index
                                , text = value
                                , placeholder = Nothing
                                , labelText = "Enter value"
                                , min = Just IO.constraints.min
                                , max = Just IO.constraints.max
                                , step = Just 1
                                }
                                |> Just

                        Just (InstructionTool.Exception exceptionMessage) ->
                            View.Input.textInput
                                []
                                { onChange = InstructionTool.Exception >> conf.onReplace index
                                , text = exceptionMessage
                                , placeholder = Nothing
                                , labelText = "Enter value"
                                }
                                |> Just

                        Just (JustInstruction _) ->
                            Nothing

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing

        toolsView =
            conf.instructionTools
                |> Array.indexedMap viewTool
                |> Array.toList
                |> wrappedRow
                    [ width (px 222)
                    , spacing 10
                    , centerX
                    ]
    in
    [ Just toolsView
    , toolExtraView
    ]
        |> Maybe.Extra.values
        |> column
            [ width (px 262)
            , height fill
            , Background.color (rgb 0.05 0.05 0.05)
            , spacing 40
            , padding 10
            , scrollbarY
            ]
