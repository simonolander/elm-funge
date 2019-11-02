module Data.Session exposing
    ( Session
    , campaignError
    , campaignLoading
    , draftBookError
    , getAccessToken
    , getCampaign
    , getDraftBook
    , getHighScore
    , getLevel
    , getLevelsByCampaignId
    , getSolutionBook
    , highScoreError
    , highScoreLoading
    , init
    , levelError
    , levelLoading
    , setCampaignCache
    , setDraftBookCache
    , setHighScoreCache
    , setLevelCache
    , setSolutionBookCache
    , solutionBookError
    , updateBlueprints
    , updateCampaignRequests
    , updateDrafts
    , updateSavingDraftRequests
    , withActualBlueprintsRequest
    , withBlueprintCache
    , withCampaign
    , withCampaignCache
    , withCampaigns
    , withDraftBook
    , withDraftBookCache
    , withDraftCache
    , withHighScore
    , withHighScoreCache
    , withHighScoreResult
    , withLevel
    , withLevelCache
    , withLevels
    , withSession
    , withSolutionBook
    , withSolutionBookCache
    , withSolutionCache
    , withUrl
    , withUser
    , withoutAccessToken
    , withoutLevel
    )

import Browser.Navigation exposing (Key)
import Data.AccessToken exposing (AccessToken)
import Data.Blueprint exposing (Blueprint)
import Data.BlueprintId exposing (BlueprintId)
import Data.Cache as Cache exposing (Cache)
import Data.Campaign exposing (Campaign)
import Data.CampaignId exposing (CampaignId)
import Data.Draft exposing (Draft)
import Data.DraftBook as DraftBook exposing (DraftBook)
import Data.DraftId exposing (DraftId)
import Data.GetError exposing (GetError)
import Data.HighScore exposing (HighScore)
import Data.Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.RemoteCache as RemoteCache exposing (RemoteCache)
import Data.RequestResult exposing (RequestResult)
import Data.SaveError exposing (SaveError)
import Data.SaveRequest exposing (SaveRequest)
import Data.Solution exposing (Solution)
import Data.SolutionBook as SolutionBook exposing (SolutionBook)
import Data.SolutionId exposing (SolutionId)
import Data.Updater exposing (Updater)
import Data.User as User exposing (User)
import Data.UserInfo exposing (UserInfo)
import Dict exposing (Dict)
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Url exposing (Url)


type alias Drafts =
    RemoteCache DraftId (Maybe Draft)


type alias Session =
    { key : Key
    , url : Url
    , user : User
    , userInfo : Maybe UserInfo
    , expectedUserInfo : Maybe UserInfo
    , actualUserInfo : RemoteData GetError UserInfo
    , levels : Cache LevelId GetError Level
    , draftBooks : Cache LevelId GetError DraftBook
    , drafts : Drafts
    , savingDraftRequests : Dict DraftId (SaveRequest SaveError (Maybe Draft))
    , solutions : RemoteCache SolutionId (Maybe Solution)
    , campaignRequests : Cache CampaignId GetError ()
    , campaigns : Cache CampaignId GetError Campaign
    , blueprints : RemoteCache BlueprintId (Maybe Blueprint)
    , actualBlueprintsRequest : RemoteData GetError ()
    , highScores : Cache LevelId GetError HighScore
    , solutionBooks : Cache LevelId GetError SolutionBook
    }


init : Key -> Url -> Session
init key url =
    { key = key
    , url = url
    , user = User.guest
    , userInfo = Nothing
    , expectedUserInfo = Nothing
    , actualUserInfo = Nothing
    , levels = Cache.empty
    , drafts = RemoteCache.empty
    , savingDraftRequests = Dict.empty
    , solutions = RemoteCache.empty
    , campaignRequests = Cache.empty
    , campaigns = Cache.empty
    , blueprints = RemoteCache.empty
    , actualBlueprintsRequest = RemoteData.NotAsked
    , highScores = Cache.empty
    , draftBooks = Cache.empty
    , solutionBooks = Cache.empty
    }


