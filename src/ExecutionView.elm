module ExecutionView exposing (view)

import Array exposing (Array)
import BoardUtils
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import ExecutionControlView
import ExecutionUtils
import History
import Html exposing (Html)
import Html.Attributes
import InstructionView
import Model exposing (..)
import ViewComponents


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


view : Execution -> ExecutionState -> Html Msg
view execution executionState =
    let
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
        [ row
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
            , Font.family [ Font.monospace ]
            , Font.color (rgb 1 1 1)
            ]


viewExecutionSidebar : Execution -> Element Msg
viewExecutionSidebar execution =
    let
        controlSize =
            50

        titleView =
            ViewComponents.viewTitle
                []
                execution.level.name

        descriptionView =
            ViewComponents.descriptionTextbox []
                execution.level.description

        backButtonView =
            ViewComponents.textButton []
                (Just (NavigationMessage (GoToSketching execution.level.id)))
                "Back"

        viewButton : ExecutionControlView.ExecutionControlInstruction -> Maybe Msg -> Element Msg
        viewButton executionControlInstruction onPress =
            Input.button
                [ width (px controlSize)
                , height (px controlSize)
                , padding 10
                , Border.width 3
                , Border.color (rgb 1 1 1)
                , mouseOver
                    [ Background.color (rgb 0.5 0.5 0.5)
                    ]
                ]
                { onPress = onPress
                , label =
                    ExecutionControlView.view
                        [ width fill
                        , height fill
                        ]
                        executionControlInstruction
                }

        undoButtonView =
            viewButton ExecutionControlView.Undo (Just (ExecutionMsg ExecutionUndo))

        stepButtonView =
            viewButton ExecutionControlView.Step (Just (ExecutionMsg ExecutionStepOne))

        runButtonView =
            viewButton ExecutionControlView.Play (Just (ExecutionMsg ExecutionRun))

        fastForwardButtonView =
            viewButton ExecutionControlView.FastForward (Just (ExecutionMsg ExecutionFastForward))

        pauseButtonView =
            viewButton ExecutionControlView.Pause (Just (ExecutionMsg ExecutionPause))

        executionControlInstructionsView =
            wrappedRow
                [ spacing 10
                , centerX
                ]
                [ undoButtonView
                , stepButtonView
                , runButtonView
                , fastForwardButtonView
                , pauseButtonView
                ]
    in
    column
        [ px 350 |> width
        , height fill
        , Background.color (rgb 0.08 0.08 0.08)
        , alignTop
        , padding 10
        , spacing 10
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
            ]
        , executionControlInstructionsView
        , el
            [ width fill
            , alignBottom
            ]
            backButtonView
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
                    case instruction of
                        Exception _ ->
                            if instructionPointer.position.x == columnIndex && instructionPointer.position.y == rowIndex then
                                rgb 0.4 0 0

                            else
                                rgb 0.1 0 0

                        _ ->
                            if instructionPointer.position.x == columnIndex && instructionPointer.position.y == rowIndex then
                                rgb 0.4 0.4 0.4

                            else
                                rgb 0 0 0

                instructionLabel =
                    el
                        [ width (px instructionSize)
                        , height (px instructionSize)
                        , Background.color backgroundColor
                        , Font.center
                        , padding 10
                        ]
                        (InstructionView.view
                            [ width fill
                            , height fill
                            ]
                            instruction
                        )
            in
            Input.button
                [ Border.width 3
                , Border.color (rgb 1 1 1)
                ]
                { onPress = Nothing
                , label = instructionLabel
                }

        viewRow : Int -> Array Instruction -> Element Msg
        viewRow rowIndex boardRow =
            boardRow
                |> Array.indexedMap (viewInstruction rowIndex)
                |> Array.toList
                |> row [ spacing instructionSpacing ]

        boardView =
            board
                |> Array.indexedMap viewRow
                |> Array.toList
                |> column
                    [ spacing instructionSpacing
                    , scrollbars
                    , width (fillPortion 3)
                    , height fill
                    , Background.color (rgb 0 0 0)
                    , padding 10
                    ]

        boardWithModalView =
            case getExceptionMessage execution of
                Just message ->
                    boardView
                        |> el
                            [ width (fillPortion 3)
                            , height fill
                            , inFront (viewExceptionModal execution message)
                            ]

                Nothing ->
                    if ExecutionUtils.executionIsSolved execution then
                        boardView
                            |> el
                                [ width (fillPortion 3)
                                , height fill
                                , inFront (viewVictoryModal execution)
                                ]

                    else if History.current execution.executionHistory |> .terminated then
                        boardView
                            |> el
                                [ width (fillPortion 3)
                                , height fill
                                , inFront (viewWrongOutputModal execution)
                                ]

                    else
                        boardView
    in
    boardWithModalView


viewExceptionModal : Execution -> String -> Element Msg
viewExceptionModal execution exceptionMessage =
    column
        [ centerX
        , centerY
        , Background.color (rgb 0.1 0 0)
        , padding 20
        , Font.color (rgb 1 0 0)
        , spacing 10
        , Border.width 3
        , Border.color (rgb 0.5 0 0)
        ]
        [ el
            [ Font.size 32
            ]
            (text "Exception")
        , paragraph
            []
            [ text exceptionMessage ]
        , ViewComponents.textButton
            [ Background.color (rgb 0 0 0)
            , Font.color (rgb 1 1 1)
            ]
            (Just (NavigationMessage (GoToSketching execution.level.id)))
            "Back to editor"
        ]


viewWrongOutputModal : Execution -> Element Msg
viewWrongOutputModal execution =
    column
        [ centerX
        , centerY
        , Background.color (rgb 0 0 0)
        , padding 20
        , Font.family [ Font.monospace ]
        , Font.color (rgb 1 1 1)
        , spacing 10
        , Border.width 3
        , Border.color (rgb 1 1 1)
        ]
        [ el
            [ Font.size 32
            ]
            (text "Wrong output")
        , paragraph
            []
            [ text "The program terminated, but the output is incorrect." ]
        , ViewComponents.textButton
            [ Background.color (rgb 0 0 0)
            , Font.color (rgb 1 1 1)
            ]
            (Just (NavigationMessage (GoToSketching execution.level.id)))
            "Back to editor"
        ]


viewVictoryModal : Execution -> Element Msg
viewVictoryModal execution =
    let
        numberOfSteps =
            execution.executionHistory
                |> History.current
                |> .stepCount

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
        , Background.color (rgb 0 0 0)
        , padding 20
        , Font.family [ Font.monospace ]
        , Font.color (rgb 1 1 1)
        , spacing 10
        , Border.width 3
        , Border.color (rgb 1 1 1)
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
            { onPress = Just (NavigationMessage (GoToBrowsingLevels (Just execution.level.id)))
            , label =
                el [ centerX, centerY ] (text "Back to levels")
            }
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
        , Background.color (rgb 0.08 0.08 0.08)
        , spacing 10
        , Font.color (rgb 1 1 1)
        , padding 5
        ]
        [ inputView, stackView, outputView ]


getExceptionMessage : Execution -> Maybe String
getExceptionMessage execution =
    execution.executionHistory
        |> History.current
        |> .exception
