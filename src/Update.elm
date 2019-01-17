module Update exposing (update)

import BoardUtils
import ExecutionUtils
import History
import JsonUtils
import LocalStorageUtils
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
            ( { model | gameState = BrowsingLevels (Just levelId) }, Cmd.none )

        SketchLevelProgress levelId ->
            ( { model | gameState = Sketching levelId JustSketching }, Cmd.none )

        SketchMsg sketchMsg ->
            case model.gameState of
                Sketching levelId sketchingState ->
                    case getLevelProgress levelId model of
                        Just levelProgress ->
                            updateSketchMsg levelProgress sketchMsg model

                        Nothing ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ExecutionMsg executionMsg ->
            ExecutionUtils.update executionMsg model

        LocalStorageMsg localStorageMsg ->
            LocalStorageUtils.update model localStorageMsg

        GoToBrowsingLevels maybeLevelId ->
            ( { model
                | gameState = BrowsingLevels maybeLevelId
              }
            , Cmd.none
            )


updateSketchMsg levelProgress msg model =
    case msg of
        NewInstructionToolbox instructionToolbox ->
            let
                boardSketch =
                    levelProgress.boardSketch

                newBoardSketch =
                    { boardSketch
                        | instructionToolbox = instructionToolbox
                    }

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

                cmd =
                    LocalStorageUtils.putBoard levelProgress.level.id
                        newBoard
                        model.funnelState
            in
            ( newModel, cmd )

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
            ( { model | gameState = BrowsingLevels (Just levelProgress.level.id) }
            , Cmd.none
            )

        SketchExecute ->
            ( { model
                | gameState = Executing (ExecutionPaused (ExecutionUtils.initialExecution levelProgress))
              }
            , Cmd.none
            )

        ImportExport ->
            ( { model
                | gameState =
                    Sketching levelProgress.level.id
                        (levelProgress.boardSketch.boardHistory
                            |> History.current
                            |> JsonUtils.encodeBoard
                            |> JsonUtils.toString
                            |> Importing
                        )
              }
            , Cmd.none
            )

        Import string ->
            case JsonUtils.fromString JsonUtils.boardDecoder string of
                Ok board ->
                    let
                        boardSketch =
                            levelProgress.boardSketch

                        newBoardHistory =
                            History.push board boardSketch.boardHistory

                        newBoardSketch =
                            { boardSketch | boardHistory = newBoardHistory }

                        newLevelProgress =
                            { levelProgress | boardSketch = newBoardSketch }

                        newModel =
                            setLevelProgress newLevelProgress model
                    in
                    ( model, Cmd.none )

                Err message ->
                    ( model, Cmd.none )



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
