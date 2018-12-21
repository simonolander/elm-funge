module Update exposing (update)

import BoardUtils
import ExecutionUtils
import History
import Model exposing (..)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Resize windowSize ->
            ( { model
                | windowSize = windowSize
              }
            , Cmd.none
            )

        SelectLevel levelId ->
            ( { model | gameState = Sketching levelId }, Cmd.none )

        SketchMsg sketchMsg ->
            case model.gameState of
                Sketching levelId ->
                    case getLevelProgress levelId model of
                        Just levelProgress ->
                            updateSketchMsg levelProgress sketchMsg model

                        Nothing ->
                            ( model, Cmd.none )

                _ ->
                    Debug.todo (Debug.toString msg)

        ExecutionMsg executionMsg ->
            ExecutionUtils.update executionMsg model


updateSketchMsg levelProgress msg model =
    case msg of
        SelectInstruction instruction ->
            let
                newBoardSketch =
                    levelProgress.boardSketch
                        |> withSelectedInstruction (Just instruction)

                newLevelProgress =
                    levelProgress |> withBoardSketch newBoardSketch

                newModel =
                    model
                        |> setLevelProgress newLevelProgress
            in
            ( newModel, Cmd.none )

        PlaceInstruction position instruction ->
            let
                boardSketch =
                    levelProgress.boardSketch

                boardHistory =
                    boardSketch.boardHistory

                newBoard =
                    History.current boardHistory
                        |> BoardUtils.set position instruction

                newBoardHistory =
                    boardHistory
                        |> History.push newBoard

                newBoardSketch =
                    { boardSketch | boardHistory = newBoardHistory }

                newLevelProgress =
                    { levelProgress | boardSketch = newBoardSketch }

                newModel =
                    setLevelProgress newLevelProgress model
            in
            ( newModel, Cmd.none )

        SketchUndo ->
            let
                boardSketch =
                    levelProgress.boardSketch

                newBoardHistory =
                    History.back boardSketch.boardHistory

                newBoardSketch =
                    { boardSketch | boardHistory = newBoardHistory }

                newLevelProgress =
                    { levelProgress | boardSketch = newBoardSketch }

                newModel =
                    setLevelProgress newLevelProgress model
            in
            ( newModel, Cmd.none )

        SketchRedo ->
            let
                boardSketch =
                    levelProgress.boardSketch

                newBoardHistory =
                    History.forward boardSketch.boardHistory

                newBoardSketch =
                    { boardSketch | boardHistory = newBoardHistory }

                newLevelProgress =
                    { levelProgress | boardSketch = newBoardSketch }

                newModel =
                    setLevelProgress newLevelProgress model
            in
            ( newModel, Cmd.none )

        SketchClear ->
            let
                boardSketch =
                    levelProgress.boardSketch

                newBoardHistory =
                    History.push levelProgress.level.initialBoard boardSketch.boardHistory

                newBoardSketch =
                    { boardSketch | boardHistory = newBoardHistory }

                newLevelProgress =
                    { levelProgress | boardSketch = newBoardSketch }

                newModel =
                    setLevelProgress newLevelProgress model
            in
            ( newModel, Cmd.none )

        SketchBackClicked ->
            ( { model | gameState = BrowsingLevels }
            , Cmd.none
            )

        SketchExecute ->
            ( { model
                | gameState = Executing (ExecutionPaused (ExecutionUtils.initialExecution levelProgress))
              }
            , Cmd.none
            )



-- LEVELPROGRESS --


getLevelProgress : LevelId -> Model -> Maybe LevelProgress
getLevelProgress levelId model =
    model.levelProgresses
        |> List.filter (\levelProgress -> levelProgress.level.id == levelId)
        |> List.head


setLevelProgress : LevelProgress -> Model -> Model
setLevelProgress levelProgress model =
    { model
        | levelProgresses =
            model.levelProgresses
                |> List.map
                    (\progress ->
                        if progress.level.id == levelProgress.level.id then
                            levelProgress

                        else
                            progress
                    )
    }


withBoardSketch : BoardSketch -> LevelProgress -> LevelProgress
withBoardSketch boardSketch levelProgress =
    { levelProgress | boardSketch = boardSketch }


withSelectedInstruction : Maybe Instruction -> BoardSketch -> BoardSketch
withSelectedInstruction selectedInstruction boardSketch =
    { boardSketch | selectedInstruction = selectedInstruction }
