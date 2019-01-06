module LevelProgressUtils exposing
    ( setLevelProgressBoardHistoryInModel
    , setLevelProgressSolvedInModel
    )

import History exposing (History)
import Model exposing (..)


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
