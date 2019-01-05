module ExecutionUtils exposing
    ( executionIsSolved
    , initialExecution
    , initialExecutionStep
    , update
    )

import BoardUtils
import History
import LocalStorageUtils
import Model exposing (..)


update : ExecutionMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        setLevelProgressCompleted levelId levelProgresses =
            levelProgresses
                |> List.map
                    (\levelProgress ->
                        if levelProgress.level.id == levelId then
                            { levelProgress | solved = True }

                        else
                            levelProgress
                    )
    in
    case model.gameState of
        Executing executionState ->
            case executionState of
                ExecutionPaused execution ->
                    case msg of
                        ExecutionStepOne ->
                            let
                                newExecution =
                                    step execution

                                ( newLevelProgresses, saveCmd ) =
                                    if executionIsSolved newExecution then
                                        ( setLevelProgressCompleted execution.level.id model.levelProgresses
                                        , LocalStorageUtils.putLevelSolved execution.level.id model.funnelState
                                        )

                                    else
                                        ( model.levelProgresses
                                        , Cmd.none
                                        )
                            in
                            ( { model
                                | gameState = Executing (ExecutionPaused newExecution)
                                , levelProgresses = newLevelProgresses
                              }
                            , saveCmd
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

                        ExecutionFastForward ->
                            ( { model | gameState = Executing (ExecutionRunning execution 100) }
                            , Cmd.none
                            )

                        ExecutionBackClicked ->
                            ( { model | gameState = Sketching execution.level.id }
                            , Cmd.none
                            )

                        ExecutionBackToBrowsingLevels ->
                            ( { model | gameState = BrowsingLevels (Just execution.level.id) }
                            , Cmd.none
                            )

                ExecutionRunning execution delay ->
                    case msg of
                        ExecutionStepOne ->
                            let
                                executionStep =
                                    History.current execution.executionHistory

                                newExecution =
                                    step execution

                                ( newLevelProgresses, saveCmd ) =
                                    if executionIsSolved newExecution then
                                        ( setLevelProgressCompleted execution.level.id model.levelProgresses
                                        , LocalStorageUtils.putLevelSolved execution.level.id model.funnelState
                                        )

                                    else
                                        ( model.levelProgresses
                                        , Cmd.none
                                        )
                            in
                            ( { model
                                | gameState =
                                    if executionStep.terminated then
                                        Executing (ExecutionPaused execution)

                                    else
                                        Executing (ExecutionRunning newExecution delay)
                                , levelProgresses = newLevelProgresses
                              }
                            , saveCmd
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
                            ( { model | gameState = Executing (ExecutionRunning execution 250) }
                            , Cmd.none
                            )

                        ExecutionFastForward ->
                            ( { model | gameState = Executing (ExecutionRunning execution 100) }
                            , Cmd.none
                            )

                        ExecutionBackClicked ->
                            ( { model | gameState = Sketching execution.level.id }
                            , Cmd.none
                            )

                        ExecutionBackToBrowsingLevels ->
                            ( { model | gameState = BrowsingLevels (Just execution.level.id) }
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
    , exception = Nothing
    , stepCount = 0
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


executionIsSolved : Execution -> Bool
executionIsSolved execution =
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
            case executionStep.exception of
                Just message ->
                    executionHistory

                Nothing ->
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


peek : List Int -> Int
peek list =
    List.head list
        |> Maybe.withDefault 0


pop2 : List Int -> ( Int, Int, List Int )
pop2 list =
    case list of
        a :: b :: tail ->
            ( a, b, tail )

        a :: tail ->
            ( a, 0, [] )

        _ ->
            ( 0, 0, [] )


peek2 : List Int -> ( Int, Int )
peek2 list =
    case list of
        a :: b :: _ ->
            ( a, b )

        a :: _ ->
            ( a, 0 )

        _ ->
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
            BoardUtils.get position board
                |> Maybe.withDefault NoOp

        boardWidth =
            BoardUtils.width board

        boardHeight =
            BoardUtils.height board

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

        Jump Forward ->
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

        _ ->
            movedExecutionStep
