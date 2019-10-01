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
import Data.BlueprintBook exposing (BlueprintBook)
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
import Data.Solution exposing (Solution)
import Data.SolutionBook as SolutionBook exposing (SolutionBook)
import Data.SolutionId exposing (SolutionId)
import Data.User as User exposing (User)
import RemoteData exposing (RemoteData(..))
import Url exposing (Url)


type alias Session =
    { key : Key
    , url : Url
    , user : User
    , levels : Cache LevelId GetError Level
    , draftBooks : Cache LevelId GetError DraftBook
    , drafts : RemoteCache DraftId (Maybe Draft)
    , solutions : RemoteCache SolutionId (Maybe Solution)
    , campaigns : Cache CampaignId GetError Campaign
    , blueprints : RemoteCache BlueprintId (Maybe Blueprint)
    , blueprintBook : RemoteData GetError BlueprintBook
    , highScores : Cache LevelId GetError HighScore
    , solutionBooks : Cache LevelId GetError SolutionBook
    }


init : Key -> Url -> Session
init key url =
    { key = key
    , url = url
    , user = User.guest
    , levels = Cache.empty
    , drafts = RemoteCache.empty
    , solutions = RemoteCache.empty
    , campaigns = Cache.empty
    , blueprints = RemoteCache.empty
    , blueprintBook = RemoteData.NotAsked
    , highScores = Cache.empty
    , draftBooks = Cache.empty
    , solutionBooks = Cache.empty
    }


withSession : a -> { b | session : a } -> { b | session : a }
withSession session model =
    { model | session = session }


withUser : User -> Session -> Session
withUser user session =
    { session
        | user = user
    }


getAccessToken : Session -> Maybe AccessToken
getAccessToken =
    .user >> User.getToken


withoutAccessToken : Session -> Session
withoutAccessToken session =
    let
        user =
            session.user
    in
    { session | user = { user | accessToken = Nothing } }


withUrl : Url -> Session -> Session
withUrl url session =
    { session | url = url }


withLevelCache : Cache LevelId GetError Level -> Session -> Session
withLevelCache cache session =
    { session | levels = cache }


withDraftCache : RemoteCache DraftId (Maybe Draft) -> Session -> Session
withDraftCache cache session =
    { session | drafts = cache }


withSolutionCache : RemoteCache SolutionId (Maybe Solution) -> Session -> Session
withSolutionCache cache session =
    { session | solutions = cache }


withCampaignCache : Cache CampaignId GetError Campaign -> Session -> Session
withCampaignCache cache session =
    { session | campaigns = cache }


withHighScoreCache : Cache LevelId GetError HighScore -> Session -> Session
withHighScoreCache cache session =
    { session | highScores = cache }


withDraftBookCache : Cache LevelId GetError DraftBook -> Session -> Session
withDraftBookCache cache session =
    { session | draftBooks = cache }


withSolutionBookCache : Cache LevelId GetError SolutionBook -> Session -> Session
withSolutionBookCache cache session =
    { session | solutionBooks = cache }


withBlueprintCache : RemoteCache BlueprintId (Maybe Blueprint) -> Session -> Session
withBlueprintCache cache session =
    { session | blueprints = cache }


withBlueprintBook : RemoteData GetError BlueprintBook -> Session -> Session
withBlueprintBook blueprintBook session =
    { session | blueprintBook = blueprintBook }



-- LEVEL CACHE


setLevelCache : Session -> Cache LevelId GetError Level -> Session
setLevelCache session cache =
    { session | levels = cache }


getLevel : LevelId -> Session -> RemoteData GetError Level
getLevel levelId session =
    Cache.get levelId session.levels


withLevel : Level -> Session -> Session
withLevel level session =
    session.levels
        |> Cache.withValue level.id level
        |> setLevelCache session


withLevels : List Level -> Session -> Session
withLevels levels session =
    List.foldl withLevel session levels


withoutLevel : LevelId -> Session -> Session
withoutLevel levelId session =
    session.levels
        |> Cache.remove levelId
        |> setLevelCache session


levelLoading : LevelId -> Session -> Session
levelLoading levelId session =
    session.levels
        |> Cache.loading levelId
        |> setLevelCache session


levelError : LevelId -> GetError -> Session -> Session
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


withCampaigns : List Campaign -> Session -> Session
withCampaigns campaigns session =
    List.foldl withCampaign session campaigns


withCampaign : Campaign -> Session -> Session
withCampaign campaign session =
    session.campaigns
        |> Cache.withValue campaign.id campaign
        |> setCampaignCache session


campaignLoading : CampaignId -> Session -> Session
campaignLoading campaignId session =
    session.campaigns
        |> Cache.loading campaignId
        |> setCampaignCache session


campaignError : CampaignId -> GetError -> Session -> Session
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


withHighScore : HighScore -> Session -> Session
withHighScore highScore session =
    session.highScores
        |> Cache.withValue highScore.levelId highScore
        |> setHighScoreCache session


withHighScoreResult : RequestResult LevelId GetError HighScore -> Session -> Session
withHighScoreResult { request, result } session =
    { session
        | highScores =
            Cache.fromResult request result session.highScores
    }


highScoreLoading : LevelId -> Session -> Session
highScoreLoading levelId session =
    session.highScores
        |> Cache.loading levelId
        |> setHighScoreCache session


highScoreError : LevelId -> GetError -> Session -> Session
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


withDraftBook : DraftBook -> Session -> Session
withDraftBook draftBook session =
    session.draftBooks
        |> Cache.withDefault draftBook.levelId draftBook
        |> Cache.map draftBook.levelId (DraftBook.withDraftIds draftBook.draftIds)
        |> setDraftBookCache session


draftBookError : LevelId -> GetError -> Session -> Session
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


withSolutionBook : SolutionBook -> Session -> Session
withSolutionBook solutionBook session =
    session.solutionBooks
        |> Cache.withDefault solutionBook.levelId solutionBook
        |> Cache.map solutionBook.levelId (SolutionBook.withSolutionIds solutionBook.solutionIds)
        |> setSolutionBookCache session


solutionBookError : LevelId -> GetError -> Session -> Session
solutionBookError levelId error session =
    session.solutionBooks
        |> Cache.withError levelId error
        |> setSolutionBookCache session
