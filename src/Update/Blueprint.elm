module Update.Blueprint exposing
    ( deleteBlueprint
    , getBlueprintByBlueprintId
    , gotDeleteBlueprintResponse
    , gotLoadBlueprintResponse
    , gotLoadBlueprintsResponse
    , gotSaveBlueprintResponse
    , loadBlueprintByBlueprintId
    , loadBlueprints
    , loadBlueprintsByBlueprintIds
    , saveBlueprint
    )

import Basics.Extra exposing (flip, uncurry)
import Data.Blueprint as Blueprint exposing (Blueprint)
import Data.BlueprintId exposing (BlueprintId)
import Data.Cache as Cache
import Data.CmdUpdater as CmdUpdater
import Data.GetError exposing (GetError)
import Data.RemoteCache as RemoteCache
import Data.SaveError exposing (SaveError)
import Data.Session as Session exposing (Session)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Debug exposing (todo)
import Dict
import Extra.Tuple exposing (fanout)
import RemoteData exposing (RemoteData(..))
import Update.General exposing (gotGetError, gotSaveError)
import Update.SessionMsg exposing (SessionMsg(..))



-- LOAD


loadBlueprintByBlueprintId : BlueprintId -> Session -> ( Session, Cmd SessionMsg )
loadBlueprintByBlueprintId blueprintId session =
    case VerifiedAccessToken.getValid session.accessToken of
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
            ( session, Cmd.none )


getBlueprintByBlueprintId : BlueprintId -> Session -> RemoteData GetError (Maybe Blueprint)
getBlueprintByBlueprintId blueprintId session =
    todo ""


loadBlueprints : Session -> ( Session, Cmd SessionMsg )
loadBlueprints session =
    case session.actualBlueprintsRequest of
        NotAsked ->
            case VerifiedAccessToken.getValid session.accessToken of
                Just accessToken ->
                    ( { session | actualBlueprintsRequest = Loading }
                    , Blueprint.loadAllFromServer GotLoadBlueprintsResponse accessToken
                    )

                Nothing ->
                    ( session, Cmd.none )

        _ ->
            ( session, Cmd.none )


loadBlueprintsByBlueprintIds : List BlueprintId -> Session -> ( Session, Cmd SessionMsg )
loadBlueprintsByBlueprintIds blueprintIds =
    CmdUpdater.batch (List.map loadBlueprintByBlueprintId blueprintIds)


gotLoadBlueprintResponse : BlueprintId -> Result GetError (Maybe Blueprint) -> Session -> ( Session, Cmd SessionMsg )
gotLoadBlueprintResponse blueprintId result session =
    case result of
        Ok maybeBlueprint ->
            gotActualBlueprint blueprintId maybeBlueprint session

        Err error ->
            let
                sessionWithActualBlueprintResult =
                    { session | blueprints = RemoteCache.withActualResult blueprintId result session.blueprints }
            in
            gotGetError error sessionWithActualBlueprintResult


gotLoadBlueprintsResponse : Result GetError (List Blueprint) -> Session -> ( Session, Cmd SessionMsg )
gotLoadBlueprintsResponse result session =
    let
        sessionWithBlueprintResponse =
            { session | actualBlueprintsRequest = RemoteData.fromResult (Result.map (always ()) result) }
    in
    case result of
        Ok blueprints ->
            List.map (fanout .id Just) blueprints
                |> List.map (uncurry gotActualBlueprint)
                |> flip CmdUpdater.batch sessionWithBlueprintResponse

        Err error ->
            gotGetError error sessionWithBlueprintResponse


