module SketchingView exposing (view)

import Array exposing (Array)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import History
import Html exposing (Html)
import Html.Attributes
import InstructionToolView
import InstructionView
import Model exposing (..)


instructionSpacing =
    10


instructionSize =
    100


view : LevelProgress -> Html Msg
view levelProgress =
    let
        selectedInstructionTool =
            getSelectedInstructionTool levelProgress.boardSketch.instructionToolbox

        boardView =
            levelProgress.boardSketch.boardHistory
                |> History.current
                |> Array.indexedMap (viewRow selectedInstructionTool)
                |> Array.toList
                |> column
                    [ spacing instructionSpacing
                    , scrollbars
                    , width (fillPortion 3)
                    , height fill
                    , padding instructionSpacing
                    ]

        headerView =
            viewHeader

        sidebarView =
            viewSidebar levelProgress
    in
    column
        [ width fill
        , height fill
        ]
        [ headerView
        , row
            [ width fill
            , height fill
            ]
            [ sidebarView
            , boardView
            ]
        ]
        |> layout
            [ Background.color (rgb 0 0 0) ]


viewSidebar levelProgress =
    let
        toolbarView =
            viewToolbar levelProgress

        undoButtonView =
            Input.button
                []
                { onPress = Just (SketchMsg SketchUndo)
                , label = text "Undo"
                }

        redoButtonView =
            Input.button
                []
                { onPress = Just (SketchMsg SketchRedo)
                , label = text "Redo"
                }

        clearButtonView =
            Input.button
                []
                { onPress = Just (SketchMsg SketchClear)
                , label = text "Clear"
                }

        executeButtonView =
            Input.button
                []
                { onPress = Just (SketchMsg SketchExecute)
                , label = text "Execute"
                }
    in
    column
        [ width (fillPortion 1)
        , height fill
        , Background.color (rgb 0.8 0.8 1)
        , alignTop
        ]
        [ toolbarView
        , undoButtonView
        , redoButtonView
        , clearButtonView
        , executeButtonView
        , el [ alignBottom, Background.color (rgb 1 0.8 0.8), width fill ] (text "footer")
        ]


viewToolbar : LevelProgress -> Element Msg
viewToolbar levelProgress =
    let
        instructionToolbox =
            levelProgress.boardSketch.instructionToolbox

        instructionTools =
            instructionToolbox.instructionTools

        viewTool index tool =
            let
                backgroundColor =
                    case instructionToolbox.selectedIndex of
                        Just selectedIndex ->
                            if index == selectedIndex then
                                rgb 0.5 0.5 0.5

                            else
                                rgb 0 0 0

                        Nothing ->
                            rgb 0 0 0

                instructionLabel =
                    el
                        [ width (px instructionSize)
                        , height (px instructionSize)
                        , Background.color backgroundColor
                        , Font.center
                        , padding 10
                        , mouseOver
                            [ Background.color (rgb 0.5 0.5 0.5) ]
                        ]
                        (InstructionToolView.view
                            [ width fill
                            , height fill
                            ]
                            tool
                        )
            in
            Input.button
                [ Border.width 3
                , Border.color (rgb 1 1 1)
                ]
                { onPress =
                    Just
                        (SketchMsg
                            (NewInstructionToolbox
                                { instructionToolbox
                                    | selectedIndex = Just index
                                }
                            )
                        )
                , label = instructionLabel
                }

        replaceToolMessage index instructionTool =
            SketchMsg
                (NewInstructionToolbox
                    { instructionToolbox
                        | instructionTools =
                            instructionTools
                                |> Array.fromList
                                |> Array.set index instructionTool
                                |> Array.toList
                    }
                )

        toolExtraView =
            case instructionToolbox.selectedIndex of
                Just index ->
                    case getSelectedInstructionTool instructionToolbox of
                        Just (ChangeAnyDirection selectedDirection) ->
                            [ Left, Up, Right, Down ]
                                |> List.map
                                    (\direction ->
                                        Input.button
                                            [ Border.width 3
                                            , Border.color (rgb 1 1 1)
                                            ]
                                            { onPress =
                                                Just
                                                    (replaceToolMessage index
                                                        (ChangeAnyDirection direction)
                                                    )
                                            , label =
                                                el
                                                    [ width (px instructionSize)
                                                    , height (px instructionSize)
                                                    , Background.color
                                                        (if selectedDirection == direction then
                                                            rgb 0.5 0.5 0.5

                                                         else
                                                            rgb 0 0 0
                                                        )
                                                    , Font.center
                                                    , padding 10
                                                    , mouseOver
                                                        [ Background.color (rgb 0.5 0.5 0.5) ]
                                                    ]
                                                    (InstructionView.view
                                                        [ width fill
                                                        , height fill
                                                        ]
                                                        (ChangeDirection direction)
                                                    )
                                            }
                                    )
                                |> wrappedRow
                                    [ spacing 10 ]

                        Just (BranchAnyDirection trueDirection falseDirection) ->
                            row []
                                [ [ Left, Up, Right, Down ]
                                    |> List.map
                                        (\direction ->
                                            Input.button
                                                [ Border.width 3
                                                , Border.color (rgb 1 1 1)
                                                ]
                                                { onPress =
                                                    Just
                                                        (replaceToolMessage index
                                                            (BranchAnyDirection direction falseDirection)
                                                        )
                                                , label =
                                                    el
                                                        [ width (px instructionSize)
                                                        , height (px instructionSize)
                                                        , Background.color
                                                            (if trueDirection == direction then
                                                                rgb 0.5 0.5 0.5

                                                             else
                                                                rgb 0 0 0
                                                            )
                                                        , Font.center
                                                        , padding 10
                                                        , mouseOver
                                                            [ Background.color (rgb 0.5 0.5 0.5) ]
                                                        ]
                                                        (InstructionView.view
                                                            [ width fill
                                                            , height fill
                                                            ]
                                                            (ChangeDirection direction)
                                                        )
                                                }
                                        )
                                    |> column
                                        [ spacing 10 ]
                                , [ Left, Up, Right, Down ]
                                    |> List.map
                                        (\direction ->
                                            Input.button
                                                [ Border.width 3
                                                , Border.color (rgb 1 1 1)
                                                ]
                                                { onPress =
                                                    Just
                                                        (replaceToolMessage index
                                                            (BranchAnyDirection trueDirection direction)
                                                        )
                                                , label =
                                                    el
                                                        [ width (px instructionSize)
                                                        , height (px instructionSize)
                                                        , Background.color
                                                            (if falseDirection == direction then
                                                                rgb 0.5 0.5 0.5

                                                             else
                                                                rgb 0 0 0
                                                            )
                                                        , Font.center
                                                        , padding 10
                                                        , mouseOver
                                                            [ Background.color (rgb 0.5 0.5 0.5) ]
                                                        ]
                                                        (InstructionView.view
                                                            [ width fill
                                                            , height fill
                                                            ]
                                                            (ChangeDirection direction)
                                                        )
                                                }
                                        )
                                    |> column
                                        [ spacing 10 ]
                                ]

                        Just (JustInstruction _) ->
                            none

                        Nothing ->
                            none

                Nothing ->
                    none
    in
    column
        []
        [ instructionTools
            |> List.indexedMap viewTool
            |> wrappedRow
                [ spacing 10 ]
        , toolExtraView
        ]


