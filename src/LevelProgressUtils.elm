module LevelProgressUtils exposing (setLevelProgressSolvedInModel)

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
