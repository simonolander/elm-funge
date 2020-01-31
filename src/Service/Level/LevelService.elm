module Update.LevelService exposing
    ( getLevelByLevelId
    , getLevelsByCampaignId
    , gotLoadLevelResponse
    , gotLoadLevelsByCampaignIdResponse
    , loadLevelByLevelId
    , loadLevelsByCampaignId
    , loadLevelsByCampaignIds
    )

import Basics.Extra exposing (flip, uncurry)
import Data.Cache as Cache
import Data.CampaignId exposing (CampaignId)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater)
import Data.GetError exposing (GetError)
import Data.Level exposing (Level, decoder)
import Data.LevelId exposing (LevelId)
import Data.Session as Session exposing (Session)
import Debug exposing (todo)
import Extra.Tuple exposing (fanout)
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Resource.LoadResourceService exposing (LoadResourceInterface, gotLoadResponse, loadPublic)
import Resource.RemoteDataDict as ResourceDict exposing (insertValue)
import Resource.ResourceType as ResourceType
import Update.SessionMsg exposing (SessionMsg(..))



-- LOAD


loadInterface : LoadResourceInterface LevelId Level LevelId {}
loadInterface =
    let
        updateSession updater session =
            let
                levels =
                    session.levels
            in
            { session | levels = { levels | cache = updater levels.cache } }

        mergeLevel id maybeLevel session =
            insertValue id maybeLevel
                |> flip updateSession session
                |> CmdUpdater.id
    in
    { updateSession = updateSession
    , getResourceDict = .levels >> .cache
    , resourceType = ResourceType.Level
    , decoder = decoder
    , responseMsg = GotLoadLevelByLevelIdResponse
    , toKey = identity
    , toString = identity
    , mergeResource = mergeLevel
    }


loadLevelByLevelId : LevelId -> CmdUpdater Session SessionMsg
loadLevelByLevelId levelId session =
    loadPublic loadInterface levelId session


gotLoadLevelByLevelIdResponse : LevelId -> Result GetError (Maybe Level) -> Session -> ( Session, Cmd SessionMsg )
gotLoadLevelByLevelIdResponse =
    gotLoadResponse loadInterface


getLevelByLevelId : LevelId -> Session -> RemoteData GetError (Maybe Level)
getLevelByLevelId levelId session =
    ResourceDict.get levelId session.levels.cache


getLevelsByCampaignId : CampaignId -> Session -> RemoteData GetError (List Level)
getLevelsByCampaignId campaignId session =
    case Cache.get campaignId session.campaignRequests of
        NotAsked ->
            NotAsked

        Loading ->
            Loading

        Failure error ->
            todo ""

        Success _ ->
            Cache.values session.levels
                |> List.filterMap RemoteData.toMaybe
                |> List.filterMap Maybe.Extra.join
                |> List.filter (.campaignId >> (==) campaignId)
                |> RemoteData.succeed


loadLevelsByCampaignId : CampaignId -> CmdUpdater Session SessionMsg
loadLevelsByCampaignId campaignId session =
    case Cache.get campaignId session.campaignRequests of
        NotAsked ->
            ( Session.updateCampaignRequests (Cache.loading campaignId) session
            , Data.Level.loadFromServerByCampaignId GotLoadLevelsByCampaignIdResponse campaignId
            )

        _ ->
            ( session, Cmd.none )


loadLevelsByCampaignIds : List CampaignId -> CmdUpdater Session SessionMsg
loadLevelsByCampaignIds campaignIds session =
    List.map loadLevelsByCampaignId campaignIds
        |> flip CmdUpdater.batch session


gotLoadLevelResponse : LevelId -> Result GetError (Maybe Level) -> CmdUpdater Session SessionMsg
gotLoadLevelResponse =
    gotLoadResponse loadInterface


gotLoadLevelsByCampaignIdResponse : CampaignId -> Result GetError (List Level) -> CmdUpdater Session SessionMsg
gotLoadLevelsByCampaignIdResponse campaignId result oldSession =
    let
        newSession =
            Result.map (always ()) result
                |> Cache.withResult campaignId
                |> flip Session.updateCampaignRequests oldSession
    in
    case result of
        Ok levels ->
            List.map (fanout .id Just >> uncurry gotLevel) levels
                |> flip CmdUpdater.batch newSession

        Err error ->
            gotGetError error newSession
