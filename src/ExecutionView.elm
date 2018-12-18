module ExecutionView exposing (view)

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


view : ExecutionState -> Html Msg
view executionState =
    let
        execution = case executionState of
            ExecutionPaused exn -> exn
            ExecutionRunning exn _ -> exn

        headerView =
            viewHeader

        boardView =
            viewBoard execution

        executionSideBarView =
            viewExecutionSidebar execution

        ioSidebarView =
            viewIOSidebar (History.current execution.executionHistory)
    in
    column
        [ width fill
        , height fill
        ]
        [ headerView
        , row
            [ width fill
            , height fill
            , htmlAttribute (Html.Attributes.style "height" "90%") -- hack
            ]
            [ executionSideBarView
            , boardView
            , ioSidebarView
            ]
        ]
        |> layout
            [ height fill
            , clip
            ]


viewExecutionSidebar : Execution -> Element Msg
viewExecutionSidebar levelProgress =
    let
        undoButtonView =
            Input.button
                []
                { onPress = Just (ExecutionMsg ExecutionUndo)
                , label = text "Undo"
                }

        stepButtonView =
            Input.button
                []
                { onPress = Just (ExecutionMsg ExecutionStepOne)
                , label = text "Step"
                }

        runButtonView =
            Input.button
                []
                { onPress = Just (ExecutionMsg ExecutionRun)
                , label = text "Run"
                }

        pauseButtonView =
            Input.button
                []
                { onPress = Just (ExecutionMsg ExecutionPause)
                , label = text "Pause"
                }
    in
    column
        [ width (fillPortion 1)
        , height fill
        , Background.color (rgb 0.8 0.8 1)
        , alignTop
        ]
        [ undoButtonView
        , stepButtonView
        , runButtonView
        , pauseButtonView
        , el [ alignBottom, Background.color (rgb 1 0.8 0.8), width fill ] (text "footer")
        ]


viewBoard : Execution -> Element Msg
viewBoard execution =
    let
        executionStep =
            execution.executionHistory
                |> History.current

        instructionPointer =
            executionStep.instructionPointer

        board =
            executionStep.board

        viewInstruction : Int -> Int -> Instruction -> Element Msg
        viewInstruction rowIndex columnIndex instruction =
            let
                backgroundColor =
                    if instructionPointer.position.x == columnIndex && instructionPointer.position.y == rowIndex then
                        rgb 1 0.6 0.6

                    else
                        rgb 1 1 1

                instructionLabel =
                    el
                        [ width (px instructionSize)
                        , height (px instructionSize)
                        , Background.color backgroundColor
                        , Font.center
                        ]
                        (text (instructionToString instruction))
            in
            Input.button
                []
                { onPress = Nothing
                , label = instructionLabel
                }

        viewRow : Int -> Array Instruction -> Element Msg
        viewRow rowIndex boardRow =
            boardRow
                |> Array.indexedMap (viewInstruction rowIndex)
                |> Array.toList
                |> row [ spacing instructionSpacing ]
    in
    board
        |> Array.indexedMap viewRow
        |> Array.toList
        |> column
            [ spacing instructionSpacing
            , scrollbars
            , width (fillPortion 3)
            , height fill
            , Background.color (rgb 0.8 1 0.8)
            ]


viewHeader : Element Msg
viewHeader =
    let
        backButtonView =
            Input.button
                []
                { onPress = Just (ExecutionMsg ExecutionBackClicked)
                , label = text "Back"
                }
    in
    row
        [ width fill
        , height shrink
        , Background.color (rgb 1 1 0.8)
        ]
        [ backButtonView
        ]


viewIOSidebar : ExecutionStep -> Element Msg
viewIOSidebar executionStep =
    let
        inputView =
            let
                header =
                    text "Input"

                inputs =
                    executionStep.input
                        |> List.map String.fromInt
                        |> List.map text
                        |> column
                            [ width fill
                            , height fill
                            , Background.color (rgb 0.2 0.2 0.2)
                            , Font.family
                                [ Font.monospace
                                ]
                            , Font.color (rgb 1 1 1)
                            , padding 5
                            , spacing 2
                            , scrollbars
                            ]
            in
            column
                [ width (fillPortion 1)
                , height fill
                , padding 5
                , Border.color (rgb 1 0 0)
                , Border.solid
                , Border.width 10
                ]
                [ header
                , inputs
                ]

        outputView =
            executionStep.output
                |> List.map String.fromInt
                |> List.map text
                |> column
                    [ width (fillPortion 1)
                    , height fill
                    , Background.color (rgb 0.7 0.6 0.5)
                    , scrollbars
                    ]
    in
    row
        [ width (fillPortion 1)
        , height fill
        , Background.color (rgb 0.8 0.8 0.8)
        ]
        [ inputView, outputView ]


instructionToString : Instruction -> String
instructionToString instruction =
    case instruction of
        NoOp ->
            ""

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
            "push " ++ String.fromInt n

        PopFromStack ->
            "pop"

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
