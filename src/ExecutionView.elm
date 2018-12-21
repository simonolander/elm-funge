module ExecutionView exposing (view)

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
import List.Extra
import Model exposing (..)


instructionSpacing =
    10


instructionSize =
    100


noPadding =
    { left = 0
    , top = 0
    , right = 0
    , bottom = 0
    }


view : ExecutionState -> Html Msg
view executionState =
    let
        execution =
            case executionState of
                ExecutionPaused exn ->
                    exn

                ExecutionRunning exn _ ->
                    exn

        headerView =
            viewHeader

        boardView =
            viewBoard execution

        executionSideBarView =
            viewExecutionSidebar execution

        ioSidebarView =
            viewIOSidebar execution
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
            , if isWon execution then
                boardView
                    |> el
                        [ width (fillPortion 3), height fill, inFront (viewVictoryModal execution) ]

              else
                boardView
            , ioSidebarView
            ]
        ]
        |> layout
            [ height fill
            , clip
            , Font.family [ Font.monospace ]
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


viewVictoryModal : Execution -> Element Msg
viewVictoryModal execution =
    let
        numberOfSteps =
            History.size execution.executionHistory - 1

        numberOfInstructions =
            History.first execution.executionHistory
                |> .board
                |> BoardUtils.count ((/=) NoOp)

        viewRow ( label, value ) =
            row [ width fill, spaceEvenly ]
                [ el [ paddingEach { noPadding | right = 30 } ] (text label)
                , text (String.fromInt value)
                ]
    in
    column
        [ centerX
        , centerY
        , Background.color (rgba 0 0 0 0.5)
        , padding 20
        , Font.family [ Font.monospace ]
        , Font.color (rgb 1 1 1)
        , spacing 10
        ]
        [ el
            [ Font.size 32
            ]
            (text "Solved")
        , viewRow ( "Number of steps", numberOfSteps )
        , viewRow ( "Number of instructions", numberOfInstructions )
        , Input.button
            [ width fill
            , Border.width 4
            , Border.color (rgb 1 1 1)
            , padding 10
            , mouseOver [ Background.color (rgba 1 1 1 0.5) ]
            ]
            { onPress = Just (ExecutionMsg ExecutionBackToBrowsingLevels)
            , label =
                el [ centerX, centerY ] (text "Back to levels")
            }
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
        , height shrink -- needed?
        , Background.color (rgb 1 1 0.8)
        ]
        [ backButtonView
        ]


viewIOSidebar : Execution -> Element Msg
viewIOSidebar execution =
    let
        executionStep =
            History.current execution.executionHistory

        viewSingle label values =
            let
                labelView =
                    el
                        [ paddingEach { noPadding | bottom = 10 }
                        , centerX
                        ]
                        (text label)

                valuesView =
                    values
                        |> List.map String.fromInt
                        |> List.map
                            (\value ->
                                el
                                    [ Font.alignRight
                                    , width fill
                                    ]
                                    (text value)
                            )
                        |> column
                            [ width fill
                            , height fill
                            , Font.alignRight
                            , padding 5
                            , spacing 2
                            , scrollbars
                            , Border.width 3
                            ]
            in
            column
                [ height fill
                , padding 5
                ]
                [ labelView
                , valuesView
                ]

        viewDouble label expected actual =
            let
                correctedActual =
                    let
                        correct a b =
                            case ( a, b ) of
                                ( ha :: ta, hb :: tb ) ->
                                    ( hb, ha == hb ) :: correct ta tb

                                ( _, [] ) ->
                                    []

                                ( [], bb ) ->
                                    List.map (\h -> ( h, False )) bb
                    in
                    correct expected (List.reverse actual)

                labelView =
                    el
                        [ paddingEach { noPadding | bottom = 10 }
                        , centerX
                        ]
                        (text label)

                expectedView =
                    expected
                        |> List.map String.fromInt
                        |> List.map
                            (\value ->
                                el
                                    [ Font.alignRight
                                    , width fill
                                    ]
                                    (text value)
                            )
                        |> column
                            [ width fill
                            , height fill
                            , Font.alignRight
                            , padding 5
                            , spacing 2
                            , scrollbars
                            , Border.width 3
                            ]

                actualView =
                    correctedActual
                        |> List.map
                            (\( value, correct ) ->
                                el
                                    [ Font.alignRight
                                    , width fill
                                    , Background.color
                                        (if correct then
                                            rgba 0 0 0 0

                                         else
                                            rgb 0.5 0 0
                                        )
                                    ]
                                    (text (String.fromInt value))
                            )
                        |> column
                            [ width fill
                            , height fill
                            , Font.alignRight
                            , padding 5
                            , spacing 2
                            , scrollbars
                            , Border.widthEach { left = 0, top = 3, right = 3, bottom = 3 }
                            ]
            in
            column
                [ height fill
                , width fill
                , padding 5
                ]
                [ labelView
                , row
                    [ height fill
                    , width fill
                    ]
                    [ expectedView, actualView ]
                ]

        inputView =
            viewSingle "Input" executionStep.input

        stackView =
            viewSingle "Stack" executionStep.stack

        outputView =
            viewDouble "Output" execution.level.io.output executionStep.output
    in
    row
        [ width (fillPortion 1)
        , height fill
        , Background.color (rgb 0 0 0)
        , spacing 10
        , Font.color (rgb 1 1 1)
        , padding 5
        ]
        [ inputView, stackView, outputView ]


isWon : Execution -> Bool
isWon execution =
    let
        executionStep =
            History.current execution.executionHistory

        expectedOutput =
            execution.level.io.output
                |> List.reverse

        outputCorrect =
            executionStep.output == expectedOutput
    in
    executionStep.terminated && outputCorrect


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
