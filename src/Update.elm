module Update exposing (update)

import BoardUtils
import Browser
import Browser.Navigation
import BrowsingLevelsUpdate
import ExecutionUtils
import History
import JsonUtils
import LocalStorageUtils
import Model exposing (..)
import NavigationUpdate
import SketchUpdate


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Resize windowSize ->
            ( { model
                | windowSize = windowSize
              }
            , Cmd.none
            )

        BrowsingLevelsMessage message ->
            BrowsingLevelsUpdate.update message model

        NavigationMessage message ->
            NavigationUpdate.update message model

        SketchMsg sketchMsg ->
            SketchUpdate.update sketchMsg model

        ExecutionMsg executionMsg ->
            ExecutionUtils.update executionMsg model

        LocalStorageMsg localStorageMsg ->
            LocalStorageUtils.update model localStorageMsg

        ChangedUrl _ ->
            ( model, Cmd.none )

        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Cmd.none )

                Browser.External href ->
                    ( model, Browser.Navigation.load href )

        ApiMsg _ ->
            ( model, Cmd.none )
