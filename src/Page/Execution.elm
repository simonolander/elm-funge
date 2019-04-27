module Page.Execution exposing (Model, Msg, getSession, init, localStorageResponseUpdate, subscriptions, update, view)

import Array exposing (Array)
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Board as Board exposing (Board)
import Data.CampaignId as CampaignId
import Data.Direction exposing (Direction(..))
import Data.Draft as Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.History as History exposing (History)
import Data.Input exposing (Input)
import Data.Instruction exposing (Instruction(..))
import Data.InstructionPointer exposing (InstructionPointer)
import Data.Level as Level exposing (Level)
import Data.Output exposing (Output)
import Data.Session as Session exposing (Session)
import Data.Stack exposing (Stack)
import Dict
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import ExecutionControlView
import Html.Attributes
import InstructionView
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Ports.LocalStorage
import Route
import Time
import View.LoadingScreen
import ViewComponents



-- MODEL


type alias ExecutionStep =
    { board : Board
    , instructionPointer : InstructionPointer
    , stack : Stack
    , input : Input
    , output : Output
    , terminated : Bool
    , exception : Maybe String
    , stepCount : Int
    }


type alias Execution =
    { executionHistory : History ExecutionStep
    , level : Level
    }


type ExecutionState
    = Paused
    | Running
    | FastForwarding


type alias Model =
    { session : Session
    , draftId : DraftId
    , execution : Maybe Execution
    , state : ExecutionState
    , error : Maybe String
    }


init : DraftId -> Session -> ( Model, Cmd Msg )
init draftId session =
    let
        model =
            { session = session
            , draftId = draftId
            , state = Paused
            , execution = Nothing
            , error = Nothing
            }
    in
    case Dict.get draftId session.drafts of
        Just draft ->
            case Dict.get draft.levelId session.levels of
                Just level ->
                    ( { model | execution = Just (initialExecution level draft) }
                    , Cmd.none
                    )

                Nothing ->
                    ( model
                    , Level.loadFromLocalStorage draft.levelId
                    )

        Nothing ->
            ( model
            , Draft.loadFromLocalStorage draftId
            )


getSession : Model -> Session
getSession { session } =
    session


setSession : Model -> Session -> Model
setSession model session =
    { model | session = session }


initialExecutionStep : Board -> Input -> ExecutionStep
initialExecutionStep board input =
    { board = board
    , instructionPointer =
        { position = { x = 0, y = 0 }
        , direction = Right
        }
    , stack = []
    , input = input
    , output = []
    , terminated = False
    , exception = Nothing
    , stepCount = 0
    }


initialExecution : Level -> Draft -> Execution
initialExecution level draft =
    let
        board =
            History.current draft.boardHistory

        input =
            level.io.input

        executionHistory =
            initialExecutionStep board input
                |> History.singleton
    in
    { level = level
    , executionHistory = executionHistory
    }


isSolved : Execution -> Bool
isSolved execution =
    let
        executionStep =
            History.current execution.executionHistory

        hasException =
            Maybe.Extra.isJust executionStep.exception

        isTerminated =
            executionStep.terminated

        isOutputCorrect =
            List.reverse executionStep.output == execution.level.io.output
    in
    isTerminated && not hasException && isOutputCorrect



-- UPDATE


type Msg
    = ClickedStep
    | ClickedUndo
    | ClickedRun
    | ClickedFastForward
    | ClickedPause
    | ClickedNavigateBack
    | ClickedNavigateBrowseLevels
    | Tick


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.execution of
        Just execution ->
            case msg of
                ClickedStep ->
                    { model | state = Paused }
                        |> stepModel execution

                ClickedUndo ->
                    ( { model
                        | execution = Just (undoExecution execution)
                        , state = Paused
                      }
                    , Cmd.none
                    )

                ClickedRun ->
                    { model | state = Running }
                        |> stepModel execution

                ClickedFastForward ->
                    { model | state = FastForwarding }
                        |> stepModel execution

                ClickedPause ->
                    ( { model | state = Paused }, Cmd.none )

                ClickedNavigateBack ->
                    ( model, Route.back model.session.key )

                ClickedNavigateBrowseLevels ->
                    let
                        levelId =
                            Dict.get model.draftId model.session.drafts
                                |> Maybe.map .levelId

                        level =
                            Maybe.andThen (flip Dict.get model.session.levels) levelId

                        campaignId =
                            Maybe.map .campaignId level
                                |> Maybe.withDefault CampaignId.standard
                    in
                    ( model, Route.pushUrl model.session.key (Route.Campaign campaignId levelId) )

                Tick ->
                    stepModel execution model

        Nothing ->
            ( model, Cmd.none )


