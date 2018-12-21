module ExecutionUtils exposing (initialExecution, initialExecutionStep, update)

import BoardUtils
import History
import Model exposing (..)


update : ExecutionMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.gameState of
        Executing executionState ->
            case executionState of
                ExecutionPaused execution ->
                    case msg of
                        ExecutionStepOne ->
                            ( { model | gameState = Executing (ExecutionPaused (step execution)) }
                            , Cmd.none
                            )

                        ExecutionUndo ->
                            ( { model | gameState = Executing (ExecutionPaused (stepBack execution)) }
                            , Cmd.none
                            )

                        ExecutionPause ->
                            ( model, Cmd.none )

                        ExecutionRun ->
                            ( { model | gameState = Executing (ExecutionRunning execution 250) }
                            , Cmd.none
                            )

                        ExecutionBackClicked ->
                            ( { model | gameState = Sketching execution.level.id }
                            , Cmd.none
                            )

                        ExecutionBackToBrowsingLevels ->
                            ( { model | gameState = BrowsingLevels }
                            , Cmd.none
                            )

                ExecutionRunning execution delay ->
                    case msg of
                        ExecutionStepOne ->
                            let
                                executionStep =
                                    History.current execution.executionHistory
                            in
                            ( { model
                                | gameState =
                                    if executionStep.terminated then
                                        Executing (ExecutionPaused execution)

                                    else
                                        Executing (ExecutionRunning (step execution) delay)
                              }
                            , Cmd.none
                            )

                        ExecutionUndo ->
                            ( { model | gameState = Executing (ExecutionPaused (stepBack execution)) }
                            , Cmd.none
                            )

                        ExecutionPause ->
                            ( { model | gameState = Executing (ExecutionPaused execution) }
                            , Cmd.none
                            )

                        ExecutionRun ->
                            ( model, Cmd.none )

                        ExecutionBackClicked ->
                            ( { model | gameState = Sketching execution.level.id }
                            , Cmd.none
                            )

                        ExecutionBackToBrowsingLevels ->
                            ( { model | gameState = BrowsingLevels }
                            , Cmd.none
                            )

        _ ->
            ( model, Cmd.none )


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
    }


initialExecution : LevelProgress -> Execution
initialExecution levelProgress =
    let
        level =
            levelProgress.level

        board =
            History.current levelProgress.boardSketch.boardHistory

        input =
            level.io.input

        executionHistory =
            initialExecutionStep board input
                |> History.singleton
    in
    { level = level
    , executionHistory = executionHistory
    }


stepBack : Execution -> Execution
stepBack execution =
    { execution
        | executionHistory = History.back execution.executionHistory
    }


step : Execution -> Execution
step execution =
    let
        executionHistory =
            execution.executionHistory

        executionStep =
            History.current executionHistory

        newExecutionHistory =
            if executionStep.terminated then
                executionHistory

            else
                History.push
                    (stepExecutionStep executionStep)
                    executionHistory
    in
    { execution
        | executionHistory = newExecutionHistory
    }


pop : List Int -> ( Int, List Int )
pop list =
    case list of
        head :: tail ->
            ( head, tail )

        _ ->
            ( 0, [] )


pop2 : List Int -> ( Int, Int, List Int )
pop2 list =
    case list of
        a :: b :: tail ->
            ( a, b, tail )

        a :: tail ->
            ( a, 0, [] )

        _ ->
            ( 0, 0, [] )


op : (Int -> Int) -> Stack -> Stack
op operation stack =
    let
        ( a, stack1 ) =
            pop stack
    in
    operation a :: stack1


op2 : (Int -> Int -> Int) -> Stack -> Stack
op2 operation stack =
    let
        ( a, b, stack1 ) =
            pop2 stack
    in
    operation a b :: stack1


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
            BoardUtils.get position board
                |> Maybe.withDefault NoOp

        boardWidth =
            BoardUtils.width board

        boardHeight =
            BoardUtils.height board

        moveInstructionPointer pointer newDirection =
            let
                oldPosition =
                    pointer.position

                newPosition =
                    case newDirection of
                        Left ->
                            { position | x = modBy boardWidth (position.x - 1) }

                        Up ->
                            { position | y = modBy boardWidth (position.y - 1) }

                        Right ->
                            { position | x = modBy boardWidth (position.x + 1) }

                        Down ->
                            { position | y = modBy boardWidth (position.y + 1) }
            in
            { position = newPosition
            , direction = newDirection
            }

        movedExecutionStep =
            { executionStep
                | instructionPointer = moveInstructionPointer instructionPointer direction
            }
    in
    case instruction of
        ChangeDirection newDirection ->
            { executionStep
                | instructionPointer = moveInstructionPointer instructionPointer newDirection
            }

        Branch trueDirection falseDirection ->
            let
                ( value, newStack ) =
                    pop stack

                newDirection =
                    if value /= 0 then
                        trueDirection

                    else
                        falseDirection

                newInstructionPointer =
                    moveInstructionPointer instructionPointer newDirection
            in
            { executionStep
                | instructionPointer = newInstructionPointer
                , stack = newStack
            }

        Read ->
            { movedExecutionStep
                | stack = Maybe.withDefault 0 (List.head input) :: stack
                , input = Maybe.withDefault [] (List.tail input)
            }

        Print ->
            { movedExecutionStep
                | stack = Maybe.withDefault [] (List.tail stack)
                , output = Maybe.withDefault 0 (List.head stack) :: output
            }

        PushToStack number ->
            { movedExecutionStep
                | stack = number :: stack
            }

        PopFromStack ->
            { movedExecutionStep
                | stack = Maybe.withDefault [] (List.tail stack)
            }

        Duplicate ->
            let
                ( a, stack1 ) =
                    pop stack
            in
            { movedExecutionStep
                | stack = a :: a :: stack1
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
                | stack = op negate stack
            }

        Abs ->
            { movedExecutionStep
                | stack = op abs stack
            }

        Not ->
            { movedExecutionStep
                | stack =
                    op
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
                | stack = op ((+) 1) stack
            }

        Decrement ->
            { movedExecutionStep
                | stack = op (\value -> value - 1) stack
            }

        Add ->
            { movedExecutionStep
                | stack = op2 (+) stack
            }

        Subtract ->
            { movedExecutionStep
                | stack = op2 (-) stack
            }

        Multiply ->
            { movedExecutionStep
                | stack = op2 (*) stack
            }

        Divide ->
            { movedExecutionStep
                | stack = op2 (//) stack
            }

        Equals ->
            { movedExecutionStep
                | stack =
                    op2
                        (\a b ->
                            if a == b then
                                1

                            else
                                0
                        )
                        stack
            }

        And ->
            { movedExecutionStep
                | stack =
                    op2
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
                    op2
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
                    op2
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
            { executionStep | terminated = True }

        _ ->
            movedExecutionStep
