module Page.Blueprints.Update exposing (init, load, subscriptions, update)

import Basics.Extra exposing (flip)
import Data.Blueprint as Blueprint
import Data.BlueprintId exposing (BlueprintId)
import Data.Cache as Cache
import Data.Session exposing (Session)
import Extra.Cmd exposing (withExtraCmd)
import Maybe.Extra
import Page.Blueprints.Model exposing (Modal(..), Model)
import Page.Blueprints.Msg exposing (Msg(..))
import Page.Mapping
import Page.PageMsg as PageMsg exposing (InternalMsg, PageMsg)
import Ports.Console as Console
import Random
import RemoteData
import Route
import Update.Blueprint


init : Maybe BlueprintId -> ( Model, Cmd PageMsg )
init selectedBlueprintId =
    let
        model =
            { selectedBlueprintId = selectedBlueprintId
            , modal = Nothing
            }
    in
    ( model, Cmd.none )


load : ( Session, Model ) -> ( ( Session, Model ), Cmd PageMsg )
load =
    let
        loadBlueprints =
            Page.Mapping.sessionLoad Update.Blueprint.loadBlueprints
    in
    Extra.Cmd.fold
        [ loadBlueprints ]


update : Msg -> ( Session, Model ) -> ( ( Session, Model ), Cmd PageMsg )
update msg tuple =
    let
        ( session, model ) =
            tuple
    in
    case msg of
        ClickedConfirmDeleteBlueprint ->
            case model.modal of
                Just (ConfirmDelete blueprintId) ->
                    Page.Mapping.sessionLoad (Update.Blueprint.deleteBlueprint blueprintId) tuple

                Nothing ->
                    ( tuple, Cmd.none )

        ClickedDeleteBlueprint blueprintId ->
            ( ( session, { model | modal = Just (ConfirmDelete blueprintId) } ), Cmd.none )

        ClickedCancelDeleteBlueprint ->
            case model.modal of
                Just (ConfirmDelete _) ->
                    ( ( session, { model | modal = Nothing } ), Cmd.none )

                Nothing ->
                    ( tuple, Cmd.none )

        BlueprintNameChanged newName ->
            case
                Maybe.map (flip Cache.get session.blueprints.working) model.selectedBlueprintId
                    |> Maybe.andThen (RemoteData.toMaybe >> Maybe.Extra.join)
            of
                Just blueprint ->
                    Page.Mapping.sessionLoad (Update.Blueprint.saveBlueprint { blueprint | name = newName }) tuple

                Nothing ->
                    ( tuple, Console.errorString "tWy71t5l    Could not update blueprint name: blueprint not found" )

        BlueprintDescriptionChanged newDescription ->
            case
                Maybe.map (flip Cache.get session.blueprints.working) model.selectedBlueprintId
                    |> Maybe.andThen (RemoteData.toMaybe >> Maybe.Extra.join)
            of
                Just blueprint ->
                    Page.Mapping.sessionLoad
                        (Update.Blueprint.saveBlueprint { blueprint | description = String.lines newDescription })
                        tuple

                Nothing ->
                    ( tuple, Console.errorString "Pm6iHnXM    Could not update blueprint description: blueprint not found" )

        SelectedBlueprintId blueprintId ->
            ( ( session, { model | selectedBlueprintId = Just blueprintId } )
            , Route.replaceUrl session.key (Route.Blueprints (Just blueprintId))
            )

        ClickedNewBlueprint ->
            ( tuple
            , Random.generate
                (PageMsg.InternalMsg << PageMsg.Blueprints << BlueprintGenerated)
                Blueprint.generator
            )

        BlueprintGenerated blueprint ->
            Page.Mapping.sessionLoad (Update.Blueprint.saveBlueprint blueprint) tuple
                |> Tuple.mapFirst (Tuple.mapSecond (\m -> { m | selectedBlueprintId = Just blueprint.id }))
                |> withExtraCmd (Route.replaceUrl session.key (Route.Blueprints (Just blueprint.id)))


subscriptions : Model -> Sub Msg
subscriptions =
    always Sub.none
