module Resource.Blueprint.Update exposing
    ( clear
    , deleteBlueprint
    , fromExpectedKey
    , fromLocalKey
    , getAllBlueprintsForUser
    , getBlueprintByBlueprintId
    , gotDeleteBlueprintResponse
    , gotLoadBlueprintByBlueprintIdResponse
    , gotSaveBlueprintResponse
    , init
    , keepLocal
    , keepServer
    , loadAllBlueprintsForUser
    , loadBlueprintByBlueprintId
    , loadBlueprintsByBlueprintIds
    , path
    , resolveConflict
    , saveBlueprint
    , toExpectedKey
    , toLocalKey
    , writeActual
    , writeExpected
    , writeLocal
    )

import Api.GCP as GCP
import Basics.Extra exposing (flip, uncurry)
import Data.Blueprint exposing (Blueprint, decoder, encode)
import Data.BlueprintId exposing (BlueprintId)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater, withCmd)
import Data.GetError as GetError exposing (GetError)
import Data.SaveError as SaveError exposing (SaveError)
import Data.SaveRequest exposing (SaveRequest(..))
import Data.Session as Session exposing (Session, updateBlueprints)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Dict
import Extra.Result
import Extra.Tuple exposing (fanout)
import Json.Decode as Decode exposing (nullable)
import Json.Encode as Encode
import Json.Encode.Extra
import Maybe.Extra
import Ports.Console as Console
import Ports.LocalStorage exposing (decodeLocalStorageEntry, storageRemoveItem, storageSetItem)
import RemoteData exposing (RemoteData(..))
import Resource.Blueprint.BlueprintResource as BlueprintResource exposing (BlueprintResource, empty, updateActual, updateExpected, updateLocal, updateSaving, withLoadAllBlueprintsRemoteData)
import Resource.MIsc as Misc
import Update.General exposing (gotGetError, gotSaveError)
import Update.SessionMsg exposing (SessionMsg(..))



-- INIT


init : List ( String, Encode.Value ) -> ( BlueprintResource, List ( String, Decode.Error ) )
init localStorageEntries =
    let
        ( localBlueprints, localErrors ) =
            List.filterMap (decodeLocalStorageEntry fromLocalKey (nullable decoder)) localStorageEntries
                |> Extra.Result.split

        ( expectedBlueprints, expectedErrors ) =
            List.filterMap (decodeLocalStorageEntry fromExpectedKey (nullable decoder)) localStorageEntries
                |> Extra.Result.split
    in
    ( { empty
        | local = Dict.fromList localBlueprints
        , expected = Dict.fromList expectedBlueprints
      }
    , List.concat
        [ localErrors
        , expectedErrors
        ]
    )



-- KEEP


keepLocal : BlueprintId -> CmdUpdater Session SessionMsg
keepLocal blueprintId session =
    case Dict.get blueprintId session.blueprints.local of
        Just maybeBlueprint ->
            writeActual blueprintId maybeBlueprint session

        Nothing ->
            ( session
            , Console.errorString "ecq6d8lfd70n9h0o    Cannot keep local blueprint: nothing to keep"
            )


keepServer : BlueprintId -> CmdUpdater Session SessionMsg
keepServer blueprintId session =
    case
        Dict.get blueprintId session.blueprints.actual
            |> Maybe.andThen RemoteData.toMaybe
    of
        Just maybeBlueprint ->
            CmdUpdater.batch
                [ writeExpected blueprintId maybeBlueprint
                , writeLocal blueprintId maybeBlueprint
                ]
                session

        Nothing ->
            ( session
            , Console.errorString "q2j8ldsa077qm2a7    Cannot keep server blueprint, it's not successfully loaded."
            )



-- BY BLUEPRINT ID


loadBlueprintsByBlueprintIds : List BlueprintId -> CmdUpdater Session SessionMsg
loadBlueprintsByBlueprintIds blueprintIds session =
    List.map loadBlueprintByBlueprintId blueprintIds
        |> flip CmdUpdater.batch session


loadBlueprintByBlueprintId : BlueprintId -> CmdUpdater Session SessionMsg
loadBlueprintByBlueprintId blueprintId session =
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            if
                Dict.get blueprintId session.blueprints.actual
                    |> Maybe.withDefault NotAsked
                    |> RemoteData.isNotAsked
            then
                Dict.insert blueprintId Loading
                    |> BlueprintResource.updateActual
                    |> flip Session.updateBlueprints session
                    |> withCmd
                        (GCP.get
                            |> GCP.withPath path
                            |> GCP.withAccessToken accessToken
                            |> GCP.withStringQueryParameter "blueprintId" blueprintId
                            |> GCP.request (GetError.expectMaybe decoder (GotLoadBlueprintResponse blueprintId))
                        )

            else
                ( session, Cmd.none )

        Nothing ->
            Dict.insert blueprintId NotAsked
                |> BlueprintResource.updateActual
                |> flip Session.updateBlueprints session
                |> CmdUpdater.id


