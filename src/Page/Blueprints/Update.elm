module Page.Blueprints.Update exposing (load, update)

import Basics.Extra exposing (flip)
import Data.Blueprint as Blueprint
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater, withModel)
import Data.Session exposing (Session)
import Maybe.Extra
import Page.Blueprints.Model exposing (Modal(..), Model)
import Page.Blueprints.Msg exposing (Msg(..))
import Page.Msg exposing (PageMsg(..))
import Ports.Console as Console
import Random
import RemoteData
import Route
import Service.Blueprint.BlueprintService exposing (deleteBlueprint, getBlueprintByBlueprintId, loadAllBlueprintsForUser, saveBlueprint)
import Update.SessionMsg exposing (SessionMsg(..))


load : CmdUpdater ( Session, Model ) SessionMsg
load =
    let
        loadBlueprints ( session, model ) =
            loadAllBlueprintsForUser session
                |> withModel model
    in
    CmdUpdater.batch
        [ loadBlueprints ]


update : Msg -> ( Session, Model ) -> ( ( Session, Model ), Cmd Page.Msg.Msg )
update msg tuple =
    let
        ( session, model ) =
            tuple

        fromMsg =
            CmdUpdater.mapCmd (BlueprintsMsg >> Page.Msg.PageMsg)

        fromSessionMsg =
            CmdUpdater.mapCmd Page.Msg.SessionMsg
    in
    case msg of
        ClickedConfirmDeleteBlueprint ->
            case model.modal of
                Just (ConfirmDelete blueprintId) ->
                    deleteBlueprint blueprintId session
                        |> withModel model
                        |> fromSessionMsg

                Nothing ->
                    ( tuple, Cmd.none )

        ClickedDeleteBlueprint blueprintId ->
            ( ( session, { model | modal = Just (ConfirmDelete blueprintId) } )
            , Cmd.none
            )

        ClickedCancelDeleteBlueprint ->
            case model.modal of
                Just (ConfirmDelete _) ->
                    ( ( session, { model | modal = Nothing } ), Cmd.none )

                Nothing ->
                    ( tuple, Cmd.none )

        BlueprintNameChanged newName ->
            case
                Maybe.map (flip getBlueprintByBlueprintId session) model.selectedBlueprintId
                    |> Maybe.andThen (RemoteData.toMaybe >> Maybe.Extra.join)
            of
                Just blueprint ->
                    saveBlueprint { blueprint | name = newName } session
                        |> withModel model
                        |> fromSessionMsg

                Nothing ->
                    ( tuple, Console.errorString "tWy71t5l    Could not update blueprint name: blueprint not found" )

        BlueprintDescriptionChanged newDescription ->
            case
                Maybe.map (flip getBlueprintByBlueprintId session) model.selectedBlueprintId
                    |> Maybe.andThen (RemoteData.toMaybe >> Maybe.Extra.join)
            of
                Just blueprint ->
                    saveBlueprint { blueprint | description = String.lines newDescription } session
                        |> withModel model
                        |> fromSessionMsg

                Nothing ->
                    ( tuple, Console.errorString "Pm6iHnXM    Could not update blueprint description: blueprint not found" )

        ClickedBlueprint blueprintId ->
            ( ( session, { model | selectedBlueprintId = Just blueprintId } )
            , Route.replaceUrl session.key (Route.Blueprints (Just blueprintId))
            )

        ClickedNewBlueprint ->
            fromMsg
                ( tuple
                , Random.generate GeneratedBlueprint Blueprint.generator
                )

        GeneratedBlueprint blueprint ->
            saveBlueprint blueprint session
                |> CmdUpdater.add (Route.replaceUrl session.key (Route.Blueprints (Just blueprint.id)))
                |> withModel { model | selectedBlueprintId = Just blueprint.id }
                |> fromSessionMsg