localStorageResponseUpdate : ( String, Encode.Value ) -> Model -> ( Model, Cmd Msg )
localStorageResponseUpdate ( key, value ) model =
    let
        session =
            getSession model

        onDraft result =
            case result of
                Ok (Just draft) ->
                    let
                        modelWithDraft =
                            Session.withDraft draft session
                                |> setSession model
                    in
                    case Dict.get draft.levelId session.levels of
                        Just level ->
                            ( { modelWithDraft
                                | execution = Just (initialExecution level draft)
                              }
                            , Cmd.none
                            )

                        Nothing ->
                            ( modelWithDraft, Level.loadFromLocalStorage draft.levelId )

                Ok Nothing ->
                    ( { model | error = Just ("Draft not found: " ++ key) }, Cmd.none )

                Err error ->
                    ( { model | error = Just (Decode.errorToString error) }, Cmd.none )

        onLevel result =
            case result of
                Ok (Just level) ->
                    let
                        modelWithLevel =
                            Session.withLevel level session
                                |> setSession model
                    in
                    case Dict.get model.draftId session.drafts of
                        Just draft ->
                            ( { modelWithLevel
                                | execution = Just (initialExecution level draft)
                              }
                            , Cmd.none
                            )

                        Nothing ->
                            ( modelWithLevel, Cmd.none )

                Ok Nothing ->
                    ( { model | error = Just ("Level not found: " ++ key) }, Cmd.none )

                Err error ->
                    ( { model | error = Just (Decode.errorToString error) }, Cmd.none )
    in
    ( key, value )
        |> Ports.LocalStorage.oneOf
            [ Draft.localStorageResponse onDraft
            , Level.localStorageResponse onLevel
            ]
        |> Maybe.withDefault ( model, Cmd.none )


stepModel : Execution -> Model -> ( Model, Cmd Msg )
stepModel oldExecution model =
    let
        execution =
            stepExecution oldExecution

        state =
            if canStepExecution execution then
                model.state

            else
                Paused

        ( session, saveDraftCmd ) =
            case Dict.get model.draftId model.session.drafts of
                Just oldDraft ->
                    if isSolved execution then
                        let
                            numberOfSteps =
                                History.current execution.executionHistory
                                    |> .stepCount

                            initialNumberOfInstructions =
                                Board.count ((/=) NoOp) execution.level.initialBoard

                            totalNumberOfInstructions =
                                History.first execution.executionHistory
                                    |> .board
                                    |> Board.count ((/=) NoOp)

                            numberOfInstructions =
                                totalNumberOfInstructions - initialNumberOfInstructions

                            score =
                                { numberOfSteps = numberOfSteps
                                , numberOfInstructions = numberOfInstructions
                                }

                            newDraft =
                                { oldDraft | maybeScore = Just score }

                            newSession =
                                Session.withDraft newDraft model.session
                        in
                        ( newSession, Draft.saveToLocalStorage newDraft )

                    else
                        ( model.session, Cmd.none )

                Nothing ->
                    ( model.session, Cmd.none )

        newModel =
            { model
                | session = session
                , execution = Just execution
                , state = state
            }

        cmd =
            saveDraftCmd
    in
    ( newModel
    , cmd
    )


canStepExecution : Execution -> Bool
canStepExecution execution =
    let
        step =
            History.current execution.executionHistory
    in
    not step.terminated && Maybe.Extra.isNothing step.exception


undoExecution : Execution -> Execution
undoExecution execution =
    { execution
        | executionHistory = History.back execution.executionHistory
    }


stepExecution : Execution -> Execution
stepExecution execution =
    if canStepExecution execution then
        { execution
            | executionHistory =
                execution.executionHistory
                    |> History.current
                    |> stepExecutionStep
                    |> History.pushflip execution.executionHistory
        }

    else
        execution


pop : List Int -> ( Int, List Int )
pop list =
    case list of
        head :: tail ->
            ( head, tail )

        _ ->
            ( 0, [] )