getBlueprintByBlueprintId : BlueprintId -> Session -> RemoteData GetError (Maybe Blueprint)
getBlueprintByBlueprintId blueprintId session =
    -- TODO Think about how this is supposed to work
    case Dict.get blueprintId session.blueprints.actual of
        Nothing ->
            NotAsked

        Just Loading ->
            Loading

        Just (Failure error) ->
            Failure error

        _ ->
            Dict.get blueprintId session.blueprints.local
                |> Maybe.Extra.join
                |> Success


gotLoadBlueprintByBlueprintIdResponse : BlueprintId -> Result GetError (Maybe Blueprint) -> CmdUpdater Session SessionMsg
gotLoadBlueprintByBlueprintIdResponse blueprintId result oldSession =
    let
        session =
            RemoteData.fromResult result
                |> Dict.insert blueprintId
                |> updateActual
                |> flip updateBlueprints oldSession
    in
    case result of
        Ok maybeActual ->
            resolveConflict blueprintId maybeActual session

        Err error ->
            gotGetError error session



-- ALL FOR USER


loadAllBlueprintsForUser : CmdUpdater Session SessionMsg
loadAllBlueprintsForUser session =
    let
        loadAllBlueprintsCmd accessToken =
            GCP.get
                |> GCP.withPath path
                |> GCP.withAccessToken accessToken
                |> GCP.request (GetError.expect (Decode.list decoder) GotLoadBlueprintsResponse)
    in
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            if
                session.blueprints.loadAllBlueprintsRemoteData
                    |> Maybe.withDefault NotAsked
                    |> RemoteData.isNotAsked
            then
                withLoadAllBlueprintsRemoteData (Just Loading)
                    |> flip updateBlueprints session
                    |> withCmd (loadAllBlueprintsCmd accessToken)

            else
                ( session, Cmd.none )

        Nothing ->
            withCmd Cmd.none <|
                if Maybe.Extra.isNothing session.blueprints.loadAllBlueprintsRemoteData then
                    withLoadAllBlueprintsRemoteData (Just NotAsked)
                        |> flip updateBlueprints session

                else
                    session


getAllBlueprintsForUser : Session -> RemoteData GetError (List Blueprint)
getAllBlueprintsForUser session =
    case session.blueprints.loadAllBlueprintsRemoteData of
        Just remoteData ->
            if RemoteData.isLoading remoteData then
                Loading

            else
                Dict.values session.blueprints.local
                    |> Maybe.Extra.values
                    |> Success

        Nothing ->
            NotAsked


gotLoadBlueprintsResponse : Result GetError (List Blueprint) -> CmdUpdater Session SessionMsg
gotLoadBlueprintsResponse result =
    let
        updateRequest =
            (RemoteData.fromResult result
                |> Just
                |> withLoadAllBlueprintsRemoteData
                |> updateBlueprints
            )
                >> CmdUpdater.id
    in
    CmdUpdater.batch <|
        (::) updateRequest <|
            case result of
                Ok blueprints ->
                    List.map (fanout .id Just) blueprints
                        |> List.map (uncurry resolveConflict)

                Err error ->
                    [ gotGetError error ]



-- SAVE


saveBlueprint : Blueprint -> CmdUpdater Session SessionMsg
saveBlueprint blueprint =
    CmdUpdater.batch
        [ writeLocal blueprint.id (Just blueprint)
        , writeActual blueprint.id (Just blueprint)
        ]


gotSaveBlueprintResponse : Blueprint -> Maybe SaveError -> CmdUpdater Session msg
gotSaveBlueprintResponse blueprint maybeError =
    CmdUpdater.batch <|
        case maybeError of
            Just error ->
                [ (Dict.insert blueprint.id (Error error)
                    |> updateSaving
                    |> updateBlueprints
                  )
                    >> CmdUpdater.id
                , gotSaveError error
                ]

            Nothing ->
                [ (Dict.insert blueprint.id (Saved (Just blueprint))
                    |> updateSaving
                    |> updateBlueprints
                  )
                    >> CmdUpdater.id
                , (Dict.insert blueprint.id (Success (Just blueprint))
                    |> updateActual
                    |> updateBlueprints
                  )
                    >> CmdUpdater.id
                , writeExpected blueprint.id Nothing
                ]



-- DELETE


