module NavigationUpdate exposing (update)

import ExecutionUtils
import LevelProgressUtils
import Model exposing (..)


update : NavigationMessage -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        GoToBrowsingLevels maybeLevelId ->
            ( { model
                | gameState = BrowsingLevels maybeLevelId
              }
            , Cmd.none
            )

        GoToSketching levelId ->
            ( { model
                | gameState = Sketching levelId JustSketching
              }
            , Cmd.none
            )

        GoToExecuting levelId ->
            case LevelProgressUtils.getLevelProgress levelId model of
                Just levelProgress ->
                    ( { model
                        | gameState = Executing (ExecutionPaused (ExecutionUtils.initialExecution levelProgress))
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )
