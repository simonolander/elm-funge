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
        Executing execution executionState ->
            case msg of
                ExecutionStepOne ->
                    case executionState of
                        ExecutionPaused ->
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
                                | gameState = Executing newExecution ExecutionPaused
                                , levelProgresses = newLevelProgresses
                              }
                            , saveCmd
                            )

                        ExecutionRunning delay ->
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
                                        Executing execution ExecutionPaused

                                    else
                                        Executing newExecution (ExecutionRunning delay)
                                , levelProgresses = newLevelProgresses
                              }
                            , saveCmd
                            )

                ExecutionUndo ->
                    case executionState of
                        ExecutionPaused ->
                            ( { model | gameState = Executing (stepBack execution) ExecutionPaused }
                            , Cmd.none
                            )

                        ExecutionRunning _ ->
                            ( model, Cmd.none )

                ExecutionPause ->
                    ( { model
                        | gameState = Executing execution ExecutionPaused
                      }
                    , Cmd.none
                    )

                ExecutionRun ->
                    ( { model
                        | gameState = Executing execution (ExecutionRunning 250)
                      }
                    , Cmd.none
                    )

                ExecutionFastForward ->
                    ( { model
                        | gameState = Executing execution (ExecutionRunning 100)
                      }
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
