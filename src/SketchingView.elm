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
import ViewComponents exposing (..)


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
            [ Background.color (rgb 0 0 0)
            , Font.family [ Font.monospace ]
            , Font.color (rgb 1 1 1)
            ]


viewSidebar levelProgress =
    let
        toolbarView =
            viewToolbar levelProgress

        undoButtonView =
            textButton []
                (Just (SketchMsg SketchUndo))
                "Undo"

        redoButtonView =
            textButton []
                (Just (SketchMsg SketchRedo))
                "Redo"

        clearButtonView =
            textButton []
                (Just (SketchMsg SketchClear))
                "Clear"

        executeButtonView =
            textButton []
                (Just (SketchMsg SketchExecute))
                "Execute"
    in
    column
        [ width (fillPortion 1)
        , height fill
        , alignTop
        , Background.color (rgb 0.08 0.08 0.08)
        , spacing 10
        , padding 10
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

        viewTool index instructionTool =
            let
                attributes =
                    case instructionToolbox.selectedIndex of
                        Just selectedIndex ->
                            if index == selectedIndex then
                                [ Background.color (rgba 1 1 1 0.5)
                                , InstructionToolView.description instructionTool
                                    |> Html.Attributes.title
                                    |> htmlAttribute
                                ]

                            else
                                [ InstructionToolView.description instructionTool
                                    |> Html.Attributes.title
                                    |> htmlAttribute
                                ]

                        Nothing ->
                            [ InstructionToolView.description instructionTool
                                |> Html.Attributes.title
                                |> htmlAttribute
                            ]

                onPress =
                    { instructionToolbox | selectedIndex = Just index }
                        |> NewInstructionToolbox
                        |> SketchMsg
                        |> Just
            in
            instructionToolButton attributes onPress instructionTool

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
                                        let
                                            attributes =
                                                if selectedDirection == direction then
                                                    [ Background.color (rgb 0.5 0.5 0.5) ]

                                                else
                                                    []

                                            onPress =
                                                ChangeAnyDirection direction
                                                    |> replaceToolMessage index
                                                    |> Just

                                            instruction =
                                                ChangeDirection direction
                                        in
                                        instructionButton attributes onPress instruction
                                    )
                                |> wrappedRow
                                    [ spacing 10
                                    ]

                        Just (BranchAnyDirection trueDirection falseDirection) ->
                            row
                                [ centerX
                                , spacing 10
                                ]
                                [ [ Left, Up, Right, Down ]
                                    |> List.map
                                        (\direction ->
                                            let
                                                attributes =
                                                    if trueDirection == direction then
                                                        [ Background.color (rgb 0.5 0.5 0.5) ]

                                                    else
                                                        []

                                                onPress =
                                                    BranchAnyDirection direction falseDirection
                                                        |> replaceToolMessage index
                                                        |> Just

                                                instruction =
                                                    ChangeDirection direction
                                            in
                                            instructionButton attributes onPress instruction
                                        )
                                    |> column
                                        [ spacing 10 ]
                                , [ Left, Up, Right, Down ]
                                    |> List.map
                                        (\direction ->
                                            let
                                                attributes =
                                                    if falseDirection == direction then
                                                        [ Background.color (rgb 0.5 0.5 0.5) ]

                                                    else
                                                        []

                                                onPress =
                                                    BranchAnyDirection trueDirection direction
                                                        |> replaceToolMessage index
                                                        |> Just

                                                instruction =
                                                    ChangeDirection direction
                                            in
                                            instructionButton attributes onPress instruction
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
        [ spacing 20
        ]
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
        onPress =
            selectedInstructionTool
                |> Maybe.map getInstruction
                |> Maybe.map (PlaceInstruction { x = columnIndex, y = rowIndex })
                |> Maybe.map SketchMsg
    in
    instructionButton [] onPress instruction


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
