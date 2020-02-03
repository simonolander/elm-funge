module Service.Blueprint.BlueprintService exposing
    ( clear
    , createFromLocalStorageEntries
    , deleteBlueprint
    , getAllBlueprintsForUser
    , getBlueprintByBlueprintId
    , getConflicts
    , gotDeleteBlueprintResponse
    , gotLoadBlueprintByBlueprintIdResponse
    , gotLoadBlueprintsResponse
    , gotSaveBlueprintResponse
    , loadAllBlueprintsForUser
    , loadBlueprintByBlueprintId
    , loadBlueprintsByBlueprintIds
    , loadChanged
    , resolveManuallyKeepLocalBlueprint
    , resolveManuallyKeepServerBlueprint
    , saveBlueprint
    )

import Api.GCP as GCP
import Basics.Extra exposing (flip, uncurry)
import Data.Blueprint as Blueprint exposing (Blueprint, decoder)
import Data.BlueprintId exposing (BlueprintId)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater, withCmd)
import Data.GetError as GetError exposing (GetError)
import Data.OneOrBoth as OneOrBoth exposing (OneOrBoth)
import Data.SaveError exposing (SaveError)
import Data.Session exposing (Session, updateBlueprints)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Dict
import Extra.Tuple exposing (fanout)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Service.Blueprint.BlueprintResource exposing (..)
import Service.ConflictResolutionService exposing (getAllManualConflicts, resolveManuallyKeepLocalResource, resolveManuallyKeepServerResource)
import Service.InterfaceHelper exposing (createModifiableRemoteResourceInterface)
import Service.LoadResourceService exposing (gotGetError, gotLoadResourceByIdResponse, loadPrivateResourceById)
import Service.LocalStorageService exposing (getResourcesFromLocalStorageEntries)
import Service.ModifiableRemoteResource as ModifiableRemoteResource
import Service.ModifyResourceService exposing (deleteResourceById, gotDeleteResourceByIdResponse, gotSaveResourceResponse, saveResource)
import Service.ResourceType as ResourceType exposing (toPath)
import Update.SessionMsg exposing (SessionMsg(..))


interface =
    createModifiableRemoteResourceInterface
        { getRemoteResource = .blueprints
        , setRemoteResource = \r s -> { s | blueprints = r }
        , encode = Blueprint.encode
        , decoder = Blueprint.decoder
        , resourceType = ResourceType.Blueprint
        , toString = identity
        , toKey = identity
        , fromKey = identity
        , fromString = identity
        , equals = (==)
        , responseMsg = GotLoadBlueprintResponse
        , gotSaveResponseMessage = GotSaveBlueprintResponse
        , gotDeleteResponseMessage = GotDeleteBlueprintResponse
        }


createFromLocalStorageEntries : List ( String, Encode.Value ) -> ( BlueprintResource, List ( String, Decode.Error ) )
createFromLocalStorageEntries localStorageEntries =
    let
        { current, expected, errors } =
            getResourcesFromLocalStorageEntries interface localStorageEntries
    in
    ( { empty
        | local = Dict.fromList current
        , expected = Dict.fromList expected
      }
    , errors
    )



-- BY BLUEPRINT ID


loadBlueprintsByBlueprintIds : List BlueprintId -> CmdUpdater Session SessionMsg
loadBlueprintsByBlueprintIds blueprintIds session =
    List.map loadBlueprintByBlueprintId blueprintIds
        |> flip CmdUpdater.batch session


loadBlueprintByBlueprintId : BlueprintId -> CmdUpdater Session SessionMsg
loadBlueprintByBlueprintId =
    loadPrivateResourceById interface


getBlueprintByBlueprintId : BlueprintId -> Session -> RemoteData GetError (Maybe Blueprint)
getBlueprintByBlueprintId blueprintId session =
    interface.getRemoteResource session
        |> ModifiableRemoteResource.getResourceById blueprintId


gotLoadBlueprintByBlueprintIdResponse : BlueprintId -> Result GetError (Maybe Blueprint) -> CmdUpdater Session SessionMsg
gotLoadBlueprintByBlueprintIdResponse =
    gotLoadResourceByIdResponse interface



-- ALL FOR USER


getAllBlueprintsForUser : Session -> RemoteData GetError (List Blueprint)
getAllBlueprintsForUser session =
    case
        interface.getRemoteResource session
            |> .loadAllBlueprintsRemoteData
    of
        NotAsked ->
            NotAsked

        Loading ->
            Loading

        -- TODO What if failure?
        Failure e ->
            let
                availableBlueprints =
                    interface.getRemoteResource session
                        |> .local
                        |> Dict.values
                        |> Maybe.Extra.values
            in
            if List.isEmpty availableBlueprints then
                Failure e

            else
                Success availableBlueprints

        Success () ->
            interface.getRemoteResource session
                |> .local
                |> Dict.values
                |> Maybe.Extra.values
                |> Success


loadAllBlueprintsForUser : CmdUpdater Session SessionMsg
loadAllBlueprintsForUser session =
    let
        loadAllBlueprintsCmd accessToken =
            GCP.get
                |> GCP.withPath (toPath interface.resourceType)
                |> GCP.withAccessToken accessToken
                |> GCP.request (GetError.expect (Decode.list decoder) GotLoadBlueprintsResponse)
    in
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            if
                interface.getRemoteResource session
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
                |> flip interface.updateRemoteResource oldSession
    in
    case result of
        Ok blueprints ->
            List.map (fanout .id Just) blueprints
                |> List.map (uncurry interface.mergeResource)
                |> flip CmdUpdater.batch session

        Err error ->
            gotGetError error session



-- SAVE


saveBlueprint : Blueprint -> CmdUpdater Session SessionMsg
saveBlueprint =
    saveResource interface


gotSaveBlueprintResponse : Blueprint -> Maybe SaveError -> CmdUpdater Session SessionMsg
gotSaveBlueprintResponse =
    gotSaveResourceResponse interface



-- DELETE


deleteBlueprint : BlueprintId -> CmdUpdater Session SessionMsg
deleteBlueprint =
    deleteResourceById interface


gotDeleteBlueprintResponse : BlueprintId -> Maybe SaveError -> CmdUpdater Session SessionMsg
gotDeleteBlueprintResponse =
    gotDeleteResourceByIdResponse interface



-- MANUAL CONFLICT RESOLUTION


loadChanged : CmdUpdater Session SessionMsg
loadChanged session =
    interface.getRemoteResource session
        |> fanout .local .expected
        |> uncurry OneOrBoth.fromDicts
        |> List.filterMap OneOrBoth.join
        |> List.filter (OneOrBoth.areSame (==) >> not)
        |> List.map (OneOrBoth.map .id >> OneOrBoth.any)
        |> flip loadBlueprintsByBlueprintIds session


getConflicts : Session -> List (OneOrBoth Blueprint)
getConflicts =
    getAllManualConflicts interface


resolveManuallyKeepLocalBlueprint : BlueprintId -> Session -> ( Session, Cmd SessionMsg )
resolveManuallyKeepLocalBlueprint =
    resolveManuallyKeepLocalResource interface


resolveManuallyKeepServerBlueprint : BlueprintId -> Session -> ( Session, Cmd SessionMsg )
resolveManuallyKeepServerBlueprint =
    resolveManuallyKeepServerResource interface
