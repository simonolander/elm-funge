module Update.Blueprint exposing (deleteBlueprint, gotSaveBlueprintResponse, loadBlueprint, loadBlueprints, saveBlueprint, gotLoadBlueprintResponse)

import Basics.Extra exposing (flip)
import Data.Blueprint as Blueprint exposing (Blueprint)
import Data.BlueprintBook as BlueprintBook
import Data.BlueprintId exposing (BlueprintId)
import Data.Cache as Cache
import Data.GetError exposing (GetError)
import Data.RemoteCache as RemoteCache
import Data.SaveError exposing (SaveError)
import Data.Session as Session exposing (Session)
import Extra.Cmd exposing (fold, noCmd)
import RemoteData exposing (RemoteData(..))
import Set
import Update.General exposing (gotGetError, gotSaveError)
import Update.SessionMsg exposing (SessionMsg(..))



-- LOAD


loadBlueprintFromLocalStorage : BlueprintId -> Session -> ( Session, Cmd msg )
loadBlueprintFromLocalStorage blueprintId session =
    case Cache.get blueprintId session.blueprints.local of
        NotAsked ->
            ( RemoteCache.withLocalLoading blueprintId session.blueprints
                |> flip Session.withBlueprintCache session
            , Blueprint.loadFromLocalStorage blueprintId
            )

        _ ->
            ( session, Cmd.none )


loadBlueprint : BlueprintId -> Session -> ( Session, Cmd SessionMsg )
loadBlueprint blueprintId session =
    case Session.getAccessToken session of
        Just accessToken ->
            case Cache.get blueprintId session.blueprints.actual of
                NotAsked ->
                    ( RemoteCache.withActualLoading blueprintId session.blueprints
                        |> flip Session.withBlueprintCache session
                    , Blueprint.loadFromServerByBlueprintId GotLoadBlueprintResponse accessToken blueprintId
                    )

                _ ->
                    ( session, Cmd.none )

        Nothing ->
            loadBlueprintFromLocalStorage blueprintId session


loadBlueprints : Session -> ( Session, Cmd SessionMsg )
loadBlueprints session =
    case session.blueprintBook of
        Success blueprintBook ->
            Set.toList blueprintBook
                |> List.map loadBlueprint
                |> flip Extra.Cmd.fold session

        NotAsked ->
            case Session.getAccessToken session of
                Just accessToken ->
                    ( { session | blueprintBook = Loading }
                    , Blueprint.loadAllFromServer GotLoadBlueprintsResponse accessToken
                    )

                Nothing ->
                    ( { session | blueprintBook = Loading }
                    , BlueprintBook.loadFromLocalStorage
                    )

        _ ->
            ( session, Cmd.none )


gotLoadBlueprintResponse : BlueprintId -> Result GetError (Maybe Blueprint) -> Session -> ( Session, Cmd SessionMsg )
gotLoadBlueprintResponse blueprintId result session =
    let
        sessionWithActualBlueprintResult =
            { session | blueprints = RemoteCache.withActualResult blueprintId result session.blueprints }
    in
    case result of
        Ok maybeBlueprint ->
            let
                blueprints =
                    sessionWithActualBlueprintResult.blueprints
                        |> RemoteCache.withLocalValue blueprintId maybeBlueprint
                        |> RemoteCache.withExpectedValue blueprintId maybeBlueprint

                cmd =
                    case maybeBlueprint of
                        Just blueprint ->
                            Cmd.batch
                                [ Blueprint.saveToLocalStorage blueprint
                                , Blueprint.saveRemoteToLocalStorage blueprint
                                ]

                        Nothing ->
                            Cmd.batch
                                [ Blueprint.removeFromLocalStorage blueprintId
                                , Blueprint.removeRemoteFromLocalStorage blueprintId
                                ]
            in
            ( { sessionWithActualBlueprintResult | blueprints = blueprints }, cmd )

        Err error ->
            fold
                [ loadBlueprintFromLocalStorage blueprintId
                , gotGetError error
                ]
                sessionWithActualBlueprintResult

gotLoadBlueprintsResponse : Result GetError (List Blueprint) -> Session -> (Session, Cmd SessionMsg)
gotLoadBlueprintsResponse result session =
    case result of
        Ok blueprints ->
            let



        Err error ->




-- SAVE


saveBlueprint : Blueprint -> Session -> ( Session, Cmd SessionMsg )
saveBlueprint blueprint session =
    let
        blueprints =
            RemoteCache.withLocalValue blueprint.id (Just blueprint) session.blueprints

        -- TODO Split blueprint book into local and actual
        blueprintBook =
            RemoteData.withDefault BlueprintBook.empty session.blueprintBook
                |> Set.insert blueprint.id
                |> RemoteData.Success

        saveActualBlueprint =
            Session.getAccessToken session
                |> Maybe.map (Blueprint.saveToServer GotSaveBlueprintResponse blueprint)
                |> Maybe.withDefault Cmd.none

        saveLocalBlueprint =
            Blueprint.saveToLocalStorage blueprint
    in
    ( { session | blueprints = blueprints, blueprintBook = blueprintBook }
    , Cmd.batch
        [ saveLocalBlueprint
        , saveActualBlueprint
        ]
    )


gotSaveBlueprintResponse : Blueprint -> Maybe SaveError -> Session -> ( Session, Cmd SessionMsg )
gotSaveBlueprintResponse blueprint maybeError session =
    case maybeError of
        Just error ->
            gotSaveError error session

        Nothing ->
            session.blueprints
                |> RemoteCache.withActualValue blueprint.id (Just blueprint)
                |> RemoteCache.withExpectedValue blueprint.id (Just blueprint)
                |> flip Session.withBlueprintCache session
                |> noCmd



-- DELETE


deleteBlueprint : BlueprintId -> Session -> ( Session, Cmd SessionMsg )
deleteBlueprint blueprintId =
    let
        removeBlueprintIdFromBlueprintBook session =
            ( { session | blueprintBook = RemoteData.map (Set.remove blueprintId) session.blueprintBook }
            , BlueprintBook.removeBlueprintIdFromLocalStorage blueprintId
            )

        removeBlueprintFromLocalStorage session =
            ( session
            , Blueprint.removeFromLocalStorage blueprintId
            )

        removeLocalBlueprintFromSession session =
            ( { session | blueprints = RemoteCache.withLocalValue blueprintId Nothing session.blueprints }
            , Cmd.none
            )

        removeBlueprintFromServer session =
            case Session.getAccessToken session of
                Just accessToken ->
                    ( { session | blueprints = RemoteCache.withActualLoading blueprintId session.blueprints }
                    , Blueprint.deleteFromServer GotDeleteBlueprintResponse accessToken blueprintId
                    )

                Nothing ->
                    ( session, Cmd.none )
    in
    fold
        [ removeBlueprintIdFromBlueprintBook
        , removeBlueprintFromLocalStorage
        , removeLocalBlueprintFromSession
        , removeBlueprintFromServer
        ]


gotDeleteBlueprintResponse : BlueprintId -> Maybe SaveError -> Session -> ( Session, Cmd SessionMsg )
gotDeleteBlueprintResponse blueprintId maybeError session =
    case maybeError of
        Just error ->
            gotSaveError error session

        Nothing ->
            session.blueprints
                |> RemoteCache.withLocalValue blueprintId Nothing
                |> RemoteCache.withExpectedValue blueprintId Nothing
                |> RemoteCache.withActualValue blueprintId Nothing
                |> flip Session.withBlueprintCache session
                |> noCmd
