module Page.Execution exposing (Model, Msg(..), init, load, subscriptions, update, view)

import ApplicationName exposing (applicationName)
import Array exposing (Array)
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Browser.Events
import Data.Board as Board exposing (Board)
import Data.Cache as Cache
import Data.CampaignId as CampaignId
import Data.Direction exposing (Direction(..))
import Data.Draft as Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.GetError as GetError exposing (GetError)
import Data.HighScore as HighScore
import Data.History as History exposing (History)
import Data.Input exposing (Input)
import Data.Instruction exposing (Instruction(..))
import Data.InstructionPointer exposing (InstructionPointer)
import Data.Int16 as Int16 exposing (Int16)
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.Output exposing (Output)
import Data.RemoteCache as RemoteCache
import Data.Score exposing (Score)
import Data.Session as Session exposing (Session)
import Data.Solution as Solution exposing (Solution)
import Data.SolutionBook as SolutionBook
import Data.Stack exposing (Stack)
import Data.Suite as Suite exposing (Suite)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import ExecutionControlView
import Extra.Cmd exposing (noCmd, withCmd, withExtraCmd)
import InstructionView
import Json.Decode as Decoder
import Maybe.Extra
import Random
import RemoteData exposing (RemoteData(..), WebData)
import Route
import SessionUpdate exposing (SessionMsg(..))
import Time
import View.Box
import View.Constant exposing (color, icons)
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


type alias ExecutionSuite =
    { executionHistory : History ExecutionStep
    , expectedOutput : Output
    }


