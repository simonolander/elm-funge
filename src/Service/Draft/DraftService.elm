module Service.Draft.DraftService exposing
    ( deleteDraftByDraftId
    , getConflicts
    , getDraftByDraftId
    , getDraftsByLevelId
    , gotDeleteDraftByIdResponse
    , gotLoadDraftByIdResponse
    , gotLoadDraftsByLevelIdResponse
    , gotSaveDraftResponse
    , loadChanged
    , loadDraftByDraftId
    , loadDraftsByDraftIds
    , loadDraftsByLevelId
    , resolveManuallyKeepLocalDraft
    , resolveManuallyKeepServerDraft
    , saveDraft
    )

import Api.GCP as GCP
import Basics.Extra exposing (flip, uncurry)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater, withCmd)
import Data.Draft as Draft exposing (Draft, decoder)
import Data.DraftId exposing (DraftId)
import Data.GetError exposing (GetError)
import Data.LevelId exposing (LevelId)
import Data.OneOrBoth as OneOrBoth exposing (OneOrBoth)
import Data.SaveError exposing (SaveError)
import Data.Session exposing (Session)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Dict
import Extra.Tuple exposing (fanout)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Service.ConflictResolutionService exposing (getAllManualConflicts, resolveManuallyKeepLocalResource, resolveManuallyKeepServerResource)
import Service.Draft.DraftResource exposing (DraftResource, empty, updateDraftsByLevelIdRequests)
import Service.InterfaceHelper exposing (createModifiableRemoteResourceInterface)
import Service.LoadResourceService exposing (LoadResourceInterface, gotGetError, gotLoadResourceByIdResponse, loadPrivateResourceById)
import Service.LocalStorageService exposing (getResourcesFromLocalStorageEntries)
import Service.ModifiableRemoteResource as ModifiableRemoteResource
import Service.ModifyResourceService exposing (deleteResourceById, gotDeleteResourceByIdResponse, gotSaveResourceResponse, saveResource)
import Service.RemoteRequestDict as RemoteRequestDict
import Service.ResourceType as ResourceType exposing (toIdParameterName, toPath)
import Update.SessionMsg exposing (SessionMsg(..))


interface =
    createModifiableRemoteResourceInterface
        { getRemoteResource = .drafts
        , setRemoteResource = \r s -> { s | drafts = r }
        , encode = Draft.encode
        , decoder = Draft.decoder
        , resourceType = ResourceType.Draft
        , toString = identity
        , toKey = identity
        , fromKey = identity
        , fromString = identity
        , equals = Draft.eq
        , responseMsg = GotLoadDraftByDraftIdResponse
        , gotSaveResponseMessage = GotSaveDraftResponse
        , gotDeleteResponseMessage = GotDeleteDraftByDraftIdResponse
        }


createFromLocalStorageEntries : List ( String, Encode.Value ) -> ( DraftResource, List ( String, Decode.Error ) )
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



-- MANUAL CONFLICT RESOLUTION


loadChanged : CmdUpdater Session SessionMsg
loadChanged session =
    interface.getRemoteResource session
        |> fanout .local .expected
        |> uncurry OneOrBoth.fromDicts
        |> List.filterMap OneOrBoth.join
        |> List.filter (OneOrBoth.areSame Draft.eq >> not)
        |> List.map (OneOrBoth.map .id >> OneOrBoth.any)
        |> flip loadDraftsByDraftIds session


getConflicts : Session -> List (OneOrBoth Draft)
getConflicts session =
    getAllManualConflicts interface session


resolveManuallyKeepLocalDraft : DraftId -> Session -> ( Session, Cmd SessionMsg )
resolveManuallyKeepLocalDraft =
    resolveManuallyKeepLocalResource interface


resolveManuallyKeepServerDraft : DraftId -> Session -> ( Session, Cmd SessionMsg )
resolveManuallyKeepServerDraft =
    resolveManuallyKeepServerResource interface



-- LOAD BY ID


getDraftByDraftId : DraftId -> Session -> RemoteData GetError (Maybe Draft)
getDraftByDraftId draftId session =
    interface.getRemoteResource session
        |> ModifiableRemoteResource.getResourceById draftId


loadDraftsByDraftIds : List DraftId -> CmdUpdater Session SessionMsg
loadDraftsByDraftIds draftIds session =
    List.map loadDraftByDraftId draftIds
        |> flip CmdUpdater.batch session


loadDraftByDraftId : DraftId -> CmdUpdater Session SessionMsg
loadDraftByDraftId =
    loadPrivateResourceById interface


gotLoadDraftByIdResponse : DraftId -> Result GetError (Maybe Draft) -> CmdUpdater Session SessionMsg
gotLoadDraftByIdResponse =
    gotLoadResourceByIdResponse interface



-- LOAD BY LEVEL ID


getDraftsByLevelId : LevelId -> Session -> RemoteData GetError (List Draft)
getDraftsByLevelId levelId session =
    interface.getRemoteResource session
        |> .draftsByLevelIdRequests
        |> RemoteRequestDict.get levelId
        -- TODO What if error?
        |> RemoteData.map
            (interface.getRemoteResource session
                |> .local
                |> Dict.values
                |> Maybe.Extra.values
                |> List.filter (.id >> (==) levelId)
                |> always
            )


loadDraftsByLevelId : LevelId -> Session -> ( Session, Cmd SessionMsg )
loadDraftsByLevelId levelId session =
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            if
                interface.getRemoteResource session
                    |> .draftsByLevelIdRequests
                    |> Dict.get levelId
                    |> Maybe.withDefault NotAsked
                    |> RemoteData.isNotAsked
            then
                Dict.insert levelId Loading
                    |> updateDraftsByLevelIdRequests
                    |> flip interface.updateRemoteResource session
                    |> withCmd
                        (GCP.get
                            |> GCP.withPath (toPath interface.resourceType)
                            |> GCP.withAccessToken accessToken
                            |> GCP.withStringQueryParameter (toIdParameterName ResourceType.Level) levelId
                            |> GCP.request (Data.GetError.expect (Decode.list decoder) (GotLoadDraftsByLevelIdResponse levelId))
                        )

            else
                ( session, Cmd.none )

        Nothing ->
            ( session, Cmd.none )


gotLoadDraftsByLevelIdResponse : LevelId -> Result GetError (List Draft) -> Session -> ( Session, Cmd SessionMsg )
gotLoadDraftsByLevelIdResponse levelId result oldSession =
    let
        session =
            RemoteData.fromResult result
                |> RemoteData.map (always ())
                |> Dict.insert levelId
                |> updateDraftsByLevelIdRequests
                |> flip interface.updateRemoteResource oldSession
    in
    case result of
        Ok drafts ->
            List.map (fanout .id Just) drafts
                |> List.map (uncurry interface.mergeResource)
                |> flip CmdUpdater.batch session

        Err error ->
            gotGetError error session



-- SAVE


saveDraft : Draft -> Session -> ( Session, Cmd SessionMsg )
saveDraft =
    saveResource interface


gotSaveDraftResponse : Draft -> Maybe SaveError -> Session -> ( Session, Cmd SessionMsg )
gotSaveDraftResponse =
    gotSaveResourceResponse interface



-- DELETE


deleteDraftByDraftId : DraftId -> Session -> ( Session, Cmd SessionMsg )
deleteDraftByDraftId =
    deleteResourceById interface


gotDeleteDraftByIdResponse : DraftId -> Maybe SaveError -> Session -> ( Session, Cmd SessionMsg )
gotDeleteDraftByIdResponse =
    gotDeleteResourceByIdResponse interface
