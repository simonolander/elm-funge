module Page.Execution.Update exposing
    ( canStepExecution
    , getNumberOfStepsForSuite
    , getScore
    , isExecutionSolved
    , isSuiteFailed
    , isSuiteSolved
    , load
    , update
    )

import Basics.Extra exposing (flip)
import Data.Board as Board exposing (Board)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater)
import Data.Direction exposing (Direction(..))
import Data.Draft exposing (Draft)
import Data.History as History
import Data.Input exposing (Input)
import Data.Instruction exposing (Instruction(..))
import Data.Int16 as Int16 exposing (Int16)
import Data.Level exposing (Level)
import Data.Score exposing (Score)
import Data.Session exposing (Session)
import Data.Solution as Solution
import Data.Stack exposing (Stack)
import Data.Suite as Suite
import Dict
import Maybe.Extra
import Page.Execution.Model exposing (Execution, ExecutionState(..), ExecutionStep, ExecutionSuite, Model)
import Page.Execution.Msg exposing (Msg(..))
import Random
import RemoteData
import Service.Draft.DraftService exposing (getDraftByDraftId, loadDraftByDraftId)
import Service.Level.LevelService exposing (getLevelByLevelId, loadLevelByLevelId)
import Update.SessionMsg exposing (SessionMsg(..))


load : CmdUpdater ( Session, Model ) SessionMsg
load =
    let
        loadDraft ( session, model ) =
            loadDraftByDraftId model.draftId session
                |> CmdUpdater.withModel model

        loadLevel ( session, model ) =
            getDraftByDraftId model.draftId session
                |> RemoteData.toMaybe
                |> Maybe.Extra.join
                |> Maybe.map .levelId
                |> Maybe.map (flip loadLevelByLevelId session)
                |> Maybe.withDefault ( session, Cmd.none )
                |> CmdUpdater.withModel model

        initializeExecution ( session, model ) =
            let
                maybeDraft =
                    getDraftByDraftId model.draftId session
                        |> RemoteData.toMaybe
                        |> Maybe.Extra.join

                maybeLevel =
                    getDraftByDraftId model.draftId session
                        |> RemoteData.toMaybe
                        |> Maybe.Extra.join
                        |> Maybe.map .levelId
                        |> Maybe.map (flip getLevelByLevelId session)
                        |> Maybe.andThen RemoteData.toMaybe
                        |> Maybe.Extra.join
            in
            case Maybe.map2 Tuple.pair maybeDraft maybeLevel of
                Just ( draft, level ) ->
                    if
                        model.loadedLevelId
                            |> Maybe.map ((==) level.id)
                            |> Maybe.withDefault False
                    then
                        ( ( session, model ), Cmd.none )

                    else
                        ( ( session
                          , { model
                                | execution = Just (initialExecution level draft)
                                , loadedLevelId = Just level.id
                            }
                          )
                        , Cmd.none
                        )

                Nothing ->
                    ( ( session, model ), Cmd.none )
    in
    CmdUpdater.batch
        [ loadDraft
        , loadLevel
        , initializeExecution
        ]


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


update : Msg -> CmdUpdater ( Session, Model ) SessionMsg
update msg ( session, model ) =
    CmdUpdater.withSession session <|
        case
            model.execution
        of
            Just execution ->
                case msg of
                    ClickedStep ->
                        { model | state = Paused }
                            |> stepModel execution session

                    ClickedUndo ->
                        ( { model
                            | execution = Just (undoExecution execution)
                            , state = Paused
                          }
                        , Cmd.none
                        )

                    ClickedRun ->
                        { model | state = Running }
                            |> stepModel execution session

                    ClickedFastForward ->
                        { model | state = FastForwarding }
                            |> stepModel execution session

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

                    Tick ->
                        stepModel execution session model

            Nothing ->
                ( model, Cmd.none )


stepModel : Execution -> Session -> CmdUpdater Model Msg
stepModel oldExecution session model =
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
                    session.solutions.local
                        |> Dict.values
                        |> List.filterMap Maybe.Extra.join
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
                    GeneratedSolution
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