deleteBlueprint : BlueprintId -> CmdUpdater Session SessionMsg
deleteBlueprint blueprintId =
    CmdUpdater.batch
        [ writeLocal blueprintId Nothing
        , writeActual blueprintId Nothing
        ]


gotDeleteBlueprintResponse : BlueprintId -> Maybe SaveError -> CmdUpdater Session msg
gotDeleteBlueprintResponse blueprintId maybeError =
    CmdUpdater.batch <|
        case maybeError of
            Just error ->
                [ (Dict.insert blueprintId (Error error)
                    |> updateSaving
                    |> updateBlueprints
                  )
                    >> CmdUpdater.id
                , gotSaveError error
                ]

            Nothing ->
                [ (Dict.insert blueprintId (Saved Nothing)
                    |> updateSaving
                    |> updateBlueprints
                  )
                    >> CmdUpdater.id
                , (Dict.insert blueprintId (Success Nothing)
                    |> updateActual
                    |> updateBlueprints
                  )
                    >> CmdUpdater.id
                , writeExpected blueprintId Nothing
                ]



-- CLEAR


clear : CmdUpdater Session msg
clear session =
    ( updateBlueprints (always empty) session
    , Cmd.batch
        [ Dict.keys session.blueprints.local
            |> List.map toLocalKey
            |> List.map storageRemoveItem
            |> Cmd.batch
        , Dict.keys session.blueprints.expected
            |> List.map toExpectedKey
            |> List.map storageRemoveItem
            |> Cmd.batch
        ]
    )



-- PRIVATE


path : List String
path =
    [ "blueprints" ]


writeLocal : BlueprintId -> Maybe Blueprint -> CmdUpdater Session msg
writeLocal blueprintId maybeBlueprint session =
    ( Dict.insert blueprintId maybeBlueprint
        |> updateLocal
        |> flip updateBlueprints session
    , storageSetItem ( toLocalKey blueprintId, Json.Encode.Extra.maybe encode maybeBlueprint )
    )


writeExpected : BlueprintId -> Maybe Blueprint -> CmdUpdater Session msg
writeExpected blueprintId maybeBlueprint session =
    ( Dict.insert blueprintId maybeBlueprint
        |> updateExpected
        |> flip updateBlueprints session
    , storageSetItem ( toExpectedKey blueprintId, Json.Encode.Extra.maybe encode maybeBlueprint )
    )


writeActual : BlueprintId -> Maybe Blueprint -> CmdUpdater Session SessionMsg
writeActual blueprintId maybeBlueprint session =
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            case maybeBlueprint of
                Just blueprint ->
                    ( Dict.insert blueprintId (Saving (Just blueprint))
                        |> updateSaving
                        |> flip updateBlueprints session
                    , GCP.put
                        |> GCP.withPath path
                        |> GCP.withAccessToken accessToken
                        |> GCP.withBody (encode blueprint)
                        |> GCP.request (SaveError.expect (GotSaveBlueprintResponse blueprint))
                    )

                Nothing ->
                    ( Dict.insert blueprintId (Saving Nothing)
                        |> updateSaving
                        |> flip updateBlueprints session
                    , GCP.delete
                        |> GCP.withPath path
                        |> GCP.withStringQueryParameter "blueprintId" blueprintId
                        |> GCP.withAccessToken accessToken
                        |> GCP.request (SaveError.expect (GotDeleteBlueprintResponse blueprintId))
                    )

        Nothing ->
            ( session, Cmd.none )


resolveConflict : BlueprintId -> Maybe Blueprint -> CmdUpdater Session SessionMsg
resolveConflict blueprintId maybeActualBlueprint session =
    Misc.resolveConflict
        { maybeLocal = Dict.get blueprintId session.blueprints.local
        , maybeExpected = Dict.get blueprintId session.blueprints.expected
        , maybeActual = maybeActualBlueprint
        , writeLocal = writeLocal blueprintId
        , writeExpected = writeExpected blueprintId
        , writeActual = writeActual blueprintId
        , equals = (==)
        }
        session


fromLocalKey : String -> Maybe BlueprintId
fromLocalKey key =
    case String.split "." key of
        "blueprints" :: blueprintId :: [] ->
            Just blueprintId

        _ ->
            Nothing


fromExpectedKey : String -> Maybe BlueprintId
fromExpectedKey key =
    case String.split "." key of
        "blueprints" :: blueprintId :: "remote" :: [] ->
            Just blueprintId

        _ ->
            Nothing


toLocalKey : BlueprintId -> String
toLocalKey blueprintId =
    String.join "." [ "blueprints", blueprintId ]


toExpectedKey : BlueprintId -> String
toExpectedKey blueprintId =
    String.join "." [ toLocalKey blueprintId, "remote" ]
