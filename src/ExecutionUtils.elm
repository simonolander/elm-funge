module ExecutionUtils exposing (initialExecution, initialExecutionStep, update)

import BoardUtils
import History
import Model exposing (..)


update : ExecutionMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.gameState of
        Executing execution ->
            case msg of
                ExecutionStepOne ->
                    ( { model | gameState = Executing (step execution) }
                    , Cmd.none
                    )

                ExecutionUndo ->
                    ( { model | gameState = Executing (stepBack execution) }
                    , Cmd.none
                    )

                ExecutionBackClicked ->
                    ( { model | gameState = Sketching execution.level.id }
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
    }


initialExecution : LevelProgress -> Execution
initialExecution levelProgress =
    let
        level =
            levelProgress.level

        board =
            History.current levelProgress.boardSketch.boardHistory

        input =
            level.cases
                |> List.head
                |> Maybe.map .input
                |> Maybe.withDefault []

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
    { execution
        | executionHistory =
            History.push
                (stepExecutionStep (History.current execution.executionHistory))
                execution.executionHistory
    }


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
    in
    case instruction of
        ChangeDirection newDirection ->
            { executionStep
                | instructionPointer = moveInstructionPointer instructionPointer newDirection
            }

        NoOp ->
            { executionStep
                | instructionPointer = moveInstructionPointer instructionPointer direction
            }

        _ ->
            { executionStep
                | instructionPointer = moveInstructionPointer instructionPointer direction
            }
