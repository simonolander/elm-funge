module SketchingView exposing (view)

import Array exposing (Array)
import BoardUtils
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


view : LevelProgress -> Html Msg
view levelProgress =
    let
        selectedInstructionTool =
            getSelectedInstructionTool levelProgress.boardSketch.instructionToolbox

        boardView =
            levelProgress.boardSketch.boardHistory
                |> History.current
                |> Array.indexedMap (viewRow levelProgress.level.initialBoard selectedInstructionTool)
                |> Array.toList
                |> column
                    [ spacing instructionSpacing
                    , scrollbars
                    , width (fillPortion 3)
                    , height fill
                    , padding instructionSpacing
                    ]

        sidebarView =
            viewSidebar levelProgress

        toolSidebarView =
            viewToolSidebar levelProgress
    in
    row
        [ width fill
        , height fill
        ]
        [ sidebarView
        , boardView
        , toolSidebarView
        ]
        |> layout
            [ Background.color (rgb 0 0 0)
            , Font.family [ Font.monospace ]
            , Font.color (rgb 1 1 1)
            , height fill
            ]


viewSidebar levelProgress =
    let
        titleView =
            viewTitle
                []
                levelProgress.level.name

        descriptionView =
            descriptionTextbox []
                levelProgress.level.description

        backButton =
            textButton []
                (Just (SketchMsg SketchBackClicked))
                "Back"

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
        [ px 350 |> width
        , height fill
        , alignTop
        , Background.color (rgb 0.08 0.08 0.08)
        , spacing 10
        , padding 10
        , scrollbarY
        ]
        [ column
            [ width fill
            , spacing 20
            , paddingEach
                { left = 0, top = 20, right = 0, bottom = 30 }
            ]
            [ titleView
            , descriptionView
            , executeButtonView
            ]
        , column
            [ width fill
            , height fill
            , spacing 10
            ]
            [ undoButtonView
            , redoButtonView
            , clearButtonView
            , el [ alignBottom, width fill ] backButton
            ]
        ]


viewToolSidebar : LevelProgress -> Element Msg
viewToolSidebar levelProgress =
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
                            [ Left, Up, Down, Right ]
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
                                    , width (px 222)
                                    , centerX
                                    ]

                        Just (BranchAnyDirection trueDirection falseDirection) ->
                            row
                                [ centerX
                                , spacing 10
                                ]
                                [ [ Up, Left, Right, Down ]
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
                                            in
                                            branchDirectionExtraButton attributes onPress True direction
                                        )
                                    |> column
                                        [ spacing 10 ]
                                , [ Up, Left, Right, Down ]
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
                                            in
                                            branchDirectionExtraButton attributes onPress False direction
                                        )
                                    |> column
                                        [ spacing 10 ]
                                ]

                        Just (PushValueToStack value) ->
                            Input.text
                                [ Background.color (rgb 0 0 0)
                                , Border.width 3
                                , Border.color (rgb 1 1 1)
                                , Border.rounded 0
                                ]
                                { onChange =
                                    \string ->
                                        string
                                            |> PushValueToStack
                                            |> replaceToolMessage index
                                , text = value
                                , placeholder = Nothing
                                , label =
                                    Input.labelAbove
                                        []
                                        (text "Enter value")
                                }

                        Just (JustInstruction _) ->
                            none

                        Nothing ->
                            none

                Nothing ->
                    none

        toolsView =
            instructionTools
                |> List.indexedMap viewTool
                |> wrappedRow
                    [ width (px 222)
                    , spacing 10
                    , centerX
                    ]
    in
    column
        [ width (px 262)
        , height fill
        , Background.color (rgb 0.08 0.08 0.08)
        , spacing 40
        , padding 10
        , scrollbarY
        ]
        [ toolsView
        , toolExtraView
        ]


viewRow : Board -> Maybe InstructionTool -> Int -> Array Instruction -> Element Msg
viewRow initialBoard selectedInstructionTool rowIndex boardRow =
    boardRow
        |> Array.indexedMap (viewInstruction initialBoard selectedInstructionTool rowIndex)
        |> Array.toList
        |> row [ spacing instructionSpacing ]


viewInstruction : Board -> Maybe InstructionTool -> Int -> Int -> Instruction -> Element Msg
viewInstruction initialBoard selectedInstructionTool rowIndex columnIndex instruction =
    let
        initialInstruction =
            BoardUtils.get { x = columnIndex, y = rowIndex } initialBoard
                |> Maybe.withDefault NoOp

        editable =
            initialInstruction == NoOp

        attributes =
            if editable then
                []

            else
                let
                    backgroundColor =
                        case initialInstruction of
                            Exception _ ->
                                rgb 0.1 0 0

                            _ ->
                                rgb 0.15 0.15 0.15
                in
                [ Background.color backgroundColor
                , htmlAttribute (Html.Attributes.style "cursor" "not-allowed")
                , mouseOver []
                ]

        onPress =
            if editable then
                selectedInstructionTool
                    |> Maybe.map getInstruction
                    |> Maybe.map (PlaceInstruction { x = columnIndex, y = rowIndex })
                    |> Maybe.map SketchMsg

            else
                Nothing
    in
    instructionButton attributes onPress instruction


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

        PushValueToStack value ->
            value
                |> String.toInt
                |> Maybe.map PushToStack
                |> Maybe.withDefault (Exception (value ++ " is not a number"))