withSession : a -> { b | session : a } -> { b | session : a }
withSession session model =
    { model | session = session }


withUser : User -> Updater Session
withUser user session =
    { session
        | user = user
    }


getAccessToken : Session -> Maybe AccessToken
getAccessToken =
    .user >> User.getToken


withoutAccessToken : Updater Session
withoutAccessToken session =
    let
        user =
            session.user
    in
    { session | user = { user | accessToken = Nothing } }


withUrl : Url -> Updater Session
withUrl url session =
    { session | url = url }


withLevelCache : Cache LevelId GetError Level -> Updater Session
withLevelCache cache session =
    { session | levels = cache }


withDraftCache : Drafts -> Updater Session
withDraftCache cache session =
    { session | drafts = cache }


updateDrafts : Updater Drafts -> Updater Session
updateDrafts updater session =
    { session | drafts = updater session.drafts }


updateBlueprints : Updater (RemoteCache BlueprintId (Maybe Blueprint)) -> Updater Session
updateBlueprints updater session =
    { session | blueprints = updater session.blueprints }


withSolutionCache : RemoteCache SolutionId (Maybe Solution) -> Updater Session
withSolutionCache cache session =
    { session | solutions = cache }


withCampaignCache : Cache CampaignId GetError Campaign -> Updater Session
withCampaignCache cache session =
    { session | campaigns = cache }


withHighScoreCache : Cache LevelId GetError HighScore -> Updater Session
withHighScoreCache cache session =
    { session | highScores = cache }


withDraftBookCache : Cache LevelId GetError DraftBook -> Updater Session
withDraftBookCache cache session =
    { session | draftBooks = cache }


withSolutionBookCache : Cache LevelId GetError SolutionBook -> Updater Session
withSolutionBookCache cache session =
    { session | solutionBooks = cache }


withBlueprintCache : RemoteCache BlueprintId (Maybe Blueprint) -> Updater Session
withBlueprintCache cache session =
    { session | blueprints = cache }


withActualBlueprintsRequest : RemoteData GetError () -> Updater Session
withActualBlueprintsRequest request session =
    { session | actualBlueprintsRequest = request }


updateCampaignRequests : (Cache CampaignId GetError () -> Cache CampaignId GetError ()) -> Updater Session
updateCampaignRequests updater session =
    { session | campaignRequests = updater session.campaignRequests }


updateSavingDraftRequests : Updater (Dict DraftId (SaveRequest SaveError (Maybe Draft))) -> Updater Session
updateSavingDraftRequests updater session =
    { session | savingDraftRequests = updater session.savingDraftRequests }



-- GETTERS


getLevelsByCampaignId : CampaignId -> Session -> RemoteData GetError (List Level)
getLevelsByCampaignId campaignId session =
    case Cache.get campaignId session.campaignRequests of
        NotAsked ->
            NotAsked

        Loading ->
            Loading

        _ ->
            Cache.values session.levels
                |> List.filterMap RemoteData.toMaybe
                |> List.filterMap Maybe.Extra.join
                |> List.filter (.campaignId >> (==) campaignId)
                |> RemoteData.succeed



-- LEVEL CACHE


setLevelCache : Session -> Cache LevelId GetError Level -> Session
setLevelCache session cache =
    { session | levels = cache }


getLevel : LevelId -> Session -> RemoteData GetError Level
getLevel levelId session =
    Cache.get levelId session.levels


withLevel : Level -> Updater Session
withLevel level session =
    session.levels
        |> Cache.withValue level.id level
        |> setLevelCache session


withLevels : List Level -> Updater Session
withLevels levels session =
    List.foldl withLevel session levels


withoutLevel : LevelId -> Updater Session
withoutLevel levelId session =
    session.levels
        |> Cache.remove levelId
        |> setLevelCache session


levelLoading : LevelId -> Updater Session
levelLoading levelId session =
    session.levels
        |> Cache.loading levelId
        |> setLevelCache session


