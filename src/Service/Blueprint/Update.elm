module Resource.Blueprint.Update exposing
    ( clear
    , deleteBlueprint
    , getAllBlueprintsForUser
    , getBlueprintByBlueprintId
    , gotDeleteBlueprintResponse
    , gotLoadBlueprintByBlueprintIdResponse
    , gotSaveBlueprintResponse
    , keepLocal
    , keepServer
    , loadAllBlueprintsForUser
    , loadBlueprintByBlueprintId
    , loadBlueprintsByBlueprintIds
    , path
    , resolveConflict
    , saveBlueprint
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
import Data.SaveError exposing (SaveError)
import Data.Session exposing (Session, updateBlueprints)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Dict
import Extra.Tuple exposing (fanout)
import Json.Decode as Decode
import Maybe.Extra
import Ports.Console as Console
import RemoteData exposing (RemoteData(..))
import Resource.Blueprint.BlueprintResource exposing (..)
import Resource.ModifiableResource exposing (..)
import Resource.ResourceUpdater as ResourceUpdater exposing (PrivateInterface, deleteResourceById, gotDeleteResourceByIdResponse, gotGetError, gotLoadResourceByIdResponse, gotSaveResourceResponse, loadResourceById, loadResourcesByIds, resolveConflict, resolveManuallyKeepLocal, resolveManuallyKeepServer, saveResource)
import Update.SessionMsg exposing (SessionMsg(..))


interface : PrivateInterface BlueprintId Blueprint a
interface =
    { getResource = .blueprints
    , updateResource = updateBlueprints
    , path = [ "blueprints" ]
    , idParameterName = "blueprintId"
    , encode = encode
    , decoder = decoder
    , gotLoadResourceResponse = GotLoadBlueprintResponse
    , gotSaveResponseMessage = GotSaveBlueprintResponse
    , gotDeleteResponseMessage = GotDeleteBlueprintResponse
    , idToString = identity
    , idFromString = identity
    , localStoragePrefix = "blueprints"
    , equals = (==)
    , empty = empty
    }



-- MANUAL CONFLICT RESOLUTION


keepLocal : BlueprintId -> CmdUpdater Session SessionMsg
keepLocal =
    resolveManuallyKeepLocal interface


keepServer : BlueprintId -> CmdUpdater Session SessionMsg
keepServer =
    resolveManuallyKeepServer interface



-- BY BLUEPRINT ID


loadBlueprintsByBlueprintIds : List BlueprintId -> CmdUpdater Session SessionMsg
loadBlueprintsByBlueprintIds =
    loadResourcesByIds interface


loadBlueprintByBlueprintId : BlueprintId -> CmdUpdater Session SessionMsg
loadBlueprintByBlueprintId =
    loadResourceById interface


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
gotLoadBlueprintByBlueprintIdResponse =
    gotLoadResourceByIdResponse interface



-- ALL FOR USER


loadAllBlueprintsForUser : CmdUpdater Session SessionMsg
loadAllBlueprintsForUser session =
    let
        loadAllBlueprintsCmd accessToken =
            GCP.get
                |> GCP.withPath interface.path
                |> GCP.withAccessToken accessToken
                |> GCP.request (GetError.expect (Decode.list decoder) GotLoadBlueprintsResponse)
    in
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            if
                interface.getResource session
                    |> .loadAllBlueprintsRemoteData
                    |> RemoteData.isNotAsked
            then
                withLoadAllBlueprintsRemoteData Loading
                    |> flip updateBlueprints session
                    |> withCmd (loadAllBlueprintsCmd accessToken)

            else
                ( session, Cmd.none )

        Nothing ->
            -- TODO Handle offline
            ( session, Cmd.none )


gotLoadBlueprintsResponse : Result GetError (List Blueprint) -> Session -> ( Session, Cmd SessionMsg )
gotLoadBlueprintsResponse result oldSession =
    let
        session =
            RemoteData.fromResult result
                |> RemoteData.map (always ())
                |> withLoadAllBlueprintsRemoteData
                |> flip interface.updateResource oldSession
    in
    case result of
        Ok blueprints ->
            List.map (fanout .id Just) blueprints
                |> List.map (uncurry (resolveConflict interface))
                |> flip CmdUpdater.batch session

        Err error ->
            gotGetError error session



-- SAVE


saveBlueprint : Blueprint -> CmdUpdater Session SessionMsg
saveBlueprint =
    saveResource interface


gotSaveBlueprintResponse : Blueprint -> Maybe SaveError -> CmdUpdater Session msg
gotSaveBlueprintResponse =
    gotSaveResourceResponse interface



-- DELETE


deleteBlueprint : BlueprintId -> CmdUpdater Session SessionMsg
deleteBlueprint =
    deleteResourceById interface


gotDeleteBlueprintResponse : BlueprintId -> Maybe SaveError -> CmdUpdater Session msg
gotDeleteBlueprintResponse =
    gotDeleteResourceByIdResponse interface



-- CLEAR


clear : Session -> ( Session, Cmd msg )
clear session =
    ResourceUpdater.clear interface session
        |> Tuple.mapFirst (updateBlueprints (always empty))
