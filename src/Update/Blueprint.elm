module Update.Blueprint exposing (deleteBlueprint, loadBlueprint, loadBlueprints, saveBlueprint)

import Basics.Extra exposing (flip)
import Data.Blueprint as Blueprint exposing (Blueprint)
import Data.BlueprintBook as BlueprintBook
import Data.BlueprintId exposing (BlueprintId)
import Data.Cache as Cache
import Data.GetError exposing (GetError)
import Data.RemoteCache as RemoteCache
import Data.Session as Session exposing (Session)
import Extra.Cmd exposing (fold)
import RemoteData exposing (RemoteData(..))
import SessionUpdate exposing (SessionMsg(..))
import Set



-- LOAD


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
            case Cache.get blueprintId session.blueprints.local of
                NotAsked ->
                    ( RemoteCache.withLocalLoading blueprintId session.blueprints
                        |> flip Session.withBlueprintCache session
                    , Blueprint.loadFromLocalStorage blueprintId
                    )

                _ ->
                    ( session, Cmd.none )


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
    case result of
        Ok maybeBlueprint ->
            let
                blueprints =
                    session.blueprints
                        |> RemoteCache.withLocalValue blueprintId maybeBlueprint
                        |> RemoteCache.withExpectedValue blueprintId maybeBlueprint
                        |> RemoteCache.withActualValue blueprintId maybeBlueprint

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
            ( { session | blueprints = blueprints }, cmd )

        Err error ->
            let
                blueprints =
                    session.blueprints
                        |> RemoteCache.withLocalValue blueprintId maybeBlueprint
                        |> RemoteCache.withExpectedValue blueprintId maybeBlueprint
                        |> RemoteCache.withActualValue blueprintId maybeBlueprint

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




-- SAVE

saveBlueprint : Blueprint -> Session -> (Session, Cmd SessionMsg)
saveBlueprint blueprint session =
    Debug.todo "save blueprint"
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
