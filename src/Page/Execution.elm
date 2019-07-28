module Page.Execution exposing (Model, Msg, getSession, init, load, subscriptions, update, view)

import Array exposing (Array)
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Board as Board exposing (Board)
import Data.Cache as Cache
import Data.CampaignId as CampaignId
import Data.DetailedHttpError as DetailedHttpError exposing (DetailedHttpError)
import Data.Direction exposing (Direction(..))
import Data.Draft as Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.History as History exposing (History)
import Data.Input exposing (Input)
import Data.Instruction exposing (Instruction(..))
import Data.InstructionPointer exposing (InstructionPointer)
import Data.Int16 as Int16 exposing (Int16)
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.Output exposing (Output)
import Data.RemoteCache as RemoteCache
import Data.Session as Session exposing (Session)
import Data.Solution as Solution exposing (Solution)
import Data.Stack exposing (Stack)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import ExecutionControlView
import Extra.Cmd exposing (noCmd)
import InstructionView
import Maybe.Extra
import Ports.Console
import Random
import RemoteData exposing (RemoteData(..), WebData)
import Result as Http
import Route
import SessionUpdate exposing (SessionMsg(..))
import Time
import View.Box
import View.ErrorScreen
import View.Header
import View.LoadingScreen
import View.Scewn
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
    , loadedLevelId : Maybe LevelId
    , execution : Maybe Execution
    , state : ExecutionState
    }


type Msg
    = ClickedStep
    | ClickedUndo
    | ClickedRun
    | ClickedFastForward
    | ClickedPause
    | ClickedNavigateBrowseLevels
    | GeneratedSolution Solution
    | Tick
    | SessionMsg SessionMsg


init : DraftId -> Session -> ( Model, Cmd Msg )
init draftId session =
    let
        model =
            { session = session
            , draftId = draftId
            , loadedLevelId = Nothing
            , state = Paused
            , execution = Nothing
            }
    in
    ( model, Cmd.none )


load : Model -> ( Model, Cmd Msg )
load =
    let
        loadActualDraft model =
            case ( Session.getAccessToken model.session, Cache.get model.draftId model.session.drafts.actual ) of
                ( Just accessToken, NotAsked ) ->
                    ( model.session.drafts
                        |> RemoteCache.withActualLoading model.draftId
                        |> flip Session.withDraftCache model.session
                        |> flip withSession model
                    , Draft.loadFromServer accessToken (SessionMsg << GotLoadDraftByDraftIdResponse) model.draftId
                    )

                _ ->
                    noCmd model

        loadLocalDraft model =
            case Cache.get model.draftId model.session.drafts.local of
                NotAsked ->
                    if Maybe.Extra.isNothing (Session.getAccessToken model.session) || RemoteData.isFailure (Cache.get model.draftId model.session.drafts.actual) then
                        ( model.session.drafts
                            |> RemoteCache.withLocalLoading model.draftId
                            |> flip Session.withDraftCache model.session
                            |> flip withSession model
                        , Draft.loadFromLocalStorage model.draftId
                        )

                    else
                        noCmd model

                _ ->
                    noCmd model

        loadLevel model =
            case
                Cache.get model.draftId model.session.drafts.local
                    |> RemoteData.toMaybe
            of
                Just draft ->
                    case Session.getLevel draft.levelId model.session of
                        NotAsked ->
                            ( model.session
                                |> Session.levelLoading draft.levelId
                                |> flip withSession model
                            , Level.loadFromServer (SessionMsg << GotLoadLevelResponse) draft.levelId
                            )

                        _ ->
                            noCmd model

                Nothing ->
                    noCmd model

        initializeExecution model =
            case RemoteData.toMaybe (Cache.get model.draftId model.session.drafts.local) of
                Just draft ->
                    case Session.getLevel draft.levelId model.session of
                        Success level ->
                            if
                                model.loadedLevelId
                                    |> Maybe.map ((==) level.id)
                                    |> Maybe.withDefault False
                            then
                                ( model, Cmd.none )

                            else
                                ( { model
                                    | execution = Just (initialExecution level draft)
                                    , loadedLevelId = Just level.id
                                  }
                                , Cmd.none
                                )

                        _ ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )
    in
    Extra.Cmd.fold
        [ loadActualDraft
        , loadLocalDraft
        , loadLevel
        , initializeExecution
        ]


