module SketchUpdate exposing (update)

import BoardUtils
import History
import Json.Decode exposing (errorToString)
import JsonUtils
import LevelProgressUtils
import LocalStorageUtils
import Model exposing (..)


update : SketchMsg -> Model -> ( Model, Cmd Msg )
update message model =
    case model.gameState of
        Sketching levelId sketchingState ->
            case LevelProgressUtils.getLevelProgress levelId model of
                Just levelProgress ->
                    case message of
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

                        ImportExportOpen ->
                            ( { model
                                | gameState =
                                    Sketching levelId
                                        (levelProgress.boardSketch.boardHistory
                                            |> History.current
                                            |> JsonUtils.encodeBoard
                                            |> JsonUtils.toString
                                            |> Importing Nothing
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

                                        cmd =
                                            LocalStorageUtils.putBoard levelProgress.level.id
                                                board
                                                model.funnelState
                                    in
                                    ( newModel, cmd )

                                Err errorMessage ->
                                    case model.gameState of
                                        Sketching id (Importing _ str) ->
                                            ( { model
                                                | gameState =
                                                    Sketching id (Importing (Just (errorToString errorMessage)) str)
                                              }
                                            , Cmd.none
                                            )

                                        _ ->
                                            ( model, Cmd.none )

                        ImportChanged newString ->
                            ( { model
                                | gameState =
                                    Sketching levelId (Importing Nothing newString)
                              }
                            , Cmd.none
                            )

                        ImportExportClose ->
                            ( { model
                                | gameState =
                                    Sketching levelId JustSketching
                              }
                            , Cmd.none
                            )

                Nothing ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- LEVELPROGRESS --


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
