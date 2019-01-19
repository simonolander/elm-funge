module BrowsingLevelsUpdate exposing (update)

import Model exposing (..)


update : BrowsingLevelsMessage -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        SelectLevel levelId ->
            ( { model
                | gameState = BrowsingLevels (Just levelId)
              }
            , Cmd.none
            )