getSession : Model -> Session
getSession { session } =
    session


withSession : Session -> Model -> Model
withSession session model =
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

                ClickedNavigateBrowseLevels ->
                    let
                        levelId =
                            Cache.get model.draftId model.session.drafts.local
                                |> RemoteData.toMaybe
                                |> Maybe.map .levelId

                        campaignId =
                            levelId
                                |> Maybe.map (flip Session.getLevel model.session)
                                |> Maybe.andThen RemoteData.toMaybe
                                |> Maybe.map .campaignId
                                |> Maybe.withDefault CampaignId.standard
                    in
                    ( model, Route.pushUrl model.session.key (Route.Campaign campaignId levelId) )

                Tick ->
                    stepModel execution model

                GeneratedSolution solution ->
                    case Session.getAccessToken model.session of
                        Just accessToken ->
                            ( { model
                                | session = Session.withSolution solution model.session
                              }
                            , Cmd.batch
                                [ Solution.saveToLocalStorage solution
                                , Solution.saveToServer (SessionMsg << GotSaveSolutionResponse) accessToken solution
                                ]
                            )

                        Nothing ->
                            ( Session.withSolution solution model.session
                                |> flip withSession model
                            , Solution.saveToLocalStorage solution
                            )

                SessionMsg sessionMsg ->
                    SessionUpdate.update sessionMsg model.session
                        |> Extra.Cmd.mapModel (flip withSession model)

        Nothing ->
            ( model, Cmd.none )


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

                    initialBoard =
                        execution.executionHistory
                            |> History.first
                            |> .board

                    generateSolutionCmd =
                        Random.generate
                            GeneratedSolution
                            (Solution.generator
                                execution.level.id
                                score
                                initialBoard
                            )
                in
                ( model.session, generateSolutionCmd )

            else
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


pop : List Int16 -> ( Int16, List Int16 )
pop list =
    case list of
        head :: tail ->
            ( head, tail )

        _ ->
            ( Int16.zero, [] )


peek : List Int16 -> Int16
peek list =
    List.head list
        |> Maybe.withDefault Int16.zero


pop2 : List Int16 -> ( Int16, Int16, List Int16 )
pop2 list =
    case list of
        [] ->
            ( Int16.zero, Int16.zero, [] )

        a :: [] ->
            ( a, Int16.zero, [] )

        a :: b :: tail ->
            ( a, b, tail )


peek2 : List Int16 -> ( Int16, Int16 )
peek2 list =
    case list of
        [] ->
            ( Int16.zero, Int16.zero )

        a :: [] ->
            ( a, Int16.zero )

        a :: b :: _ ->
            ( a, b )


popOp : (Int16 -> Int16) -> Stack -> Stack
popOp operation stack =
    let
        ( a, stack1 ) =
            pop stack
    in
    operation a :: stack1


popOp2 : (Int16 -> Int16 -> Int16) -> Stack -> Stack
popOp2 operation stack =
    let
        ( a, b, stack1 ) =
            pop2 stack
    in
    operation a b :: stack1


peekOp : (Int16 -> Int16) -> Stack -> Stack
peekOp operation stack =
    operation (peek stack) :: stack