viewRow : Maybe InstructionTool -> Int -> Array Instruction -> Element Msg
viewRow selectedInstructionTool rowIndex boardRow =
    boardRow
        |> Array.indexedMap (viewInstruction selectedInstructionTool rowIndex)
        |> Array.toList
        |> row [ spacing instructionSpacing ]


viewInstruction : Maybe InstructionTool -> Int -> Int -> Instruction -> Element Msg
viewInstruction selectedInstructionTool rowIndex columnIndex instruction =
    let
        instructionLabel =
            el
                [ width (px instructionSize)
                , height (px instructionSize)
                , Font.center
                , padding 10
                , mouseOver
                    [ Background.color (rgb 0.5 0.5 0.5) ]
                ]
                (InstructionView.view
                    [ width fill
                    , height fill
                    ]
                    instruction
                )

        onPress : Maybe Msg
        onPress =
            selectedInstructionTool
                |> Maybe.map getInstruction
                |> Maybe.map (PlaceInstruction { x = columnIndex, y = rowIndex })
                |> Maybe.map SketchMsg
    in
    Input.button
        [ Border.width 3
        , Border.color (rgb 1 1 1)
        ]
        { onPress = onPress
        , label = instructionLabel
        }


viewHeader : Element Msg
viewHeader =
    let
        backButtonView =
            Input.button
                []
                { onPress = Just (SketchMsg SketchBackClicked)
                , label = text "Back"
                }
    in
    row
        [ width fill
        , Background.color (rgb 1 1 0.8)
        ]
        [ backButtonView
        ]


getSelectedInstructionTool : InstructionToolbox -> Maybe InstructionTool
getSelectedInstructionTool instructionToolbox =
    instructionToolbox.selectedIndex
        |> Maybe.andThen
            (\index ->
                instructionToolbox.instructionTools
                    |> Array.fromList
                    |> Array.get index
            )


getInstruction : InstructionTool -> Instruction
getInstruction instructionTool =
    case instructionTool of
        JustInstruction instruction ->
            instruction

        ChangeAnyDirection direction ->
            ChangeDirection direction

        BranchAnyDirection trueDirection falseDirection ->
            Branch trueDirection falseDirection