levelError : LevelId -> GetError -> Updater Session
levelError levelId error session =
    session.levels
        |> Cache.withError levelId error
        |> setLevelCache session



-- CAMPAIGN CACHE


setCampaignCache : Session -> Cache CampaignId GetError Campaign -> Session
setCampaignCache session cache =
    { session | campaigns = cache }


getCampaign : CampaignId -> Session -> RemoteData GetError Campaign
getCampaign campaignId session =
    Cache.get campaignId session.campaigns


withCampaigns : List Campaign -> Updater Session
withCampaigns campaigns session =
    List.foldl withCampaign session campaigns


withCampaign : Campaign -> Updater Session
withCampaign campaign session =
    session.campaigns
        |> Cache.withValue campaign.id campaign
        |> setCampaignCache session


campaignLoading : CampaignId -> Updater Session
campaignLoading campaignId session =
    session.campaigns
        |> Cache.loading campaignId
        |> setCampaignCache session


campaignError : CampaignId -> GetError -> Updater Session
campaignError campaignId error session =
    session.campaigns
        |> Cache.withError campaignId error
        |> setCampaignCache session



-- HIGH SCORE CACHE


setHighScoreCache : Session -> Cache LevelId GetError HighScore -> Session
setHighScoreCache session cache =
    { session | highScores = cache }


getHighScore : LevelId -> Session -> RemoteData GetError HighScore
getHighScore levelId session =
    Cache.get levelId session.highScores


withHighScore : HighScore -> Updater Session
withHighScore highScore session =
    session.highScores
        |> Cache.withValue highScore.levelId highScore
        |> setHighScoreCache session


withHighScoreResult : RequestResult LevelId GetError HighScore -> Updater Session
withHighScoreResult { request, result } session =
    { session
        | highScores =
            Cache.fromResult request result session.highScores
    }


highScoreLoading : LevelId -> Updater Session
highScoreLoading levelId session =
    session.highScores
        |> Cache.loading levelId
        |> setHighScoreCache session


highScoreError : LevelId -> GetError -> Updater Session
highScoreError levelId error session =
    session.highScores
        |> Cache.withError levelId error
        |> setHighScoreCache session



-- DRAFT BOOK CACHE


setDraftBookCache : Session -> Cache LevelId GetError DraftBook -> Session
setDraftBookCache session cache =
    { session | draftBooks = cache }


getDraftBook : LevelId -> Session -> RemoteData GetError DraftBook
getDraftBook levelId session =
    Cache.get levelId session.draftBooks


withDraftBook : DraftBook -> Updater Session
withDraftBook draftBook session =
    session.draftBooks
        |> Cache.withDefault draftBook.levelId draftBook
        |> Cache.map draftBook.levelId (DraftBook.withDraftIds draftBook.draftIds)
        |> setDraftBookCache session


draftBookError : LevelId -> GetError -> Updater Session
draftBookError levelId error session =
    session.draftBooks
        |> Cache.withError levelId error
        |> setDraftBookCache session



-- SOLUTION BOOK CACHE


setSolutionBookCache : Session -> Cache LevelId GetError SolutionBook -> Session
setSolutionBookCache session cache =
    { session | solutionBooks = cache }


getSolutionBook : LevelId -> Session -> RemoteData GetError SolutionBook
getSolutionBook levelId session =
    Cache.get levelId session.solutionBooks


withSolutionBook : SolutionBook -> Updater Session
withSolutionBook solutionBook session =
    session.solutionBooks
        |> Cache.withDefault solutionBook.levelId solutionBook
        |> Cache.map solutionBook.levelId (SolutionBook.withSolutionIds solutionBook.solutionIds)
        |> setSolutionBookCache session


solutionBookError : LevelId -> GetError -> Updater Session
solutionBookError levelId error session =
    session.solutionBooks
        |> Cache.withError levelId error
        |> setSolutionBookCache session
