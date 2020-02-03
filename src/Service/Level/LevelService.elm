module Service.Level.LevelService exposing
    ( createFromLocalStorageEntries
    , getLevelByLevelId
    , getLevelsByCampaignId
    , gotLoadLevelByLevelIdResponse
    , gotLoadLevelsByCampaignIdResponse
    , loadLevelByLevelId
    , loadLevelsByCampaignId
    , loadLevelsByCampaignIds
    , reloadLevelsByCampaignId
    )

import Api.GCP as GCP
import Basics.Extra exposing (flip, uncurry)
import Data.CampaignId exposing (CampaignId)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater)
import Data.GetError as GetError exposing (GetError)
import Data.Level as Level exposing (Level, decoder)
import Data.LevelId exposing (LevelId)
import Data.Session exposing (Session)
import Dict
import Extra.Tuple exposing (fanout)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Service.InterfaceHelper exposing (createRemoteResourceInterface)
import Service.Level.LevelResource exposing (LevelResource, empty, updateLevelsByCampaignIdRequests)
import Service.LoadResourceService exposing (LoadResourceInterface, gotGetError, gotLoadResourceByIdResponse, loadPublicResourceById)
import Service.LocalStorageService exposing (getResourcesFromLocalStorageEntries)
import Service.RemoteDataDict as RemoteDataDict
import Service.RemoteRequestDict as RemoteRequestDict
import Service.RemoteResource as RemoteResource
import Service.ResourceType as ResourceType exposing (toIdParameterName, toPath)
import Update.SessionMsg exposing (SessionMsg(..))


interface =
    createRemoteResourceInterface
        { getRemoteResource = .levels
        , setRemoteResource = \r s -> { s | levels = r }
        , encode = Level.encode
        , decoder = Level.decoder
        , resourceType = ResourceType.Level
        , toString = identity
        , toKey = identity
        , fromString = identity
        , responseMsg = GotLoadLevelByLevelIdResponse
        }


createFromLocalStorageEntries : List ( String, Encode.Value ) -> ( LevelResource, List ( String, Decode.Error ) )
createFromLocalStorageEntries localStorageEntries =
    let
        { current, expected, errors } =
            getResourcesFromLocalStorageEntries interface localStorageEntries
    in
    ( { empty
        | actual = RemoteDataDict.fromList current
      }
    , errors
    )



-- LOAD BY LEVEL ID


getLevelByLevelId : LevelId -> Session -> RemoteData GetError (Maybe Level)
getLevelByLevelId levelId session =
    RemoteResource.getResourceById levelId session.levels


loadLevelByLevelId : LevelId -> CmdUpdater Session SessionMsg
loadLevelByLevelId levelId session =
    loadPublicResourceById interface levelId session


gotLoadLevelByLevelIdResponse : LevelId -> Result GetError (Maybe Level) -> Session -> ( Session, Cmd SessionMsg )
gotLoadLevelByLevelIdResponse =
    gotLoadResourceByIdResponse interface



-- LOAD BY CAMPAIGN ID


getLevelsByCampaignId : CampaignId -> Session -> RemoteData GetError (List Level)
getLevelsByCampaignId campaignId session =
    interface.getRemoteResource session
        |> .levelsByCampaignIdRequests
        |> RemoteRequestDict.get campaignId
        |> RemoteData.map
            (interface.getRemoteResource session
                |> .actual
                |> Dict.values
                |> List.filterMap RemoteData.toMaybe
                |> Maybe.Extra.values
                |> List.filter (.campaignId >> (==) campaignId)
                |> always
            )


loadLevelsByCampaignId : CampaignId -> CmdUpdater Session SessionMsg
loadLevelsByCampaignId campaignId session =
    if
        interface.getRemoteResource session
            |> .levelsByCampaignIdRequests
            |> RemoteRequestDict.get campaignId
            |> RemoteData.isNotAsked
    then
        reloadLevelsByCampaignId campaignId session

    else
        ( session, Cmd.none )


reloadLevelsByCampaignId : CampaignId -> CmdUpdater Session SessionMsg
reloadLevelsByCampaignId campaignId session =
    ( RemoteRequestDict.loading campaignId
        |> updateLevelsByCampaignIdRequests
        |> flip interface.updateRemoteResource session
    , GCP.get
        |> GCP.withPath (toPath interface.resourceType)
        |> GCP.withStringQueryParameter (toIdParameterName ResourceType.Campaign) campaignId
        |> GCP.request (GetError.expect (Decode.list decoder) (GotLoadLevelsByCampaignIdResponse campaignId))
    )


gotLoadLevelsByCampaignIdResponse : CampaignId -> Result GetError (List Level) -> CmdUpdater Session SessionMsg
gotLoadLevelsByCampaignIdResponse campaignId result oldSession =
    let
        session =
            RemoteRequestDict.insertResult campaignId result
                |> updateLevelsByCampaignIdRequests
                |> flip interface.updateRemoteResource oldSession
    in
    case result of
        Ok levels ->
            List.map (fanout .id (Just >> Ok)) levels
                |> List.map (uncurry gotLoadLevelByLevelIdResponse)
                |> flip CmdUpdater.batch session

        Err error ->
            gotGetError error session


loadLevelsByCampaignIds : List CampaignId -> CmdUpdater Session SessionMsg
loadLevelsByCampaignIds campaignIds session =
    List.map loadLevelsByCampaignId campaignIds
        |> flip CmdUpdater.batch session
