module Update.Level exposing
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
import Data.GetError exposing (GetError)
import Data.Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.Session as Session exposing (Session)
import Debug exposing (todo)
import Extra.Tuple exposing (fanout)
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Update.General exposing (gotGetError)
import Update.SessionMsg exposing (SessionMsg(..))



-- LOAD


loadLevelByLevelId : LevelId -> Session -> ( Session, Cmd SessionMsg )
loadLevelByLevelId levelId session =
    todo ""


getLevelByLevelId : LevelId -> Session -> RemoteData GetError (Maybe Level)
getLevelByLevelId levelId session =
    todo ""


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


loadLevelsByCampaignId : CampaignId -> Session -> ( Session, Cmd SessionMsg )
loadLevelsByCampaignId campaignId session =
    case Cache.get campaignId session.campaignRequests of
        NotAsked ->
            ( Session.updateCampaignRequests (Cache.loading campaignId) session
            , Data.Level.loadFromServerByCampaignId GotLoadLevelsByCampaignIdResponse campaignId
            )

        _ ->
            ( session, Cmd.none )


loadLevelsByCampaignIds : List CampaignId -> Session -> ( Session, Cmd SessionMsg )
loadLevelsByCampaignIds campaignIds session =
    List.map loadLevelsByCampaignId campaignIds
        |> flip fold session


gotLoadLevelResponse : LevelId -> Result GetError (Maybe Level) -> Session -> ( Session, Cmd SessionMsg )
gotLoadLevelResponse levelId result session =
    todo ""


gotLoadLevelsByCampaignIdResponse : CampaignId -> Result GetError (List Level) -> Session -> ( Session, Cmd SessionMsg )
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
                |> flip fold newSession

        Err error ->
            gotGetError error newSession



-- PRIVATE


gotLevel : LevelId -> Maybe Level -> Session -> ( Session, Cmd SessionMsg )
gotLevel levelId maybeLevel session =
    todo ""
