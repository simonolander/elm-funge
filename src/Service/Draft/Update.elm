module Resource.Draft.Update exposing
    ( deleteDraftByDraftId
    , getDraftByDraftId
    , getDraftsByLevelId
    , gotDeleteDraftByIdResponse
    , gotLoadDraftByIdResponse
    , gotLoadDraftsByLevelIdResponse
    , gotSaveDraftResponse
    , loadDraftByDraftId
    , loadDraftsByDraftIds
    , loadDraftsByLevelId
    , saveDraft
    )

import Api.GCP as GCP
import Basics.Extra exposing (flip, uncurry)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater, withCmd)
import Data.Draft as Draft exposing (Draft, decoder, encode)
import Data.DraftId exposing (DraftId)
import Data.GetError exposing (GetError)
import Data.LevelId exposing (LevelId)
import Data.SaveError exposing (SaveError)
import Data.Session exposing (Session)
import Data.Updater exposing (Updater)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Dict
import Extra.Tuple exposing (fanout)
import Json.Decode
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Resource.Draft.DraftResource exposing (DraftResource, empty, updateDraftsByLevelIdRequests)
import Resource.LoadResourceService exposing (LoadResourceInterface)
import Resource.ResourceType as ResourceType
import Resource.ResourceUpdater exposing (PrivateInterface, deleteResourceById, getResourceById, gotDeleteResourceByIdResponse, gotGetError, gotLoadResourceByIdResponse, gotSaveResourceResponse, loadResourceById, resolveConflict, saveResource)
import Update.SessionMsg exposing (SessionMsg(..))


interface : PrivateInterface DraftId Draft a
interface =
    { getResource = .drafts
    , updateResource = updateResource
    , path = [ "drafts" ]
    , idParameterName = "draftId"
    , encode = encode
    , decoder = decoder
    , gotLoadResourceResponse = GotLoadDraftByDraftIdResponse
    , gotSaveResponseMessage = GotSaveDraftResponse
    , gotDeleteResponseMessage = GotDeleteDraftResponse
    , idToString = identity
    , idFromString = identity
    , localStoragePrefix = "drafts"
    , equals = Draft.eq
    , empty = empty
    }


loadInterface : LoadResourceInterface DraftId Draft DraftId {}
loadInterface =
    let
        getter =
            .drafts

        setter r s =
            { s | drafts = r }

        updater u s =
            getter s |> u |> flip setter s

        merger i r s =
            insertValue id r
                |> flip updateSession s
                |> CmdUpdater.id
    in
    { updateSession = updateSession
    , getResourceDict = .levels >> .cache
    , resourceType = ResourceType.Draft
    , decoder = decoder
    , responseMsg = GotLoadDraftByDraftIdResponse
    , toKey = identity
    , toString = identity
    , mergeResource = mergeLevel
    }



-- GET


getDraftByDraftId : DraftId -> Session -> RemoteData GetError (Maybe Draft)
getDraftByDraftId =
    getResourceById interface


getDraftsByLevelId : LevelId -> Session -> RemoteData GetError (List Draft)
getDraftsByLevelId levelId session =
    interface.getResource session
        |> .draftsByLevelIdRequests
        |> Dict.get levelId
        |> Maybe.withDefault NotAsked
        |> RemoteData.map
            (interface.getResource session
                |> .local
                |> Dict.values
                |> Maybe.Extra.values
                |> List.filter (.id >> (==) levelId)
                |> always
            )



-- LOAD BY ID


loadDraftsByDraftIds : List DraftId -> CmdUpdater Session SessionMsg
loadDraftsByDraftIds draftIds session =
    List.map loadDraftByDraftId draftIds
        |> flip CmdUpdater.batch session


loadDraftByDraftId : DraftId -> CmdUpdater Session SessionMsg
loadDraftByDraftId =
    loadResourceById interface


gotLoadDraftByIdResponse : DraftId -> Result GetError (Maybe Draft) -> CmdUpdater Session SessionMsg
gotLoadDraftByIdResponse =
    gotLoadResourceByIdResponse interface



-- LOAD BY LEVEL ID


loadDraftsByLevelId : LevelId -> Session -> ( Session, Cmd SessionMsg )
loadDraftsByLevelId levelId session =
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            if
                interface.getResource session
                    |> .draftsByLevelIdRequests
                    |> Dict.get levelId
                    |> Maybe.withDefault NotAsked
                    |> RemoteData.isNotAsked
            then
                Dict.insert levelId Loading
                    |> updateDraftsByLevelIdRequests
                    |> flip interface.updateResource session
                    |> withCmd
                        (GCP.get
                            |> GCP.withPath interface.path
                            |> GCP.withAccessToken accessToken
                            |> GCP.withStringQueryParameter "levelId" levelId
                            |> GCP.request (Data.GetError.expect (Json.Decode.list decoder) (GotLoadDraftsByLevelIdResponse levelId))
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
                |> flip interface.updateResource oldSession
    in
    case result of
        Ok drafts ->
            List.map (fanout .id Just) drafts
                |> List.map (uncurry (resolveConflict interface))
                |> flip CmdUpdater.batch session

        Err error ->
            gotGetError error session



-- SAVE


saveDraft : Draft -> Session -> ( Session, Cmd SessionMsg )
saveDraft =
    saveResource interface


gotSaveDraftResponse : Draft -> Maybe SaveError -> Session -> ( Session, Cmd msg )
gotSaveDraftResponse =
    gotSaveResourceResponse interface



-- DELETE


deleteDraftByDraftId : DraftId -> Session -> ( Session, Cmd SessionMsg )
deleteDraftByDraftId =
    deleteResourceById interface


gotDeleteDraftByIdResponse : DraftId -> Maybe SaveError -> Session -> ( Session, Cmd msg )
gotDeleteDraftByIdResponse =
    gotDeleteResourceByIdResponse interface



-- INTERNAL


updateResource : Updater DraftResource -> Updater Session
updateResource updater session =
    { session | drafts = updater session.drafts }