peek : List Int -> Int
peek list =
    List.head list
        |> Maybe.withDefault 0


pop2 : List Int -> ( Int, Int, List Int )
pop2 list =
    case list of
        a :: b :: tail ->
            ( a, b, tail )

        a :: [] ->
            ( a, 0, [] )

        [] ->
            ( 0, 0, [] )


peek2 : List Int -> ( Int, Int )
peek2 list =
    case list of
        a :: b :: _ ->
            ( a, b )

        a :: [] ->
            ( a, 0 )

        [] ->
            ( 0, 0 )


popOp : (Int -> Int) -> Stack -> Stack
popOp operation stack =
    let
        ( a, stack1 ) =
            pop stack
    in
    operation a :: stack1


popOp2 : (Int -> Int -> Int) -> Stack -> Stack
popOp2 operation stack =
    let
        ( a, b, stack1 ) =
            pop2 stack
    in
    operation a b :: stack1


peekOp : (Int -> Int) -> Stack -> Stack
peekOp operation stack =
    operation (peek stack) :: stack


peekOp2 : (Int -> Int -> Int) -> Stack -> Stack
peekOp2 operation stack =
    let
        ( a, b ) =
            peek2 stack
    in
    operation a b :: stack


stepExecutionStep : ExecutionStep -> ExecutionStep
stepExecutionStep executionStep =
    let
        instructionPointer =
            executionStep.instructionPointer

        position =
            instructionPointer.position

        direction =
            instructionPointer.direction

        board =
            executionStep.board

        stack =
            executionStep.stack

        input =
            executionStep.input

        output =
            executionStep.output

        instruction =
            Board.get position board
                |> Maybe.withDefault NoOp

        boardWidth =
            Board.width board

        boardHeight =
            Board.height board

        moveInstructionPointer newDirection pointer =
            let
                oldPosition =
                    pointer.position

                newPosition =
                    case newDirection of
                        Left ->
                            { oldPosition | x = modBy boardWidth (oldPosition.x - 1) }

                        Up ->
                            { oldPosition | y = modBy boardWidth (oldPosition.y - 1) }

                        Right ->
                            { oldPosition | x = modBy boardWidth (oldPosition.x + 1) }

                        Down ->
                            { oldPosition | y = modBy boardWidth (oldPosition.y + 1) }
            in
            { position = newPosition
            , direction = newDirection
            }

        incrementedExecutionStep =
            { executionStep
                | stepCount = executionStep.stepCount + 1
            }

        movedExecutionStep =
            { incrementedExecutionStep
                | instructionPointer = moveInstructionPointer direction instructionPointer
            }
    in
    case instruction of
        ChangeDirection newDirection ->
            { incrementedExecutionStep
                | instructionPointer = moveInstructionPointer newDirection instructionPointer
            }

        Branch trueDirection falseDirection ->
            let
                newDirection =
                    if peek stack /= 0 then
                        trueDirection

                    else
                        falseDirection

                newInstructionPointer =
                    moveInstructionPointer newDirection instructionPointer
            in
            { incrementedExecutionStep
                | instructionPointer = newInstructionPointer
            }

        Read ->
            let
                ( value, newInput ) =
                    pop input
            in
            { movedExecutionStep
                | stack = value :: stack
                , input = newInput
            }

        Print ->
            { movedExecutionStep
                | output = peek stack :: output
            }

        PushToStack number ->
            { movedExecutionStep
                | stack = number :: stack
            }

        PopFromStack ->
            { movedExecutionStep
                | stack =
                    stack
                        |> pop
                        |> Tuple.second
            }

        Duplicate ->
            { movedExecutionStep
                | stack = peek stack :: stack
            }

        Swap ->
            let
                ( a, b, stack1 ) =
                    pop2 stack
            in
            { movedExecutionStep
                | stack = b :: a :: stack1
            }

        Negate ->
            { movedExecutionStep
                | stack = popOp negate stack
            }

        Abs ->
            { movedExecutionStep
                | stack = popOp abs stack
            }

        Not ->
            { movedExecutionStep
                | stack =
                    popOp
                        (\a ->
                            if a == 0 then
                                1

                            else
                                0
                        )
                        stack
            }

        Increment ->
            { movedExecutionStep
                | stack = popOp ((+) 1) stack
            }

        Decrement ->
            { movedExecutionStep
                | stack = popOp (\value -> value - 1) stack
            }

        Add ->
            { movedExecutionStep
                | stack = popOp2 (+) stack
            }

        Subtract ->
            { movedExecutionStep
                | stack = popOp2 (-) stack
            }

        Multiply ->
            { movedExecutionStep
                | stack = popOp2 (*) stack
            }

        Divide ->
            { movedExecutionStep
                | stack = popOp2 (//) stack
            }

        Equals ->
            { movedExecutionStep
                | stack =
                    popOp2
                        (\a b ->
                            if a == b then
                                1

                            else
                                0
                        )
                        stack
            }

        CompareLessThan ->
            { movedExecutionStep
                | stack =
                    peekOp2
                        (\a b ->
                            if a < b then
                                1

                            else
                                0
                        )
                        stack
            }

        And ->
            { movedExecutionStep
                | stack =
                    popOp2
                        (\a b ->
                            if a /= 0 && b /= 0 then
                                1

                            else
                                0
                        )
                        stack
            }

        Or ->
            { movedExecutionStep
                | stack =
                    popOp2
                        (\a b ->
                            if a /= 0 || b /= 0 then
                                1

                            else
                                0
                        )
                        stack
            }

        XOr ->
            { movedExecutionStep
                | stack =
                    popOp2
                        (\a b ->
                            if (a /= 0) /= (b /= 0) then
                                1

                            else
                                0
                        )
                        stack
            }

        NoOp ->
            movedExecutionStep

        Terminate ->
            { incrementedExecutionStep | terminated = True }

        Exception message ->
            { incrementedExecutionStep | exception = Just message }

        JumpForward ->
            { incrementedExecutionStep
                | instructionPointer =
                    instructionPointer
                        |> moveInstructionPointer direction
                        |> moveInstructionPointer direction
            }

        SendToBottom ->
            let
                ( value, tempStack ) =
                    pop stack

                newStack =
                    tempStack ++ [ value ]
            in
            { movedExecutionStep
                | stack = newStack
            }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    if Maybe.Extra.isJust model.execution then
        case model.state of
            Paused ->
                Sub.none

            Running ->
                Time.every 250 (always Tick)

            FastForwarding ->
                Time.every 100 (always Tick)

    else
        Sub.none



-- VIEW


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


view : Model -> Document Msg
view model =
    let
        content =
            case model.error of
                Just error ->
                    View.LoadingScreen.view error

                Nothing ->
                    case model.execution of
                        Just execution ->
                            viewLoaded execution model

                        Nothing ->
                            View.LoadingScreen.view "Loading..."

        body =
            layout
                [ height fill
                , clip
                , Font.family [ Font.monospace ]
                , Font.color (rgb 1 1 1)
                ]
                content
                |> List.singleton
    in
    { title = "Executing"
    , body = body
    }


viewLoaded : Execution -> Model -> Element Msg
viewLoaded execution model =
    let
        boardView =
            viewBoard execution model

        executionSideBarView =
            viewExecutionSidebar execution model

        ioSidebarView =
            viewIOSidebar execution model

        content =
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
    in
    content


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

        backButtonView =
            ViewComponents.textButton []
                (Just ClickedNavigateBack)
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
            viewButton ExecutionControlView.Undo (Just ClickedUndo)

        stepButtonView =
            viewButton ExecutionControlView.Step (Just ClickedStep)

        runButtonView =
            viewButton ExecutionControlView.Play (Just ClickedRun)

        fastForwardButtonView =
            viewButton ExecutionControlView.FastForward (Just ClickedFastForward)

        pauseButtonView =
            viewButton ExecutionControlView.Pause (Just ClickedPause)

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


viewBoard : Execution -> Model -> Element Msg
viewBoard execution model =
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
                            , inFront (viewExceptionModal execution model message)
                            ]

                Nothing ->
                    if isSolved execution then
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
        , ViewComponents.textButton
            [ Background.color (rgb 0 0 0)
            , Font.color (rgb 1 1 1)
            ]
            (Just ClickedNavigateBack)
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
            (Just ClickedNavigateBack)
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
                |> Board.count ((/=) NoOp)

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
            { onPress = Just ClickedNavigateBrowseLevels
            , label =
                el [ centerX, centerY ] (text "Back to levels")
            }
        ]


viewIOSidebar : Execution -> Model -> Element Msg
viewIOSidebar execution model =
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