gotActualBlueprint : BlueprintId -> Maybe Blueprint -> Session -> ( Session, Cmd SessionMsg )
gotActualBlueprint blueprintId maybeActualBlueprint oldSession =
    let
        sessionWithActualBlueprint =
            { oldSession | blueprints = RemoteCache.withActualValue blueprintId maybeActualBlueprint oldSession.blueprints }

        maybeLocalBlueprint =
            Dict.get blueprintId sessionWithActualBlueprint.blueprints.local

        maybeExpectedBlueprint =
            Dict.get blueprintId sessionWithActualBlueprint.blueprints.expected

        overwriteLocal maybeBlueprint session =
            ( { session | blueprints = RemoteCache.withLocalValue blueprintId maybeBlueprint session.blueprints }
            , case maybeBlueprint of
                Just blueprint ->
                    Blueprint.saveToLocalStorage blueprint

                Nothing ->
                    Blueprint.removeFromLocalStorage blueprintId
            )

        overwriteExpected maybeBlueprint session =
            ( { session | blueprints = RemoteCache.withExpectedValue blueprintId maybeBlueprint session.blueprints }
            , case maybeBlueprint of
                Just blueprint ->
                    Blueprint.saveRemoteToLocalStorage blueprint

                Nothing ->
                    Blueprint.removeRemoteFromLocalStorage blueprintId
            )

        functions =
            case ( maybeLocalBlueprint, maybeExpectedBlueprint, maybeActualBlueprint ) of
                ( Just (Just localBlueprint), Just (Just expectedBlueprint), Just actualBlueprint ) ->
                    if localBlueprint == expectedBlueprint then
                        [ overwriteLocal maybeActualBlueprint, overwriteExpected maybeActualBlueprint ]

                    else if localBlueprint == actualBlueprint then
                        [ overwriteExpected maybeActualBlueprint ]

                    else if expectedBlueprint == actualBlueprint then
                        []

                    else
                        Debug.todo "1 2 3"

                ( Just (Just localBlueprint), Just (Just expectedBlueprint), Nothing ) ->
                    if localBlueprint == expectedBlueprint then
                        [ overwriteLocal Nothing, overwriteExpected Nothing ]

                    else
                        Debug.todo "1 2 0"

                ( Just (Just localBlueprint), Just Nothing, Just actualBlueprint ) ->
                    if localBlueprint == actualBlueprint then
                        [ overwriteExpected maybeActualBlueprint ]

                    else
                        Debug.todo "1 0 2"

                ( Just (Just localBlueprint), Nothing, Just actualBlueprint ) ->
                    if localBlueprint == actualBlueprint then
                        [ overwriteExpected maybeActualBlueprint ]

                    else
                        Debug.todo "1 ? 2"

                ( Just (Just localBlueprint), Nothing, Nothing ) ->
                    Debug.todo "1 ? 0"

                ( Just Nothing, Just (Just expectedBlueprint), Just actualBlueprint ) ->
                    if expectedBlueprint == actualBlueprint then
                        Debug.todo "0 1 1"

                    else
                        Debug.todo "0 1 2"

                ( Just Nothing, Just Nothing, Just actualBlueprint ) ->
                    Debug.todo "0 0 1"

                ( Just Nothing, _, Nothing ) ->
                    [ overwriteLocal maybeActualBlueprint, overwriteExpected maybeActualBlueprint ]

                ( Just Nothing, Nothing, _ ) ->
                    [ overwriteLocal maybeActualBlueprint, overwriteExpected maybeActualBlueprint ]

                ( Nothing, _, _ ) ->
                    [ overwriteLocal maybeActualBlueprint, overwriteExpected maybeActualBlueprint ]
    in
    fold functions sessionWithActualBlueprint



-- SAVE


saveBlueprint : Blueprint -> Session -> ( Session, Cmd SessionMsg )
saveBlueprint blueprint session =
    let
        blueprints =
            RemoteCache.withLocalValue blueprint.id (Just blueprint) session.blueprints

        saveActualBlueprint =
            Session.getAccessToken session
                |> Maybe.map (Blueprint.saveToServer GotSaveBlueprintResponse blueprint)
                |> Maybe.withDefault Cmd.none

        saveLocalBlueprint =
            Blueprint.saveToLocalStorage blueprint
    in
    ( { session | blueprints = blueprints }
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
deleteBlueprint blueprintId session =
    let
        removeLocalBlueprintCmd =
            Blueprint.removeFromLocalStorage blueprintId

        removeActualBlueprintCmd =
            Session.getAccessToken session
                |> Maybe.map (Blueprint.deleteFromServer GotDeleteBlueprintResponse blueprintId)
                |> Maybe.withDefault Cmd.none
    in
    ( { session | blueprints = RemoteCache.withLocalValue blueprintId Nothing session.blueprints }
    , Cmd.batch
        [ removeLocalBlueprintCmd
        , removeActualBlueprintCmd
        ]
    )


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
