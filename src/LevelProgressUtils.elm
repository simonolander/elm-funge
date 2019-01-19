module LevelProgressUtils exposing
    ( getLevelProgress
    , setLevelProgressBoardHistoryInModel
    , setLevelProgressSolvedInModel
    )

import History exposing (History)
import Model exposing (..)


getLevelProgress : LevelId -> Model -> Maybe LevelProgress
getLevelProgress levelId model =
    model.levelProgresses
        |> List.filter (\levelProgress -> levelProgress.level.id == levelId)
        |> List.head


setLevelProgressSolvedInModel : LevelId -> Model -> Model
setLevelProgressSolvedInModel levelId model =
    let
        levelProgresses =
            model.levelProgresses
                |> List.map
                    (\levelProgress ->
                        if levelId == levelProgress.level.id then
                            { levelProgress
                                | solved = True
                            }

                        else
                            levelProgress
                    )
    in
    { model
        | levelProgresses = levelProgresses
    }


setLevelProgressBoardHistoryInModel : LevelId -> History Board -> Model -> Model
setLevelProgressBoardHistoryInModel levelId boardHistory model =
    let
        levelProgresses =
            model.levelProgresses
                |> List.map
                    (\levelProgress ->
                        if levelId == levelProgress.level.id then
                            let
                                boardSketch =
                                    levelProgress.boardSketch
                            in
                            { levelProgress
                                | boardSketch =
                                    { boardSketch
                                        | boardHistory = boardHistory
                                    }
                            }

                        else
                            levelProgress
                    )
    in
    { model
        | levelProgresses = levelProgresses
    }
