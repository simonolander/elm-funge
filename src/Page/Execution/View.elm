module Page.Execution.View exposing (view)

import Array exposing (Array)
import Data.GetError as GetError
import Data.History as History
import Data.Instruction exposing (Instruction(..))
import Data.Int16 as Int16
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import ExecutionControlView
import Html exposing (Html)
import InstructionView
import Page.Execution.Model exposing (Execution, ExecutionState(..), Model)
import Page.Execution.Msg exposing (Msg(..))
import Page.Execution.Update exposing (canStepExecution, getNumberOfStepsForSuite, getScore, isExecutionSolved, isSuiteFailed, isSuiteSolved)
import RemoteData exposing (RemoteData(..))
import Route
import Service.Draft.DraftService exposing (getDraftByDraftId)
import Service.Level.LevelService exposing (getLevelByLevelId)
import View.Box
import View.Constant exposing (color, icons)
import View.ErrorScreen
import View.Header
import View.LoadingScreen
import View.Scewn
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


view : Session -> Model -> ( String, Html Msg )
view session model =
    let
        content =
            case getDraftByDraftId model.draftId session of
                NotAsked ->
                    View.ErrorScreen.view ("Draft " ++ model.draftId ++ " not asked :/")

                Loading ->
                    View.LoadingScreen.view ("Loading draft " ++ model.draftId ++ " from local storage")

                Failure error ->
                    View.ErrorScreen.view (GetError.toString error)

                Success Nothing ->
                    View.ErrorScreen.view ("Draft " ++ model.draftId ++ " not found")

                Success (Just draft) ->
                    case getLevelByLevelId draft.levelId session of
                        NotAsked ->
                            View.ErrorScreen.view ("Level " ++ draft.levelId ++ " not asked :/")

                        Loading ->
                            View.LoadingScreen.view ("Loading level " ++ draft.levelId)

                        Failure error ->
                            View.ErrorScreen.view (GetError.toString error)

                        Success _ ->
                            case model.execution of
                                Just execution ->
                                    viewLoaded execution session model

                                Nothing ->
                                    View.LoadingScreen.view "Initializing execution"
    in
    ( "Execution"
    , layout
        [ height fill
        , clip
        , Font.family [ Font.monospace ]
        , color.font.default
        ]
        content
    )


viewLoaded : Execution -> Session -> Model -> Element Msg
viewLoaded execution session model =
    let
        main =
            viewBoard execution model

        west =
            viewExecutionSidebar execution model

        east =
            viewIOSidebar execution model

        header =
            View.Header.view session

        modal =
            case
                History.current execution.executionSuites
                    |> .executionHistory
                    |> History.current
                    |> .exception
            of
                Just message ->
                    Just (viewExceptionModal execution model message)

                Nothing ->
                    if canStepExecution execution then
                        Nothing

                    else if isExecutionSolved execution then
                        Just (viewVictoryModal model execution)

                    else
                        Just (viewWrongOutputModal model execution)
    in
    View.Scewn.view
        { west = Just west
        , north = Just header
        , east = Just east
        , center = Just main
        , south = Nothing
        , modal = modal
        }


viewExecutionSidebar : Execution -> Model -> Element Msg
viewExecutionSidebar execution model =
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

        homeButtonView =
            viewButton ExecutionControlView.Home (Just ClickedHome)

        undoButtonView =
            viewButton ExecutionControlView.Undo (Just ClickedUndo)

        stepButtonView =
            viewButton ExecutionControlView.Step (Just ClickedStep)

        runButtonView =
            viewButton ExecutionControlView.Play (Just ClickedRun)

        fastForwardButtonView =
            viewButton ExecutionControlView.FastForward (Just ClickedFastForward)

        pauseButtonView =
            viewButton ExecutionControlView.Pause (Just ClickedPause)

        suiteView =
            let
                { passedSuites, currentSuite, futureSuites } =
                    let
                        { past, present, future } =
                            History.toPastPresentFuture execution.executionSuites
                    in
                    { passedSuites = past, currentSuite = present, futureSuites = future }

                size =
                    { left = 0, top = 0, right = 0, bottom = 0 }

                running =
                    el [ alignLeft, paddingEach { size | left = 10 } ] (image [ width (px 10) ] { src = icons.spinner, description = "Running" })

                passed =
                    el [ alignLeft, paddingEach { size | left = 10 } ] (image [ width (px 10) ] { src = icons.circle.green, description = "Passed" })

                failed =
                    el [ alignLeft, paddingEach { size | left = 10 } ] (image [ width (px 10) ] { src = icons.circle.red, description = "Failed" })

                paused =
                    el [ alignLeft, paddingEach { size | left = 10 } ] (image [ width (px 10) ] { src = icons.pause, description = "Paused" })

                passedView =
                    List.indexedMap
                        (\index suite ->
                            row
                                [ width fill
                                ]
                                [ el [ alignLeft ] (text ("Suite " ++ String.fromInt (index + 1)))
                                , passed
                                , el [ alignRight ] (text (String.fromInt (getNumberOfStepsForSuite suite)))
                                ]
                        )
                        passedSuites

                currentView =
                    row
                        [ width fill
                        ]
                        [ el [ alignLeft ] (text ("Suite " ++ String.fromInt (List.length passedSuites + 1)))
                        , if isSuiteSolved currentSuite then
                            passed

                          else if isSuiteFailed currentSuite then
                            failed

                          else if model.state == Paused then
                            paused

                          else
                            running
                        , el [ alignRight ] (text (String.fromInt (getNumberOfStepsForSuite currentSuite)))
                        ]

                futureView =
                    List.indexedMap
                        (\index _ ->
                            text ("Suite " ++ String.fromInt (index + List.length passedSuites + 2))
                        )
                        futureSuites

                totalView =
                    row
                        [ width fill
                        , Border.widthEach
                            { size | top = 2 }
                        , color.font.subtle
                        , paddingEach
                            { size | top = 6 }
                        ]
                        [ text "Total "
                        , el [ alignRight ] (text (String.fromInt (getScore execution).numberOfSteps))
                        ]
            in
            column
                [ width fill, spacing 5, padding 10, Border.width 3 ]
                (List.concat
                    [ passedView
                    , [ currentView ]
                    , futureView
                    , [ totalView ]
                    ]
                )

        executionControlInstructionsView =
            wrappedRow
                [ spacing 10
                , centerX
                ]
                [ homeButtonView
                , undoButtonView
                , stepButtonView
                , runButtonView
                , fastForwardButtonView
                , pauseButtonView
                ]
    in
    column
        [ width (px 350)
        , height fill
        , Background.color (rgb 0.08 0.08 0.08)
        , alignTop
        , padding 10
        , spacing 20
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
        , suiteView
        ]


