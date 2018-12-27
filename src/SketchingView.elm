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
                    , Background.color (rgb 0.8 1 0.8)
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
            []


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

        options =
            instructionTools
                |> List.indexedMap
                    (\index instructionTool ->
                        Input.option index (text (Debug.toString instructionTool))
                    )

        selectInstructionTool : Int -> Msg
        selectInstructionTool index =
            SketchMsg
                (NewInstructionToolbox
                    { instructionToolbox
                        | selectedIndex = Just index
                    }
                )
    in
    Input.radio
        []
        { onChange = selectInstructionTool
        , selected = instructionToolbox.selectedIndex
        , label = Input.labelAbove [] (text "Instructions")
        , options = options
        }


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
                , Background.color (rgb 1 1 1)
                , centerX
                , centerY
                , Font.center
                ]
                (text (Debug.toString instruction))

        onPress : Maybe Msg
        onPress =
            selectedInstructionTool
                |> Maybe.map getInstruction
                |> Maybe.map (PlaceInstruction { x = columnIndex, y = rowIndex })
                |> Maybe.map SketchMsg
    in
    Input.button
        []
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

        _ ->
            NoOp
