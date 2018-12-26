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
        selectedInstruction =
            levelProgress.boardSketch.selectedInstruction

        boardView =
            levelProgress.boardSketch.boardHistory
                |> History.current
                |> Array.indexedMap (viewRow selectedInstruction)
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
        permittedInstructions =
            levelProgress.level.permittedInstructions

        options =
            permittedInstructions
                |> List.map
                    (\instruction ->
                        Input.option instruction (text (instructionToString instruction))
                    )
    in
    Input.radio
        []
        { onChange = SketchMsg << SelectInstruction
        , selected = levelProgress.boardSketch.selectedInstruction
        , label = Input.labelAbove [] (text "Instructions")
        , options = options
        }


viewRow : Maybe Instruction -> Int -> Array Instruction -> Element Msg
viewRow selectedInstruction rowIndex boardRow =
    boardRow
        |> Array.indexedMap (viewInstruction selectedInstruction rowIndex)
        |> Array.toList
        |> row [ spacing instructionSpacing ]


viewInstruction : Maybe Instruction -> Int -> Int -> Instruction -> Element Msg
viewInstruction selectedInstruction rowIndex columnIndex instruction =
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
                (text (instructionToString instruction))

        onPress : Maybe Msg
        onPress =
            selectedInstruction
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


instructionToString : Instruction -> String
instructionToString instruction =
    case instruction of
        NoOp ->
            "nop"

        ChangeDirection direction ->
            case direction of
                Left ->
                    "left"

                Up ->
                    "up"

                Right ->
                    "right"

                Down ->
                    "down"

        PushToStack n ->
            String.fromInt n

        Add ->
            "+"

        Subtract ->
            "-"

        Multiply ->
            "*"

        Divide ->
            "/"

        Read ->
            "read"

        Print ->
            "print"

        otherwise ->
            Debug.toString otherwise