viewBoard : Execution -> Model -> Element Msg
viewBoard execution model =
    let
        executionSuite =
            History.current execution.executionSuites

        executionStep =
            History.current executionSuite.executionHistory

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
    in
    boardView


viewExceptionModal : Execution -> Model -> String -> Element Msg
viewExceptionModal execution model exceptionMessage =
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
        , View.Box.link
            "Back to editor"
            (Route.EditDraft model.draftId)
        ]


viewWrongOutputModal : Model -> Execution -> Element Msg
viewWrongOutputModal model execution =
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
        , View.Box.link
            "Back to editor"
            (Route.EditDraft model.draftId)
        ]


viewVictoryModal : Model -> Execution -> Element Msg
viewVictoryModal model execution =
    let
        { numberOfSteps, numberOfInstructions } =
            getScore execution

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
        , View.Box.link
            "Back to levels"
            (Route.Campaign execution.level.campaignId (Just execution.level.id))
        , View.Box.link
            "Continue editing"
            (Route.EditDraft model.draftId)
        ]


viewIOSidebar : Execution -> Model -> Element Msg
viewIOSidebar execution model =
    let
        executionSuite =
            History.current execution.executionSuites

        executionStep =
            History.current executionSuite.executionHistory

        characterWidth =
            6

        maxCharacters =
            12

        paddingWidth =
            5

        borderWidth =
            3

        columnWidth =
            characterWidth * maxCharacters + paddingWidth * 2 + borderWidth * 2

        totalWidth =
            4 * columnWidth + 10 * paddingWidth

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
                        |> List.map Int16.toString
                        |> List.map
                            (\value ->
                                el
                                    [ Font.alignRight
                                    , width fill
                                    ]
                                    (text value)
                            )
                        |> column
                            [ width (px columnWidth)
                            , height fill
                            , Font.alignRight
                            , padding paddingWidth
                            , spacing 2
                            , scrollbars
                            , Border.width borderWidth
                            ]
            in
            column
                [ height fill
                , padding paddingWidth
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
                                    ( Int16.toString hb, ha == hb ) :: correct ta tb

                                ( _, [] ) ->
                                    []

                                ( [], bb ) ->
                                    List.map (\h -> ( Int16.toString h, False )) bb
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
                        |> List.map Int16.toString
                        |> List.map
                            (\value ->
                                el
                                    [ Font.alignRight
                                    , width fill
                                    ]
                                    (text value)
                            )
                        |> column
                            [ width (px columnWidth)
                            , height fill
                            , Font.alignRight
                            , padding paddingWidth
                            , spacing 2
                            , scrollbars
                            , Border.width borderWidth
                            ]

                actualView =
                    correctedActual
                        |> List.map
                            (\( value, correct ) ->
                                el
                                    [ Font.alignRight
                                    , width fill
                                    , alignRight
                                    , Background.color
                                        (if correct then
                                            rgba 0 0 0 0

                                         else
                                            rgb 0.5 0 0
                                        )
                                    ]
                                    (text value)
                            )
                        |> column
                            [ width (px columnWidth)
                            , height fill
                            , Font.alignRight
                            , padding paddingWidth
                            , spacing 2
                            , scrollbars
                            , Border.widthEach
                                { left = 0
                                , top = borderWidth
                                , right = borderWidth
                                , bottom = borderWidth
                                }
                            ]
            in
            column
                [ height fill
                , width shrink
                , padding 5
                ]
                [ labelView
                , row
                    [ height fill
                    , width shrink
                    ]
                    [ expectedView, actualView ]
                ]

        inputView =
            viewSingle "Input" executionStep.input

        stackView =
            viewSingle "Stack" executionStep.stack

        outputView =
            viewDouble "Output" executionSuite.expectedOutput executionStep.output
    in
    row
        [ width (px totalWidth)
        , height fill
        , Background.color (rgb 0.08 0.08 0.08)
        , spacing paddingWidth
        , Font.color (rgb 1 1 1)
        , padding paddingWidth
        , scrollbars
        ]
        [ inputView, stackView, outputView ]