peekOp2 : (Int16 -> Int16 -> Int16) -> Stack -> Stack
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
                    if peek stack /= Int16.zero then
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
                | stack = popOp Int16.negate stack
            }

        Abs ->
            { movedExecutionStep
                | stack = popOp Int16.abs stack
            }

        Not ->
            { movedExecutionStep
                | stack =
                    popOp
                        (\a ->
                            if a == Int16.zero then
                                Int16.one

                            else
                                Int16.zero
                        )
                        stack
            }

        Increment ->
            { movedExecutionStep
                | stack = popOp (Int16.add Int16.one) stack
            }

        Decrement ->
            { movedExecutionStep
                | stack = popOp (flip Int16.subtract Int16.one) stack
            }

        Add ->
            { movedExecutionStep
                | stack = popOp2 Int16.add stack
            }

        Subtract ->
            { movedExecutionStep
                | stack = popOp2 Int16.subtract stack
            }

        Multiply ->
            { movedExecutionStep
                | stack = popOp2 Int16.multiply stack
            }

        Divide ->
            { movedExecutionStep
                | stack = popOp2 Int16.divide stack
            }

        Equals ->
            { movedExecutionStep
                | stack =
                    popOp2
                        (\a b ->
                            if a == b then
                                Int16.one

                            else
                                Int16.zero
                        )
                        stack
            }

        CompareLessThan ->
            { movedExecutionStep
                | stack =
                    peekOp2
                        (\a b ->
                            if Int16.isLessThan a b then
                                Int16.one

                            else
                                Int16.zero
                        )
                        stack
            }

        And ->
            { movedExecutionStep
                | stack =
                    popOp2
                        (\a b ->
                            if a /= Int16.zero && b /= Int16.zero then
                                Int16.one

                            else
                                Int16.zero
                        )
                        stack
            }

        Or ->
            { movedExecutionStep
                | stack =
                    popOp2
                        (\a b ->
                            if a /= Int16.zero || b /= Int16.zero then
                                Int16.one

                            else
                                Int16.zero
                        )
                        stack
            }

        XOr ->
            { movedExecutionStep
                | stack =
                    popOp2
                        (\a b ->
                            if (a /= Int16.zero) /= (b /= Int16.zero) then
                                Int16.one

                            else
                                Int16.zero
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
            case Cache.get model.draftId model.session.drafts.local of
                NotAsked ->
                    View.ErrorScreen.view ("Draft " ++ model.draftId ++ " not asked :/")

                Loading ->
                    View.LoadingScreen.view ("Loading draft " ++ model.draftId)

                Failure error ->
                    let
                        errorMessage =
                            case error of
                                DetailedHttpError.NotFound ->
                                    "Draft " ++ model.draftId ++ " not found"

                                _ ->
                                    DetailedHttpError.toString error
                    in
                    View.ErrorScreen.view errorMessage

                Success draft ->
                    case Session.getLevel draft.levelId model.session of
                        NotAsked ->
                            View.ErrorScreen.view ("Level " ++ draft.levelId ++ " not asked :/")

                        Loading ->
                            View.LoadingScreen.view ("Loading level " ++ draft.levelId)

                        Failure error ->
                            View.ErrorScreen.view (DetailedHttpError.toString error)

                        Success _ ->
                            case model.execution of
                                Just execution ->
                                    viewLoaded execution model

                                Nothing ->
                                    View.LoadingScreen.view "Initializing execution"

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
        main =
            viewBoard execution model

        west =
            viewExecutionSidebar execution model

        east =
            viewIOSidebar execution model

        header =
            View.Header.view model.session

        modal =
            case getExceptionMessage execution of
                Just message ->
                    Just (viewExceptionModal execution model message)

                Nothing ->
                    if isSolved execution then
                        Just (viewVictoryModal execution)

                    else if History.current execution.executionHistory |> .terminated then
                        Just (viewWrongOutputModal model execution)

                    else
                        Nothing
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


viewVictoryModal : Execution -> Element Msg
viewVictoryModal execution =
    let
        numberOfSteps =
            execution.executionHistory
                |> History.current
                |> .stepCount

        numberOfInitialInstructions =
            execution.level
                |> .initialBoard
                |> Board.count ((/=) NoOp)

        numberOfInstructions =
            History.first execution.executionHistory
                |> .board
                |> Board.count ((/=) NoOp)
                |> flip (-) numberOfInitialInstructions

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
            viewDouble "Output" execution.level.io.output executionStep.output
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


getExceptionMessage : Execution -> Maybe String
getExceptionMessage execution =
    execution.executionHistory
        |> History.current
        |> .exception