type alias Execution =
    { executionSuites : History ExecutionSuite
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
    = InternalMsg InternalMsg
    | SessionMsg SessionMsg


type InternalMsg
    = ClickedStep
    | ClickedUndo
    | ClickedRun
    | ClickedFastForward
    | ClickedPause
    | ClickedHome
    | ClickedNavigateBrowseLevels
    | ClickedContinueEditing
    | GeneratedSolution Solution
    | Tick


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
                    , Draft.loadFromServer (SessionMsg << GotLoadDraftByDraftIdResponse model.draftId) accessToken model.draftId
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
                    |> Maybe.Extra.join
            of
                Just draft ->
                    case Cache.get draft.levelId model.session.levels of
                        NotAsked ->
                            ( model.session.levels
                                |> Cache.loading draft.levelId
                                |> flip Session.withLevelCache model.session
                                |> flip withSession model
                            , Level.loadFromServer (SessionMsg << GotLoadLevelByLevelIdResponse draft.levelId) draft.levelId
                            )

                        _ ->
                            noCmd model

                Nothing ->
                    noCmd model

        initializeExecution model =
            case
                model.session.drafts.local
                    |> Cache.get model.draftId
                    |> RemoteData.toMaybe
                    |> Maybe.Extra.join
            of
                Just draft ->
                    case Cache.get draft.levelId model.session.levels of
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

        executionSuite suite =
            { executionHistory = History.singleton (initialExecutionStep board suite.input)
            , expectedOutput = suite.output
            }

        suites =
            History.fromList level.suites
                |> Maybe.withDefault (History.singleton Suite.empty)
                |> History.map executionSuite
    in
    { level = level
    , executionSuites = suites
    }


isExecutionSolved : Execution -> Bool
isExecutionSolved execution =
    History.toList execution.executionSuites
        |> List.all isSuiteSolved


getNumberOfStepsForSuite : ExecutionSuite -> Int
getNumberOfStepsForSuite suite =
    History.current suite.executionHistory
        |> .stepCount


getScore : Execution -> Score
getScore execution =
    let
        numberOfSteps =
            execution.executionSuites
                |> History.toList
                |> List.map getNumberOfStepsForSuite
                |> List.sum

        initialNumberOfInstructions =
            Board.count ((/=) NoOp) execution.level.initialBoard

        totalNumberOfInstructions =
            History.current execution.executionSuites
                |> .executionHistory
                |> History.first
                |> .board
                |> Board.count ((/=) NoOp)

        numberOfInstructions =
            totalNumberOfInstructions - initialNumberOfInstructions

        score =
            { numberOfSteps = numberOfSteps
            , numberOfInstructions = numberOfInstructions
            }
    in
    score



-- UPDATE


update : InternalMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case
        model.execution
    of
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

                ClickedHome ->
                    let
                        newExecution =
                            { execution
                                | executionSuites =
                                    History.update
                                        (\suite ->
                                            { suite
                                                | executionHistory = History.toBeginning suite.executionHistory
                                            }
                                        )
                                        execution.executionSuites
                            }
                    in
                    ( { model
                        | execution = Just newExecution
                        , state = Paused
                      }
                    , Cmd.none
                    )

                ClickedContinueEditing ->
                    ( model, Route.pushUrl model.session.key (Route.EditDraft model.draftId) )

                ClickedNavigateBrowseLevels ->
                    let
                        levelId =
                            Cache.get model.draftId model.session.drafts.local
                                |> RemoteData.toMaybe
                                |> Maybe.Extra.join
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
                    let
                        solutionCache =
                            RemoteCache.withLocalValue solution.id (Just solution) model.session.solutions

                        solutionBookCache =
                            Cache.get solution.levelId model.session.solutionBooks
                                |> RemoteData.withDefault (SolutionBook.empty solution.levelId)
                                |> SolutionBook.withSolutionId solution.id
                                |> flip (Cache.withValue solution.levelId) model.session.solutionBooks

                        highScoreCache =
                            Cache.update
                                solution.levelId
                                (RemoteData.withDefault (HighScore.empty solution.levelId) >> HighScore.withScore solution.score >> RemoteData.Success)
                                model.session.highScores

                        modelWithSolution =
                            model.session
                                |> Session.withSolutionBookCache solutionBookCache
                                |> Session.withSolutionCache solutionCache
                                |> Session.withHighScoreCache highScoreCache
                                |> flip withSession model
                    in
                    case Session.getAccessToken model.session of
                        Just accessToken ->
                            modelWithSolution
                                |> withCmd (Solution.saveToLocalStorage solution)
                                |> withExtraCmd (Solution.saveToServer (SessionMsg << GotSaveSolutionResponse solution) accessToken solution)

                        Nothing ->
                            ( modelWithSolution
                            , Solution.saveToLocalStorage solution
                            )

        Nothing ->
            ( model, Cmd.none )


stepModel : Execution -> Model -> ( Model, Cmd Msg )
stepModel oldExecution model =
    let
        ( execution, state ) =
            if canStepExecution oldExecution then
                ( stepExecution oldExecution, model.state )

            else
                ( oldExecution, Paused )

        generateSolutionCmd =
            let
                initialBoard =
                    History.current execution.executionSuites
                        |> .executionHistory
                        |> History.first
                        |> .board

                isNewSolution board =
                    model.session.solutions.local
                        |> Cache.values
                        |> List.filterMap (RemoteData.toMaybe >> Maybe.Extra.join)
                        |> List.filter (.levelId >> (==) execution.level.id)
                        |> List.any (.board >> (==) board)
                        |> not
            in
            if isExecutionSolved execution && isNewSolution initialBoard then
                let
                    score =
                        getScore execution
                in
                Random.generate
                    (InternalMsg << GeneratedSolution)
                    (Solution.generator
                        execution.level.id
                        score
                        initialBoard
                    )

            else
                Cmd.none

        newModel =
            { model
                | execution = Just execution
                , state = state
            }

        cmd =
            generateSolutionCmd
    in
    ( newModel
    , cmd
    )


undoExecution : Execution -> Execution
undoExecution execution =
    let
        undoSuite suite =
            { suite | executionHistory = History.back suite.executionHistory }
    in
    { execution
        | executionSuites = History.update undoSuite execution.executionSuites
    }


isOutputCorrect : ExecutionSuite -> Bool
isOutputCorrect suite =
    History.current suite.executionHistory
        |> .output
        |> List.reverse
        |> (==) suite.expectedOutput


isTerminated : ExecutionSuite -> Bool
isTerminated suite =
    History.current suite.executionHistory
        |> .terminated


hasException : ExecutionSuite -> Bool
hasException suite =
    History.current suite.executionHistory
        |> .exception
        |> Maybe.Extra.isJust


isSuiteFailed : ExecutionSuite -> Bool
isSuiteFailed suite =
    hasException suite || (isTerminated suite && (not << isOutputCorrect) suite)


isSuiteSolved : ExecutionSuite -> Bool
isSuiteSolved suite =
    isTerminated suite && (not << isSuiteFailed) suite


hasNextSuite : Execution -> Bool
hasNextSuite =
    .executionSuites >> History.hasFuture


canStepSuite : ExecutionSuite -> Bool
canStepSuite suite =
    (not << isTerminated) suite && (not << hasException) suite


canStepExecution : Execution -> Bool
canStepExecution execution =
    let
        suite =
            History.current execution.executionSuites
    in
    canStepSuite suite || (hasNextSuite execution && isSuiteSolved suite)


stepSuite : ExecutionSuite -> ExecutionSuite
stepSuite executionSuite =
    let
        nextExecutionStep =
            History.current executionSuite.executionHistory
                |> stepExecutionStep
    in
    { executionSuite | executionHistory = History.push nextExecutionStep executionSuite.executionHistory }


stepExecution : Execution -> Execution
stepExecution execution =
    let
        suite =
            History.current execution.executionSuites
    in
    if canStepSuite suite then
        { execution | executionSuites = History.update stepSuite execution.executionSuites }

    else if isSuiteSolved suite then
        { execution | executionSuites = History.forward execution.executionSuites }

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
                Time.every 250 (always (InternalMsg Tick))

            FastForwarding ->
                Browser.Events.onAnimationFrame (always (InternalMsg Tick))

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
                    case Cache.get model.draftId model.session.drafts.actual of
                        Loading ->
                            View.LoadingScreen.view ("Loading draft " ++ model.draftId ++ " from server")

                        _ ->
                            View.ErrorScreen.view ("Draft " ++ model.draftId ++ " not asked :/")

                Loading ->
                    View.LoadingScreen.view ("Loading draft " ++ model.draftId ++ " from local storage")

                Failure error ->
                    View.ErrorScreen.view (Decoder.errorToString error)

                Success Nothing ->
                    View.ErrorScreen.view ("Draft " ++ model.draftId ++ " not found")

                Success (Just draft) ->
                    case Session.getLevel draft.levelId model.session of
                        NotAsked ->
                            View.ErrorScreen.view ("Level " ++ draft.levelId ++ " not asked :/")

                        Loading ->
                            View.LoadingScreen.view ("Loading level " ++ draft.levelId)

                        Failure error ->
                            View.ErrorScreen.view (GetError.toString error)

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
    { title = String.concat [ "Execution", " - ", applicationName ]
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
                        Just (viewVictoryModal execution)

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
            viewButton ExecutionControlView.Home (Just (InternalMsg ClickedHome))

        undoButtonView =
            viewButton ExecutionControlView.Undo (Just (InternalMsg ClickedUndo))

        stepButtonView =
            viewButton ExecutionControlView.Step (Just (InternalMsg ClickedStep))

        runButtonView =
            viewButton ExecutionControlView.Play (Just (InternalMsg ClickedRun))

        fastForwardButtonView =
            viewButton ExecutionControlView.FastForward (Just (InternalMsg ClickedFastForward))

        pauseButtonView =
            viewButton ExecutionControlView.Pause (Just (InternalMsg ClickedPause))

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
                        , Border.color color.font.subtle
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


viewVictoryModal : Execution -> Element Msg
viewVictoryModal execution =
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
        , Input.button
            [ width fill
            , Border.width 4
            , Border.color (rgb 1 1 1)
            , padding 10
            , mouseOver [ Background.color (rgba 1 1 1 0.5) ]
            ]
            { onPress = Just (InternalMsg ClickedNavigateBrowseLevels)
            , label =
                el [ centerX, centerY ] (text "Back to levels")
            }
        , Input.button
            [ width fill
            , Border.width 4
            , Border.color (rgb 1 1 1)
            , padding 10
            , mouseOver [ Background.color (rgba 1 1 1 0.5) ]
            ]
            { onPress = Just (InternalMsg ClickedContinueEditing)
            , label =
                el [ centerX, centerY ] (text "Continue editing")
            }
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
