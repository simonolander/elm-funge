module Update exposing (update)

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

        SelectLevel levelProgress ->
            ( { model | gameState = Sketching levelProgress }, Cmd.none )

        SketchMsg sketchMsg ->
            ( model, Cmd.none )

        ExecutionMsg executionMsg ->
            ( model, Cmd.none )
